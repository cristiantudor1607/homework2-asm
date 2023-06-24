
section .rodata:
	; taken from fnctl.h
	O_RDONLY	equ 00000
	O_WRONLY	equ 00001
	O_TRUNC		equ 01000
	O_CREAT		equ 00100
	S_IRUSR		equ 00400
	S_IRGRP		equ 00040
	S_IROTH		equ 00004

section .data
	length: dd 		0
	fileID:	dd 		0
	delim: 	db 		".,!? ", 0Ah, 0
	Marco: 	db 		"Marco", 0
	Polo: 	db 		"Polo", 0
	
	in_buffer: 		times 100 	db 0
	out_buffer:		times 100 	db 0

section .text
	global replace_marco
	extern strlen
	extern strstr
	extern strcat
	extern strncat

;; void replace_marco(const char *in_file_name, const char *out_file_name)
;  it replaces all occurences of the word "Marco" with the word "Polo",
;  using system calls to open, read, write and close files.

replace_marco:
	;; Clear the buffers
	mov 	ecx, 100
_clear_buff:
	mov 	byte [in_buffer + ecx], 0
	mov 	byte [out_buffer + ecx], 0
	loop 	_clear_buff

	;; "Prologue"
	push	ebp
	mov 	ebp, esp
	pushad

	;; Open the  input file
	mov 	eax, 5			; sys_open number
	mov		ebx, [ebp + 8] 	; the name of the file to open
	mov 	ecx, O_RDONLY 	; read only
	mov 	edx, 666o		; read and write permissions of the file
	int 	0x80 			; call the kernel

	;; Read into in_buffer
	mov		ebx, eax		; put the file descriptor in ebx
	mov 	ecx, in_buffer	; put the pointer to in_buffer in ecx
	mov		edx, 100		; put the in_buffer size in edx
	mov 	eax, 3 			; sys_read number
	int 	0x80			; call the kernel

	;; Close the input file
	mov 	eax, 6			; sys_close number
	;; ebx has the file descriptor from the previous step
	int 	0x80			; call kernel

	;; Open the output file
	mov 	eax, 5			; sys_open number
	mov 	ebx, [ebp + 12] ; the name of the output file
	mov 	ecx, 1			; write only
	mov		edx, 666o 		; read and write permissions of the file
	int 	0x80			; call the kernel

	;; Check if the error code is -2, in which case the file doesn't exist and
	;; I should create it
	cmp 	eax, -2
	jnz		_skip_create

	;; Create the file	
	mov 	eax, 8			; sys_creat number
	;; ebx has the name of the output file from previous step
	mov 	ecx, 666o		; create a file with read and write permissions
	int 	0x80			; call the kernel

_skip_create:
	mov		dword [fileID], eax		; save the file descriptor in memory
	mov		esi, in_buffer			; load the address of the in_buffer into esi
	mov 	edi, out_buffer 		; load the address of out_buffer into edi

	;; calculate the length of the input string
	pushad
	push 	esi
	call 	strlen
	add 	esp, 4
	mov 	dword [length], eax		; store the length in memory
	popad

	xor 	ecx, ecx				; set ecx to 0, because it will be used as counter
_loop_words:
	;; ecx will move with esi pointer in the buffer, and it will eventually reache the
	;; very last position in the string
	cmp 	ecx, dword [length]
	jge 	_end_loop_words
	push 	ecx 					; save ecx
	
	;; Get the first occurance of "Marco" in the string
	push 	Marco
	push 	esi
	call 	strstr
	add 	esp, 8
	cmp 	eax, 0 					; check is strstr didn't find any Marco substring
	je 		_copy_string 			; copy all the characters in the buffer

	;; First, copy all that is between the start of the string and the first
	;; occurence of "Marco"

	;; Compute the difference between the 2 addresses to find out how many bytes
	;; to copy
	mov 	edx, eax
	sub 	edx, esi
	
	;; If the difference is 0, it means that the first occurence and the start
	;; of the strig coincide
	cmp 	edx, 0
	je 		_replace_word

	;; copy edx bytes from esi to the end of edi
	pushad
	push 	edx
	push 	esi
	push 	edi
	call 	strncat
	add 	esp, 12
	popad

	;; Update ecx and put it back on stack
	pop 	ecx
	add 	ecx, edx
	push 	ecx

	;; Move the pointer to the start of "Marco" sequence
	add 	esi, edx

	;; Replace "Marco" with "Polo"
_replace_word:
	pushad
	push 	Polo
	push 	edi
	call 	strcat
	add 	esp, 8
	popad

	;; Update ecx and put it back
	pop 	ecx
	add 	ecx, 5 		; "Marco" has length 5
	push 	ecx

	add 	esi, 5		; also. move the pointer after "Marco"
	jmp 	_ret_to_loop

	;; It will jump here when there is no "Marco" in the substring
	;; In this case, I should concatenate the string at the end of output
	;; string
_copy_string:
	push 	esi			; source string
	push 	edi			; destination string
	call 	strcat
	add 	esp, 8		; restablish stack
	pop 	ecx			; pop ecx, because it jumps at the very end
	jmp 	_end_loop_words
_ret_to_loop:
	pop 	ecx			; bring back ecx to be used at the start of the loop
	jmp 	_loop_words
_end_loop_words:
	
	;; Calculate the length of the new string
	push 	edi
	call 	strlen
	add 	esp, 4
	mov 	edx, eax				; number of bytes to write

	;; Write the buffer in file
	mov 	eax, 4 					; sys_write number
	mov 	ebx, dword [fileID]		; put the descriptor in ebx
	mov 	ecx, edi				; pointer to buffer in ecx
	;; the number of bytes are already in edx
	int 	0x80					; call the kernel

	;; Close the file
	mov 	eax, 6					; sys_close number
	;; the file descriptor is already in ebx from previous step
	int 	0x80 					; call the kernel

	;; "Epilogue"
	popad
	leave
	ret