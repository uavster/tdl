JUMPS

.386p
.model flat
.code

include irq.inc
include dpmi.inc
include alloc.inc
include stderror.inc

NUM_IRQS			EQU 16
MASTER_IRQ_BASE		EQU 8
SLAVE_IRQ_BASE		EQU 70h

rm_common_handler_entry_points LABEL
IRQ_NUM=0
REPT    NUM_IRQS
        mov     al,IRQ_NUM
        jmp     short rm_common_handler
        IRQ_NUM=IRQ_NUM+1
ENDM
end_of_rm_common_handler_entry_points LABEL

irq_rm_handler_offset	MACRO irq_number
		movzx	eax,irq_number
		xor		edx,edx
		mov		ebx,(offset end_of_rm_common_handler_entry_points-offset rm_common_handler_entry_points)/NUM_IRQS
		mul		ebx
		add		eax,offset rm_common_handler_entry_points
ENDM

rm_common_handler	proc
		; AL = IRQ number
		push	ds es fs gs
		pushad
		movzx	eax,al
		mov		esi,[offset irq_hook_data_pointers+eax*4]
		pushfd
		call	fword ptr [esi.pm_handler]
		popad
		pop		gs fs es ds

        cld
        lodsw
        mov     es:[edi.rm_ip],ax
        lodsw
        mov     es:[edi.rm_cs],ax
        lodsw
        mov     es:[edi.rm_flags],ax
        add     es:[edi.rm_sp],2*3
        iretd
endp
end_of_rm_handler_lock_area	LABEL

;-----------------------------------------------------------------
; Initializes IRQ handling library.
;
; OUTPUT:
;	CF = 0 if successful; 1, otherwise.
;-----------------------------------------------------------------
IRQInit		proc
	; Initialize pointers to IRQ data structures
	xor		eax,eax
	push	ds
	pop		es
	mov		edi,offset irq_hook_data_pointers
	mov		ecx,NUM_IRQS
	rep		stosd
	; Lock region of the RM common handler
	mov		ebx,offset rm_common_handler_entry_points
	mov		ecx,offset end_of_rm_handler_lock_area-offset rm_common_handler_entry_points
	call	LockMem	
	ret
endp

;-----------------------------------------------------------------
; Uninitializes IRQ handling library.
;
; OUTPUT:
;	CF = 0 if successful; 1, otherwise.
;-----------------------------------------------------------------
IRQUninit	proc
	; Restore all missing IRQs
	xor		al,al
	restore_missing_irqs:
			push	eax
			call	IRQRestore
			pop		eax
			jc		irq_uninit_error
			inc		al
	cmp		al,NUM_IRQS
	jnz 	restore_missing_irqs
	
	; Unlock common callback memory area
	mov		ebx,offset rm_common_handler_entry_points
	mov		ecx,offset end_of_rm_handler_lock_area-offset rm_common_handler_entry_points
	call	UnlockMem
	irq_uninit_error:
	ret
endp

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
IRQHook		proc
	pushfd
	cli
	movzx	eax,al
	push	eax ebx ecx
	; Allocate data structure with IRQ state
	mov		ecx,size IRQHookData
	call	malloc
	mov		eax,MALLOC_ERROR
	or		ebx,ebx
	jz		irq_hook_error_no_dpmi
	mov		esi,ebx
	pop		ecx ebx eax
	mov		[offset irq_hook_data_pointers+eax*4],esi
	; IRQ -> int number
	mov		[esi.irq_number],al
	cmp		al,MASTER_IRQ_BASE
	jb		low_irq
			add		eax,SLAVE_IRQ_BASE-MASTER_IRQ_BASE
	low_irq:
	add		eax,MASTER_IRQ_BASE
	mov		[esi.int_number],al
	mov		[esi.pm_handler],ebx
	mov		[esi.pm_handler+4],cs
	mov		[esi.lock_bytes],ecx
	; Lock handler memory
	push	esi
	call	LockMem
	pop		esi
	mov		eax,MALLOC_ERROR
	jc		irq_hook_error
	; Save existing RM IRQ handler
	mov     ax,200h
	mov     bl,[esi.int_number]
	int     31h
	jc		irq_hook_error
	mov     [esi.rm_handler],dx
	mov		[esi.rm_handler+2],cx
	; Save previous protected mode interrupt handler
	mov     ax,204h
	mov     bl,[esi.int_number]
	int     31h
	jc		irq_hook_error
	mov	    [esi.old_pm_handler],edx
	mov	    word ptr [esi.old_pm_handler+4],cx
	; Set new protected mode interrupt handler
	mov		edx,[esi.pm_handler]
	mov		cx,word ptr [esi.pm_handler+4]
	mov     ax,205h
	mov     bl,[esi.int_number]
	int     31h
	jc		irq_hook_error
	; Get a real mode callback to our protected mode routine
	push	ds es esi
	push	ds
	pop		es
	lea     edi,[esi.rm_registers]
	push    cs
	pop     ds
	irq_rm_handler_offset	[esi.irq_number]
	mov     esi,eax
	mov     ax,303h
	int     31h
	pop		esi es ds
	jc		irq_hook_error
	mov		[esi.rm_callback],dx
	mov		[esi.rm_callback+2],cx
	; Point IRQ to the real mode callback
	mov     ax,201h
	mov     bl,[esi.int_number]
	int     31h	
	popfd
	xor		eax,eax
	clc
	ret
	
	irq_hook_error:
	or		eax,DPMI_ERROR
	irq_hook_error_no_dpmi:
	popfd
	stc
	ret
