;�����������������������������������������������������������������������������
; KEYBOARD routines for common key handling
;       Coded by Ignacio Mellado Bataller a.k.a. B52 / the D@rkRising
;�����������������������������������������������������������������������������

ROUTINE_PAGES   EQU 4   ; 4Kb pages to lock for each routine

.386p
.model flat
.code

INCLUDE dpmi.inc
INCLUDE irq.inc

public  enable_keyb
public  disable_keyb
public  add_key
public  remove_key
public  keyb_map
public 	add_default_key
public	remove_default_key
public 	is_key_pressed

;�����������������������������������������������������������������������������
; Common irq1 handler
; NOTE: Saves all registers and calls every handler with all segment
;       registers set with a 32bit 4Gb selector
;�����������������������������������������������������������������������������
common_key_handler      proc far
		IRQEnter
		
		; Read key code
        xor     eax,eax
        in      al,60h

; ������������������-��-�---�-��-������ �  � 
;   Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro!
;                          �  � ����-��-�--�-�-��-�������������������������
        mov     bl, al
        not     bl
        shr     bl, 7
        mov     ecx, eax
        and     ecx, 127
        mov     keyb_map[ecx], bl
; ������������������-��-�---�-��-������ �  �
;   Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro!
;                          �  � ����-��-�--�-�-��-�������������������������

        mov     ebx,[eax*4+key_array]
        cmp     ebx,-1
        jz      no_reaction
                call    ebx
				jmp		no_default_handler
        no_reaction:
		; If no special handler for the key, call default handler
		mov		ebx,default_key_handler
		or		ebx,ebx
		jz		chain_old_isr
				call	ebx
		no_default_handler:
		or		eax,eax
		jnz		chain_old_isr
		
		; Ack interrupt controller
		IRQMasterAck
		IRQLeave
		
		chain_old_isr:
		; Chain with RM keyboard irq handler.
		; It should acknowledge the keyboard controller and the master irq controller.
		mov		al,1
		call	IRQCallRealModeHandler
		IRQLeave
		
common_key_handler      endp

; offsets to call with each keyboard event
key_array				dd 102+128 dup(-1)

lock_end:       ; memory will be locked down to here...

;�����������������������������������������������������������������������������
; Enables keyboard extensions (sets irq1 handler)
;
; OUTPUT:
;	CF = 0, if success
; 	CF = 1, if error
;		EAX = Error code
;�����������������������������������������������������������������������������
enable_keyb     proc
        test    keyb_enabled,1
        jz 	    enable_key_continue
				xor		eax,eax
				ret
		enable_key_continue:

		; Initialize key map
        mov     edi, offset keyb_map    ; Nitro!
        mov     ecx, 128/4              ; Nitro!
        xor     eax, eax                ; Nitro!
        rep     stosd                   ; Nitro!
		
        ; Lock the memory that the handler will touch
        mov     ebx, offset keyb_map    ; Nitro!
        mov     ecx, 128                ; Nitro!
        call    LockMem                 ; Nitro!
		jc		enable_key_error

		; Hook handler on IRQ 1
		mov		al,1
		mov		ebx,offset common_key_handler
		mov		ecx,offset lock_end-offset common_key_handler
		call	IRQHook
		jc		enable_key_error
        mov     keyb_enabled,1
		
        enable_key_error:		
        ret
enable_keyb     endp

;�����������������������������������������������������������������������������
; Disables keyboard extensions (restores irq1 handler) 
;
; OUTPUT:
;	CF = 0, if success
; 	CF = 1, if error
;		EAX = Error code
;�����������������������������������������������������������������������������
disable_keyb    proc
        test    keyb_enabled,1
        jnz     disable_keyb_continue
				xor		eax,eax
				ret
		disable_keyb_continue:
		
		; Restore IRQ 1 handler
		mov		al,1
		call	IRQRestore
		jc		disable_keyb_error
		
        ; Unlock the memory to allow VM management
        mov     ebx, offset keyb_map
        mov     ecx, 128 
        call    UnlockMem
		jc		disable_keyb_error
		
        mov     keyb_enabled,0
		
        disable_keyb_error:
        ret
disable_keyb    endp

;�����������������������������������������������������������������������������
; Sets the routine to be called by a keyboard event
;
; INPUT -> AL = keyboard scancode
;          DS:EBX -> routine to be called when the scancode is received
;		   The routine returns != 0, if the IRQ must chain with the old ISR,
;		   or 0, otherwise.
;�����������������������������������������������������������������������������
add_key proc
        ; need to lock the routine memory field
        push    ebx eax
        mov     ecx,4096*ROUTINE_PAGES  ; 8Kb for the routine
        call    LockMem
        pop     eax 
        ; we fill the scancode slot
        movzx   eax,al
        pop     dword ptr [eax*4+key_array]
        ret
add_key endp

;�����������������������������������������������������������������������������
; Sets the routine to be called by any keyboard event that has no specific handler
; associated to it
;
; INPUT -> DS:EBX -> routine to be called when any scancode is received or NULL if none
; 		   The routine is called with EAX = scancode
;		   The routine returns != 0, if the IRQ must chain with the old ISR,
;		   or 0, otherwise.
;�����������������������������������������������������������������������������
add_default_key proc
		mov		default_key_handler,ebx
		ret
add_default_key	endp

;�����������������������������������������������������������������������������
; Removes the routine called by any keyboard event
;
; INPUT -> AL = keyboard scancode
;�����������������������������������������������������������������������������
remove_key      proc
        movzx   eax,al
        mov     ebx,-1
        xchg    [eax*4+key_array],ebx
        cmp     ebx,-1
        jz      nothing_to_unlock
        mov     ecx,4096*ROUTINE_PAGES
        call    UnlockMem
        nothing_to_unlock:
        ret
remove_key      endp

;�����������������������������������������������������������������������������
; Removes the routine to be called by any keyboard event
;�����������������������������������������������������������������������������
remove_default_key 	proc
		mov		default_key_handler,0
		ret
remove_default_key	endp

;�����������������������������������������������������������������������������
; Removes the routine called by any keyboard event
;
; INPUT -> AL = keyboard scancode
; OUTPUT : If key pressed,
;				CF = 1 and EAX != 0
;		   If key not pressed,
;				CF = 0 and EAX == 0
;�����������������������������������������������������������������������������
is_key_pressed	proc
		and		al,127
		movzx	eax,al
		movzx	eax,keyb_map[eax]
		or		eax,eax
		jz		key_not_pressed
				stc
		key_not_pressed:
		ret
is_key_pressed	endp

.data
keyb_enabled    	dd 0
default_key_handler	dd 0

.data?
keyb_map        	db 128 dup (?)

end