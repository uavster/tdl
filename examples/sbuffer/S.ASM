.386p
.model flat
.stack 1000h
.data
        INCLUDE utils.inc
        INCLUDE blitter.inc
        INCLUDE sli.inc
        INCLUDE newsgl.inc
        INCLUDE loader.inc
        INCLUDE sbuffer.inc

        OddFlag dd  0
        stest   SPAN    ?
.code

SCREENX EQU 640
SCREENY EQU 480
CBITS   EQU 24

start:
        InitDPMI

        call    InitSGL
        ErrorExit "Error!"

        mov     eax,SCREENX
        mov     ebx,SCREENY
        mov     ecx,CBITS
        call    CreateVideoSLI
        ErrorExit "Error creating video SLI"

        mov     eax, offset fname
        mov     ebx, 32
        call    LoadGFX
        ErrorExit "Error loading file"
        mov     source, ebx

        call    GetVideoSLI
        ;call    SLI2SBuffer
        ;ErrorExit "Error creating SBuffer"

        bucle:
                call    GetVideoSLI
                ;call    InitSBufferSLI


                call    GetVideoSLI
                mov     ebx, 30
                and     ebx, OddFlag
                xor     OddFlag, -1
                call    ClearCurrentFrame

                call    GetVideoSLI
                mov     edi, eax
                mov     esi, source
                call    blit

                mov     ecx, 315
            DibujaLineas:
                push    ecx
                mov     stest.SPx1, ecx
                mov     stest.SPx2, 315
                mov     stest.SPType, 1
                mov     stest.SPN, 1
                mov     stest.SPiZ, 1
                mov     stest.SPDiZ, 1

                mov     ebx, ecx
                shl     ebx, 9
                lea     ebx, [ebx+ecx*4]
                lea     ebx, [ebx+ebx*4]
                mov     stest.SPTexture, ebx
                push    ecx
                call    GetVideoSLI
                pop     ecx
                mov     ebx, offset stest
                ;call    InsertSpan
                pop     ecx
                loop    DibujaLineas

                call    GetVideoSLI
                ;call    RenderSbufferSLI

                call    ShowPage

        mov     ah,1
        int     16h
        jz      bucle
        xor     ah,ah
        int     16h

        mov     eax,3
        call    DestroyVideoSLI
        ErrorExit "Error destroying video SLI"

        call    UnInitSGL

        call    mem_statistix

        Exit
.data
        source  dd      ?
        fname   db  "carr03.pcx",0
end start
