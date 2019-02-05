#!/usr/bin/env bash

# unbound variable will cause an error
# good for catching vars with mis-typed names
set -u 

source ./ansi-color.sh

##############################
# Variables that can be 
# controlled from CLI
##############################

##############################
# enable debug
# use debug=1 on CLI to enable
##############################
declare debug=${debug:-0}

declare internalDebug

if [[ $debug -eq 0 ]]; then
	internalDebug=1
else
	internalDebug=0
fi

#####################
# print help
#####################
declare help=${help:-0}

######################################
# control use of color in logfile
# set useColor=0 should you want a log file without the escape codes
######################################
declare useColor=${useColor:-1}

###############################################
# control the use of python for parsing JSON
# python is used if jq is not installed
# this can force the use of Python
###############################################
declare usePython=${usePython:-0}

####################################
# enable for timestamped log files
# useTimeStamps=1 on the command line
###################################
declare useTimeStamps=${useTimeStamps:-0}
declare timeStamp=$(date +%Y-%m-%d_%H-%M-%S)

###################################
# set the JSON file name
# unitTestJson=some-file-name.json
##################################
declare unitTestJson=${unitTestJson:-'unit-test.json'}
declare logFile=$(echo $unitTestJson | cut -f1 -d\.)
[[ $useTimeStamps -gt 0 ]] && logFile=${logFile}_${timeStamp}.log || logFile=${logFile}.log

#########################################
# dry run only 
# display commands but do not execute
#########################################
declare dryRun=${dryRun:-0}


#########################################
# other global vars
#########################################

# the number of key value pairs per object
# currently
# - notes
# - cmd
# - result-type
# - result
declare valuesPerObject=4

declare -a jqColumns

jqColumns[0]='.notes'
jqColumns[1]='.cmd'
jqColumns[2]='."result-type"'
jqColumns[3]='.result'

