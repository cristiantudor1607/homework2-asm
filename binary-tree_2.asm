extern array_idx_2      ;; int array_idx_2

struc node
	.value:     resd 1
	.left:      resd 1
	.right:     resd 1
endstruc

section .text
    global inorder_intruders


;;  inorder_intruders(struct node *node, struct node *parent, int *array)
;       functia va parcurge in inordine arborele binar de cautare, salvand
;       valorile nodurilor care nu respecta proprietatea de arbore binar
;       de cautare: |node->value > node->left->value, daca node->left exista
;                   |node->value < node->right->value, daca node->right exista
;
;    @params:
;        node   -> nodul actual din arborele de cautare;
;        parent -> tatal/parintele nodului actual din arborele de cautare;
;        array  -> adresa vectorului unde se vor salva valorile din noduri;

inorder_intruders:
    enter 0, 0
    pushad
    mov     edx, [ebp + 8]				; take the current node
	mov 	ebx, [ebp + 12] 			; take the parrent node
	mov 	edi, [ebp + 16]				; take the array

	;; The base case
	cmp 	edx, 0
	je 		null_address

	;; Call the function for the left child
	mov 	eax, dword [edx + node.left]
	push 	edi							; the same address to store the numbers
	push 	edx 						; the current node will be the parent
	push 	eax 						; the node param will be node->left
	call 	inorder_intruders
	add 	esp, 12 					; restablish the stack

	;; When it comes back from recursion, do the actual work

	;; If the parent of the current node is null, it means that the node is the 
	;; root of the tree, and in this case, I have to jump over this step
	cmp 	ebx, 0
	je 		_call_right
	
	;; Check if the current node is the left child of the parent
	cmp 	dword [ebx + node.left], edx
	je 		left_child

	;; If it reaches this point, the node is a right child
	mov 	eax, [ebx + node.value]		; the parent value
	mov  	ecx, [edx + node.value] 	; the left child value
	;; node->value should be greater than the parent->value, since the node
	;; is the right child (so eax should be less than ecx)
	cmp 	eax, ecx
	
	;; If the values are in the right order, don't put the value in the array
	jl  	_call_right

	;; Otherwise, I have to put the value stored in ecx in the array
	mov 	eax, dword [array_idx_2] 	; take the index
	mov 	dword [edi + 4 * eax], ecx 	; put the value
	inc 	dword [array_idx_2]

	jmp 	_call_right
left_child:
	mov 	eax, [ebx + node.value]		; the parent value
	mov 	ecx, [edx + node.value]		; the left child value
	;; node->value should be less that parent->value, since the node is
	;; the left child (eax should be grater than ecx)
	cmp 	eax, ecx

	;; If the values are in the right order, don't put the value in the
	;; array
	jg 		_call_right

	;; Otherwise, I have to put the value stored in ecx in the array
	mov 	eax, dword [array_idx_2] 	; take the index
	mov 	dword [edi + 4 * eax], ecx  ; put the value
	inc 	dword [array_idx_2]

	;; Call the function for the right child
_call_right:
	mov 	eax, dword [edx + node.right]
	push 	edi
	push 	edx
	push 	eax
	call 	inorder_intruders
	add  	esp, 12

null_address:
    popad
    leave
    ret
