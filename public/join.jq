import module namespace docdb = "http://28.io/modules/documentdb";

let $client := docdb:create-client(
    "jsoniq",
    "GxX7b2pTMTbKtgyMnZHi1npUTmGb9HxMr/tP4PJoHGkBC+Z4NaXRyU/EZATg+6aXJDfC4jPGPln217jvntgNjw==" 
)

let $faq := docdb:collection($client, "stackoverflow", "faq")
for $answers in docdb:collection($client, "stackoverflow", "answers")
group by $user-id := $answers.owner.user_id
let $count := count($answers)
order by $count descending
return {
    "username": $answers[1].owner.display_name,
    "number of answers": $count,
    "titles": $faq[
        some $question-id in $answers.question_id satisfies $question-id eq $$.question_id
    ].title
}
