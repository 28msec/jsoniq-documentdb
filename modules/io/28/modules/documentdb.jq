jsoniq version "1.0";

module namespace d = "http://28.io/modules/documentdb";
import module namespace hmac = "http://zorba.io/modules/hmac";
import module namespace base64 = "http://zorba.io/modules/base64";

import module namespace http-client = "http://zorba.io/modules/http-client";

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

declare %an:sequential function d:list-databases( 
    $client as object
) as object 
{
let $now := format-dateTime(adjust-dateTime-to-timezone(current-dateTime(), xs:dayTimeDuration("PT0H")), "[FNn,*-3], [D01] [MNn,*-3] [Y0001] [H01]:[m01]:[s01] GMT")
return
parse-json(http-client:send-request(
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
    }).body.content)
};