#!/usr/bin/env bash

# unbound variable will cause an error
# good for catching vars with mis-typed names
set -u 

source ./ansi-color.sh

###################################
# stuff that needs to be at the top
###################################

declare -A globals
# define but do not initialize

globals[internalDebug]=''

: << 'BOOLEANS'

Shell expects the return of a command to be 0 if successful

Variables are often set to 1 to enable a feature, or 0 to disable

Testing variables and results can be confusing.

The use of booleans may help mitigate that - it is worth testing at least

setBoolConf can be used to set configuration values to true or false for those that enable/disable a feature

if the variable is 1, set true

if the variable is not 1, set false

BOOLEANS

setBoolConf () {
	declare var2set=$1
	declare val2set=$2

	#echo "setBoolConf DEBUG var2set: $var2set"
	#echo "setBoolConf DEBUG val2set: $val2set"

	declare internalBool

	[[ $val2set -eq 1 ]] && internalBool=true || internalBool=false

	#echo "setBoolConf DEBUG internalBool: $internalBool"

	printf -v $var2set $internalBool

}

##############################
# Variables that can be 
# controlled from CLI
##############################

##############################
# enable debug
# use debug=1 on CLI to enable
##############################
declare debug=${debug:-0}
setBoolConf globals[internalDebug] $debug

#if [[ $debug -eq 0 ]]; then
	#internalDebug=1
#else
	#internalDebug=0
#fi

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

declare boolSuccessRetval=true
declare boolFailRetval=false

# channel where STDOUT is saved
: << 'COMMENT'

An attempt was made to use variables to save and restore file descriptors

For some reason using variables names does not work correctly.

The usage appears to be correct as per documention, so I am not sure what the problem is.

What happens when variables are used:

The run() function will encounter an invalid file descriptor (fd).

When the fd values are hardcoded all works fine.

When variables are used, it breaks.

This has nothing to do with the code that redirects stdout/stderr to a tee coprocess just a few lines below.
Removing those lines does not change the behavior

Bash at this time is version 4.3.48

And so these variables are not currently used, but may be in the future if I can learn how to make this work properly with variables.

COMMENT

declare -a channels
declare rptChannel=6
declare stdoutSaveChannel=7
declare stderrSaveChannel=8
declare STDIN=0
declare STDOUT=1
declare STDERR=2

# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
# process substitution
# clear/recreate the logfile
> $logFile
#exec {channels[$rptChannel]> >(tee -ia $logFile)
exec 1> >(tee -ia $logFile)
exec 2> >(tee -ia $logFile >&2)

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

disableDebug () {
	globals[internalDebug]=$boolFailRetval
}

enableDebug () {
	globals[internalDebug]=$boolSuccessRetval
}

## use the actual values, not the logical ones
## used for getting/setting state such as when we do not want debug to run

getDebug () {
	echo ${globals[internalDebug]}
}

setDebug () {
	globals[internalDebug]=$1
}

: << 'COMMENT'

Why is STDOUT being redirected to STDERR?

If a script under test indicates succuss/failure by the last text string that it output,
we need to capture that string.

This script unit-test.sh also writes informational and debugging error messages.
This are being written to STDERR so as not to interfere with output from the scripts under test.

See the comments near the top of the script about redirection with variables.

For some reason the use of variables for fd redirection is not working.

COMMENT

redirectSTDOUT () {

	# save old STDOUT
	#exec {channels[$stdoutSaveChannel]}>&"$STDOUT"
	#exec {stdoutSaveChannel}>&"$STDOUT"
	exec 7>&1

	# redirect STDOUT to STDERR
	#exec {channels[$STDOUT]}>&"$STDERR"
	#exec {STDOUT}>&"$STDERR"
	exec 1>&2
}

restoreSTDOUT () {

	# restore STDOUT
	#exec {channels[$STDOUT]}>&"${channels[$stdoutSaveChannel]}"
	#exec {STDOUT}>&"$stdoutSaveChannel"
	exec 1>&7 

	# close the save channel
	#exec {channels[$stdoutSaveChannel]}>&-
	#exec {stdoutSaveChannel}>&-
	exec 7>&-


}

