#!/usr/bin/env bash


: << 'COMMENTS'

If the first argument is 1 or 2, print warning or error message and exit appropriately

Otherwise print the arguments and exit 0

COMMENTS

declare args="$@"

declare -a argArray=($args)

#echo "Arg 0: ${argArray[0]}"

[[ ${argArray[0]} == 'Warning' ]] && { 
	echo 'Warning'
	exit 1
}

[[ ${argArray[0]} == 'Error' ]] && { 
	echo 'Error'
	exit 2
}

echo "OK"

exit 0