# lowest element  is 0, so subtract 1 as this reports count
declare jqLastEl=${#jqColumns[@]}
(( jqLastEl-- )) 

# values that functions return for success/failure
declare funcSuccessRetval=0
declare funcFailRetval=1

: << 'COMMENT'

internalDebug: reverse value of debug

variables are set at the command line to disable or enable a feature

show debug output

debug=1

disable debug output

debug=0

shell return values are the opposite

0 = true
!0 = false

COMMENT

isDebugEnabled () {
	return $internalDebug
}

disableDebug () {
	internalDebug=$funcFailRetval
}

enableDebug () {
	internalDebug=$funcSuccessRetval
}

## use the actual values, not the logical ones
## used for getting/setting state such as when we do not want debug to run

getDebug () {
	echo $internalDebug
}

setDebug () {
	internalDebug=$1
}

printDebug () {
	declare msg="$@"

	if $(isDebugEnabled); then
		if [[ $useColor -ne 0 ]]; then
			# redirect this call to STDERR as all debug statements to go to STDERR
			# save old STDOUT
			exec 7>&1
			# redirect STDOUT to STDERR
			exec 1>&2
			# output
			colorPrint fg=lightYellow bg=blue msg="$msg"
			# restore STDOUT and close 7
			exec 1>&7 7>&-
		else
			echo 1>&2 "$msg"
		fi
	fi
}

help () {

	 basename $0
 
cat <<-EOF
  Set Variables on the CLI to control
  ( getopts not used)

  useColor=[0|1]
    0: do not use colors
    1: use colors (default)

  useTimeStamps=[0|1]
    0: do not use timestamps when creating log files (default)
    1: use timestamps when creating log files

  unitTestJson='filename'
    default is 'unit-test.json

  usePython=[0|1]
    0: parse with Python only if JQ (jquery) is not installed (default)
    1: parse with Python 

  debug=[0|1]
    0: do not print debug statements (default)
    1: print debug statements

  dryRun=[0|1]
    0: run all tests (default)
    1: do not run tests - print the CMDs to be run

  help=[0|1]
    0: do not show help (default)
    1: show help and exit

EOF

}


##############################################
# use jq to parse JSON if it is available
##############################################

jqBin=$(which jq)
pythonBin=$(which python)

declare jqVersion=$($jqBin --version 2>/dev/null)
declare useJQ=1
printDebug "jqVersion: $jqVersion"

if [[ -n $jqVersion ]]; then
	useJQ=0
fi

printDebug "useJQ: $useJQ"

forcePython () {
	if [[ $usePython -eq 0 ]]; then
		return $funcFailRetval; # false
	else
		return $funcSuccessRetval; # true
	fi
}

isJQEnabled () {
	if $(forcePython); then
		return $funcFailRetval; # false
	else
		return $useJQ
	fi
}



printError () {
	declare msg="$@"
	if [[ $useColor -ne 0 ]]; then

		# redirect this call to STDERR as all debug statements to go to STDERR
		# save old STDOUT
		exec 7>&1
		# redirect STDOUT to STDERR
		exec 1>&2
		# output
		colorPrint fg=red bg=lightGray msg="$msg"
		# restore STDOUT and close 7
		exec 1>&7 7>&-
	else
		echo 1>&2 "$msg"
	fi
}

printErrorRpt () {
	declare msg="$@"
	if [[ $useColor -ne 0 ]]; then
		# redirect this call to STDERR as all debug statements to go to STDERR
		# save old STDOUT
		exec 7>&1
		# redirect STDOUT to STDERR
		exec 1>&2
		# output
		colorPrint fg=black bg=yellow msg="$msg"
		# restore STDOUT and close 7
		exec 1>&7 7>&-
	else
		echo 1>&2 "$msg"
	fi
}

printTestError () {
	declare msg="$@"
	if [[ $useColor -ne 0 ]]; then
		# redirect this call to STDERR as all debug statements to go to STDERR
		# save old STDOUT
		exec 7>&1
		# redirect STDOUT to STDERR
		exec 1>&2
		# output
		colorPrint fg=white bg=red msg="$msg"
		# restore STDOUT and close 7
		exec 1>&7 7>&-
	else
		echo 1>&2 "$msg"
	fi
}

printOK () {
	declare msg="$@"
	if [[ $useColor -ne 0 ]]; then
		# redirect this call to STDERR as all debug statements to go to STDERR
		# save old STDOUT
		exec 7>&1
		# redirect STDOUT to STDERR
		exec 1>&2
		# output
		colorPrint fg=black bg=lightGreen msg="$msg"
		# restore STDOUT and close 7
		exec 1>&7 7>&-
	else
		echo 1>&2 "$msg"
	fi
}


if $(isDebugEnabled); then
	echo "Log File: $logFile"
	echo "Unit Test: $unitTestJson"
	#exit
fi


[[ -r $unitTestJson ]] || {
	echo
	printError "Could not open $unitTestJson!"
	echo 
	exit 1
}

# test the JSON file to be at least syntactically correct
if $(isJQEnabled); then
	printDebug "parsing JSON with JQ"
	[[ -x $jqBin ]] || {
		echo
		printf "\n!! executable for jq is not available !!\n\n"
		exit 1
	}
	$jqBin . $unitTestJson >/dev/null 2>/dev/null
else
	printDebug "parsing JSON with Python"
	[[ -x $pythonBin ]] || {
		echo
		printf "\n!! executable for python is not available !!\n\n"
		exit 1
	}
	$pythonBin -c "import sys, json; print 'version:', (json.load(sys.stdin)['version'])" < $unitTestJson >/dev/null 2>/dev/null
fi
rc=$?

[[ $rc -ne 0 ]] && {
	echo
	printError "JSON File $unitTestJson is invalid!"
	printError "check syntax with 'test-json.sh  $unitTestJson'"
	echo 
	exit 1
}

bannerChr='#'
bannerLine=$(perl -e "print '$bannerChr' x 80")
exeEnabled=0

banner () {
	declare bannerText="$@"

	echo
	echo $bannerLine
	printf "$bannerChr $bannerText\n"
	echo $bannerLine
	echo
}

exeEnable () {
	exeEnabled=0
}

exeDisable () {
	exeEnabled=1
}

isExeEnabled () {
	return $exeEnabled
}

# if $(executionSucceeded ${returnTypes[$i]} ${expectedRC[$i]}); then

executionSucceeded () {
	declare returnType=$1
	declare expectedVal=$2
	declare actualVal=$3

	printDebug "====  executionSucceeded ===="
	printDebug "returnType: $returnType"
	printDebug "expectedVal: $expectedVal"
	printDebug "actualVal: $actualVal"

	declare retval=$funcFailRetval # default is fail ( 0 is success )
	declare actualType

	# is it a number?
	declare actualValIsNumber='N';

	if [[ $actualVal =~ ^[[:digit:]]+ ]]; then
		actualValIsNumber='Y'
	fi
	printDebug "is number: $actualValIsNumber"

	if [[ $returnType = 'string' ]]; then

		if [[ $actualVal == $expectedVal ]]; then
			retval=$funcSuccessRetval
		else
			retval=$funcFailRetval
		fi
	
	else # numeric
		if [[ $actualValIsNumber == 'Y' ]]; then
			if [[ $actualVal -eq $expectedVal ]]; then
				retval=$funcSuccessRetval
			else
				retval=$funcFailRetval
			fi
		else
			printError "Expected a Numeric return of "$expectedVal" but got "$actualVal" instead"
			retval=$funcFailRetval
		fi
	fi

	return $retval
}

# always echo the return value for consistency

run () {
	declare returnType=$1
	shift
	declare cmd="$*"

	declare retval

	#echo 1>&2 "CMD: $cmd"
	#echo 1>&2 "Return Type: $returnType"

	if $(isExeEnabled); then
		#echo "CMD is Enabled"

		# eval "$cmd" is used as some commands take this form
		# set_some_var=1 ./run-my-test.sh.
		# simulated on the command line:
		# "x=1 ls" - does not work
		# eval "x=1 ls" - this does work

		echo 1>&2 "arg type: $returnType"

		if [[ $returnType == 'string' ]]; then
			echo 1>&2 "Evaluating string"
			retval=$(eval "$cmd")
		else
			echo 1>&2 "Evaluating integer"
			eval 1>&2 "$cmd"
			retval=$?
		fi
	else
		#echo 1>&2 "CMD is Disabled"
		:
	fi

	echo $retval
}



# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
# process substitution
> $logFile
exec > >(tee -ia $logFile)
exec 2> >(tee -ia $logFile >&2)
#exec 2>&1

exeEnable
if [[ $dryRun -ne 0 ]]; then
	exeDisable
fi

##############################
# variable declarations
##############################


FAIL_COUNT=0

# put commands and banners in arrays

# stuff cmds and messages into arrays

declare -a cmds
declare -a cmdMessages
declare -a returnTypes
declare -a expectedRC  # RC = result code

# stacks for tests that fail
declare -a failedCMD
declare -a failedTest
declare -a failedExpectedRC
declare -a failedActualRC

failedIDX=-1

# get the count of commands, notes and expected results
# all 3 should be the same value

cmdCount=$(grep -Pc '"cmd"\s+:' $unitTestJson)
noteCount=$(grep -Pc '"notes"\s+:' $unitTestJson)
rcTypeCount=$(grep -Pc '"result-type"\s+:' $unitTestJson)
expectedResultCount=$(grep -Pc '"result"\s+:' $unitTestJson)

# valuesPerObject x any of them should equal the sum of all
# valuesPerObject because each test desscripotion has N lines
(( testCount = cmdCount + noteCount + rcTypeCount + expectedResultCount ))
(( chkCount = cmdCount * valuesPerObject ))

[[ $testCount -ne chkCount ]] && {
	printError "There is a problem in $unitTestJson - the count of cmds, notes and results are different"
	exit 1;
}

#exit

# JSON data zero based
(( lineCount = cmdCount -1 ))

################################
# main program
################################

if [[ $help -ne 0 ]]; then
	help
	exit
fi

printDebug "lineCount: $lineCount"

#declare i=-1

# Read commands from JSON file
# Python is used because json is part of the standard install
# this one liner is a little clumsy, but easy to use
# pull requests for improvement here are welcome

printDebug "Reading JSON file $unitTestJson"

# build up the jq command

declare jqCmd="$jqBin -r '.tests[] | [" 
declare jqColumnList=''

for el in $(seq 0 $jqLastEl)
do

	jqColumnList="$jqColumnList ${jqColumns[$el]}"

	[[ $el -lt $jqLastEl ]] && {
		jqColumnList="$jqColumnList ,"
	}
	
done

jqCmd="$jqCmd $jqColumnList ] | @csv' "

printDebug jqCmd: $jqCmd

if $(isJQEnabled); then

	# separated with ^ to avoid possible issues with commas in data
	declare i=0

	# using this method of reading input stores entire line in the 'line' variable
	# the from of 'for line in $(do something)' causes IFS to store only the first space-separated word
	while read line
	do

		# printDebug "line: $line"
		cmdMessages[$i]=$(echo $line | cut -f1 -d^)
		cmds[$i]=$(echo $line | cut -f2 -d^)
		returnTypes[$i]=$(echo $line | cut -f3 -d^)
		expectedRC[$i]=$(echo $line | cut -f4 -d^)
		printDebug "CMD: ${cmds[$i]}"
		printDebug "       Return Type: ${returnTypes[$i]}"
		printDebug "   Expected Return: ${expectedRC[$i]}"

		(( i ++ ))
	#done < <( $jqBin -r '.tests[] | [.notes, .cmd, ."result-type", .result] | @csv' $unitTestJson | sed -e 's/"//g'  |  perl -ne ' my @a=split(/,/); print join(qq{^},@a)' )
	done < <( ( eval $jqCmd $unitTestJson ) | sed -e 's/"//g'  |  perl -ne ' my @a=split(/,/); print join(qq{^},@a)' )

else

	for i in $( seq 0 $lineCount)
	do
		#python -c "import sys, json; print(json.load(sys.stdin)['tests']["$i"]['notes'])" < unit-test.jso
		cmds[$i]=$($pythonBin -c "import sys, json; print(json.load(sys.stdin)['tests']["$i"]['cmd'])" < $unitTestJson)
		cmdMessages[$i]=$($pythonBin -c "import sys, json; print(json.load(sys.stdin)['tests']["$i"]['notes'])" < $unitTestJson)
		returnTypes[$i]=$($pythonBin -c "import sys, json; print(json.load(sys.stdin)['tests']["$i"]['result-type'])" < $unitTestJson)
		expectedRC[$i]=$($pythonBin -c "import sys, json; print(json.load(sys.stdin)['tests']["$i"]['result'])" < $unitTestJson)
		printDebug "CMD: ${cmds[$i]}"
		printDebug "       Return Type: ${returnTypes[$i]}"
		printDebug "   Expected Return: ${expectedRC[$i]}"
	done
fi

#exit


# this cannot be set until previous loop completes
idxCount=${#cmds[@]}
# arrays are zero based so decrement
(( idxCount-- ))

printDebug "idxCount: $idxCount"

: << 'DEBUG-FLAG-TEST' 
# test the enable/disable of debug
enableDebug
declare debugStateTest=$(getDebug)
disableDebug

echo Debug should be disabled
if $(isDebugEnabled); then
	echo "  Fail! - Debug is still enabled"
else
	echo "  Success - Debug is disabled"
fi

setDebug $debugStateTest

echo Debug should be enabled
if $(isDebugEnabled); then
	echo "  Success - Debug is enabled"
else
	echo "  Fail! - Debug is still disabled"
fi

exit

DEBUG-FLAG-TEST

for i in $( seq 0 $idxCount)
do
	echo "CMD $i: ${cmds[$i]}"
	banner "${returnTypes[$i]} | ${cmdMessages[$i]}"
	tmpRC=$(run ${returnTypes[$i]} ${cmds[$i]} )
	#tmpRC=$?

	# if dryrun via dryRun=1 then set the return code to the expected value
	if $(isExeEnabled); then
		printDebug "Setting rc = $tmpRC"
		rc=$tmpRC
	else
		rc=expectedRC[$i]
	fi

	# change this to test expected outcome based on the return-type
	#if [[ ${expectedRC[$i]} -ne $rc ]]; then

	# trace the function that determines success or failure
	if $(isDebugEnabled); then
		printDebug "Execution State Test"
		executionSucceeded ${returnTypes[$i]} ${expectedRC[$i]} $rc
	fi

	# this next will not work if debug is enabled
	# save the state and then re-enable
	declare currDebugState=$(getDebug)
	echo "currDebugState: |$currDebugState|"
	disableDebug;

	if $(executionSucceeded ${returnTypes[$i]} ${expectedRC[$i]} $rc); then
		printOK "OK: ${cmds[$i]}"
		setDebug $currDebugState
	else

		setDebug $currDebugState

		(( FAIL_COUNT++ ))
		printTestError "Error encountered in ${cmds[$i]}\nExpected RC=${expectedRC[$i]} - Actual RC: $rc"

		# pushed fail info to arrays
		(( failedIDX++ ))

		failedCMD[$failedIDX]=${cmds[$i]}
		failedTest[$failedIDX]=${cmdMessages[$i]}
		failedExpectedRC[$failedIDX]=${expectedRC[$i]}
		failedActualRC[$failedIDX]=$rc

	fi

done

echo

if [[ $FAIL_COUNT -gt 0 ]]; then

	failedCount=${#failedCMD[@]}

	echo
	if [[ $useColor -ne 0 ]]; then
		colorPrint fg=white bg=red msg="$failedCount tests have failed"
	else
		echo "$failedCount tests have failed"
	fi
	echo

	# decrement for zero based
	(( failedCount-- ))

	# output the failed items
	printErrorRpt "$bannerLine"
	printErrorRpt "$bannerChr Error Report"
	printErrorRpt "$bannerLine"

	for i in $( seq 0 $failedCount )
	do
		printErrorRpt "Test: ${failedTest[$i]}"
		printErrorRpt "CMD: ${failedCMD[$i]}"
		printErrorRpt "Expected RC: ${failedExpectedRC[$i]}"
		printErrorRpt "  ACtual RC: ${failedActualRC[$i]}"
		printErrorRpt "============================================================"
	done

else 
	printOK "All Tests Passed!"
fi

echo
printOK "Output is in $logFile"
echo

