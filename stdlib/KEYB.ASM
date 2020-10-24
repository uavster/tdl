;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; KEYBOARD routines for common key handling
;       Coded by Ignacio Mellado Bataller a.k.a. B52 / the D@rkRising
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ROUTINE_PAGES   EQU 4   ; 4Kb pages to lock for each routine

.386p
.model flat
.code

INCLUDE dpmi.inc

public  enable_keyb
public  disable_keyb
public  add_key
public  remove_key
public  keyb_map
public 	add_default_key
public	remove_default_key

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Common irq1 handler
; NOTE: Saves all registers and calls every handler with all segment
;       registers set with a 32bit 4Gb selector
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
common_key_handler      proc far
        push    ds es fs gs
        pushad

        mov     ax,DataSelector
        mov     ds,ax
        mov     es,ax
        mov     fs,ax
        mov     gs,ax
        xor     eax,eax
        in      al,60h

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ-ÄÄ-Ä---ú-úú-úúúúúú ú  ú 
;   Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro!
;                          ú  ú úúúú-úú-ú--Ä-Ä-ÄÄ-ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        mov     bl, al
        not     bl
        shr     bl, 7
        mov     ecx, eax
        and     ecx, 127
        mov     keyb_map[ecx], bl
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ-ÄÄ-Ä---ú-úú-úúúúúú ú  ú
;   Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro! Nitro!
;                          ú  ú úúúú-úú-ú--Ä-Ä-ÄÄ-ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

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
		mov		al,20h
		mov		dx,20h
		out		dx,al
		popad
		pop		gs fs es ds
		iretd
		
		chain_old_isr:
		popad
		pop		gs fs es ds
		; Chain with previous keyboard irq handler.
		; Previous handler should acknowledge the keyboard controller and the master irq controller.
		jmp fword ptr cs:old_handler
common_key_handler      endp

old_handler				dd ?
						dw ?

; offsets to call with each keyboard event
key_array				dd 102+128 dup(-1)

lock_end:       ; memory will be locked until here...

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Enables keyboard extensions (sets irq1 handler)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
enable_keyb     proc
        test    keyb_enabled,1
        jnz     keyb_already_enabled
        mov     keyb_enabled,1
        ; first, we lock the memory that the handler will touch
        mov     ebx,offset common_key_handler
        mov     ecx,offset lock_end-offset common_key_handler
        call    LockMem

        mov     ebx, offset keyb_map    ; Nitro!
        mov     ecx, 128                ; Nitro!
        call    LockMem                 ; Nitro!

        ; we change irq1
        mov     ax,204h
        mov     bl,9
        int     31h
        mov     old_handler,edx
        mov     word ptr old_handler+4,cx
        mov     ax,205h
        mov     bl,9
        mov     cx,cs
        mov     edx,offset common_key_handler
        int     31h
        mov     edi, offset keyb_map    ; Nitro!
        mov     ecx, 128/4              ; Nitro!
        xor     eax, eax                ; Nitro!
        rep     stosd                   ; Nitro!
        keyb_already_enabled:
        ret
keyb_enabled    dd 0
enable_keyb     endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Disables keyboard extensions (restores irq1 handler) 
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
disable_keyb    proc
        test    keyb_enabled,1
        jz      keyb_still_not_enabled
        mov     edx,old_handler
        mov     ecx,dword ptr old_handler+4     ; smaller op.code with dword 
        mov     bl,9
        mov     ax,205h
        int     31h
        ; now, it's time to unlock the memory to allow VM management
        mov     ebx,offset common_key_handler
        mov     ecx,offset lock_end-offset common_key_handler
        call    UnlockMem
        mov     ebx, offset keyb_map
        mov     ecx, 128 
        call    UnlockMem
        mov     keyb_enabled,0
        keyb_still_not_enabled:
        ret
disable_keyb    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the routine to be called by a keyboard event
;
; INPUT -> AL = keyboard scancode
;          DS:EBX -> routine to be called when the scancode is received
;		   The routine returns != 0, if the IRQ must chain with the old ISR,
;		   or 0, otherwise.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the routine to be called by any keyboard event that has no specific handler
; associated to it
;
; INPUT -> DS:EBX -> routine to be called when any scancode is received or NULL if none
; 		   The routine is called with EAX = scancode
;		   The routine returns != 0, if the IRQ must chain with the old ISR,
;		   or 0, otherwise.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
add_default_key proc
		mov		default_key_handler,ebx
		ret
add_default_key	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Removes the routine called by any keyboard event
;
; INPUT -> AL = keyboard scancode
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
remove_key      proc
        movzx   eax,al
        mov     ebx,-1
        xchg    [eax*4+key_array],ebx
        mov     ecx,4096*ROUTINE_PAGES
        call    UnlockMem
        ret
remove_key      endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Removes the routine to be called by any keyboard event
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
remove_default_key 	proc
		mov		default_key_handler,0
		ret
remove_default_key	endp

.data
default_key_handler	dd 0

.data?
keyb_map        	db 128 dup (?)
end

