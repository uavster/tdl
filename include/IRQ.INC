;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; IRQ helpers
;       Coded by Ignacio Mellado Bataller a.k.a. B52 / the D@rkRising
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

IRQEnter	MACRO
        pushad
        push    ds es fs gs
        mov     ax,cs:DataSelector
        mov     ds,ax
        mov     es,ax
		mov		fs,ax
		mov		gs,ax
ENDM

IRQLeave	MACRO
        pop     gs fs es ds
        popad
        iretd
ENDM

IRQMasterAck	MACRO
		mov		al,20h
		out		20h,al
ENDM

IRQSlaveAck		MACRO
		mov		al,20h
		out		0a0h,al
ENDM

IRQAck	MACRO irq_number
		; Acknowledge PIC
        mov     al,20h
		cmp		irq_number,8
		jb		ack_master_pic
		; Acknowledge slave PIC first
		out		0a0h,al
		ack_master_pic:
		; Acknowledge master PIC
        out     20h,al	
ENDM