printDebug () {
	declare msg="$@"

	if [[ ${globals[internalDebug]} == true ]]; then
		if [[ $useColor -ne 0 ]]; then
			# redirect this call to STDERR as all debug statements to go to STDERR
			redirectSTDOUT
			colorPrint fg=lightYellow bg=blue msg="$msg"
			restoreSTDOUT
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

		redirectSTDOUT
		colorPrint fg=red bg=lightGray msg="$msg"
		restoreSTDOUT
	else
		echo 1>&2 "$msg"
	fi
}

printErrorRpt () {
	declare msg="$@"
	if [[ $useColor -ne 0 ]]; then
		redirectSTDOUT
		colorPrint fg=black bg=yellow msg="$msg"
		restoreSTDOUT
	else
		echo 1>&2 "$msg"
	fi
}

printTestError () {
	declare msg="$@"
	if [[ $useColor -ne 0 ]]; then
		redirectSTDOUT
		colorPrint fg=white bg=red msg="$msg"
		restoreSTDOUT
	else
		echo 1>&2 "$msg"
	fi
}

printOK () {
	declare msg="$@"
	if [[ $useColor -ne 0 ]]; then
		redirectSTDOUT
		colorPrint fg=black bg=lightGreen msg="$msg"
		restoreSTDOUT
	else
		echo 1>&2 "$msg"
	fi
}

printMsg () {
	declare msg="$@"
	redirectSTDOUT
	if [[ $useColor -ne 0 ]]; then
		colorPrint fg=black bg=cyan msg="$msg"
	else
		echo "$msg"
	fi
	restoreSTDOUT
}


if [[ ${globals[internalDebug]} == true ]]; then
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

exeEnable
if [[ $dryRun -ne 0 ]]; then
	exeDisable
fi

