;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; TIMER routines for common irq0 handling
;       Coded by Ignacio Mellado Bataller a.k.a. B52 / the D@rkRising
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

NUM_HANDLES     equ 20  ; handle capacity
USER_TIMER_ROUTINE_LOCK_SIZE		equ 4*4096

JUMPS

.386p
.model flat
.code

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


        INCLUDE timer.inc
        INCLUDE dpmi.inc
		INCLUDE stderror.inc

rm_common_handler	proc
		push	ds es fs gs
		pushad
		pushfd
		call	fword ptr cs:common_handler_address
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
common_handler_address		dd offset common_handler
common_handler_address_seg	dw ?
rm_common_handler	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Common irq0 handler that calls all near routines in allocated slots
; NOTE: All registers are pushed so that routines don't need register saving
;       and all segment registers are set to a 32bit 4Gb data selector
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
common_handler  proc far
        push    ds es fs gs
        pushad
		mov		cs:old_irq_called,0
        mov     ax,cs:DataSelector
        mov     ds,ax
        mov     es,ax
        mov     fs,ax
        mov     gs,ax

        mov     ecx,NUM_HANDLES
        mov     esi,offset handler_chain
        walk_handlers:
                cmp     [esi.pointer],-1
                jz      all_handlers_done
                cmp     dword ptr [esi.period+4],1
                jz      time_for_handler       ; if period = 1.00 go always
                mov     eax,dword ptr [esi.period]
                add     [esi.count],eax
                jnc     no_time_for_handler
                        time_for_handler:
                        or      [esi.status],0  ; is timer off?
                        jz      no_time_for_handler
                        push    ds es fs gs esi ecx
                        call    [esi.pointer]
                        pop     ecx esi gs fs es ds
                no_time_for_handler:
                add     esi,size Ttimer
        loop    walk_handlers
        all_handlers_done:
        ; master irq controller aknowledgement
		cmp		cs:old_irq_called,0
		jnz		ack_done
				mov     al,20h
				out     20h,al
		ack_done:
        popad
        pop     gs fs es ds
        iretd
old_irq_called	db ?
common_handler_end:
common_handler  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Routine to call old irq0 handler
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
call_old_handler        proc
		; Call real mode proc with iret frame
		mov		ax,302h
		xor		bh,bh
		xor		ecx,ecx
		push	ds
		pop		es
		mov		edi,offset rm_call_regs_old_irq
		mov		dx,word ptr old_rm_handler
		mov		[edi.rm_ip],dx
		mov		dx,word ptr old_rm_handler+2
		mov		[edi.rm_cs],dx
		mov		[edi.rm_ss],0
		mov		[edi.rm_sp],0
		mov		[edi.rm_flags],0	; IRQ code will expect IF to be off.
		int		31h
		mov		cs:old_irq_called,1
        ret
call_old_handler        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Enables timer extensions (sets irq0 handler)
;
;       NOTE: This function executes all timer routines previously allocated
;             for synchronization
;
; INPUT -> EAX = 32bit floating point frequency to call old handler at
;                ( 0 if old handler will be ignored)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
enable_timer    proc
        cli
        test    enabled,1
        jnz     timer_already_enabled
		mov		old_handler_freq,eax
		mov		cs:common_handler_address_seg,cs
		; Lock handler memory
		mov		ebx,offset common_handler
		mov		ecx,offset common_handler_end-offset common_handler
		call	LockMem
		mov		ebx,offset handler_chain
		mov		ecx,size handler_chain
		call	LockMem
		; Save old IRQ handler
        mov     ax,200h
        mov     bl,8
        int     31h
        mov     old_rm_handler,dx
		mov		old_rm_handler+2,cx
		; Save previous protected mode interrupt handler
        mov     ax,204h
        mov     bl,8
        int     31h
        mov     old_handler,edx
        mov     word ptr old_handler+4,cx
		; Set new protected mode interrupt handler
        mov     ax,205h
        mov     bl,8
        mov     cx,cs
        mov     edx,offset common_handler
        int     31h
		; Get a real mode callback to our protected mode routine
		push	ds es
		push	ds
		pop		es
        mov     edi,offset rm_call_struct
        push    cs
        pop     ds
        mov     esi,offset rm_common_handler
        mov     ax,303h
        int     31h
		pop		es ds
		mov		rm_callback_seg,cx
		mov		rm_callback_off,dx
		; Point timer IRQ0 to the real mode callback
        mov     ax,201h
        mov     bl,8
        int     31h
		
        ; first time execution of all timers allocated
        mov     ecx,NUM_HANDLES
        mov     esi,offset handler_chain
        exec_handlers:
                cmp     [esi.pointer],-1
                jz      all_handlers_executed
                push    dword ptr [esi.status]
                push    ecx esi
                mov     [esi.status],0              ; don't want execution                
                call    [esi.pointer]               ; inside irq while
                pop     esi ecx                     ; executing here    
                pop     dword ptr [esi.status]
                add     esi,size Ttimer
        loop    exec_handlers
        all_handlers_executed:
		; Call the original timer ISR
		mov		eax,old_handler_freq
        mov     ebx,offset call_old_handler
        call    add_timer
        ; we set the enable flag
        mov     enabled,1
        timer_already_enabled:
        sti
        ret
