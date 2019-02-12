#!/usr/bin/env bash


declare args="$@"

declare -a argArray=($args)

# display output to verify unit-test.sh gets only the last line as the return value

echo "Arguments: $args"

#echo "Arg 0: ${argArray[0]}"

[[ ${argArray[0]} == 'Warning' ]] && { 
	echo 'Warning'
	exit 1
}

[[ ${argArray[0]} == 'Error' ]] && { 
	echo 'Error'
	exit 2
}

[[ ${argArray[0]} == 'Two' && ${argArray[1]} == 'Words' ]] && { 
	echo 'Two Words'
	exit 0
}

echo 'OK'

exit 0


