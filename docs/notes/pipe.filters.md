# Pipe | filters

## | Pipe 
Send the output of one command as the input to another.

### Real-World Examples

#### Find and Kill a Process
```bash
ps aux | grep nginx | awk '{print $2}' | xargs kill
# Find the process ID of nginx and terminate it.
```

#### Search for Errors in Logs
```bash
cat server.log | grep "ERROR" | wc -l
# Count the number of error occurrences in a log file.
```

#### Extract Specific Data from a File
```bash
cat data.csv | grep "2023" | cut -d',' -f2 | sort | uniq
# Extract and deduplicate the second column of entries from 2023 in a CSV file.
```

#### Replace Text in a Stream
```bash
echo "hello world" | sed 's/world/universe/'
# Replace "world" with "universe" in the input text.
```

#### Combine Commands for Directory Analysis
```bash

```
| **Command** | **Purpose**                                              | **Example with Pipe**                |
|-------------|----------------------------------------------------------|---------------------------------------|
| `grep`      | Searches for a specific pattern in the input.            | `ls -la \| grep "pattern"`             |
| `awk`       | A powerful text-processing language for pattern scanning and processing. | `cat data.txt \| awk '{print $1}'`    |
| `sed`       | A stream editor for simple text transformations.         | `echo "hello" \| sed 's/hello/world/'` |
| `cut`       | Extracts specific sections (columns) from each line.     | `who \| cut -d' ' -f1`                 |
| `sort`      | Sorts lines of text alphabetically or numerically.       | `cat names.txt \| sort`               |
| `uniq`      | Removes or reports duplicate adjacent lines.             | `cat names.txt \| uniq`               |
| `head`      | Outputs the first part (10 lines by default) of the file.| `ls -la \| head`                      |
| `tail`      | Outputs the last part of the file.                       | `cat logs.txt \| tail`                |

#### Combine Commands for Directory Analysis
```bash
find . -type f -name "*.log" | xargs grep "ERROR" | tee errors.txt | wc -l
# Find all log files, extract errors, save them to a file, and count them
```

## Common Pipeline Commands

| **Command** | **Description** | **Example with Pipe** |
|-------------|----------------|------------------------|
| `tee` | Splits output to display and save to file | `echo "hello world" \| tee file.txt` |
| `xargs` | Builds and executes commands from standard input | `echo "file1 file2" \| xargs ls -l` |
| `grep` | Searches for patterns in text | `cat /etc/passwd \| grep root` |
| `awk` | Pattern scanning and text processing language | `echo "Alice 90" \| awk '{print $1}'` |
| `sed` | Stream editor for text transformation | `echo "hello world" \| sed 's/world/shell/'` |
| `sort` | Sorts lines of text | `cat data.txt \| sort` |

## Advanced Pipeline Examples

### Using `tee` to Split Output
```bash
echo "hello world" | tee file.txt
# Displays "hello world" and saves it to file.txt
```

### Different Ways to Use `xargs`

```bash
echo "a b c" | xargs mkdir

# ./setup.sh "file1.txt file2.txt"
echo "$1" | xargs ls -l
# ls -l file1.txt file2.txt as $1 = "file1.txt file2.txt"
echo "file1.txt file2.txt" | xargs -n 1 ls -l
# ls -l file1.txt
# ls -l file2.txt
echo "file1.txt file2.txt" | xargs -I {} echo "Processing {} now"
echo "file1.txt file2.txt" | xargs -n 1 -I {} echo "Processing {}"
echo "file1.txt file2.txt" | xargs -I {} mv {} backup/{}

#: -I {} now you keep {} anywhere it will be the placement
```

### Pattern Searching with `grep`
```bash
cat /etc/passwd | grep root
# Finds lines containing "root"
grep -i "error" logfile.txt    # Case-insensitive search
grep -v "warning" logfile.txt  # Inverted match (lines without "warning")
grep -E "[0-9]{3}" data.txt    # Using regex
```

### Text Processing with `awk`
```bash
echo "Alice 90" | awk '{print $1}'   # Prints "Alice"
echo "Alice 90" | awk '{print $2}'   # Prints "90"
cat marks.txt | awk '$2 > 50 {print $1}'  # Prints names with score > 50
```

### Text Transformation with `sed`
```bash
echo "hello world" | sed 's/world/shell/'
# Replaces "world" with "shell"
```

### Sorting Data
```bash
cat data.txt | sort           # Alphabetical sort
cat data.txt | sort -n        # Numerical sort
cat data.txt | sort -r        # Reverse sort
```

### Complex Pipeline Example
```bash
cat marks.txt \
    | grep "Alice" \
    | cut -d' ' -f2 \
    | tee score.txt \
    | xargs echo "Alice scored"
# Extracts Alice's score, saves to file, and prints a message
```

