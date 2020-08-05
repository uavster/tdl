.386p
.model flat
.stack 1000h
.code
        INCLUDE utils.inc
start:
        InitDPMI

        movf    eax,1.00
        mov     ebx,offset routine
        call    add_timer

        wk:
        in      al,60h
        dec     al
        jnz     wk

        Exit

routine:
        xor     byte ptr ds:[0b8000h+1],1
        ret
end start