executionSucceeded () {

	if [[ ${globals[internalDebug]} == true ]]; then
		printMsg "all args: $*"
	fi

	declare returnType=$1
	# quotes required as the values may have multiple words
	declare expectedVal="$2"

	# var reference name - bash 4.3+
	declare -n actualValArray
	declare actualVal

	printDebug "====  executionSucceeded ===="
	printDebug "returnType: $returnType"
	printDebug "expectedVal: $expectedVal"
	

	declare retval=$funcFailRetval # default is fail ( 0 is success )

	if [[ $returnType == 'string' ]]; then

		actualValArray=$3

		maxEl=${#actualValArray[@]}
		(( maxEl-- ))

		# read backwards as the string to match is likely near the end
		for i in $(seq $maxEl -1 0)
		do
			printDebug "actualVal string $i: " ${actualValArray[$i]}
			
			[[ "${actualValArray[$i]}" =~ ^$expectedVal$ ]] && {
				retval=$funcSuccessRetval
				break
			}
		done
	
	else # numeric

		# is it a number?	
		actualVal=$3

		printDebug "actualVal integer: $actualVal"

		if [[ $actualVal =~ ^[[:digit:]]+ ]]; then
			if [[ $actualVal -eq $expectedVal ]]; then
				retval=$funcSuccessRetval
			fi
		else
			printError "Expected a Numeric return of "$expectedVal" but got "$actualVal" instead"
		fi

	fi

	return $retval
}

: << 'rundoc'

  run 'string|integer' array_name expectedResult retVar cmdtext 

  run "${returnTypes[$i]}" cmdOutput "${expectedRC[$i]}" retVar "${cmds[$i]}"


rundoc

run () {

	declare returnType=$1; shift
	# passed by reference
	declare -n txtAry=$1; shift
	declare expectedResult=$1; shift
	declare retVar=$1; shift
	declare cmd="$@"

	declare retval

	echo 1>&2 "CMD: $cmd"
	echo 1>&2 "Return Type: $returnType"
	echo 1>&2 "Return Var: $retVar"
	echo 1>&2 "Expected Result: $expectedResult"

	if $(isExeEnabled); then
		#echo "CMD is Enabled"

		# eval "$cmd" is used as some commands take this form
		# set_some_var=1 ./run-my-test.sh.
		# simulated on the command line:
		# "x=1 ls" - does not work
		# eval "x=1 ls" - this does work

		#printMsg "arg type: $returnType"

		if [[ $returnType == 'string' ]]; then
			retval='NA'
			#echo 1>&2 "Evaluating string"
			# using a loop in the event the test script emits many lines
			# get the final line as the return value
			declare i=0
			while read line
			do
				txtAry[$i]="$line"
				(( i++ ))
				#retval="$line"
			done < <( eval "$cmd" )

			declare finalTxtEl=${#txtAry[@]}
			(( finalTxtEl-- ))
			printDebug "finalTxtEl: $finalTxtEl"
			for i in $( seq $finalTxtEl -1 0 )
			do
				printDebug "txtAry line $i: looking for $expectedResult in  ${txtAry[$i]}"
				if [[ ${txtAry[$i]} =~ $expectedResult ]]; then
					printDebug "!! Found IT! ${txtAry[$i]}"
					retval=${txtAry[$i]}
					printDebug "!! retval: $retval! "
					break
				else
					printDebug '!! Did NOT Find It!'
				fi
			done
		else
			printDebug "Evaluating integer"
			eval 1>&2 "$cmd"
			retval=$?
			echo 1>&2 "run() retval: $retval"
		fi
	else
		#echo 1>&2 "CMD is Disabled"
		retval='Command Execution Disabled'
	fi

	printf -v $retVar $retval
	printDebug "retVar run(): $retVar"
}

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
	printDebug ""

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
		printDebug ""

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
		printDebug ""
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
if [[ ${globals[internalDebug]} == true ]]; then
	echo "  Fail! - Debug is still enabled"
else
	echo "  Success - Debug is disabled"
fi

setDebug $debugStateTest

echo Debug should be enabled
if [[ ${globals[internalDebug]} == true ]]; then
	echo "  Success - Debug is enabled"
else
	echo "  Fail! - Debug is still disabled"
fi

exit

DEBUG-FLAG-TEST

declare cmdExeEnabled
isExeEnabled
cmdExeEnabled=$?

declare scriptRC
declare rc

for i in $( seq 0 $idxCount)
do
	banner "CMD $i: ${cmds[$i]}"
	banner "${returnTypes[$i]} | ${cmdMessages[$i]}"
	declare -a cmdOutput
	cmdOutput[0]='initialize'
	
	
	# run() will check if command execution is enabled
	# if not then all that run() will do is print the command
  	run "${returnTypes[$i]}" cmdOutput "${expectedRC[$i]}" scriptRC "${cmds[$i]}"
	printDebug "rc called run(): $scriptRC"
	rc=$scriptRC

	printDebug "RC: $rc"

	# quotes required as the values may have multiple words
	if [[ $cmdExeEnabled -eq 0   ]]; then
		if [[ ${returnTypes[$i]} == 'string' ]]; then
			resultCode=$(executionSucceeded ${returnTypes[$i]} "${expectedRC[$i]}" cmdOutput)
		else
			resultCode=$(executionSucceeded ${returnTypes[$i]} "${expectedRC[$i]}" "$rc")
		fi

			if $(exit $resultCode); then
				printOK "OK: ${cmds[$i]}"
				#setDebug $currDebugState
			else

				#setDebug $currDebugState
				printDebug "resultCode: $resultCode" 

				(( FAIL_COUNT++ ))
				printTestError "Error encountered in ${cmds[$i]}\nExpected RC=|${expectedRC[$i]}| - Actual RC: |$rc|"

				# pushed fail info to arrays
				(( failedIDX++ ))

				failedCMD[$failedIDX]=${cmds[$i]}
				failedTest[$failedIDX]=${cmdMessages[$i]}
				failedExpectedRC[$failedIDX]=${expectedRC[$i]}
				failedActualRC[$failedIDX]=$rc

			fi


	else
		resultCode=0
	fi

done

echo

if [[ ( $cmdExeEnabled -eq 0 )  && ( $FAIL_COUNT -gt 0 ) ]]; then

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
		printErrorRpt "  Actual RC: ${failedActualRC[$i]}"
		printErrorRpt "============================================================"
	done

else 
	printOK "All Tests Passed!"
#fi
fi

echo
printOK "Output is in $logFile"
echo

