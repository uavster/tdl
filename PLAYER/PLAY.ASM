JUMPS
.486P
.MODEL FLAT
.STACK 400h
        assume cs:@code, ds:@data, es:@data
.DATA
        cmdline         db 256 dup(?)

        curpos          dw ?

        txt_row         db 'Playing ... Patt : %bn'
                        dd npatt
                        db ', Row : %bn'
                        dd nrow
                        db '       ',0
        npatt           db 0
        nrow            db 0

.CODE
        include player.inc
        include sb.inc
        include utils.inc
        include waitvr.inc

        ;extrn   xprint:NEAR

        PUBLIC main_
main_:
;Start:
        InitDPMI
        sti

        ;mov     esi, offset msg_intro
        ;call    xprint


        mov     esi, ProgramPSP
        add     esi, 81h
        mov     edi, offset cmdline
        call    GetCommandParam

        mov     edx, offset cmdline
        call    LoadModule
        jc      salircagandoleches

        mov     eax, 45454
        call    InitPlayer
        jc      salircagandoleches

        call    PLAY
        jc      salircagandoleches

        mov     al, 0ffh
        call    SetVolume
        call    SetGlobalVolume

        ;mov     ah, 3
        ;xor     bh, bh
        ;int     10h

        ;mov     curpos, dx

        mov     PlayerFlags, 0          ; surround & tick
tecla:
    sti
comment „
        call    Check4Sync
        jc      noefecto
        cmp     al, 080h
        jne     norow

ootot1:
        call    Check4Sync
        jc      ootot1
        mov     npatt, al
ootot2:
        call    Check4Sync
        jc      ootot2
        mov     nrow, al

        mov     dx, curpos
        mov     ah, 2
        xor     bh, bh
        int     10h

        print   txt_row

        mov     dx, curpos
        mov     ah, 2
        xor     bh, bh
        int     10h

        jmp     noefecto

norow:
        cmp     al, 0h
        jne     noefecto
        call    efecto
noefecto:

        ;mov     ah, 1
        ;int     16h
        „

        in      al, 60h
        cmp     al, 1
        jne     tecla

        ;mov     ah, 0
        ;int     16h

        ;cmp     al, 's'
        ;je      surround
        ;cmp     al, 'r'
        ;je      sync
        ;cmp     al, 'q'
        ;je      final

        ;jmp     tecla

final:
        call    STOP
salircagandoleches:
        mov     ax, 4c00h
        int     21h



surround:
        xor     PlayerFlags, 1
        jmp     tecla

sync:
        xor     PlayerFlags, 2
        jmp     tecla


efecto          PROC
        push    ax dx
        wait_vr
        wait_vr
        wait_vr
        mov     dx, 3c8h
        xor     al, al
        out     dx, al
        inc     dx
        not     al
        out     dx, al
        out     dx, al
        out     dx, al
        wait_vr
        wait_vr
        wait_vr
        mov     dx, 3c8h
        xor     al, al
        out     dx, al
        inc     dx
        out     dx, al
        out     dx, al
        out     dx, al
        pop     dx ax
        ret
efecto          ENDP
        



END;     Start
