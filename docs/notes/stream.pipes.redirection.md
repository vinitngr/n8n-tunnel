# Bash Output Streams, Pipes, and Redirection Notes

This note covers **stdout**, **stderr**, pipes, `2>&1`, and how they interact in shell scripts.

---

## 1. Output Streams in Bash

Bash has two main output streams:

| Stream | File Descriptor | Description | Default Destination |
| :--- | :--- | :--- | :--- |
| stdout | 1 | Normal output | Terminal |
| stderr | 2 | Error messages / warnings | Terminal |

> Both appear on the terminal by default but are **separate streams**.

---

## 2. Example: stdout vs stderr

```bash
# stdout example
echo "This is normal output"

# stderr example
ls missing_file
```

`echo` prints to stdout. `ls missing_file` prints to stderr. Both show on the terminal, but internally they are separate.

---

## 3. Piping Output

Pipes (`|`) send the stdout of the left command to the stdin of the right command.

```bash
echo "Hello World" | awk '{print "PREFIX: "$0}'
```

Output:
```
PREFIX: Hello World
```

Only stdout is sent to awk. stderr bypasses the pipe and prints directly to the terminal.

Example with errors:

```bash
ls existing_file missing_file | awk '{print "PREFIX: "$0}'
```

Output will look like this:
```
ls: cannot access 'missing_file': No such file or directory
PREFIX: existing_file
```

`existing_file` (stdout) is piped and prefixed, while the missing_file error (stderr) bypasses the pipe and prints raw to the terminal.

---

## 4. Redirecting stderr into stdout (2>&1)

`2>&1` merges stderr (file descriptor 2) into stdout (file descriptor 1). This is essential when you want both normal output and errors to go through a pipe or into a file.

Example:

```bash
ls existing_file missing_file 2>&1 | awk '{print "PREFIX: "$0}'
```

Output:
```
PREFIX: existing_file
PREFIX: ls: cannot access 'missing_file': No such file or directory
```

Now both stdout and stderr are prefixed by awk.

---

## 5. Silencing Output

To discard all output, redirect it to `/dev/null`.

```bash
command >/dev/null 2>&1
```

- `>/dev/null` → stdout goes to null.
- `2>&1` → stderr is redirected to stdout, so it also goes to null.

Optional: run in the background:

```bash
command >/dev/null 2>&1 &
```

`$!` captures the background process ID (PID).

---

## 6. Using Pipes with Partial Redirection

Only stdout through the pipe:

```bash
command 2>/dev/null | awk '{print $0}'
```

Only stderr through the pipe:

```bash
command 1>/dev/null 2>&1 | awk '{print $0}'
```

Key point: Pipes only capture stdout by default, not stderr.

---

## 7. Summary Table

| Symbol / Concept | Purpose | Example |
| :--- | :--- | :--- |
| `>` | Redirect stdout | `echo hi > file.txt` |
| `2>` | Redirect stderr | `ls missing 2> errors.txt` |
| `2>&1` | Merge stderr into stdout | `cmd 2>&1` |
| `|` | Pipe stdout to another command | `cmd | grep pattern` |
| `/dev/null` | Discard output | `cmd > /dev/null 2>&1` |
| `$!` | Last background process PID | `sleep 10 &; echo $!` |
| `$?` | Last command exit code | `ls missing; echo $?` |
| `$@` | All script arguments (separate) | `for arg in "$@"; do echo $arg; done` |
| `$*` | All script arguments (single string) | `echo "$*"` |

---

## 8. Real-World Example in a Script

```bash
start_cloudflared_tunnel() {
    # Merge stdout and stderr, prefix lines, run in background
    cloudflared tunnel run --config "$CONFIG_PATH" "$TUNNEL_NAME" 2>&1 | \
    awk -v prefix="----- TUNNEL ----- " -v max=80 \
        '{ line = $0; if (length(line) > max) { line = substr(line,1,max) " ..." } print prefix line }' &
    tunnel_pid=$!
}
```

- `2>&1` ensures both normal logs and errors go through awk.
- `&` runs the process in the background.
- `$!` stores the background process PID.

---

## ✅ Key Takeaways

- stdout = normal output, stderr = errors; both go to the terminal by default.
- Pipes only send stdout; use `2>&1` to include stderr.
- Redirecting to `/dev/null` silences output completely.
- `$!` and `$?` are essential for process control in scripts.