
section .data
	back db "..", 0
	curr db ".", 0
	slash db "/", 0
	; declare global vars here

section .text
	global pwd
	extern strcat
	extern strcmp
	extern strlen

;;	void pwd(char **directories, int n, char *output)
;	Adauga in parametrul output path-ul rezultat din
;	parcurgerea celor n foldere din directories
pwd:
	enter 0, 0
	pushad 							; save the values from the functions that calls
									; this function (let's call it main function)
	mov     esi, [ebp + 8]          ; store the start address of directories in esi
	mov     eax, [ebp + 12]			; store the number of directories in eax
	mov     edi, [ebp + 16]			; store the start address of output string in edi

	mov		byte [edi], '/'			; put "/" at the begging of the string		
	mov 	byte [edi + 1], 0		; put "\0" to mark the current end of the string
	mov 	ebx, edi				; ebx will point to the last character in the string
									; (the last printable character, not the \0)
	xor 	ecx, ecx				; ecx will go from 0 to n - 1
loop_words:
	cmp 	ecx, eax				; check if ecx is n
	jge 	end_loop_words
	mov		edx, [esi + 4 * ecx]	; take the start address of the current word
	
	;; First, check if it is a single dot ".". In this case, I will jump over
	;; all the next operations, because it will stay in the same directory
	pushad							; save the values, because strcmp will alter them
	push 	edx 					; one param of strcmp is the string that start at edx
	push 	curr 					; the second param of strcmp is "." string
	call 	strcmp 					; compare the words
	add     esp, 8                  ; restablish the initial state of the stack
	cmp 	eax, 0					; if the strings are equal eax will become 0
	je 		pop_and_skip		    ; pop the values and skip the string proccessing
	popad 							; bring back the values saved before strcmp

	;; Check if the string is a double-dot construction "..".
	pushad 							; save the values before calling the func
	push 	edx						; string1 to compare
	push 	back 					; string2 to compare
	call 	strcmp 					; compare the strings
	add 	esp, 8					; set the esp pointer back where it was				
	cmp 	eax, 0					; check if the strings are the same
	jne 	pop_and_concatenate		; bring back the values and concatenate
	popad 							; restore the values saved before calling the func

	;; Check if there isn't something to delete
	;; This case happens when the string from edi is just a /
	;; So, the simplest way, is to compare the string from edi with
	;; slash
	pushad 							; save the values before calling the function, as usual
	push 	edi 					; one parameter is the output string
	push 	slash					; and the other one is the slash string
	call 	strcmp
	add 	esp, 8					; restablish the initial stack state
	;; If the result of strcmp is 0, that means I have to stay in the same root (/) directory,
	;; so I'll have to skip everything, like in the case of a single dot
	cmp 	eax, 0
	je 		pop_and_skip
	popad 							; restore the values saved before, as usual

	;; If I have to go back in the directories, I want to move the ebx pointer to the next
	;; / (from end to start), and put \0 after the character
move_pointer:
	sub 	ebx, 1					; first, subtract 1, because the last character is a \
									; and we want to find the next one
	cmp 	byte [ebx], '/'			; otherwise, if I don't subtract 1, this will always be true
	je 		end_move_pointer
	jmp 	move_pointer
end_move_pointer:
	mov 	byte [ebx + 1], 0		; put \0 after the slash
	jmp 	skip 					; skip the concatenation
pop_and_concatenate:
	popad 							; because it makes a jump, the values that we need
									; are still on stack. If the jump wasn't made, I'll
									; have to jump over this pop
concatenate_words:
	;; Concatenate the edx to the end of edi
	pusha 							; save the values, because I will call strcat func
	push 	edx 					; the source string
	push 	edi 					; the destination string
	call 	strcat 					; put edx to the end of edi
	add 	esp, 8					; restablish the state of the stack
	popa							; restore the values

	;; Calculate the length of the string
	;; Save the values of eax and ecx, in case strlen alter them
	push 	eax
	push 	ecx

	push 	edx						; the parameter for strlen function
	call 	strlen
	add 	esp, 4 					; move esp back, above the parameter
	add 	ebx, eax				; set the pointer to the end of the string,
									; by adding the string length
	
	;; Restore the old values used in the function
	pop 	ecx						
	pop 	eax

	;; Put "/" at the end of the string
	pushad
	push 	slash 					; the source string
	push 	edi 					; the destination string
	call 	strcat
	add 	esp, 8 					; restablish the stack state after the function call
	popad
	add 	ebx, 1					; move the pointer one position
	jmp 	skip 					; the next pop comes from the results of strcmp, that
									; make the jumps here. If it reaches this point, I'll
									; get a big error if I'd try to pop all
pop_and_skip:
	popad
skip:
	inc 	ecx 					; take the next element
	jmp 	loop_words 				; return in loop
end_loop_words:
	popad							; restore the values from the main function
	leave
	ret