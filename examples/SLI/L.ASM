.386p
.model flat
.stack 1000h

        X_INCREMENT     EQU 8
        Y_INCREMENT     EQU 4

.code
        INCLUDE utils.inc
        INCLUDE newsgl.inc
        INCLUDE sli.inc
        INCLUDE blitter.inc
        INCLUDE gfx.inc
start:
        InitDPMI

        mov     eax,640
        mov     ebx,480
        mov     ecx,16
        call    CreateVideoSLI
        ErrorExit "Unable to set video mode"

        mov     eax,320
        mov     ebx,200
        mov     ecx,32
        mov     edx,1
        call    CreateSLI
        ErrorExit "Error creating SLI"
        mov     output_sli,ebx

        mov     edi,ebx
        mov     eax,25
        mov     ebx,25
        mov     ecx,100
        mov     edx,100
        call    SetClip

        main:
                mov     eax,output_sli
                xor     ebx,ebx
                call    ClearCurrentFrame

                mov     eax,lx1
                mov     ebx,ly1
                mov     ecx,lx2
                mov     edx,ly2
                mov     edi,output_sli
                mov     esi,0ffffffh
                call    Line

                call    GetVideoSLI
                mov     edi,eax
                mov     esi,output_sli
                call    Blit
                ErrorExit "Error blitting!"
                call    ShowPage
        xor     ah,ah
        int     16h
        cmp     al,'u'
        jnz     no_u
                sub     lx1,X_INCREMENT
                jmp     main
        no_u:
        cmp     al,'i'
        jnz     no_i
                add     lx1,X_INCREMENT
                jmp     main
        no_i:
        cmp     al,'o'
        jnz     no_o
                sub     lx2,X_INCREMENT
                jmp     main
        no_o:
        cmp     al,'p'
        jnz     no_p
                add     lx2,X_INCREMENT
                jmp     main
        no_p:

        cmp     al,'q'
        jnz     no_q
                sub     ly1,Y_INCREMENT
                jmp     main
        no_q:
        cmp     al,'a'
        jnz     no_a
                add     ly1,Y_INCREMENT
                jmp     main
        no_a:
        cmp     al,'w'
        jnz     no_w
                sub     ly2,Y_INCREMENT
                jmp     main
        no_w:
        cmp     al,'s'
        jnz     no_s
                add     ly2,Y_INCREMENT
                jmp     main
        no_s:

        dec     ah
        jnz     main

        mov     eax,3
        call    DestroyVideoSLI

        Exit

.data
lx1             dd 30
ly1             dd 30
lx2             dd 70
ly2             dd 30

.data?
output_sli      dd ?

end start
