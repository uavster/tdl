.386p
.model flat
.stack 1000h
.code
        INCLUDE list.inc
        INCLUDE utils.inc
start:
        InitDPMI

        call    NewList
        ErrorExit "Error creating list"
        mov     list,eax

        mov     eax,list
        mov     ebx,offset elem1
        call    AddElement

        mov     eax,list
        mov     ebx,offset elem1
        call    DeleteElement

        mov     eax,list
        mov     ebx,offset elem2
        call    AddElement

        mov     eax,list
        call    DeleteList

        Exit

.data
elem1   dd 1
elem2   dd 2

.data?
list    dd ?

end start
