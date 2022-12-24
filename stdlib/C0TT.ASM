;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; file: c0tt.asm
;
;  A little startup code to use Watcom C with #Trouble# Team's DarkX.
;
;       by Xavier Rubio Jansana, a.k.a. Teknik / #Trouble# Team, July 1998
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

        .386p
        .model flat

        .stack  10000h

MAX_DOS_COMMAND_LINE_LENGTH		EQU 127		; Including final carry return.

		.data
		is_verbose	db 0

		.data?		
		cmd_line	db MAX_DOS_COMMAND_LINE_LENGTH dup(?)
		argc		dd ?
		argv		db 4 * ((MAX_DOS_COMMAND_LINE_LENGTH - 1) / 2) dup(?)	; strlen(command_line) + sizeof(char *) * max_dos_commands (one-char commands with one space in between, and final carry return)

        .code

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

        include alloc.inc
        include utils.inc
		include memcpy.inc
		include dpmi.inc
        INCLUDE newsgl.inc

        extrn   main_: near
        public  _cstart_
        public  _exit_          ; B52

GetCommandLine	proc
		; Create argv as array of pointers to null-terminated copies of the parameters.
		GetCommandLineOffset
		mov		esi,eax
		mov		edi,offset cmd_line
		xor		edx,edx
		extract_args:
		mov		[offset argv+edx*4],edi
		push	edx
		call	GetCommandParam
		pop		edx
		; Skip the parameter if it is -verbose.
		cmp		ecx,8
		jnz		not_verbose_flag
		cmp		dword ptr [edi],'rev-'
		jnz		not_verbose_flag
		cmp		dword ptr [edi+4],'esob'
		jnz		not_verbose_flag
		cmp		byte ptr [edi+8],0
		jnz		not_verbose_flag
				dec		edx
				mov		is_verbose,1
		not_verbose_flag:
		inc		edx
		lea		edi,[edi+ecx+1]
		test	ecx,ecx
		jnz		extract_args
		dec		edx
		mov		argc,edx
		ret
endp
	
    ; NOTA: sembla que l'WLINK vol el _cstart_, encara que no ha de ser
    ;       per for놹 el nom del punt d'entrada.

_cstart_:
        jmp     short skip_watcom_signature
        db      "WATCOM"        ; Esta linea es necesaria para poder ejecutar
                                ; el programa con el DOS4GW y con el debugger

        skip_watcom_signature:

		call 	InitDPMIVariables
		; Pass argc and argv to main in EAX and EDX, respectively.
		call	GetCommandLine

		cmp		is_verbose,0
		jnz		run_init_dpmi
				mov		eax,SSO_QuietInit OR SSO_QuietFinish
				call	SetSGLOptions
		run_init_dpmi:
        InitDPMI
		
		mov		eax,argc
		mov		edx,offset argv
        call    main_

_cfinish_:
		cmp		is_verbose,0
		jnz		exit_verbosely
        ExitSilently
		exit_verbosely:
		Exit

_exit_  proc
        mov     ReturnCode,al
        pop     eax             ; B52 - pop return EIP
        jmp     _cfinish_
        endp

        end     _cstart_

