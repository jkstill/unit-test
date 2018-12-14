#!/usr/bin/env bash

# unbound variable will cause an error
# good for catching vars with mis-typed names
set -u 

source ./ansi-color.sh

debug=${debug:-0}
declare internalDebug

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

if [[ $debug -eq 0 ]]; then
	internalDebug=1
else
	internalDebug=0
fi

isDebugEnabled () {
	return $internalDebug
}

printDebug () {
	declare msg="$@"

	if $(isDebugEnabled); then
		if [[ $useColor -ne 0 ]]; then
			colorPrint fg=lightYellow bg=blue msg="$msg"
		else
			echo "$msg"
		fi
	fi
}


##############################################
# use jq to parse JSON if it is available
##############################################

declare usePython=${usePython:-1}

jqBin=$(which jq)
pythonBin=$(which python)

declare jqVersion=$($jqBin --version 2>/dev/null)
declare useJQ=1
#echo jqVersion: "|$jqVersion|"

if [[ -n $jqVersion ]]; then
	useJQ=0
fi

printDebug "useJQ: $useJQ"

forcePython () {
	if [[ $usePython -eq 0 ]]; then
		return 1; # false
	else
		return 0; # true
	fi
}

isJQEnabled () {
	if $(forcePython); then
		return 1; # false
	else
		return $useJQ
	fi
}


# enable for timestamped log files
useTimeStamps=${useTimeStamps:-0}
timeStamp=$(date +%Y-%m-%d_%H-%M-%S)

# set useColor=0 should you want a log file without the escape codes
useColor=${useColor:-1}

printError () {
	declare msg="$@"
	if [[ $useColor -ne 0 ]]; then
		colorPrint fg=red bg=lightGray msg="$msg"
	else
		echo "$msg"
	fi
}

printErrorRpt () {
	declare msg="$@"
	if [[ $useColor -ne 0 ]]; then
		colorPrint fg=black bg=yellow msg="$msg"
	else
		echo "$msg"
	fi
}

printTestError () {
	declare msg="$@"
	if [[ $useColor -ne 0 ]]; then
		colorPrint fg=white bg=red msg="$msg"
	else
		echo "$msg"
	fi
}

printOK () {
	declare msg="$@"
	if [[ $useColor -ne 0 ]]; then
		colorPrint fg=black bg=lightGreen msg="$msg"
	else
		echo "$msg"
	fi
}

unitTestJson=${unitTestJson:-'unit-test.json'}
logFile=$(echo $unitTestJson | cut -f1 -d\.)
[[ $useTimeStamps -gt 0 ]] && logFile=${logFile}_${timeStamp}.log || logFile=${logFile}.log

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

run () {
	declare cmd="$*"
	echo "CMD: $cmd"
	if $(isExeEnabled); then
		#echo "CMD is Enabled"
		$cmd
	else
		echo "CMD is Disabled"
	fi
}



# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
# process substitution
> $logFile
exec > >(tee -ia $logFile)
exec 2> >(tee -ia $logFile >&2)
#exec 2>&1

exeEnable
## arg of -n means do not run executables, just show cmds
getopts n arg
#echo "ARG: $arg"
if [[ $arg = 'n' ]]; then
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
expectedResultCount=$(grep -Pc '"result"\s+:' $unitTestJson)

# 3 x any of them should equal the sum of all
# 3 because each test desscripotion has 3 lines
(( testCount = cmdCount + noteCount + expectedResultCount ))
(( chkCount = cmdCount * 3 ))

[[ $testCount -ne chkCount ]] && {
	printError "There is a problem in $unitTestJson - the count of cmds, notes and results are different"
}

#exit

# JSON data zero based
(( lineCount = cmdCount -1 ))

################################
# main program
################################

printDebug "lineCount: $lineCount"

#declare i=-1

# Read commands from JSON file
# Python is used because json is part of the standard install
# this one liner is a little clumsy, but easy to use
# pull requests for improvement here are welcome

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
		expectedRC[$i]=$(echo $line | cut -f3 -d^)

		(( i ++ ))
	done < <( $jqBin -r '.tests[] | [.notes, .cmd, .result] | @csv' $unitTestJson | sed -e 's/"//g'  |  perl -ne ' my @a=split(/,/); print join(qq{^},@a)' )

else

	for i in $( seq 0 $lineCount)
	do
		#python -c "import sys, json; print(json.load(sys.stdin)['tests']["$i"]['notes'])" < unit-test.jso
		cmds[$i]=$($pythonBin -c "import sys, json; print(json.load(sys.stdin)['tests']["$i"]['cmd'])" < $unitTestJson)
		cmdMessages[$i]=$($pythonBin -c "import sys, json; print(json.load(sys.stdin)['tests']["$i"]['notes'])" < $unitTestJson)
		expectedRC[$i]=$($pythonBin -c "import sys, json; print(json.load(sys.stdin)['tests']["$i"]['result'])" < $unitTestJson)
	done
fi


# this cannot be set until previous loop completes
idxCount=${#cmds[@]}
# arrays are zero based so decrement
(( idxCount-- ))

printDebug "idxCount: $idxCount"


for i in $( seq 0 $idxCount)
do
	#echo "CMD $i: ${cmds[$i]}"
	banner "${cmdMessages[$i]}"
	run ${cmds[$i]}
	tmpRC=$?

	# if dryrun via -n then set the return code to the expected value
	if $(isExeEnabled); then
		printDebug "Setting rc = $tmpRC"
		rc=$tmpRC
	else
		rc=expectedRC[$i]
	fi

	if [[ ${expectedRC[$i]} -ne $rc ]]; then

		(( FAIL_COUNT++ ))
		printTestError "Error encountered in ${cmds[$i]}\nExpected RC=${expectedRC[$i]} - Actual RC: $rc"

		# pushed fail info to arrays
		(( failedIDX++ ))

		failedCMD[$failedIDX]=${cmds[$i]}
		failedTest[$failedIDX]=${cmdMessages[$i]}
		failedExpectedRC[$failedIDX]=${expectedRC[$i]}
		failedActualRC[$failedIDX]=$rc

	else
		printOK "OK: ${cmds[$i]}"
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

