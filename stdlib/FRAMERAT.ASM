;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Simple routines to measure the frame rate
;       by Ignacio Mellado Bataller a.k.a. B52 / the DarkRising
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

.386p
.model flat
.code

        INCLUDE utils.inc
        INCLUDE framerat.inc

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Starts the frame rate measure (to be called just before the loop)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
StartFrameRate  proc
		push	ebp
        xor     ah,ah
        int     1Ah
        mov     eax,ecx
        shl     eax,16
        mov     ax,dx
        mov     frames_sec,eax
        mov     frames,0
		pop		ebp
        ret
StartFrameRate  endp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Increments frame counter (to be called each frame)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
IncFrameCounter proc
        inc     frames  ; un frame m쟳...
        ret
IncFrameCounter endp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Stops the frame rate measure (to be called just at the end of the loop)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
StopFrameRate   proc
		push	ebp
        xor     ah,ah
        int     1Ah
        mov     eax,ecx
        shl     eax,16
        mov     ax,dx
        sub     eax,frames_sec
        mov     ebx,eax
        mov     eax,1193182     ; 18.21 con precisi줻 de 16 bits
        mul     frames          ; ( num. frames / ticks por segundo ) * 65536
        xor     edx,edx
        div     ebx
        shr     eax,16          ; fuera precisi줻...
        mov     frames_sec,eax
		pop		ebp
        ret
StopFrameRate   endp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Shows the frame rate measurement results
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
ShowFrameRateResult     proc
		push	ebp
        mov     eax,frames_sec
        mov     ebx,10
        mov     esi,offset number
        call    TransToBase

        mov     esi,offset cadena
        call    printf
        mov     esi,offset cr
        call    printf
		pop		ebp
        ret
ShowFrameRateResult     endp

.data
cadena          db "Frames/second: "
number          db 11 dup(0)
cr              db 13,10,0

.data?
frames          dd ?
frames_sec      dd ?

end
