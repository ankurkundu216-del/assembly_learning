# 🐚 Mini Shell in x86-64 Assembly (`minish`)

A minimal, educational UNIX-like shell written completely from scratch in 64-bit x86-64 Assembly using Linux system calls. 

This project is designed as an interactive guide to lower-level OS mechanics, process management, and bare-metal assembly programming.

---

## 📚 Educational Highlights & Mechanics

This shell implements the foundational **REPL** (Read-Evaluate-Print-Loop) model with extensive inline documentation explaining Linux kernel primitives:

### 1. Process Lifecycle & Execution (`sys_fork` & `sys_execve`)
* **`sys_fork` (Syscall 57):** Duplicates the shell process into a parent and child process.
* **`sys_execve` (Syscall 59):** Executed inside the child process to load and run executable binaries (e.g., `/bin/ls`, `/bin/date`).
* **`sys_wait4` (Syscall 61):** Suspends the parent shell process until the child process completes execution, preventing terminal output overlap.

### 2. Built-in Commands vs External Binaries
* Shell built-ins like `exit` must be handled internally within the parent process rather than spawned as external binaries.
* **Little-Endian Matching:** Demonstrates string parsing by comparing 32-bit registers against little-endian hex values (`0x74697865` for `"exit"`) followed by null-byte verification.

### 3. Low-Level Memory & Registers
* Direct manipulation of `.data`, `.bss`, and `.text` sections.
* Buffer sanitization and newline replacement (`\n` $\rightarrow$ `\0`) prior to syscall execution.
* Direct register setup following standard x86-64 Linux ABI convention (`rax`, `rdi`, `rsi`, `rdx`, `r10`).

---

## 🚀 Building and Running

### Prerequisites
* Linux Environment (Ubuntu / Debian / Arch / Fedora or Linux VM)
* `GNU Assembler (as)` and `GNU Linker (ld)`

### Step 1: Assemble the Source File
Assemble the source code using Intel syntax processing:
```bash
as --64 mini_sh.s -o mini_sh.o
```

### Step 2: Link the Object File
Link the object file into an executable binary:
```bash
ld mini_sh.o -o mini_sh
```

### Step 3: Run the Shell
Execute your custom assembly shell:
```bash
./mini_sh
```
🛠️ Usage Example
```bash
minish$ /bin/ls
mini_sh.s  mini_sh.o  mini_sh
minish$ /bin/uname -a
Linux ubuntu-vm 6.8.0 #1 SMP x86_64
minish$ exit
```

Note: Since absolute path resolution (PATH parsing) is omitted for educational simplicity, execute external binaries using their full path (e.g., /bin/ls, /bin/date, /bin/pwd).

### 🤝 Contributing & Feedback

This repository is maintained as an open learning resource for low-level systems programming, x86-64 assembly, and kernel interface exploration.

Feel free to open an issue or pull request if you'd like to suggest optimizations, bug fixes, or additional built-in functions!

Developed as part of the assembly_learning series.
