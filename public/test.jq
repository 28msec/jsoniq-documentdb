import module namespace d = "http://28.io/modules/documentdb";

let $client := d:create-client(
    "28msec",
    "WR3BIb8iqy/4WQ84rtAniwXVs75htuRL+SKCcsa7Wb5nOMTj8sRc0jlcmLhAXd57/c9LOQxi4Rc4KpHUWzchVA==" 
)
return d:list-databases($client)