.386p
.model flat
.stack 1000h
.code
        INCLUDE list.inc
        INCLUDE utils.inc

PrintList	proc
	mov		esi,offset elems_str
	call	printf
	mov		eax,list
	call	ResetListPtr
	mov		eax,list
	call	GetNextElement
	jc		elems_printed			
	mov		esi,offset elem_str
	mov		elem_ptr,ebx
	call	printf
	print_elems:
			mov		eax,list
			call	GetNextElement
			jc		elems_printed		
			mov		esi,offset comma_str
			call	printf
			mov		esi,offset elem_str			
			mov		elem_ptr,ebx
			call	printf
	jmp		print_elems
	elems_printed:
	mov		esi,offset cr_str
	call	printf
	ret
endp
		
start:
        InitDPMI

		LPrintS ""
		LPrintS "Creating list..."

        call    NewList
        ErrorExit "Error creating list"
        mov     list,eax

		call	PrintList

		LPrintS "Adding 1 at start..."
        mov     eax,list
        mov     ebx,offset elem1
		xor		ecx,ecx
        call    AddElement

		call	PrintList
		
		LPrintS "Adding 2 at end..."
        mov     eax,list
        mov     ebx,offset elem2
		mov		ecx,LIST_END
        call    AddElement
		
		call	PrintList
		
		LPrintS "Deleting 1..."
        mov     eax,list
        mov     ebx,offset elem1
        call    DeleteElement

		call	PrintList
		
		LPrintS "Adding 3 at start..."
        mov     eax,list
        mov     ebx,offset elem3
		xor		ecx,ecx
        call    AddElement

		call	PrintList
		
		LPrintS "Adding 4 between 3 and 2..."
        mov     eax,list
        mov     ebx,offset elem4
		mov		ecx,1
        call    AddElement
		
		call	PrintList
		
        mov     eax,list
        call    DeleteList

        ExitSilently

.data
elem1   dd 1
elem2   dd 2
elem3	dd 3
elem4	dd 4

elem_str	db "%dn"
elem_ptr	dd ?
			db 0
elems_str	db "Elements: ",0
cr_str		db 13,10,0
comma_str	db ",",0

.data?
list    dd ?

end start
