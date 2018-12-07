#!/usr/bin/env bash


: << 'COMMENTS'

If the first argument is 1 or 2, print warning or error message and exit appropriately

Otherwise print the arguments and exit 0

COMMENTS

declare args="$@"

declare -a argArray=($args)

#echo "Arg 0: ${argArray[0]}"

[[ ${argArray[0]} -eq 1 ]] && { 
	echo 'Script exiting with Warning'
	exit 1
}

[[ ${argArray[0]} -eq 2 ]] && { 
	echo 'Script exiting with Error'
	exit 2
}

echo "Args: $args"

exit 0


