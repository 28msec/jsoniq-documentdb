import module namespace d = "http://28.io/modules/documentdb";

let $client := d:create-client(
    "jsoniq",
    "GxX7b2pTMTbKtgyMnZHi1npUTmGb9HxMr/tP4PJoHGkBC+Z4NaXRyU/EZATg+6aXJDfC4jPGPln217jvntgNjw==" 
)
return (
    try { d:collection($client, "stackoverflow", "answers") } catch * { $err:description, $err:value }
)