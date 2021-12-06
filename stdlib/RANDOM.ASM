JUMPS
.386p
.model flat
.code
public      random
public      randomize
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
random proc
; INPUT  -> AX = maximum random value
; OUTPUT -> AX = random number
        mov      cx,ax          ; save limit
        mov      ax,Word ptr [RandSeed+2]
        mov      bx,Word ptr [RandSeed]
        mov      si,ax
        mov      di,bx
        mov      dl,ah
        mov      ah,al
        mov      al,bh
        mov      bh,bl
        xor      bl,bl
        rcr      dl,1
        rcr      ax,1
        rcr      bx,1
        add      bx,di
        adc      ax,si
        add      bx,62e9h
        adc      ax,3619h
        mov      word ptr [RandSeed],bx
        mov      word ptr [RandSeed+2],ax
        xor      dx,dx
        div      cx
        movzx	 eax,dx                  ; return modulus
        ret
randseed        dd 0
random endp
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
randomize proc
        mov ah,2Ch
        int 21h
        mov      Word ptr [RandSeed],cx
        mov      Word ptr [RandSeed+2],dx
        ret
randomize endp
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
end
