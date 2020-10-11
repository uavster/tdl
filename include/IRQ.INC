;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; IRQ helpers
;       Coded by Ignacio Mellado Bataller a.k.a. B52 / the D@rkRising
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

IRQEnter	MACRO
        pushad
        push    ds es
        mov     ax,DataSelector
        mov     ds,ax
        mov     es,ax		
ENDM

IRQLeave	MACRO
        pop     es ds
        popad
        iretd
ENDM

IRQAck	MACRO irq_number
		; Acknowledge PIC
        mov     al,20h
		cmp		irq_number,8
		jb		ack_master_pic
		; Acknowledge slave PIC first
		mov		dx,0a0h
		out		dx,al
		ack_master_pic:
		; Acknowledge master PIC
        mov     dx,20h
        out     dx,al	
ENDM
