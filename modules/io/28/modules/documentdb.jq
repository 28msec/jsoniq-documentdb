jsoniq version "1.0";

module namespace d = "http://28.io/modules/documentdb";
import module namespace hmac = "http://zorba.io/modules/hmac";
import module namespace base64 = "http://zorba.io/modules/base64";
import module namespace dateTime = "http://zorba.io/modules/datetime";

import module namespace http-client = "http://zorba.io/modules/http-client";

declare %an:nondeterministic function d:now(
)
{
    let $current := dateTime:current-dateTime()
    let $rounded := $current
    return format-dateTime(
        adjust-dateTime-to-timezone(
            $rounded,
            xs:dayTimeDuration("PT0H")
        ),
        "[FNn,*-3], [D01] [MNn,*-3] [Y0001] [H01]:[m01]:[s01] GMT"
    )
};

declare function d:create-client(
    $account,
    $master-key
) as object
{
    {
        Host: "https://"||$account||".documents.azure.com:443",
        MasterKey: $master-key
    }
};

declare function d:sign-request(
    $verb as string, $resource-type as string, $resource-id as string, $ms-date as string, $date as string, $master-key as string) as string
{
    "type=master&ver=1.0&sig=" ||
        string(hmac:compute(
            lower-case($verb||"\n"||$resource-type||"\n"||$resource-id||"\n"||$ms-date||"\n"||$date||"\n"),
            base64:decode(base64Binary($master-key)),
            "sha256"
        ))
};

declare %an:nondeterministic function d:list-databases( 
    $client as object
) as object 
{
let $now := d:now()
let $request :=
    { href: $client.Host || "/dbs",
      headers: {
          "Authorization" :
            d:sign-request(
              "get",
              "dbs",
              "",
              $now,
              "",
              $client.MasterKey),
          x-ms-date: $now,
          Date: $now,
          Accept: "application/json" }
    }
let $response := http-client:send-nondeterministic-request($request)
let $body := parse-json($response.body.content)
return if($response.status eq 200) then $body else d:list-databases($client, 10)
};


declare %an:nondeterministic function d:list-databases( 
    $client as object,
    $retries as integer
) as object 
{
let $now := d:now()
let $request :=
    { href: $client.Host || "/dbs",
      headers: {
          "Authorization" :
            d:sign-request(
              "get",
              "dbs",
              "",
              $now,
              "",
              $client.MasterKey),
          x-ms-date: $now,
          Date: $now,
          Accept: "application/json" }
    }
let $response := http-client:send-nondeterministic-request($request)
let $body := parse-json($response.body.content)
return if($response.status eq 200) then $body else
    if($retries gt 0)
    then d:list-databases($client, $retries - 1)
    else error(QName("d:ERR0001"), $body.message, $request)
};


declare %an:nondeterministic function d:get-database( 
    $client as object,
    $dbid as string
) as object?
{
    d:list-databases($client).Databases[][$$.id eq $dbid]
};

declare %an:nondeterministic function d:list-collections( 
    $client as object,
    $database as string
) as object 
{
let $now := d:now()
let $db-object := d:get-database($client, $database)
let $request := { href: $client.Host || "/" || $db-object._self || $db-object._colls,
      headers: {
          "Authorization" :
            d:sign-request(
              "get",
              "colls",
              $db-object._rid,
              $now,
              "",
              $client.MasterKey),
          x-ms-date: $now,
          Date: $now,
          Accept: "application/json" }
    }
let $response := http-client:send-nondeterministic-request($request)
let $body := parse-json($response.body.content)
return if($response.status eq 200) then $body else d:list-collections($client, $database, 10)
};

declare %an:nondeterministic function d:list-collections( 
    $client as object,
    $database as string,
    $retries as integer
) as object 
{
let $now := d:now()
let $db-object := d:get-database($client, $database)
let $request := { href: $client.Host || "/" || $db-object._self || $db-object._colls,
      headers: {
          "Authorization" :
            d:sign-request(
              "get",
              "colls",
              $db-object._rid,
              $now,
              "",
              $client.MasterKey),
          x-ms-date: $now,
          Date: $now,
          Accept: "application/json" }
    }
let $response := http-client:send-nondeterministic-request($request)
let $body := parse-json($response.body.content)
return if($response.status eq 200) then $body else
    if($retries gt 0)
    then d:list-collections($client, $database, $retries - 1)
    else error(QName("d:ERR0001"), $body.message, $request)
};

declare %an:nondeterministic function d:get-collection( 
    $client as object,
    $dbid as string,
    $collid as string
) as object?
{
    d:list-collections($client, $dbid).DocumentCollections[][$$.id eq $collid]
};

declare %an:nondeterministic function d:collection( 
    $client as object,
    $dbid as string,
    $collid as string
) as object*
{
let $now := d:now()
let $collobject := d:list-collections($client, $dbid).DocumentCollections[][$$.id eq $collid]
let $request := 
    { href: $client.Host || "/" || $collobject._self || $collobject._docs,
      headers: {
          "Authorization" :
            d:sign-request(
              "get",
              "docs",
              $collobject._rid,
              $now,
              "",
              $client.MasterKey),
          x-ms-date: $now,
          Date: $now,
          Accept: "application/json" }
    }
let $response := http-client:send-nondeterministic-request($request)
let $body as object* := parse-json($response.body.content).Documents[]
return if($response.status eq 200) then $body else d:collection($client, $dbid, $collid, 10)
};

declare %an:nondeterministic function d:collection( 
    $client as object,
    $dbid as string,
    $collid as string,
    $retries as integer
) as object*
{
let $now := d:now()
let $collobject := d:list-collections($client, $dbid).DocumentCollections[][$$.id eq $collid]
let $request := 
    { href: $client.Host || "/" || $collobject._self || $collobject._docs,
      headers: {
          "Authorization" :
            d:sign-request(
              "get",
              "docs",
              $collobject._rid,
              $now,
              "",
              $client.MasterKey),
          x-ms-date: $now,
          Date: $now,
          Accept: "application/json" }
    }
let $response := http-client:send-nondeterministic-request($request)
let $body as object* := parse-json($response.body.content).Documents[]
return if($response.status eq 200) then $body else
    if($retries gt 0)
    then d:collection($client, $dbid, $collid, $retries -1 )
    else error(QName("d:ERR0001"), $body.message, $request)
};