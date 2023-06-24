
struc node
	.value:     resd 1
	.left:      resd 1
	.right:     resd 1
endstruc

section .text
    global inorder_fixing

;;  inorder_fixing(struct node *node, struct node *parent)
;       functia va parcurge in inordine arborele binar de cautare, modificand
;       valorile nodurilor care nu respecta proprietatea de arbore binar
;       de cautare: |node->value > node->left->value, daca node->left exista
;                   |node->value < node->right->value, daca node->right exista.
;
;       Unde este nevoie de modificari se va aplica algoritmul:
;           - daca nodul actual este fiul stang, va primi valoare tatalui - 1,
;                altfel spus: node->value = parent->value - 1;
;           - daca nodul actual este fiul drept, va primi valoare tatalui + 1,
;                altfel spus: node->value = parent->value + 1;

;    @params:
;        node   -> nodul actual din arborele de cautare;
;        parent -> tatal/parintele nodului actual din arborele de cautare;

inorder_fixing:
    enter 0, 0
    ;; As usual, save the values from main function, before starting anything
	pushad
    mov     edx, [ebp + 8]              ; put the node parameter in edx
    mov     ebx, [ebp + 12]             ; put the parent parameter in ebx

    ;; The base case to return from recursion
	cmp     edx, 0      
    je      _null_pointer


    ;; Call the function for the left child of the node. In this case the node becomes
    ;; the parent
    push    edx                         ; the new parent
    push    dword [edx + node.left]     ; the new node
    call    inorder_fixing
    add     esp, 8

	;; Another special case if when the node has no parent. This happens when it reaches 
	;; the root of the tree. For this, I'll skip the processing and just call the function
	;; for the right child
	cmp     ebx, 0
    je      _call_right

	;; Split the problem:
	;; Check if the current node is the left child or the right child of the parent node
	;; My idea is to compare the addresses
	mov 	eax, dword [ebx + node.right]
	cmp 	edx, eax
	je 		_right_child

	;; If it reaches this point, it means that the previous jump wasn't made, so the
	;; current node is a left child
_left_child:
	mov 	eax, dword [edx + node.value] ; put the value of the node in eax
	mov 	ecx, dword [ebx + node.value] ; put the value of the parent node in ecx
	;; I have to check if node->value < parent->value
	cmp 	eax, ecx
	jl 		_call_right

	;; Change the value within the node
	sub 	ecx, 1 							; calculate (parent->value - 1)
	mov 	dword [edx + node.value], ecx
	jmp 	_call_right

_right_child:
	mov 	eax, dword [edx + node.value] ; put the value of the node in eax
	mov 	ecx, dword [ebx + node.value] ; put the value of the parent node in ecx

	;; I have to check if node->value > parent->value
	cmp 	eax, ecx
	jg 		_call_right

	;; Change the value within the node
	add 	ecx, 1
	mov 	dword [edx + node.value], ecx

	;; Call the function for the right child. The node becomes the parent and the right
	;; child becomes the node.
_call_right:
	push 	edx 						; the new parent
	push 	dword [edx + node.right]	; the new node
	call 	inorder_fixing
	add 	esp, 8

_null_pointer:
    popad
    leave
    ret
