;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Complete 2D graphic system
;       by C‚sar Guirao Robles (a.k.a. Nitro! / the DarkRising)
;       and Ignacio Mellado Bataller (a.k.a. B52 / the D@rkRising)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

INCLUDE newsgl.inc
INCLUDE alloc.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the memory needed by an image of the specified dimensions and color depth
;
; INPUT  -> EAX = X Size
;           EBX = Y Size
;           ECX = Color depth (Number of bits per pixel)
;
; OUTPUT -> CF = 0 if memory size < 4Gb (physically addresseable)
;               ECX = Memory needed
;           CF = 1 if elsewhere
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetImageMemory  proc
        mul     ebx
        mul     ecx
        sub     edx,1
        jc      GetImMemError
        mov     ecx,eax
        ret

        GetImMemError:
        ret
GetImageMemory  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Creates a new SGL Linear Image
;
; INPUT  -> EAX = X Size
;           EBX = Y Size
;
; OUTPUT -> CF = 0 & EAX = 0 if SLI created ok
;               EBX -> SLI info block
;           CF = 1 & EAX = Error code if error
;                     Error codes:
;                       1 - Not enough memory for bitmap  
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
NewSLI  proc
        ; Alojamos memoria para el info block y la imagen en un bloque
        mov     ecx,DefaultDepth
        call    GetImageMemory
        jc      NewSLIError1
        add     ecx,size SLI    ; le sumamos el tama¤o del info block
        call    malloc
        jc      NewSLIError1
        ; Ponemos el info block por defecto
        mov     esi,offset DefaultInfoBlock
        mov     edi,ebx
        mov     ecx,size SLI
        rep     movsb
        ret

        NewSLIError1:
        mov     eax,1
        ret
NewSLI  endp

.data
DefaultInfoBlock        SLI <0,0,VISIBLE,0,BLIT_COPY,0,0,0,<0,0>,<0,0>,<<0,0>,<0,0>>,0,0,-1,4,0,0,0,1,10000h,0,0,>

.data?
DefaultDepth    dd 4    ; 32 bits de color para buffers
