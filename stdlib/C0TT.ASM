;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; file: c0tt.asm
;
;  A little startup code to use Watcom C with #Trouble# Team's DarkX.
;
;       by Xavier Rubio Jansana, a.k.a. Teknik / #Trouble# Team, July 1998
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

        .386p
        .model flat

        .stack  10000h

        .code

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

        include alloc.inc
        include utils.inc

        extrn   main_: near
        public  _cstart_
        public  _exit_          ; B52

    ; NOTA: sembla que l'WLINK vol el _cstart_, encara que no ha de ser
    ;       per for놹 el nom del punt d'entrada.

_cstart_:

        InitDPMI

        call    main_

_cfinish_:
        ExitSilently

_exit_  proc
        mov     ReturnCode,al
        pop     eax             ; B52 - pop return EIP
        jmp     _cfinish_
        endp

        end     _cstart_

