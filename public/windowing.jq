import module namespace docdb = "http://28.io/modules/documentdb";

declare function local:epoch-seconds-to-dateTime($v)
as xs:dateTime
{
    xs:dateTime("1970-01-01T00:00:00-00:00") + xs:dayTimeDuration(concat("PT", $v, "S"))
};

let $client := docdb:create-client(
    "jsoniq",
    "GxX7b2pTMTbKtgyMnZHi1npUTmGb9HxMr/tP4PJoHGkBC+Z4NaXRyU/EZATg+6aXJDfC4jPGPln217jvntgNjw==" 
)
for $answers in docdb:collection($client, "stackoverflow", "answers")
group by $user-id := $answers.owner.user_id

let $answers := for $answer in $answers
                order by $answer.creation_date
                return {|
                    $answer,
                    { creation_dateTime: local:epoch-seconds-to-dateTime($answer.creation_date) }
                |}
               
let $streaks := for tumbling window $answers in $answers
start $start when true
end $end next $next when $next.creation_dateTime - $end.creation_dateTime gt dayTimeDuration("P7D")
return $end.creation_dateTime - $start.creation_dateTime

let $streak := max($streaks)
let $rep   := sum($answers.score)
let $count := count($answers)
order by $streak descending
return {
    "username": $answers[1].owner.display_name,
    "number of answers": $count,
    "reputation": $rep,
    "largest contribution streak": days-from-duration($streak)
}