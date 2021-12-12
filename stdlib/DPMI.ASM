;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; file: dpmi.asm
;
;  DPMI interface routines.
;
;       by C‚sar Guirao Robles, a.k.a. Nitro! / #Trouble# Team
;       (RealCall,LockMem,UnlockMem by Ignacio Mellado Bataller,
;        a.k.a. B52 / #TROUBLE# Team) ;)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

        JUMPS

        .386p
        .model flat

        .code

        include alloc.inc
        include dpmi.inc
		include stderror.inc
		
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Locks a memory region
;
; INPUT -> DS:EBX -> memory region to lock
;          ECX = size of region to lock
; OUTPUT -> CF = 0, if success
;			CF = 1, if error
;				EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
LockMem proc
        push    ecx
        mov     ecx,ebx
        shr     ebx,16
        pop     edi
        mov     esi,edi
        shr     esi,16
        mov     ax,600h
        int     31h
		jc		lock_mem_error
		ret
		
		lock_mem_error:
		and		eax,0ffffh
		or		eax,DPMI_ERROR
		stc
        ret
LockMem endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Unlocks a memory region
;
; INPUT -> DS:EBX -> memory region to unlock
;          ECX = size of region to unlock
; OUTPUT -> CF = 0, if success
;			CF = 1, if error
;				EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
UnlockMem       proc
        push    ecx
        mov     ecx,ebx
        shr     ebx,16
        pop     edi
        mov     esi,edi
        shr     esi,16
        mov     ax,601h
        int     31h
		and		eax,0ffffh
		jc		unlock_mem_error
		clc
		ret
		
		unlock_mem_error:
		and		eax,0ffffh
		or		eax,DPMI_ERROR
		stc
        ret
UnlockMem       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes common variables
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
InitDPMIVariables       proc
        ; cs     -> code segment base 0
        ; ds     -> data segment base 0
        ; es     -> psp
        ; ss     -> stack segment base 0
        ; fs, gs -> 0
		cmp		cs:ProgramPSP,0
		jz		run_init_dpmi		
		ret

		run_init_dpmi:
        mov     ax, ds          ; Ajusta selectors
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     DataSelector,ax

        mov     ah,62h
        int     21h

;        mov     bx, es          ; Obt‚ l'adre‡a del PSP (selector -> near ptr)
        mov     ax, 6h
        int     31h
        shl     ecx, 16
        mov     cx, dx
        mov     ProgramPsp, ecx

        mov     bx,[ecx+2Ch]    ; B52 -> Obtiene la direcci¢n del entorno
        mov     ax,6h           ; B52
        int     31h             ; B52
        shl     ecx,16          ; B52
        mov     cx,dx           ; B52
        mov     ENVPtr,ecx      ; B52

        mov     EXEName,0

        ; B52 -> we need to lock the memory where global variables are
        ; (maybe some irq handler will touch them)
        mov     ebx,offset global_vars
        mov     ecx,offset global_vars_end-offset global_vars
        call    LockMem
        ret

global_vars:
        ProgramPsp      dd      0
        EXEName         dd      ?
        ENVPtr          dd      ?
        DataSelector    dw      ?       ; needed for irq handlers (B52)
global_vars_end:

endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      RealCall:       Llama a un procedimiento en modo real
;³                      pas ndole segmentos de modo real
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        En la pila el puntero FAR al proc. real (DWORD)
;³                      en RealDSSeg, RealESSeg
;³                         RealGSSeg, RealFSSeg los segmentos reales
;³                      y en RealStackCopy el numero de palabras a copiar
;³                      de la pila real
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         Lo esperado de la interrupcion, o no
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

RealCall        proc
        push    dword ptr 0
        push    dword ptr ss:[esp+4*2]
        push    word ptr RealGSSegment
        push    word ptr RealFSSegment
        push    word ptr RealDSSegment
        push    word ptr RealESSegment
        push    word ptr 0
        pushad
;        mov     ecx,[RealStackCopy]
;        mov     esi,esp
;        add     esi,8*4+5*2+2*4+4+4
;        mov     edi,esp
;        or      ecx,ecx
;        jz      no_stack_copy
;        sub     edi,ecx
;        sub     edi,ecx
;        push    edi
;        cld
;        rep     movsw
;        pop     esi
;        mov     edi,esp
;        no_stack_copy:
;        mov     esp,esi
;        mov     ecx,RealStackCopy
;        push    ecx
        mov     edi,esp
        mov     ecx,[RealStackCopy]
        push    word ptr stack_param
        mov     ax,0301h
        xor     ebx,ebx
        int     31h
        pop     word ptr stack_param
;        pop     ecx
;        lea     esp,[esp+ecx*2]
        popad
        lea     esp,[esp+2]
        pop     word ptr RealESSegment
        pop     word ptr RealDSSegment
        pop     word ptr RealFSSegment
        pop     word ptr RealGSSegment
        lea     esp,[esp+8]
        ret     4
trash           dd ?
stack_param     dw ?
        endp
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      RealInterrupt:  Llama a una interrupcion del modo real
;³                      pasandole segmentos del modo real
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        En la pila el numero de la interrupcion (dword)
;³                      en RealDSSeg, RealESSeg
;³                         RealGSSeg, RealFSSeg los segmentos reales
;³                      y en RealStackCopy el numero de palabras a copiar
;³                      de la pila real
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         Lo esperado de la interrupcion, o no
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    RealStackCopy   dd 0
    RealDSSegment   dw 0
    RealESSegment   dw 0
    RealGSSegment   dw 0
    RealFSSegment   dw 0

RealInterrupt   proc
        push    dword ptr 0
        push    dword ptr 0
        push    word ptr RealGSSegment
        push    word ptr RealFSSegment
        push    word ptr RealDSSegment
        push    word ptr RealESSegment
        push    word ptr 0
        pushad
		push	ss
		pop		es
        mov     edi,esp
        mov     ax,0300h
        mov     ecx,[RealStackCopy]
        xor     ebx,ebx
        mov     bl,ss:[esp +36h]
        int     31h
        popad
        lea     esp,[esp+2]
        pop     word ptr RealESSegment
        pop     word ptr RealDSSegment
        pop     word ptr RealFSSegment
        pop     word ptr RealGSSegment
        lea     esp,[esp+8]
        ret     4
        endp
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      MapMemory:      Esta rutina mapea una direccion fisica de memoria
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        ECX: Direccion fisica de memoria
;³                      ESI: Tama¤o de la region a mapear
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         Si Carry hay un error
;³                      sino en ECX la direccion que se puede utilizar
;³                      para acceder a la direccion fisica de memoria.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Preserva:       todo menos ESI, ECX
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MapMemory       proc
        push    eax ebx edi
        mov     ax,800h
        mov     ebx,ecx
        shr     ebx,16
        mov     edi,esi
        shr     esi,16
        int     31h
        jc      exit_map
        shl     ecx, 16
        mov     cx, bx
        ror     ecx, 16
        pop     edi ebx eax
        clc
        ret
exit_map:
        pop     edi ebx eax
        stc
        ret
        endp
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      RealAddress:    Convierte una direccion del modo real a una direccion
;³                      accesible en el modo protegido
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX : Puntero lejano en modo real
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         EAX : Puntero cercano en modo protegido
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Preserva:       Todo menos EAX
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
RealAddress     proc
        push    ebx
        mov     ebx,eax
        and     eax,0FFFFh
        shr     ebx,16                  ; Separado en dos partes para poner
        shl     ebx,4                   ;  a cero los bits bajos...
        add     eax,ebx
        pop     ebx
        ret
        endp
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

        end

