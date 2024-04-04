;�����������������������������������������������������������������������������
; Simple routines to measure the frame rate
;       by Ignacio Mellado Bataller a.k.a. B52 / the DarkRising
;�����������������������������������������������������������������������������

.386p
.model flat
.code

        INCLUDE utils.inc
        INCLUDE framerat.inc

;�����������������������������������������������������������������������������
; Starts the frame rate measure (to be called just before the loop)
;�����������������������������������������������������������������������������
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

;�����������������������������������������������������������������������������
; Increments frame counter (to be called each frame)
;�����������������������������������������������������������������������������
IncFrameCounter proc
        inc     frames  ; un frame m�s...
        ret
IncFrameCounter endp

;�����������������������������������������������������������������������������
; Stops the frame rate measure (to be called just at the end of the loop)
;�����������������������������������������������������������������������������
StopFrameRate   proc
    cmp   frames,0
    jz    no_frames_counted
		push	ebp
        xor     ah,ah
        int     1Ah
        mov     eax,ecx
        shl     eax,16
        mov     ax,dx
        sub     eax,frames_sec
        mov     ebx,eax
        mov     eax,1193182     ; 18.21 con precisi�n de 16 bits
        mul     frames          ; ( num. frames / ticks por segundo ) * 65536
        xor     edx,edx
        div     ebx
        shr     eax,16          ; fuera precisi�n...
        mov     frames_sec,eax
		pop		ebp
    no_frames_counted:
        ret
StopFrameRate   endp

;�����������������������������������������������������������������������������
; Shows the frame rate measurement results
;�����������������������������������������������������������������������������
ShowFrameRateResult     proc    
		push	ebp
    cmp frames,0
    jz invalid_measure
        mov     eax,frames_sec
        mov     ebx,10
        mov     esi,offset number
        call    TransToBase
    invalid_measure:
        mov     esi,offset cadena
        call    printf
        mov     esi,offset cr
        call    printf
		pop		ebp
        ret
ShowFrameRateResult     endp

.data
frames          dd 0
cadena          db "Frames/second: "
number          db "-"
                db 10 dup(0)
cr              db 13,10,0

.data?
frames_sec      dd ?

end
