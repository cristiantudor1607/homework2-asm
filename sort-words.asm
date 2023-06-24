
section .data
	delim db ",.", 0Ah, 020h, 0
	;; defineste aici delimitatorii

section .text
	global get_words
	global compare_func
	global sort
	extern strtok
	extern strcpy
	extern strcmp
	extern strlen
	extern strchr
	extern qsort


compare_func:
	enter 0, 0
	;; First things first: the function will return something, so I have
	;; to save all the values from the registers except eax, because there
	;; will be the return values
	push 	esi
	push 	edi
	push 	ebx
	push 	ecx
	push 	edx

	;; Here starts the actual function
	;; Put the parameters into registers
	mov 	esi, [ebp + 8]			; esi will be a char ** pointing to the string1
	mov 	edi, [ebp + 12]			; edi will be a char ** pointing to the string2
	;; Every time I want to access a string, I will have to dereferentiate the pointer

	;; Length for the first string
	push 	dword [esi] 			; first string is given as parameter
	call 	strlen
	add 	esp, 4					; move the esp pointer back where it was before
									; pushing the parameter
	push 	eax 					; save the length, because eax will store the second
									; string length, after calling strlen second time
	;; Length for the second string
	push 	dword [edi]  			; second string is given as parameter
	call 	strlen
	add 	esp, 4					; remove the parameter from the stack
	pop 	ebx 					; bring back the lenfth of the first strings

	;; We want to order strings, first by length.
	;; The function qsort sorts the elements in ascending order, so I have to
	;; return < 0 if length(string1) < length(string2), or > 0 in the opposite
	;; case. In our case, I have to return the ebx - eax difference.
	xchg 	eax, ebx				; it would be great to swap the values, because
									; the result has to be in eax
	sub 	eax, ebx
	cmp 	eax, 0 					; if the result is 0, I have to check the 
									; lexicographic order
	jnz 	end_of_compare

	;; If it reaches this point, I have to order the words lexically
	push 	dword [edi]
	push 	dword [esi]
	call 	strcmp
	add 	esp, 8
	;; At this point, the return value is in the eax register, there is no more
	;; comparison I have to make, so I should leave the function
end_of_compare:
	;; Here ends the actual function
	pop 	edx
	pop 	ecx
	pop 	ebx
	pop 	edi
	pop 	esi
	leave
	ret

;; sort(char **words, int number_of_words, int size)
;  functia va trebui sa apeleze qsort pentru soratrea cuvintelor 
;  dupa lungime si apoi lexicografix
sort:
    ;; Prologue
    enter 0, 0
	pushad
    
    ;; Take the parameters
    mov 	esi, [ebp + 8] 			; store the address of the array in esi	
	mov 	eax, [ebp + 12]			; store the number of words in eax
	mov 	ebx, [ebp + 16]			; store the size of a word in ebx

    ;; Call qsort
	push 	dword compare_func
	push 	ebx
	push 	eax
	push 	esi
	call 	qsort
	add 	esp, 16

    ;; "Epilogue"
	popad
    leave
    ret

;; get_words(char *s, char **words, int number_of_words)
;  separa stringul s in cuvinte si salveaza cuvintele in words
;  number_of_words reprezinta numarul de cuvinte
get_words:
    enter 0, 0
    mov     esi, [ebp + 8]			; the start address of s will be stored in esi
	mov 	edi, [ebp + 12] 		; the start address of words array will be stored in edi
	mov 	eax, [ebp + 16] 		; the numer of words will be stored in eax

	xor 	ecx, ecx 				; ecx will take the role of "i" from the other programming 
									; languages, and it will go from 0 to number_of_words - 1
split_string:
	cmp 	ecx, eax
	jge  	end_split
	mov 	edx, [edi + 4 * ecx]	; take the current word from the array of words
	
	;; Take the word
	pushad 							; save the values before calling the function
	push 	delim 					; the delim string for strtok
	push 	esi 					; the string we want to split in words
	call 	strtok
	add 	esp, 8					; restablish the state of the stack
	popad 							; restore the values after calling the function
	
	;; Put the word in the array
	pushad
	push 	esi 					; the source string
	push 	edx 					; the destination string
	call 	strcpy
	add 	esp, 8					; restablish the stack
	popad

	;; Move the esi pointer to point to the begging of the next word
move_pointer:
	cmp 	byte [esi], 0 			; the moving stops when it reaches the first '\0'
	je 		end_move_pointer
	add 	esi, 1					; increase pointer 1 by 1
	jmp 	move_pointer
end_move_pointer:

	;; If there are other delimiters after \0, I have to jump over them
	add 	esi, 1 					; take the first character after \0
skip_delims:
	pushad							; save all the values because I will call a function
	movzx 	eax, byte [esi] 		; push just one character
	push 	eax
	push 	delim
	call 	strchr
	add 	esp, 8					; restablish the stack
	cmp 	eax, 0  				; check if the character is a delimiter
	je 		end_skip_delims
	popad  							; restore the values after calling the function
	add 	esi, 1
	jmp 	skip_delims
end_skip_delims:
	
	popad 							; restore the values after calling strchr and making the jump
	inc  	ecx
	jmp 	split_string
end_split:
    leave
    ret