old_handler_freq	dd ?
enable_timer    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Disables timer extensions (restores irq0 handler) 
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
disable_timer   proc
        test    enabled,1
        jz      timer_still_not_enabled
        mov     enabled,0                       ; timer is off
		; Restore normal timer frequency
        mov     eax,18
        call    set_timer_freq
		; Restore real mode interrupt handler
        mov     ax,201h
		mov		cx,old_rm_handler+2
		mov		dx,old_rm_handler
        mov     bl,8
        int     31h
		jc		disable_timer_error		
		; Free real mode callback
		mov		ax,304h
		mov		cx,rm_callback_seg
		mov		dx,rm_callback_off
		int		31h
		jc		disable_timer_error
		; Restore protected mode interrupt handler
        mov     edx,old_handler
        mov     ecx,dword ptr old_handler+4     ; smaller op.code with dword 
        mov     bl,8
        mov     ax,205h
        int     31h
		jc		disable_timer_error
		; Unlock handler memory
		mov		ebx,offset handler_chain
		mov		ecx,size handler_chain
		call	UnlockMem
		jc		disable_timer_leave
		mov		ebx,offset common_handler
		mov		ecx,offset common_handler_end-offset common_handler
		call	UnlockMem
		jc		disable_timer_leave
        timer_still_not_enabled:
		clc
		disable_timer_leave:
		ret
		
		disable_timer_error:
		and		eax,0ffffh
		or		eax,DPMI_ERROR
		stc
		ret
disable_timer   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Adds a timer routine to the handler chain
;
;       NOTE: This function executes the input timer routine inmediately
;             if timer has been enabled before with 'enable_timer' for
;             synchronization
;
; INPUT  -> EAX = 32-bit floating point frequency to call the routine at
;           DS:EBX -> near pointer to routine
;
; OUTPUT -> CF = 0 if success
;           CF = 1 if error
;               AL = error code
;                       00h if no more free timer slots
;                       01h if too high frequency
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
add_timer       proc
        or      eax,eax
        jz      handler_is_ignored
        mov     trash,eax
        fld     trash
        fistp   trash
        cmp     trash,1193182
        ja      too_high_freq
        mov     esi,offset handler_chain
        mov     ecx,NUM_HANDLES
        look_for_free_slot:
                cmp     [esi.pointer],-1
                jz      found_free_slot
                add     esi,size Ttimer
        loop    look_for_free_slot
        xor     al,al
        stc
        ret

        found_free_slot:
		push	eax ebx esi
		mov		ecx,USER_TIMER_ROUTINE_LOCK_SIZE
		call	LockMem
		pop		esi ebx eax
        ; we disconnect the timer
        mov     [esi.status],0
        ; slot is filled with data
        mov     [esi.pointer],ebx
        mov     [esi.frequency],eax
        push    esi
        call    search_highest_freq
        mov     eax,current_freq
        call    force_frequency
        pop     esi
        mov     [esi.count],0
        ; first time routine execution only if timer has been enabled
        or      enabled,0
        jz      still_off
        call    [esi.pointer]   ; won't be executed inside irq, now
        still_off:
        mov     [esi.status],1  ; activate
        handler_is_ignored:
        clc
        ret

        too_high_freq:
        mov     al,1
        stc
        ret
add_timer       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Looks for a handler in the chain
;
; INPUT  -> EBX = offset of the handler or NULL if old irq0 handler
;
; OUTPUT -> handler found:     DS:ESI -> handler data and continues execution
;           handler NOT found: CF = 1 and returns
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
LookForHandler  MACRO
LOCAL   look_for_slot,found_slot
        mov     esi,offset handler_chain
        or      ebx,ebx
        jz      found_slot
        mov     ecx,NUM_HANDLES
        look_for_slot:
                cmp     [esi.pointer],ebx
                jz      found_slot
                add     esi,size Ttimer                        
        loop    look_for_slot
        stc
        ret
        found_slot:
ENDM

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Removes a timer routine from the handler chain
;
; INPUT  -> DS:EBX -> near pointer to routine or NULL if old irq0 handler
;
; OUTPUT -> CF = 0 if success
;           CF = 1 if pointer not found in the handler chain
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
remove_timer    proc

        LookForHandler

        ; we move back the handler chain so that there are no free slots
        ; before the last full slot
        push    esi
        mov     edi,esi
        add     esi,size Ttimer
        mov     ecx,(NUM_HANDLES+1)*size Ttimer+offset handler_chain
        sub     ecx,esi
        ; ECX won't be 0
        push    ecx
        shr     ecx,2
        cli     ; handling an irq0 while moving pointers would'nt be nice :)
        cld
        rep     movsd
        ; we move the rest if size was not divisible by 4 ;)
        pop     ecx
        and     ecx,3
        or      ecx,ecx
        jz      no_more_bytes
        rep     movsb
        no_more_bytes:
        sti
        pop     esi

		push	esi
		mov		ebx,esi
		mov		ecx,USER_TIMER_ROUTINE_LOCK_SIZE
		call	UnlockMem
		pop		esi

        ; if the current frequency corresponds to the removed one, we search
        ; the highest again and recalculate the periods
        mov     eax,[esi.frequency]
        cmp     eax,current_freq
        jnz     not_the_current
                call    search_highest_freq
                mov     eax,current_freq
                call    force_frequency
        not_the_current:                
        clc
        ret
