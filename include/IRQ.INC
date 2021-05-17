;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; IRQ helpers
;       Coded by Ignacio Mellado Bataller a.k.a. B52 / the D@rkRising
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

Trm_reg         STRUC
        rm_edi          dd ?
        rm_esi          dd ?
        rm_ebp          dd ?
                        dd ?
        rm_ebx          dd ?
        rm_edx          dd ?
        rm_ecx          dd ?
        rm_eax          dd ?
        rm_flags        dw ?
        rm_es           dw ?
        rm_ds           dw ?
        rm_fs           dw ?
        rm_gs           dw ?
        rm_ip           dw ?
        rm_cs           dw ?
        rm_sp           dw ?
        rm_ss           dw ?
ENDS

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
		out		0a0h,al		; ACK slave PIC
		out		20h,al		; ACK master PIC
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

IRQHookData		STRUC
		irq_number		db ?
		int_number		db ?
		pm_handler		dd ?
						dw ?
		lock_bytes		dd ?
		old_pm_handler	dd ?
						dw ?
		rm_handler		dw ?
						dw ?
		rm_callback		dw ?
						dw ?
		rm_registers	Trm_reg<>
		rm_handler_regs Trm_reg<>
ENDS

;-----------------------------------------------------------------
; Initializes IRQ handling library.
;
; OUTPUT:
;	CF = 0 if successful; 1, otherwise.
;-----------------------------------------------------------------
global	IRQInit : NEAR

;-----------------------------------------------------------------
; Uninitializes IRQ handling library.
;
; OUTPUT:
;	CF = 0 if successful; 1, otherwise.
;-----------------------------------------------------------------
global	IRQUninit : NEAR

;-----------------------------------------------------------------
; Sets a protected mode interrupt handler that will be called from
; both protected and real mode (via callback).
;
; INPUT:
;	AL = IRQ number
;	CS:EBX -> Interrupt Service Routine
;	ECX = Bytes to lock from ISR start
;
; OUTPUT:
;	CF = 0 and EAX = 0, if success
;	CF = 1 and EAX != 0, if error
;-----------------------------------------------------------------
global	IRQHook : NEAR

;-----------------------------------------------------------------
; Restores interrupts handlers and callbacks set with IRQHook for
; an IRQ.
;
; INPUT:
;	AL = IRQ number
;
; OUTPUT:
;	CF = 0 and EAX = 0, if success
;	CF = 1 and EAX != 0, if error
;-----------------------------------------------------------------
global IRQRestore : NEAR

;-----------------------------------------------------------------
; Calls the original real-mode ISR from protected mode.
;
; INPUT:
;	AL = IRQ number
;
; OUTPUT:
;	CF = 0 and EAX = 0, if success
;	CF = 1 and EAX != 0, if error
;-----------------------------------------------------------------
global IRQCallRealModeHandler : NEAR

;-----------------------------------------------------------------
; Returns the InDOS and ErrorMode flags.
;
; If the InDOS flags is not zero, the IRQ can only call DOS
; services 01h thru 0Ch safely. If the ErrorMode flag is not zero,
; the IRQ must not call any DOS services.
;
; OUTPUT:
;   AL = ErrorMode flag
;   AH = InDOS flag
;	Upper EAX word is 0
;	All other registers are preserved
;-----------------------------------------------------------------
global IRQDOSFlags : NEAR