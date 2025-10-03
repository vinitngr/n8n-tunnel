# Shell Scripting Basics

## Shebang Line
Defines the interpreter for script execution:
```bash
#!/bin/bash         # Use bash as interpreter
#!/usr/bin/env bash # More portable bash
#!/usr/bin/env python3  # Python interpreter
```

## Variables and Expansion
```bash
name="John"         # Define variable (no spaces around =)
echo "$name"        # Simple expansion
echo "${name}smith" # Braces for clarity
readonly PI=3.14    # Constant (read-only)
export PATH="$PATH:/new/path" # Environment variable
```

## Special Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `$0` | Script name | `echo "$0"` → `./script.sh` |
| `$1, $2` | Positional parameters | `./script.sh arg1 arg2` |
| `$#` | Number of arguments | `echo "$#"` → `2` |
| `$@` | All arguments (separate) | `for arg in "$@"; do echo "$arg"; done` |
| `$*` | All arguments (single string) | `echo "$*"` → `arg1 arg2` |
| `$?` | Last command exit status | `grep pattern file; echo "$?"` |
| `$$` | Current shell PID | `echo "Running as $$"` |

## Exit Status
```bash
exit 0      # Success
exit 1      # General error
echo $?     # Check last command's exit status
command && echo "Success" || echo "Failed" # Conditional execution
```

## Conditional Testing

### Test Brackets
```bash
# Traditional test (needs quoting)
[ -f "$file" ] && echo "File exists"

# Extended test (preferred)
[[ $string == *txt ]] && echo "Ends with txt" 
```

### Comparison Operators
| Numeric | String | File Test | Description |
|---------|--------|-----------|-------------|
| `-eq` | `==` | `-e` | Equal / Exists |
| `-ne` | `!=` | `-f` | Not equal / Regular file |
| `-lt` | `<` | `-d` | Less than / Directory |
| `-le` | `≤` | `-r` | Less than or equal / Readable |
| `-gt` | `>` | `-w` | Greater than / Writable |
| `-ge` | `≥` | `-x` | Greater than or equal / Executable |

## Conditionals
```bash
# if-else
if [[ $count -gt 10 ]]; then
    echo "Greater than 10"
elif [[ $count -eq 10 ]]; then
    echo "Equal to 10"
else
    echo "Less than 10"
fi

# case statement
case "$extension" in
    jpg|jpeg) echo "Image file" ;;
    txt|md)   echo "Text file" ;;
    *)        echo "Other file" ;;
esac
```

## Loops
```bash
# for loop (iterating through values)
for name in Alice Bob Charlie; do
    echo "Hello, $name!"
done

# for loop (C-style)
for ((i=1; i<=5; i++)); do
    echo "Count: $i"
done

# while loop (condition is true)
count=1
while [[ $count -le 5 ]]; do
    echo "Count: $count"
    ((count++))
done

# until loop (until condition becomes true)
count=5
until [[ $count -le 0 ]]; do
    echo "Countdown: $count"
    ((count--))
done
```

## Debugging
```bash
set -x      # Enable debug mode (trace commands)
set +x      # Disable debug mode
set -e      # Exit on error
set -u      # Error on undefined variables
set -o pipefail # Catch pipe failures
```

## Functions
```bash
greet() {
    local name="$1"
    echo "Hello, $name!"
}

greet "World" 
```

return value
```bash
add() {
    local sum=$(( $1 + $2 ))
    echo $sum   # return value
}

result=$(add 5 3)
echo "Sum is $result"
```
return for status
``` bash
is_even() {
    if [ $(( $1 % 2 )) -eq 0 ]; then
        return 0  # success
    else
        return 1  # failure
    fi
}

is_even 4 && echo "Even" || echo "Odd"
```

# Array
```bash
# Define array
fruits=("apple" "banana" "cherry") 
echo ${fruits[0]}   # apple
echo ${fruits[@]}   # apple banana cherry
echo ${#fruits[@]}  # 3
echo ${!fruits[@]}  # 0 1 2
fruits+=("orange")  # add elements

# Create array from command output
files=($(ls *.txt))
echo "Found ${#files[@]} text files"

data="one,two,three"
IFS=',' read -ra items <<< "$data"
echo "${items[1]}"  # two
```


# subshell and grouping
Runs commands in a separate shell. Variables inside do not affect parent shell.

subshell
``` bash
x=10
(
    x=20
    echo "Inside subshell: $x"
)
echo "Outside subshell: $x"  # Still 10
```
grouping
``` bash
x=10
{
    x=20
    echo "Inside grouping: $x"
}
echo "Outside grouping: $x"  # 20
```
``` bash
{ echo "Header"; ls; } > output.txt
```

# command subsitution
``` bash
# both just work same
# Backticks
today=`date`
echo "Today is $today"

# $( ) preferred
today=$(date)
echo "Today is $today"
```
example 
```bash
file_count=$(ls | wc -l)
echo "Total files: $file_count"
```

# user input
```bash
read -p "Enter your username" name
echo "hello $name"
```

## Redirection

| Operator | Description | Example |
|----------|-------------|---------|
| `>` | Redirect stdout to file (overwrite) | `echo "hello" > file.txt` |
| `>>` | Append stdout to file | `echo "world" >> file.txt` |
| `<` | Read input from file | `wc -l < file.txt` |
| `2>` | Redirect stderr to file | `ls /notexist 2> error.log` |
| `2>>` | Append stderr to file | `ls /notexist 2>> error.log` |
| `&>` | Redirect both stdout and stderr | `command &> all.log` |
| `&>>` | Append both stdout and stderr | `command &>> all.log` |
| `1>&2` | Redirect stdout to stderr | `echo "Error" 1>&2` |
| `2>&1` | Redirect stderr to stdout | `find / -name x 2>&1 \| grep "denied"` |
| `<<<` | Here-string (input from string) | `grep "pattern" <<< "$variable"` |
| `\|` | Pipe output to another command | `ls \| grep ".txt"` |

```bash
while read line; do
    echo "Config: $line"
done < config.txt
```
```bash
grep "pattern" file.txt 2> error.logs
```


### default value
```bash
NAME=""
echo "${NAME:-Guest}"  
# Output: Guest

NAME="Bob"
echo "${NAME:-Guest}"  
# Output: Bob

#Uses default_value and sets the variable if it was empty/unset.
AGE=""
echo "${AGE:=18}"  
# Output: 18
echo "$AGE"  
# Output: 18 (variable is now set)


#3. ${VAR:+value}
#Uses value only if variable is set.
CITY="London"
echo "${CITY:+Available}"  
# Output: Available
CITY=""
echo "${CITY:+Available}"  
# Output: (nothing)

#4. ${VAR:?error_message}
USERNAME=""
echo "${USERNAME:?USERNAME is required}"  
# Output: bash: USERNAME: USERNAME is required

#using || 
NAME=""
echo "$NAME" || echo "Guest"  
```