import module namespace docdb = "http://28.io/modules/documentdb";

declare function local:top-answered-questions($answers)
{
    subsequence(
        for $a in $answers
        order by $a.score descending
        return $a.question_id, 1, 3)
};

let $client := docdb:create-client(
    "jsoniq",
    "GxX7b2pTMTbKtgyMnZHi1npUTmGb9HxMr/tP4PJoHGkBC+Z4NaXRyU/EZATg+6aXJDfC4jPGPln217jvntgNjw==" 
)
for $answer in docdb:collection($client, "stackoverflow", "answers")
let $name := $answer.owner.display_name
group by $name
let $avg-rep := floor(avg($answer.owner.reputation))
order by $avg-rep descending empty least
return {
  name: $name,
  avg-rep: $avg-rep,
  top: local:top-answered-questions($answer)
}
