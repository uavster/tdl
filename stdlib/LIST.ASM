;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Generic listing functions
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / the DarkRising)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.386p
.model flat
.code

    INCLUDE alloc.inc
    INCLUDE stderror.inc
    INCLUDE list.inc

if LIST_DEBUG
    INCLUDE utils.inc
endif

List        struc
    LFirst      dd ?
    LLast       dd ?
    LCurrent    dd ?
    ends

ListAtom    struc
    LAPrev      dd ?
    LANext      dd ?
    LAObject    dd ?
    ends

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Creates a list
;
; OUTPUT : CF = 0 if ok
;               EAX = NULL
;               EBX -> List
;          CF = 1 if error
;               EAX = Error code (MALLOC_ERROR)
;				EBX = NULL
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
NewList proc
        mov     ecx,size List
        call    malloc
        ErrorCode MALLOC_ERROR
        mov     eax,ebx
        mov     [ebx.LFirst],0
        mov     [ebx.LLast],0
        mov     [ebx.LCurrent],0
        clc
        ret
NewList endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Deletes a list and all its atoms
;
; INPUT  : EAX -> List to delete
;
; OUTPUT : CF = 0 if ok
;               EAX = NULL
;          CF = 1 if error
;               EAX = Error code (FREE_ERROR)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DeleteList      proc
        mov     ebx,[eax.LFirst]
        push    eax
        test    ebx,ebx
        jz      no_atoms_to_del
        delete_atoms:
                mov     eax,[ebx.LANext]
                push    eax
                call    free
                pop     eax
                ErrorCode FREE_ERROR
                mov     ebx,eax
        test    ebx,ebx
        jnz     delete_atoms
        no_atoms_to_del:
        pop     ebx
        call    free
        ErrorCode FREE_ERROR
        xor     eax,eax
        clc
        ret
DeleteList      endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Inserts an atom A between atoms B and B+1 (updates LFirst and LLast
; if needed)
;
; INPUT  : EAX -> Atom A
;          EBX -> Atom B (if 0, atom B will be inserted last)
;          ECX -> List
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
InsertAtom      proc
        test    ebx,ebx
        jnz     found_atom
                mov     ebx,[ecx.LLast] ; If atom B = 0, insert the last
                test    ebx,ebx         ; If EBX = NULL, insert the first
                jnz     found_atom
                mov     [ecx.LFirst],eax
                mov     [ecx.LLast],eax
                mov     [eax.LANext],0
                mov     [eax.LAPrev],0
                ret
        found_atom:

        ; Inserting after B
        mov     edx,[ebx.LANext]
        test    edx,edx         ; If B+1 doesn't exists, we are the last
        jnz     not_last
                mov     [ecx.LLast],eax
                jmp     last_jmp
        not_last:               ; Else, B+1 points to us
                mov     [edx.LAPrev],eax
        last_jmp:
        mov     [eax.LANext],edx
        mov     [eax.LAPrev],ebx
        mov     [ebx.LANext],eax
        ret
InsertAtom      endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Deletes an atom (updates LFirst and LLast if needed)
;
; INPUT  : EAX -> Atom
;          ECX -> List
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DeleteAtom      proc
        mov     edx,[eax.LANext]
        test    edx,edx         ; If next doesn't exists, we are the last
        jnz     not_last2
                mov     ebx,[eax.LAPrev]
                mov     [ecx.LLast],ebx
                test    ebx,ebx
                jnz     no_first_correc
                mov     [ecx.LFirst],ebx
                jmp     del_jmp
                no_first_correc:
                mov     [ebx.LANext],0
                jmp     del_jmp
        not_last2:              ; Else, B+1 points to us
        mov     ebx,[eax.LAPrev]
        test    ebx,ebx
        jnz     not_first2
                mov     ebx,[eax.LANext]
                mov     [ecx.LFirst],ebx
                test    ebx,ebx
                jnz     no_last_correc
                mov     [ecx.LLast],ebx
                jmp     del_jmp
                no_last_correc:
                mov     [ebx.LAPrev],0
                jmp     del_jmp
        not_first2:
        mov     [edx.LAPrev],ebx
        mov     [ebx.LANext],edx
        del_jmp:
        ret
