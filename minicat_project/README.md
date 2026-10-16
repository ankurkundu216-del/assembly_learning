# Mini-Cat in Pure x86_64 Assembly 🐱

A lightweight, custom implementation of the classic Unix `cat` utility written entirely from scratch in **pure x86_64 assembly** for Linux. 

This project is built **without the C standard library (`libc`)**, meaning it bypasses traditional wrappers and talks directly to the Linux kernel using raw system calls (`syscall`).

---

## 📂 Project Files

This repository contains three iterations of the utility, showing how it evolved from a basic file reader into a robust, production-style multi-file command-line tool:

1. **`minicat.s`**: The foundational single-file reader. It reads a file path from command-line arguments (`argv[1]`) and streams its contents to standard output (`stdout`).
2. **`minicat_err.s`**: An upgraded version featuring **error handling**. If a file does not exist, it routes a descriptive error message to standard error (`stderr`, file descriptor 2) and exits cleanly.
3. **`minicat_multi.s`**: The final version with **multi-file processing**. It loops through all provided command-line arguments, safely opens/reads each file, closes file descriptors to prevent leaks, handles missing files without crashing (just like the real Unix `cat`), and uses `r13` to protect loop counters from kernel register clobbering.

---

## ⚙️ How It Works Under the Hood

Instead of relying on `printf`, `fopen`, or `fread` from C, this program uses raw Linux kernel system calls:

* **`sys_open` (Syscall `2`)**: Opens the target file in read-only mode (`O_RDONLY = 0`). Returns a file descriptor.
* **`sys_read` (Syscall `0`)**: Reads chunks of data (up to 1024 bytes at a time) from the file descriptor into an uninitialized `.bss` buffer.
* **`sys_write` (Syscall `1`)**: Writes the buffer contents either to `stdout` (`fd 1`) for normal text or `stderr` (`fd 2`) for errors.
* **`sys_close` (Syscall `3`)**: Closes active file descriptors after reading finishes.
* **`sys_exit` (Syscall `60`)**: Terminates the program cleanly with an appropriate exit code.

### 💡 Key Assembly Lessons Learned
* **Stack Parsing**: Navigating the stack pointer (`rsp`) to retrieve `argc` at `[rsp]` and index through `argv` pointer arrays (`[rsp + 8 + rax]`).
* **Syscall Clobbering**: Recognizing that the Linux kernel overwrites `rcx` and `r11` during a `syscall`, requiring loop counters to be stored in callee-safe registers like `r13`.
* **Error Routing**: Using the `js` (Jump if Sign) instruction to instantly catch negative return values from failed system calls and redirect execution to error handlers.

---

## 🚀 Build and Run Instructions

Make sure you are running on an **Ubuntu x86_64 Linux** environment with the GNU Assembler (`as`) and Linker (`ld`) installed.

### 1. Clone the Repository
```bash
git clone https://github.com/ankurkundu216-del/assembly_learning.git
cd assembly_learning/minicat_project
```

### 2. Assemble and Link (Multi-file version)
```bash
as -o minicat_multi.o minicat_multi.s
ld -o minicat_multi minicat_multi.o
```

### 3. Test It Out
```bash
echo "Hello from file one!" > file1.txt
echo "Greetings from file two!" > file2.txt

# Run mini-cat on multiple files
./minicat_multi file1.txt file2.txt
```

## 🛠️ Requirements

    Ubuntu Linux (x86_64 architecture)

    GNU Assembler (as)

    GNU Linker (ld)
