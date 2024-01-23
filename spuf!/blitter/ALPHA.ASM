;�����������������������������������������������������������������������������
; Table for alpha routines
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;�����������������������������������������������������������������������������

.386p
.model flat
.code

        INCLUDE alpha.inc
        INCLUDE alloc.inc
        INCLUDE stderror.inc

;�����������������������������������������������������������������������������
; Initializes tables for routines with alpha calculation
;
; OUTPUT -> CF = 0 if succes
;               EAX = 0
;           CF = 1 if error
;               EAX = Error code
;�����������������������������������������������������������������������������
InitAlphaFX       proc
        mov     ecx,256*256*2
        call    malloc
        ErrorCode MALLOC_ERROR

        mov     edi,ebx
        mov     ImgAlphaTable,ebx
        lea     eax,[ebx+256*256]
        mov     BackAlphaTable,eax
        xor     ecx,ecx
        mov     esi,255
        color_col:
                xor     ebx,ebx
                alpha_row:
                        mov     eax,ebx
                        mul     ecx
                        div     esi
                        mov     [edi+ebx],al
                        push    ecx
                        mov     eax,ebx
                        inc     cl
                        neg     cl
                        mul     ecx
                        div     esi
                        mov     [edi+ebx+256*256],al
                        pop     ecx
                inc     bl
                jnz     alpha_row
                add     edi,256
        inc     cl
        jnz     color_col
        xor     eax,eax
        clc
        ret
InitAlphaFX       endp

.data?
ImgAlphaTable   dd ?
BackAlphaTable  dd ?

end
