
#--------------------------------------------------------------------------------------------------------------------
# STEP 1: HOW A SHELL WORKS: THE REPL LOOP
# At its core, every shell (like Bash and Zsh) runs in continuous loop called a REPL (Read, Evaluate, Print, Loop):
# (a). Read: Print a prompt(e.g., $) and wait for the user input (sys_read).
# (b). Evaluate: Parse the input string into a command and its argument, then tell the kernel to execute it.
# (c). Print: Let the command output to the screen.
# (d). Loop: Wait for the command to finish, then go back to step 1 and show the prompt again.
#--------------------------------------------------------------------------------------------------------------------
# STEP 2: HOW PROCESS EXECUTION WORKS
# When we type a command in a shell, it cannot just run it directly in the same process,
# because sys_execve completely replaces the current program's memory with the new binary.
# If your shell didn't duplicate itself first, your shell would vanish the moment you run a single command!
# (a) sys_fork (Syscall 57): Duplicates the shell process
# -> In Child process(rax==0), we prepare to execute the user's command.
# -> In Parent process(rax>0), rax holds the process ID(PID) of the child, and the shell prepares to wait.
# (b) sys_execve (Syscall 59): Executed inside the child process to load and run the requested binary
# (e.g., /bin/ls). It requires a path and an argument vector(argv) array terminated by a null pointer.
# (c) sys_wait4 (Syscall 61): Executed by the parent process(the shell) to pause execution until
# the child process finishes printing its output, preventing terminal overlap.
#--------------------------------------------------------------------------------------------------------------------
# Some commands cannot be run as external binaries using sys_fork and sys_execve.
# 1. exit: If exit were an external binary (/bin/exit), the kernel would fork a child process,
# the child process would terminate, and your shell would keep running! To terminate the shell itself,
# the shell process must handle exit internally.
# 2. cd (Change Directory): Similarly, if you run cd as an external binary,
# it changes the working directory of the child process, leaving the shell's working directory completely unchanged.
#>> HOW TO CHECK FOR exit IN ASSEMBLY?
# We can check if the user typed "exit" by comparing the first 4 bytes of our input buffer
# against the ASCII value of "exit" in little-endian format (0x74697865), and ensuring the 5th byte
# is a null terminator (0) so it doesn't match commands like exit_us or exiting.
#--------------------------------------------------------------------------------------------------------------------
.global _start
.intel_syntax noprefix

.data
	prompt: .ascii "minish$ "
	prompt_len = . - prompt

.bss
	.lcomm buffer, 256		# 256-byte buffer for user command input
	.lcomm argv_array, 16		# argv[0] pointer (8 bytes) + NULL terminator (8 bytes)

.text
_start:

repl_loop:
	# 1. Display the shell prompt: sys_write(1, prompt, prompt_len)
	mov rax, 1			# sys_write syscall number
	mov rdi, 1			# file descriptor 1 (stdout)
	lea rsi, [rip + prompt]		# pointer to the prompt string
	mov rdx, prompt_len		# no. of bytes to write
	syscall
#------------------------------------------------------------------------------------
	# 2. Read user input: sys_read(0, buffer, 256)
	mov rax, 0			# sys_read syscall number
	mov rdi, 0			# file descriptor 0 (stdin)
	lea rsi, [rip + buffer]		# pointer to our .bss buffer
	mov rdx, 256
	syscall

	# Check if sys_read returned <= 0 (It handles EOF like Ctrl+D, or errors)
	test rax, rax
	jle exit_program

	# Save the number of bytes read in r12
	mov r12, rax
#------------------------------------------------------------------------------------
	# 3. Parse Input: Strip trailing newline (\n) -> null-terminate (\0)
	lea rsi, [rip + buffer]		# load buffer address
	xor rcx, rcx			# index counter = 0

scan_newline:
	cmp rcx, r12			# did we checked all read bytes
	jge check_builtins

	mov al, byte ptr [rsi + rcx]	# grab curr byte
	cmp al, 10			# ASCII code 10 is newline ('\n')
	je replace_newline_null

	inc rcx
	jmp scan_newline

replace_newline_null:
	mov byte ptr [rsi + rcx], 0	# Replace '\n' with null-terminator '\0'
	mov r12, rcx			# Update actual string length with newline

check_builtins:
	# Check if user just hit enter(empty command)
	cmp byte ptr [rip + buffer], 0
	je repl_loop

	# Check if command is "exit" (ASCII "exit" in hex: 0x74697865)
	mov eax, [rip + buffer]
	cmp eax, 0x74697865
	jne do_fork
	# Ensure exact match by checking
	# if the 5th byte is null-terminator.
	cmp byte ptr [rip + buffer + 4], 0
	je exit_program

parse_arguments:
	# 4. Tokenize Arguments (Split by spaces)
	lea rsi, [rip+buffer]
	lea rdi, [rip+argv_array]

	# argv[0] points to the start of the buffer
	mov [rdi], rsi
	mov r8, 1			# Start filling argv[1]

	mov rcx, rcx			# Buffer index


do_fork:
	# 4. Fork Process: sys_fork()
	mov rax, 57		# sys_fork syscall number
	syscall

	test rax, rax
	js repl_loop		# Handle fork error by looping back
	jz child_process	# if rax==0, we are in child process

parent_process:
	# 5. Wait for Child: sys_wait4(pid, status, options, rusage)
	mov rdi, rax			# Child PID returned by fork
	mov rax, 61			# sys_wait4 syscall number
	xor rsi, rsi			# status=0
	xor rdx, rdx			# options=0
	xor r10, r10			# rusage=0
	syscall
	jmp repl_loop			# Go back to REPL prompt

child_process:
	# --- CHILD PROCESS EXEXUTION ---
	# Set up argv array: argv[0]=buffer, argv[1]=0(NULL)
	lea rax, [rip+buffer]
	lea rbx, [rip+argv_array]
	mov qword ptr [rbx], rax	# argv[0] points to our command string
	mov qword ptr [rbx + 8], 0	# argv[1] is a 64-bit null pointer

	# 6. Execute Program: sys_execve(filename, argv, envp)
	mov rax, 59			# sys_execve syscall number
	lea rdi, [rip+buffer]		# path to binary
	lea rsi, [rip+argv_array]	# pointer to argv array
	xor rdx, rdx			# envp = 0(empty environment)
	syscall

	# If sys_execve returns,
	# it means an error occured (e.g., command not found)
	mov rax, 60
	mov rdi, 0
	syscall
#------------------------------------------------------------------------------------
exit_program:
	# sys_exit(0)
	mov rax, 60			# sys_exit syscall number
	xor rdi, rdi			# status 0
	syscall
