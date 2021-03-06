
# Bash Script Unit Testing

Occasionally I have a need to run a script with different inputs and options to validate if the script is working as expected.

Once the number of different commandlines exceeds 3 or so, it is difficult to look at the test script and quickly determine if all the test succeeeded.

If some failed, it can be a bit of a chore to comb through the log to determine which options and inputs caused a problem.

And so this script was born.

The bash script will execute the command, log the output, collect the exit code and compare it to the expected exit code.

If the expected code and the actual code do not match, and error message is raised with ANSI colors designed to stand out.

The same is done for a warning code, but a different color.

All errors are pushed on to a stack and reported at the end of the script.

If no errors occurred, all you need to see is the 'Success' message.


## Configuration File

The configuration file is JSON.

It is assumed that Python is installed on the system.

Python is used as by default in includes JSON processing code.

Currently this works with Python 2 only, Python 3 will cause an error.

There are 4 values expected for each test, any notes, the cmd itself, the type of the returned value and the expected return code

There are two types of possible return values

- integer
- string

If 'integer' the value is taken from $? as the ```exit N``` that indicates if the script execution succeeded or not.

The traditional value for this is 0 (zero) for success, and different positive integers for failures, though it is not necessary to use 0 for success.

If 'string' it may be multiple words, and the value used to determine success/failure *MUST* be the last line output by the script under test

Following is the configuration file included here, unit-test.json

```json
{
	"comments" : "This is the configuration file for unit-test.sh",
	"version" : 1.0,
	"tests" : [
		{
			"notes" : "normal successful execution",
			"cmd" : "./script-under-test.sh this is a test",
			"result-type" : "integer",
			"result" : 0
		},
		{
			"notes" : "execution with Warning ",
			"cmd" : "./script-under-test.sh 1 this test exits with a warning",
			"result-type" : "integer",
			"result" : 1
		},
		{
			"notes" : "execution with Error ",
			"cmd" : "./script-under-test.sh 2 this test exits with an error",
			"result-type" : "integer",
			"result" : 2
		},
		{
			"notes" : "This test should FAIL - This script name has a typo",
			"cmd" : "./script-under-te5t.sh 2 this test exits with an error",
			"result-type" : "integer",
			"result" : 2
		},
		{
			"notes" : "string return type - successful execution",
			"cmd" : "./script-under-test-string.sh this is a test",
			"result-type" : "string",
			"result" : "OK"
		},
		{
			"notes" : "string return type - Two Words returned - successful execution",
			"cmd" : "./script-under-test-string.sh Two Words this is a test",
			"result-type" : "string",
			"result" : "Two Words"
		},
		{
			"notes" : "string return type - successful execution of failure with warning",
			"cmd" : "./script-under-test-string.sh Warning",
			"result-type" : "string",
			"result" : "Warning"
		},
		{
			"notes" : "string return type - successful execution of failure with error",
			"cmd" : "./script-under-test-string.sh Error",
			"result-type" : "string",
			"result" : "Error"
		},
		{
			"notes" : "This test should FAIL - string return type - failed execution - expecting Error - gets OK",
			"cmd" : "./script-under-test-string.sh OK",
			"result-type" : "string",
			"result" : "Error"
		},
		{
			"notes" : "this test should FAIL - string return type - failed execution - expecting OK - gets Warning",
			"cmd" : "./script-under-test-string.sh Warning",
			"result-type" : "string",
			"result" : "OK"
		}
	]
}
```

## unit-test.sh

Currently the name of the JSON file to be used is hard coded in the top of the script _unit-test.sh_.

This behavior can be changed by setting the value for unitTestJson at the command line, as per the following example:

```bash

$ debug=1  bash unit-test.sh
Log File: unit-test.log
Unit Test: unit-test.json

$ debug=1 unitTestJson=mytest.json bash unit-test.sh
Log File: mytest.log
Unit Test: mytest.json

```
Timestamps may also be added to the log file name

```bash

$ useTimeStamps=1 debug=1 unitTestJson=mytest.json bash unit-test.sh
Log File: mytest_2018-12-06_15-25-52.log
Unit Test: mytest.json

```

To summarize usage of _unit-test.sh_:

Environment variables

 - useTimeStamps: setting to 1 causes logs to have a timestamp as part of the log file name
 -         debug: setting to 1 will include debugging output
 -  unitTestJson: set this to the name of your JSON configuration file
 -      useColor: set this to 0 (zero) if you do not want colors
 -     usePython: force the use of python to parse JSON - jq normally used if available
 -        dryRun: set to 1 and CMDs will be shown, but not executed
 -          help: print help and exit

The timestamped logs are useful for comparing runs.

Setting useColor=0 is useful when you need a logfile that does not have color escape codes in it.

## convert-json.sh

usage: convert-json.sh my-unit-tests.json

If you have any JSON files that were created for use with the previous iteration of _unit-test.sh_, the _convert-json.sh_ script will add the "result-type" lines for you.

Running the script twice on the same script will have no effect as the new line will be detected.

## test-json.sh

usage: test-json.sh

The _test-json.sh_ script can be used to validate a JSON file.

The script returns 0 for success, 1 for failure.


```bash
$ ./test-json.sh test.json
version: 0.1
$ $?
0

$  ./test-json.sh error.json
version:
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/usr/lib/python2.7/json/__init__.py", line 291, in load
    **kw)
  File "/usr/lib/python2.7/json/__init__.py", line 339, in loads
    return _default_decoder.decode(s)
  File "/usr/lib/python2.7/json/decoder.py", line 364, in decode
    obj, end = self.raw_decode(s, idx=_w(s, 0).end())
  File "/usr/lib/python2.7/json/decoder.py", line 382, in raw_decode
    raise ValueError("No JSON object could be decoded")
ValueError: No JSON object could be decoded

$ echo $?
1
```

# Dependencies

## ansi-color.sh

This script has a dependency on the script _ansi-color.sh_, which  should be in the same directory as _unit-test.sh_.

_ansi-color.sh is found at [ansi-color](https://github.com/jkstill/ansi-colors)

## Bash 4.3

Due to the use of 'declare -n' in unit-test.sh, Bash 4.3+ is required.

unit-test.sh will not work with Bash 4.2 or earlier.

I have installed bash 4.4 when necessary. 

The following web page has instructions on doing so.  When I have done the Bash 4.4 was installed into /usr/local/bin so as to not overwrite the system Bash.

[Installing Gnu Bash 4.4](https://fossbytes.com/installing-gnu-bash-4-4-linux-distros/)

### Ubuntu

```bash
apt-get install build-essential
```

### RedHat

```bash
yum groupinstall 'Development Tools' 'Legacy Software Development'
```

Now get the source, build and install

```bash
wget http://ftp.gnu.org/gnu/bash/bash-4.4.tar.gz
tar xvfz bash-4.4.tar.gz
cd bash-4.4
./configure
make
make install
/usr/local/bin/bash -version
```



