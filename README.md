
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

There are 3 values expected for each test, any notes, the cmd itself, and the expected return code

Following is the configuration file included here, unit-test.json

```json
{
   "comments" : "This is the configuration file for unit-test.sh",
   "version" : 1.0,
   "tests" : [
      {
         "notes" : "normal successful execution",
         "cmd" : "./script-under-test.sh this is a test",
         "result" : 0
      },
      {
         "notes" : "execution with Warning ",
         "cmd" : "./script-under-test.sh 1 this test exits with a warning",
         "result" : 1
      },
      {
         "notes" : "execution with Error ",
         "cmd" : "test-cmd-3",
         "cmd" : "./script-under-test.sh 2 this test exits with an error",
         "result" : 2
      },
      {
         "notes" : "This script does not exist",
         "cmd" : "no-script-exists.sh",
         "result" : 0
      }
   ]
}
```

The validity of the file can be tested with the test-json.sh script

```bash
>  ./test-json.sh unit-test.json
version: 1.0
```

If the script is not valid JSON there will be error output:

```bash

>  ./test-json.sh unit-test.json
version:
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/usr/lib/python2.7/json/__init__.py", line 291, in load
    **kw)
  File "/usr/lib/python2.7/json/__init__.py", line 339, in loads
    return _default_decoder.decode(s)
  File "/usr/lib/python2.7/json/decoder.py", line 364, in decode
    obj, end = self.raw_decode(s, idx=_w(s, 0).end())
  File "/usr/lib/python2.7/json/decoder.py", line 380, in raw_decode
    obj, end = self.scan_once(s, idx)
ValueError: Expecting property name: line 3 column 2 (char 4)

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

The command line switch '-n' is used do initiate the dry-run mode where none of the test commands are actually executed, but only displayed

To summarize usage of _unit-test.sh_:

Switches:

 * -n dry run mode

Environment variables

 * useTimeStamps: setting to 1 causes logs to have a timestamp as part of the log file name
 *         debug: setting to 1 will include debugging output
 *  unitTestJson: set this to the name of your JSON configuration file
 *      useColor: set this to 0 (zero) if you do not want colors

The timestamped logs are useful for comparing runs.

Setting useColor=0 is useful when you need a logfile that does not have color escape codes in it.

# Dependencies

This script has a dependency on the script _ansi-color.sh_, which  should be in the same directory as _unit-test.sh_.

_ansi-color.sh is found at [ansi-color](https://github.com/jkstill/ansi-colors)