endp

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
IRQRestore	proc
	pushfd
	cli
	movzx	eax,al
	mov		esi,[offset irq_hook_data_pointers+eax*4]
	cmp		esi,0
	jnz		hook_data_valid
			popfd
			xor		eax,eax
			ret
	hook_data_valid:
	; Restore real mode interrupt handler
	cmp		[esi.rm_handler],0
	jz		rm_handler_restored
			mov     ax,201h
			mov		dx,[esi.rm_handler]
			mov		cx,[esi.rm_handler+2]
			mov     bl,[esi.int_number]
			int     31h
			jc		irq_restore_error
			mov		dword ptr [esi.rm_handler],0
	rm_handler_restored:
	; Free real mode callback
	cmp		dword ptr [esi.rm_callback],0
	jz		rm_callback_freed
			mov		ax,304h
			mov		dx,[esi.rm_callback]
			mov		cx,[esi.rm_callback+2]
			int		31h
			jc		irq_restore_error
			mov		dword ptr [esi.rm_callback],0
	rm_callback_freed:
	; Restore protected mode interrupt handler
	cmp		[esi.old_pm_handler],0
	jnz		restore_pm_handler
	cmp		word ptr [esi.old_pm_handler+4],0
	jz		pm_handler_restored
	restore_pm_handler:
			mov     edx,[esi.old_pm_handler]
			mov     cx,word ptr [esi.old_pm_handler+4]
			mov     bl,[esi.int_number]
			mov     ax,205h
			int     31h
			jc		irq_restore_error
			mov		[esi.old_pm_handler],0
			mov		word ptr [esi.old_pm_handler+4],0
	pm_handler_restored:
	; Unlock handler memory
	cmp		[esi.lock_bytes],0
	jz		pm_handler_unlocked
			mov		ebx,[esi.pm_handler]
			mov		ecx,[esi.lock_bytes]
			push	esi
			call	UnlockMem
			pop		esi
			jc		irq_restore_error
			mov		[esi.pm_handler],0
			mov		[esi.lock_bytes],0
	pm_handler_unlocked:
	; NULL data pointer
	movzx	eax,[esi.irq_number]
	mov		dword ptr [offset irq_hook_data_pointers+eax*4],0
	; Free data structure
	mov		ebx,esi
	call	free
	jc		irq_restore_malloc_error
	popfd
	xor		eax,eax
	ret
	
	irq_restore_malloc_error:
	popfd
	mov		eax,MALLOC_ERROR
	stc
	ret
	
	irq_restore_error:
	popfd
	; Free data structure
	push	eax
	mov		ebx,esi
	call	free
	pop		eax
	or		eax,DPMI_ERROR
	stc
	ret
endp

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
IRQCallRealModeHandler	proc
	; Call real mode proc with iret frame
	pushfd
	cli
	movzx	eax,al
	mov		esi,[offset irq_hook_data_pointers+eax*4]
	mov		edx,dword ptr [esi.rm_handler]
	lea		edi,[esi.rm_handler_regs]
	popfd
	mov		ax,302h
	xor		bh,bh
	xor		ecx,ecx
	push	ds
	pop		es
	mov		[edi.rm_ip],dx
	shr		edx,16
	mov		[edi.rm_cs],dx
	mov		[edi.rm_ss],0
	mov		[edi.rm_sp],0
	mov		[edi.rm_flags],0	; IRQ code will expect IF to be off.
	int		31h
	jc		irq_call_real_mode_handler_error
	xor		eax,eax
	ret

	irq_call_real_mode_handler_error:
	or		eax,DPMI_ERROR
	stc
	ret
endp

.data?
irq_hook_data_pointers	dd NUM_IRQS dup(?)

end