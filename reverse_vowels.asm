
section .data

section .text
	global reverse_vowels
	global is_vowel

;; int is_vowel(char c)
is_vowel:
	push 	ebp						; save the current base pointer
	xor		ebp, ebp				; set it to 0
	add 	ebp, esp 				; add esp to ebp, to make ebp = esp
	
	;; Now, I want to save all I have in the registers, except eax, which will
	;; return true or false (1 or 0)
	push 	ebx						; ebx saved first
	push 	ecx  					; ecx saved second
	push 	edx 					; edx saved third

	xor		eax, eax				; initialize eax to 0
	xor 	edx, edx				; set edx to 0
	add 	edx, [ebp + 8]			; store the character in edx
	
	cmp		edx, 'a'
	je		return_true

	cmp 	edx, 'e'
	je		return_true

	cmp		edx, 'i'
	je 		return_true

	cmp		edx, 'o'
	je 		return_true

	cmp		edx, 'u'
	je 		return_true
	jmp		return_false

return_true:
	add 	eax, 1

return_false:

	pop 	edx 					; edx saved third => edx retrieved first
	pop 	ecx 					; ecx saved second => ecx retrieved second
	pop 	ebx						; ebx saved first => ebx retrieved third
	pop 	ebp
	ret

;;	void reverse_vowels(char *string)
;	Cauta toate vocalele din string-ul `string` si afiseaza-le
;	in ordine inversa. Consoanele raman nemodificate.
;	Modificare se va face in-place
reverse_vowels:
	push	ebp						; save the current base pointer
	xor		ebp, ebp				; set it to 0
	add		ebp, esp 				; add esp, to set ebp to esp
	pusha							; save all to retrieve them at the end of
									; the execution
	xor		esi, esi				; set esi to 0. It will store string (the
									; begging address of the string, actually)
	add		esi, [ebp + 8]			; put the address in esi

	xor		ecx, ecx 				; set ecx to 0. It will be the index in the
									; string
push_vowels:
	xor		ebx, ebx				; set ebx to 0, to store the current char
									; in bl
	add		bl, byte [esi + ecx]	; put the current char in bl
	cmp		bl, 0					; check if the char is the \0 terminator
	je		end_push_vowels			; if it is, it means we reached the end of
									; the string
	push 	ebx						; set the parameter for the is_vowel func
	call	is_vowel				; check if the current letter is a vowel
	pop 	ebx

	cmp		eax, 1					; if is not a vowel, don't push the letter
	jne		not_vowel
	
	push 	ebx						; push the vowel

not_vowel:
	inc 	ecx 					; take the next character
	jmp		push_vowels 			; return to the loop
end_push_vowels:
	
	xor		ecx, ecx 				; go trough the string again
replace_vowels:
	xor		ebx, ebx				; set ebx to 0, to move the value by
									; adding it to ebx
	add 	bl, byte [esi + ecx]	; take the letter at index ecx (string[ecx])
	cmp		bl, 0					; check if it has reached the end of the string
	je 		end_replace_vowels 		; exit the loop

	push 	ebx						; parameter for is_vowel func
	call 	is_vowel				; the func will put 0 or 1 in eax
	pop 	ebx						; bring stack to it's initial "configuration"

	cmp		eax, 1					; if it's not a vowel, just skip this step				
	jne		skip

	pop 	edx						; store the new vowel in edx
	;; I want to make some trick to put the value stored in edx in string[ecx]:
	;; I will set eax to 0, then I move by adding the current letter (string[ecx]),
	;; and then I will subtract from the value at string[ecx], what at I have in
	;; eax, so that I will put 0 there
	xor 	eax, eax
	add 	al, byte [esi + ecx]
	sub 	byte [esi + ecx], al
	
	add 	byte [esi + ecx], dl	; the new letter is in dl
skip:
	inc 	ecx
	jmp 	replace_vowels
end_replace_vowels:

	popa
	pop 	ebp
	ret