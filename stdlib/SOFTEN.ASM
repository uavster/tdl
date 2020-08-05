;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Various buffer interpolation routines
;       by Ignacio Mellado Bataller (a.k.a. B52 / the D@rkRising)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
JUMPS
.386p
.model flat
.stack 100h
.code
        INCLUDE soften.inc
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Performs a buffer interpolation with the 8 rounding bytes of each point
;       
;       Interpolation: The center point is calculated as the average
;                      of 'x' points
;               
;                       x x x
;                       x ú x
;                       x x x
;
; INPUT  -> DS:ESI -> buffer to soften
;           DS:EDI -> buffer where to store result
;           ECX = X size of buffer
;           EDX = Y size of buffer
;
; OUTPUT -> DS:EDI -> buffer softened
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
soften8 proc
        mov counter_x8,ecx
        mov ebp,ecx
        neg ebp
        xor ebx,ebx
        soft_it1_8:
        push edx
        soft_it_8:
                ; OPTIMIZATION: bytes are read from lower to higher in memory
                ;               for best cache use ;)
                xor eax,eax
                mov al,[esi+ebp-1]
                mov bl,[esi+ebp]
                add eax,ebx
                mov bl,[esi+ebp+1]
                add eax,ebx
                mov bl,[esi-1]
                add eax,ebx
                mov bl,[esi+1]
                add eax,ebx
                mov bl,[esi+ecx-1]
                add eax,ebx
                mov bl,[esi+ecx]
                add eax,ebx
                mov bl,[esi+ecx+1]
                add eax,ebx
                shr eax,3
                mov [edi],al
                inc esi
                inc edi    
        dec edx
        jnz soft_it_8
        pop edx
        dec counter_x8
        jnz soft_it1_8
        ret
counter_x8      dd 1
soften8 endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Performs a buffer interpolation with the 4 corner bytes of each point
;       
;       Interpolation: The center point is calculated as the average
;                      of 'x' points
;               
;                       x   x
;                         ú  
;                       x   x
;
; INPUT  -> DS:ESI -> buffer to soften
;           DS:EDI -> buffer where to store result
;           ECX = X size of buffer
;           EDX = Y size of buffer
;
; OUTPUT -> DS:EDI -> buffer softened
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
soften4 proc
        mov counter_x4,ecx
        mov ebp,ecx
        neg ebp
        xor ebx,ebx
        soft_it1_4:
        push edx
        soft_it_4:        
                ; OPTIMIZATION: bytes are read from lower to higher in memory
                ;               for best cache use ;)
                xor eax,eax
                mov al,[esi+ebp-1]      ; cache line is loaded
                mov bl,[esi+ebp+1]      ; it's already in cache
                add eax,ebx
                mov bl,[esi+ecx-1]      ; cache line is loaded
                add eax,ebx
                mov bl,[esi+ecx+1]      ; it's already in cache
                add eax,ebx
                shr eax,2
                mov [edi],al
                inc esi
                inc edi    
        dec edx
        jnz soft_it_4
        pop edx
        dec counter_x4
        jnz soft_it1_4
        ret
counter_x4      dd 1
soften4 endp
end