remove_timer    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Forces the frequency of the system timer for accurate timing
;
; INPUT -> EAX = 32-bit floating point frequency to be forced
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
force_frequency proc
        mov     trash,eax
        fld     trash
        fcomp   min_freq
        fstsw   fpu_status
        mov     ax,fpu_status
        sahf
        jae     no_freq_fixup
                ; minimum frequency is 18.2 Hz
                mov     ebx,min_freq
                mov     trash,ebx
        no_freq_fixup:
        fld     trash
        fst     current_freq
        fistp   trash
        call    calc_all_periods
        mov     eax,trash
        call    set_timer_freq
        ret
min_freq        dd 18.2
force_frequency endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Changes the status of a given timer routine
;
;       NOTE: When stopped, the count of the routine is still running but
;             it is not called when the count ends
;
; INPUT  -> DS:EBX -> near pointer to routine or NULL if old irq0 handler
;           AL = status
;                     00h if stopped
;                     01h if resumed
;
; OUTPUT -> CF = 0 if success
;           CF = 1 if pointer not found in the handler chain
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
timer_status    proc
        LookForHandler
        mov     [esi.status],al
        clc
        ret
timer_status    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the count of a timer routine to zero to perform synchronization
;
; INPUT  -> DS:EBX -> near pointer to routine or NULL if old timer
;
; OUTPUT -> CF = 0 if success
;           CF = 1 if pointer not found in the handler chain
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
sync_timer      proc
        LookForHandler
        mov     [esi.count],0
        clc
        ret
sync_timer      endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Changes the frequency of the system timer
; INPUT -> EAX = int frequency in Hz (max. 1193182 Hz)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
set_timer_freq  proc
        ; 1193182/frequency is given to the controller
        mov     ebx,eax
        mov     eax,1193182     ; magic constant ;) (max. frequency)
        xor     edx,edx
        div     ebx
        cmp     eax,65536       ; max. port value = 65536 (=0)
        jb      no_fixup
                xor     eax,eax
        no_fixup:
        mov     ebx,eax
        mov     al,36h
        out     43h,al
        mov     al,bl
        out     40h,al
        mov     al,bh
        out     40h,al        
        ret
set_timer_freq  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Looks for the highest frequency in the handler chain and sets 'current_freq'
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
search_highest_freq     proc
        mov     ecx,NUM_HANDLES
        mov     esi,offset handler_chain
        mov     current_freq,0
        search_highest:
                cmp     [esi.pointer],-1
                jz      highest_found
                        fld     [esi.frequency]
                        fcomp   current_freq
                        fstsw   fpu_status
                        mov     ax,fpu_status
                        sahf
                        jbe     dont_change_current
                                mov     eax,[esi.frequency]
                                mov     current_freq,eax
                        dont_change_current:
                add     esi,size Ttimer
        loop    search_highest
        highest_found:
        ret
search_highest_freq     endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Calculates the period of each timer from its frequency
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
calc_all_periods        proc
        mov     ecx,NUM_HANDLES
        mov     esi,offset handler_chain
        calc_periods:
                cmp     [esi.pointer],-1
                jz      periods_done
                fld     [esi.frequency]
                fmul    precision_ct    ; 32-bit fixed point precision
                fdiv    current_freq
                fistp   [esi.period]
                add     esi,size Ttimer
        loop calc_periods
        periods_done:
        ret
calc_all_periods        endp

.data

Ttimer  STRUC
        pointer         dd -1
        status          db 0,0,0,0      ; 1 = active , 0 = paused (4 bytes to align)
        frequency       dd 18.2
        period          dq 0
        count           dd 0
ENDS

precision_ct    dq 4294967296.0         ; = 2^32
current_freq    dd 18.2
num_timers      dd 0
enabled         db 0

handler_chain   Ttimer NUM_HANDLES+1 dup(<>)
                ; last handle is end of data (for moving back the chain)
hihi            db 30h

.data?
trash           dd ?
old_handler     dd ?    ; old irq0 handler routine
                dw ?
old_rm_handler	dw ?
				dw ?
rm_callback_off dw ?
rm_callback_seg	dw ?
fpu_status      dw ?
rm_call_struct	Trm_reg<?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?>
rm_call_regs_old_irq Trm_reg<?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?>

end 
