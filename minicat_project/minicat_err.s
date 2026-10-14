.global _start
.intel_syntax noprefix

.data
	err_msg: .ascii "Error: Could not open file or file does not exit\n"
	err_len = . - err_msg
.bss
	.lcomm buffer, 1024

.text
_start:
	# 1. Take out argv[1] (file pointer) from stack
	mov rdi, [rsp+16]

	# Check if the file name given or not(if not give error)
	test rdi, rdi
	jz handle_error

	# 2. sys_open(filename, O_RDONLY=0)
	mov rax, 2		# sys_open
	xor rsi, rsi		# flags=0(O_RDONLY)
	# filename pointer is already present in rdi
	syscall

	# if rax is negative then error
	test rax, rax
	js handle_error

	# save the file descriptor to a safe register(like rbx)
	mov rbx, rax

read_loop:
	# 3. sys_read(fd, buffer, 1024)
	mov rax, 0		# sys_read
	mov rdi, rbx		# file descriptor
	lea rsi, [rip+buffer]	# buffer pointer
	mov rdx, 1024		# max bytes to read
	syscall

	# if rax<=0, file is finished(EOF) or error
	test rax, rax
	jle close_file
	# save bytes read count
	mov r12, rax

	# 4. sys_write(1, buffer, bytes_read)
	mov rax, 1		# sys_write
	mov rdi, 1		# stdout descriptor
	lea rsi, [rip+buffer]
	mov rdx, r12		# no. of bytes that were read
	syscall

	# Run the loop again so that the another 1024 bytes can be read again
	jmp read_loop

close_file:
	# (Optional) You can close the file descriptor here

exit_program:
	#sys_exit(0)
	mov rax, 60		# sys_write
	xor rdi, rdi		# status 0
	syscall

handle_error:
	# print error message to stderr(fd 2)
	mov rax, 1		# sys_write
	mov rdi, 2		# stderr file descriptor
	lea rsi, [rip + err_msg]
	mov rdx, err_len
	syscall

	# Exit with error code 1
	mov rax, 60
	mov rdi, 1
	syscall
