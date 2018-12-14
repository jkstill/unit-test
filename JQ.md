
# JQ - JSON Query

Some examples of using jq to query the JSON config files

## object output

jq may be used to parse the JSON files if available

jq '{ comment: .comments, version: .version, tests: [ .tests[]  | { cmd: .cmd } ] }' test.json

jq '{ comment: .comments, version: .version }' test.json

jq '{ tests: [ .tests[]  | { cmd: .cmd } ] }' test.json


jq '{ tests: [ .tests[]  | { notes: .notes } ] }' test.json


jq '{ tests: [ .tests[]  | { result: .result } ] }' test.json


jq '{ tests: [ .tests[]  | { notes: .notes, cmd: .cmd, result: .result } ] }' test.json

## array [] output

jq '{ tests: [ .tests[]  | [  .notes,  .cmd, .result ] ] }' test.json


## CSV Output

jq -r '.tests[] | [.notes, .cmd, .result] | @csv' test.json


## CSV output with quotes removed

jq -r '.tests[] | [.notes, .cmd, .result] | @csv' test.json \
  | sed -e 's/"//g' \
  |  perl -ne ' my @a=split(/,/); print join(qq{^},@a)' \
  | cut -f1 -d^

