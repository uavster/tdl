.386p
.model  flat
 jumps
.stack  200h
.code
    include utils.inc
    include newsgl.inc

sleep   macro
        xor     eax, eax
        int     16h
endm

    testx   equ 320
    testy   equ 400
    testc   equ 16

    assume  cs:@code, ds:@code, es:@code

start:
    InitDPMI
    ;mov     eax, SSO_QuietFinish
    ;call    SetSGLOptions
    sleep

comment ¤
    mov     eax, 320
    mov     ebx, 200
    mov     ecx, 8
    call    SetVideoMode
    ErrorExit "Can not set mode!"

    sleep
    Call    GetAvailPage
    mov     edi, eax
    mov     ecx, 320*200/4
    mov     eax, 0f10300fh
    rep     stosd
    sleep

    mov     eax, 1
    call    ShowPage
    sleep

    mov     eax, 256
    mov     ebx, 256
    mov     ecx, 8
    call    SetVideoMode
    ErrorExit "Can not set mode!"
    sleep

    Call    GetAvailPage
    mov     edi, eax
    mov     ecx, 16384
    mov     eax, 0f10300fh
    rep     stosd
    sleep


    mov     eax, 1
    call    ShowPage
    sleep



    mov     eax, 320
    mov     ebx, 400
    mov     ecx, 16 OR SGL_MemoryBuffer
    call    SetVideoMode
    ErrorExit "Can not set mode! 320x400x16 bits"

    mov     eax, 1
    call    ShowPage
    sleep

    call    GetAvailPage
    mov     edi, eax
    mov     ecx, 320*400*2/4
    mov     eax, 00f32ffffh
    rep     stosd

    mov     eax, 1
    call    ShowPage
    sleep

    call    GetAvailPage
    mov     edi, eax
    mov     ecx, 320*400*2/4
    mov     eax, 012345678h
    rep     stosd

    mov     eax, 1
    call    ShowPage
    sleep


    ¤

    mov     eax, 640
    mov     ebx, 480
    mov     ecx, 16 + SGL_MemoryBuffer
    call    SetVideoMode
    ErrorExit "Can not set mode! 640x480x16 bits"

    mov     eax, 1
    call    ShowPage
    sleep

    call    GetAvailPage
    mov     edi, eax
    mov     ecx, 640*480*2/2
    mov     eax, 011111100000b
    rep     stosw

    mov     eax, 1
    call    ShowPage
    sleep

    call    GetAvailPage
    mov     edi, eax
    mov     ecx, 640*480*2/2
    mov     eax, not 011111100000b
    rep     stosw

    mov     eax, 1
    call    ShowPage
    sleep


    mov     eax, 3
    call    UnSetVideoMode
    ErrorExit "Can not unset mode!"
    sleep

    Exit

end start
