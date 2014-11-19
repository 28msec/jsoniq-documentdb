#JSONiq connector for DocumentDB

##How to use
Using the [28 CLI](https://github.com/28msec/28), you can deploy the connector to your own project
```bash
$ 28 upload myproject
```
To edit queries:
```bash
$ 28 watch myproject
```

Or by using the portal at http://hq.28.io

##Example
```jsoniq
import module namespace docdb = "http://28.io/modules/documentdb";

let $client := docdb:create-client(
    "jsoniq",
    "<master token>" 
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
```

