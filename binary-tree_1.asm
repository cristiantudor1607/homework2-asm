
extern array_idx_1      ;; int array_idx_1

struc node
	.value:     resd 1
	.left:      resd 1
	.right:     resd 1
endstruc

section .text
	global inorder_parc

;;  inorder_parc(struct node *node, int *array);
;       functia va parcurge in inordine arborele binar de cautare, salvand
;       valorile nodurilor in vectorul array.
;    @params:
;        node  -> nodul actual din arborele de cautare;
;        array -> adresa vectorului unde se vor salva valorile din noduri;

inorder_parc:
	enter 0, 0
	;; First things first, save the values from the main function
	pushad

	mov     edx, [ebp + 8] 					; edx will store the address of the current node
	mov 	esi, [ebp + 12] 				; esi will store the address of the array
	;; The base case
	cmp 	edx, 0
	je 		null_address

	;; Call the function for the left child
	mov 	eax, dword [edx + node.left]		
	pushad
	push 	esi								; the same address to store the numbers
	push 	eax  							; the left child node
	call 	inorder_parc					; call the function for the left child
	add 	esp, 8 							; restablish the stack, after calling the function
	popad 							
	
	;; Put the element in the array, after it comes back from recursion
	mov 	eax, dword [edx + node.value]	; take the value
	mov 	ecx, dword [array_idx_1]		; take the index
	mov 	dword [esi + 4 * ecx], eax 		; put the value at the current index
	inc 	dword [array_idx_1] 			; increse the index

	;; Call the function for the right child
	mov 	eax, [edx + node.right]
	pushad
	push 	esi								; the same address to store numbers
	push 	eax 							; the right child of the node
	call 	inorder_parc 					; call the function for the right child
	add 	esp, 8							; restablish stack
	popad
null_address:
	;; Restore the values from the main function
	popad
	leave
	ret
