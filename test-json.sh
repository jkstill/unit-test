#!/usr/bin/env bash

jsonFile=${1:-'test.json'}

python -c "import sys, json; print 'version:' , (json.load(sys.stdin)['version'])" < $jsonFile

