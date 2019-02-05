#!/usr/bin/env bash

: << 'COMMENT'

A simple script to add the 'return-type' line to existing JSON.

COMMENT


jsonToConvert=$1

[[ -z $jsonToConvert ]] && {
	echo
	echo Please provide the JSON file to convert
	echo
	exit 1
}

# validate the incoming JSON

./test-json.sh $jsonToConvert >/dev/null 2>&1

if [[ $? -ne 0 ]]; then
	echo
	echo The file $jsonToConvert does not contain valid JSON
	echo
	exit 2
fi

# check if already converted

if $(grep -q "result-type" $jsonToConvert); then
	echo
	echo "The file $jsonToConvert already has the 'result-type' data"
	echo 
	exit 3
fi

tmpJSONFile=/tmp/$$.json

while IFS= read line
do
	# capture the same spacing
	[[ $line =~ ([[:space:]]+) ]]
	space=${BASH_REMATCH[1]}
	#echo "SPACE: |$space|"
	if [[ $line =~ '"result" :' ]]; then
		echo "${space}"'"result-type" : "integer",'
	fi
	echo "$line"
done < $jsonToConvert > $tmpJSONFile

# validate the new JSON file

./test-json.sh $tmpJSONFile >/dev/null 2>&1

if [[ $? -ne 0 ]]; then
	echo
	echo Something has gone wrong 
	echo The tmp file $tmpJSONFile does not contain valid JSON
	echo Aborting...
	echo
	exit 4
fi

mv $jsonToConvert ${jsonToConvert}.orig
mv $tmpJSONFile $jsonToConvert 

rm -f $tmpJSONFile


