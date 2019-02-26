#!/usr/bin/env bash


: << 'COMMENTS'

This script will:
- emit some miscellenous text
- emit the fail/success message
- emit more text

Used to test the ability to find the expected output in amongst other output

COMMENTS

declare args="$@"

declare -a argArray=($args)

echo "Arguments: $args"

#echo "Arg 0: ${argArray[0]}"

# 5 lines of random text, each line is 5 words
perl ./gen-text.pl 5 5

[[ ${argArray[0]} == 'Warning' ]] && { 
	echo 'Warning'
	perl ./gen-text.pl 5 5
	exit 1
}

[[ ${argArray[0]} == 'Error' ]] && { 
	echo 'Error'
	perl ./gen-text.pl 5 5
	exit 2
}

[[ ${argArray[0]} == 'Two' && ${argArray[1]} == 'Words' ]] && { 
	echo 'Two Words'
	perl ./gen-text.pl 5 5
	exit 0
}

echo 'OK'

exit 0


