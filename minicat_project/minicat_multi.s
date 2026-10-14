.global _start
.intel_syntax noprefix

.data
	err_msg: .ascii "Error: Could not open file or file does not exit\n"
	err_len = . - err_msg
.bss
	.lcomm buffer, 1024

.text
_start:
	# 1. Load argc into r8
	mov r8, [rsp]		#argc

	# check if any file argument is provided (argc<2), if no file given then exit
	cmp r8, 2
	jl exit_program

	# initialize  argument index r13=1
	mov r13, 1

next_file:
	# Check if r13 >= argc
	cmp r13, r8
	jge exit_program

	# calculate addr. of argv[r13]: pointer is at [rsp + 8 + r13 * 8]
	mov rax, r13
	shl rax, 3			# rax = r13 * 8
	mov rdi, [rsp + 8 + rax]	# rdi = filename pointer

	# 2. sys_open(filename, O_RDONLY=0)
	mov rax, 2
	xor rsi, rsi
	syscall

	test rax, rax
	js handle_file_error
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
	# sys_close(fd)
	mov rax, 3
	mov rdi, rbx
	syscall

	# move on to next file
	inc r13
	jmp next_file

handle_file_error:
	# print error message to stderr(fd 2)
	mov rax, 1		# sys_write
	mov rdi, 2		# stderr file descriptor
	lea rsi, [rip + err_msg]
	mov rdx, err_len
	syscall

	# if error comes the program won't crash, instead it will move to the next file(like the real cat does)
	inc r13
	jmp next_file

exit_program:
        #sys_exit(0)
        mov rax, 60             # sys_write
        xor rdi, rdi            # status 0
        syscall
