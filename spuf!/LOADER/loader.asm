;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Graphics loader
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / The DarkRising)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.386p
.model flat
.code
        INCLUDE loader.inc
        INCLUDE pcx.inc
        INCLUDE stderror.inc
        INCLUDE sli.inc
        INCLUDE blitter.inc

GRAPHIC_FORMATS EQU 1
LOAD_PROCS      EQU offset PCXProcs

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Loads a graphic file into a memory SLI
;
; INPUT  : EAX -> GFX file name
;          EBX = Output SLI color depth (number of bits)
;
; OUTPUT : CF = 0 if success
;               EAX = NULL
;               EBX -> Memory SLI
;          CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
LoadGFX proc
        push    ebp
        mov     sli_c,ebx
        mov     ecx,GRAPHIC_FORMATS
        xor     esi,esi
        try_formats:
                push    ecx eax esi
                mov     edx,eax
                mov     edi,[LoadProcs+esi*4]
                push    edi
                call    [edi.TestProc]
                mov     real_x,eax
                mov     real_y,ebx
                mov     real_c,ecx
                mov     real_frames,edx
                pop     edi
                mov     ebp,eax
                pop     esi eax ecx
                jnc     found_format
                cmp     ebp,INVALID_FORMAT
                jnz     load_error
                inc     esi
        loop    try_formats
        stc
        mov     eax,INVALID_FORMAT
        pop     ebp
        ret

        found_format:
        mov     format_handler,edi
        mov     edx,eax
        call    [edi.InitProc]
        ErrorCodePOP eax, ebp

        mov     eax,real_x
        mov     ebx,real_Y
        mov     ecx,real_c
        shl     ecx,3
        mov     edx,1
        call    CreateVoidSLI
        ErrorCodePOP eax, ebp
        mov     source_sli,ebx

        mov     eax,real_x
        mov     ebx,real_y
        mov     ecx,sli_c
        mov     edx,real_frames
        call    CreateSLI
        ErrorCodePOP eax, ebp
        mov     our_sli,ebx

        xor     ecx,ecx
        decompress_frames:
                push    ecx
                mov     edi,format_handler
                call    [edi.LoadProc]
                ErrorCodePOP eax, ebp
                push    eax
                mov     eax,source_sli
                call    SetPalette
                pop     ecx
                mov     eax,source_sli
                xor     ebx,ebx         ; Frame 0
                call    SetFramePtr
                mov     eax,source_sli
                xor     ebx,ebx
                call    SetFrame
                mov     esi,source_sli
                mov     edi,our_sli
                call    Blit
                pop     ebx
                ErrorCodePOP eax, ebp
                mov     eax,our_sli
                inc     ebx
                push    ebx
                call    SetFrame
                pop     ecx
        cmp     ecx,real_frames
        jnz     decompress_frames

        mov     eax,source_sli
        call    DestroySLI
        ErrorCodePOP eax, ebp
        mov     eax,our_sli
        xor     ebx,ebx
        call    SetFrame

        mov     edi,format_handler
        call    [edi.EndProc]
        ErrorCodePOP eax, ebp

        mov     ebx,our_sli
        xor     eax,eax
        clc
        pop     ebp
        ret

        load_error:
        stc
        pop     ebp
        ret
LoadGFX endp

.data
LoadProcs       dd LOAD_PROCS

.data?
sli_c           dd ?
real_x          dd ?
real_y          dd ?
real_c          dd ?
real_frames     dd ?
source_sli      dd ?
our_sli         dd ?
format_handler  dd ?

end