DeleteAtom      endp


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Adds an element to a list
;
; INPUT  : EAX -> List
;          EBX -> Element to add
;          ECX = Position to enter element at ( 0 = first ; -1 = last )
;
; OUTPUT : CF = 0 if ok
;               EAX = NULL
;          CF = 1 if error
;               EAX = Error code (MALLOC_ERROR)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
AddElement      proc
        push    eax ebx ecx
        mov     ecx,size ListAtom
        call    malloc
        pop     ecx edx eax
        ErrorCode MALLOC_ERROR
        mov     [ebx.LAObject],edx

        test    ecx,ecx
        jnz     wont_be_first
                mov     edx,[eax.LFirst]
                test    edx,edx
                jnz     xfirst
                        mov     [eax.LLast],ebx
                        mov     [eax.LFirst],ebx
                        mov     [ebx.LANext],0
                        mov     [ebx.LAPrev],0
                        jmp     first_done
                xfirst:
                mov     [edx.LAPrev],ebx
                mov     [ebx.LANext],edx
                mov     [ebx.LAPrev],0
                mov     [eax.LFirst],ebx
                first_done:
                xor     eax,eax
                clc
                ret
        wont_be_first:

        mov     edx,[eax.LFirst]
        test    edx,edx
        jz      found_pos
        walk_atoms:
                dec     ecx
                jz      found_pos
                mov     edx,[edx.LANext]
        test    edx,edx
        jnz     walk_atoms

        found_pos:
        mov     ecx,eax
        mov     eax,ebx
        mov     ebx,edx
        call    InsertAtom
        xor     eax,eax
        clc
        ret
AddElement      endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Removes an element from a list
;
; INPUT  : EAX -> List
;          EBX -> Element to remove
;
; OUTPUT : CF = 0 if ok
;               EAX = 0
;          CF = 1 if error
;               EAX = Error code (ELEMENT_NOT_FOUND, FREE_ERROR)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DeleteElement   proc
        mov     edx,[eax.LFirst]
        sub     edx,1
        ErrorCode ELEMENT_NOT_FOUND
        inc     edx
        find_element:
                cmp     [edx.LAObject],ebx
                jz      elem_found
                mov     edx,[edx.LANext]
        test    edx,edx
        jnz     find_element
        stc
        mov     eax,ELEMENT_NOT_FOUND
        ret

        elem_found:
        mov     ecx,eax
        mov     eax,edx
        push    eax
        call    DeleteAtom
        pop     ebx
        call    free
        ErrorCode FREE_ERROR
        xor     eax,eax
        clc
        ret
DeleteElement   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets next element from a list
;
; INPUT  : EAX -> List
;
; OUTPUT : CF = 0 if ok
;               EAX = 0        
;               EBX -> Element
;          CF = 1 if list finished
;               EAX = Error code (ELEMENT_NOT_FOUND)
;				EBX = NULL
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetNextElement  proc
        mov     edx,[eax.LCurrent]
        test    edx,edx
        jnz     ptr_not_first
                mov     eax,ELEMENT_NOT_FOUND
				xor		ebx,ebx
                stc
                ret
        ptr_not_first:
        cmp     edx,-1
        jnz     ptr_not_last
                mov     eax,ELEMENT_NOT_FOUND
				xor		ebx,ebx
                stc
                ret
        ptr_not_last:
        mov     ebx,[edx.LAObject]
        mov     ecx,[edx.LANext]
        sub     ecx,1
        jc      next_is_end
                inc     ecx
        next_is_end:
        mov     [eax.LCurrent],ecx
        xor     eax,eax
        clc
        ret
GetNextElement  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Resets internal pointer of a list
;
; INPUT : EAX -> List
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ResetListPtr    proc
        mov     ebx,[eax.LFirst]
        mov     [eax.LCurrent],ebx
        ret
ResetListPtr    endp

if LIST_DEBUG
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Prints the satus of a list
;
; INPUT : EAX -> list
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ListStatus      proc
        pushfd
        pushad
        mov     list_pos,eax
        mov     ecx,[eax.LFirst]
        mov     first_obj,ecx
        mov     ecx,[eax.LLast]
        mov     last_obj,ecx
        mov     esi,offset lpos_str
        call    printf
        mov     eax,list_pos
        mov     ebx,[eax.LFirst]
        test    ebx,ebx
        jz      status_ends
        debug_atoms:
                mov     ecx,[ebx.LAPrev]
                mov     ourprev,ecx
                mov     ecx,[ebx.LAObject]
                mov     ourobj,ecx
                mov     ecx,[ebx.LANext]
                mov     ournext,ecx
                mov     esi,offset atom_str
                push    ebx
                call    printf
                pop     ebx
                mov     ebx,[ebx.LANext]
        test    ebx,ebx
        jnz     debug_atoms
        status_ends:
        LPrintS "End of list"
        xor     ah,ah
        int     16h
        popad
        popfd
        ret
lpos_str        db 13,10,"-------------------------------------------------------",13,10
                db "Print status of list at %dhn"
                dd offset list_pos
                db "h...",13,10
                db "First object: %dhn"
                dd offset first_obj
                db "h - Last object: %dhn"
                dd offset last_obj
                db "h",13,10,0

list_pos        dd ?
first_obj       dd ?
last_obj        dd ?

atom_str        db 13,10,"-----------"
                db 13,10,"Previous: %dhn"
                dd offset ourprev
                db "h"
                db 13,10,"Object: %dhn"
                dd offset ourobj
                db "h"
                db 13,10,"Next: %dhn"
                dd offset ournext
                db "h",13,10,0

ourprev         dd ?
ourobj          dd ?
ournext         dd ?

ListStatus      endp
endif

end
