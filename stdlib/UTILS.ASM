;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; file: utils.asm
;
;  Some utility routines.
;
;       by C‚sar Guirao Robles, a.k.a. Nitro! / theDarkRising
;       ( GetEnvironmentVar, SkipCharacters & GetHexInteger by
;         Ignacio Mellado Bataller, a.k.a. B52 / theDarkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

        JUMPS
        .386p
        .model flat
        .code

        INCLUDE dpmi.inc
		INCLUDE assert.inc
		
		DOUBLE_STRING_NUM_DECIMAL_DIGITS	EQU 6

        public  GetCommandParam,PrintFormatted,FormatString,PrintChar,CopyString,StringLength
        public  GetInteger,TransToBase,PushToString,CopyFilename
        public  SearchExtension,ReadLine,UpperCase,CompareString
        public  GetEnvironmentVar, SkipCharacters, GetHexInteger
		public	ReturnCode

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets a long integer from a hexadecimal string
;
; INPUT  -> DS:ESI -> ASCIIZ hexadecimal string
;
; OUTPUT -> CF = 0 if success
;               EAX = integer
;           CF = 1 if error
;               AL = error code
;                       01h -> invalid character in string
;                       02h -> invalid string length
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetHexInteger   proc
        call    StringLength
        mov     al,2            ; error code 2
        cmp     ecx,8
        ja      not_converted
        or      ecx,ecx
        jz      errorcode1
        mov     edx,ecx
        dec     ecx
        xor     ebx,ebx
        shl     ecx,2
        convert_to_binary:
                xor     eax,eax
                lodsb
                or      al,al
                jz      converted
                sub     al,'0'
                jb      errorcode1
                cmp     al,9
                jbe     accumulate_value
                sub     al,'A'-'0'-0ah
                jb      errorcode1
                cmp     al,0fh
                jbe     accumulate_value
                sub     al,'a'-'A'
                jb      errorcode1
                cmp     al,0fh
                ja      errorcode1
                accumulate_value:
                shl     eax,cl
                or      ebx,eax
                sub     cl,4
        dec     edx
        jnz     convert_to_binary
        converted:
        mov     eax,ebx
        clc
        ret

        errorcode1:
        mov     al,1
        not_converted:
        stc
        ret
GetHexInteger   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Skips a string of the given character
;
; INPUT  -> AL = character
;           DS:EBX -> string to skip
;
; OUTPUT -> ZF = 0 if no zero found
;               DS:EAX -> next byte after character string
;           ZF = 1 if zero found
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SkipCharacters  proc
                cmp     byte ptr [ebx],0
                jz      no_space
                cmp     [ebx],al
                jnz     no_space
                inc     ebx
        jmp     SkipCharacters
        no_space:
        ret
SkipCharacters  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Looks for the value of an environment variable
;
; INPUT ->  DS:EAX -> ASCIIZ variable name
;
; OUTPUT -> CF = 0 if variable found
;               DS:EAX -> ASCIIZ variable contents
;           CF = 1 if variable not found
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetEnvironmentVar       proc
        cld
        mov     edi,eax
        mov     ecx,eax
        mov     esi,ENVPtr      ; DS:ESI -> environment
        search_string:
                lodsb
                cmp     al,[edi]
                jnz     search_next
                inc     edi
        cmp     byte ptr [edi],0
        jnz     search_string
        cmp     byte ptr [esi],'='
        jnz     string_not_found
        mov     eax,esi
        inc     eax
        clc
        ret

        search_next:
                cmp     byte ptr [esi-1],0
                jz      found_end
                inc     esi
        jmp     search_next
        found_end:
        mov     edi,ecx                 ; DS:EDI -> variable name, again
        cmp     byte ptr [esi],0        ; if double zero, environment end
        jnz     search_string
        string_not_found:
        stc
        ret
GetEnvironmentVar       endp

CompareString   proc
        push    edx ecx

        call    StringLength
        push    esi ecx
        mov     esi,edi
        call    StringLength
        mov     edx,ecx
        pop     ecx esi
        cmp     edx,ecx
        jnz     CPT003

CPT001: lodsb
        or      al,al
        jz      CPT002
        cmp     al,[edi]
        jne     CPT003
        inc     edi
        jmp     CPT001
CPT002:
        clc
        pop     ecx edx
        ret
CPT003:
        stc
        pop     ecx edx
        ret
        endp

ReadLine        proc
        push    eax edx
        push    ecx
        mov     ah,3fh
        mov     ecx,1
        mov     edx,offset RDLbuff
        int     21h
        pop     ecx
        jc      RDLlab2
        or      eax,eax
        jz      RDLlab5
        cmp     RDLbuff,26
        jz      RDLlab5
        cmp     RDLbuff,10
        je      rdllab1
        cmp     RDLbuff,13
        je      rdllab3
        mov     al,rdlbuff
        stosb
        dec     ecx
        jz      RDLlab4
RDLlab1:
        push    ecx
        mov     ah,3fh
        mov     ecx,1
        mov     edx,offset RDLbuff
        int     21h
        pop     ecx
        jc      rdllab2
        or      eax,eax
        je      rdllab3
        cmp     RDLbuff,13
        je      rdllab3
        cmp     RDLbuff,10
        je      rdllab3
        cmp     RDLbuff,26
        je      rdllab3
        mov     al,rdlbuff
        stosb
        dec     ecx
        jz      RDLlab4
        jmp     rdllab1
rdllab3:
        xor     al,al
        stosb
RDLlab2:
        pop     edx eax
        ret
RDLlab4:
        mov     ecx,-1
        pop     edx eax
        ret
RDLlab5:
        xor     al, al
        stosb
        mov     ecx,-2
        pop     edx eax
        ret
RDLbuff db      ?
        endp

SearchExtension proc
        push    edx ebx
        xor     al,al
        mov     edx,esi
SEElab1:
        lodsb
        or      al,al
        jne     seelab1
        dec     esi
        mov     ebx,esi
SEElab2:
        dec     esi
        mov     al,[esi]
        cmp     al,'.'
        je      SEElab3
        cmp     al,'\'
        je      SEElab5
        cmp     al,':'
        je      SEElab5
        cmp     esi,edx
        jne     SEElab2
SEElab5:
        xor     al,al
        mov     esi,ebx
        jmp     SEElab4
SEElab3:
        mov     al,-1
SEElab4:
        pop     ebx edx
        ret
        endp

CopyString      proc
        push    eax esi edi
COSLab1:
        lodsb
        stosb
        or      al,al
        jne     COSLab1
        pop     edi esi eax
        ret
        endp

CopyFilename    proc
        push    eax ecx esi edi
        call    StringLength
        xchg    esi,ecx
        add     esi,ecx
COFlab1:
        dec     esi
        mov     al,[esi]
        cmp     al,':'
        je      COFlab2
        cmp     al,'\'
        je      COFlab2
        cmp     ecx,esi
        jne     COFlab1
        jmp     COFlab3
COFlab2:
        inc     esi
COFLab3:
        lodsb
        stosb
        or      al,al
        jne     COFlab3
        pop     edi esi ecx eax
        ret
        endp

GetCommandParam proc
        push    edi
        xor     ecx,ecx
GCPlab3:
        lodsb
		or		al,al
		je		GCPlab2
        cmp     al,20h
        je      GCPlab3
        cmp     al,','
        je      GCPlab3
        cmp     al,';'
        je      GCPlab3
        dec     esi

GCPlab1:
        lodsb
        cmp     al,13
        je      GCPlab2
        or      al,al
        je      GCPlab2
        cmp     al,20h
        je      GCPlab2
        cmp     al,','
        je      GCPlab2
        cmp     al,';'
        je      GCPlab2
        stosb
        inc     ecx
        jmp     GCPlab1
GCPlab2:
        dec     esi
        mov     al,0
        stosb
        pop     edi
        ret
        endp

UpperCase       proc
        cmp     al,'¤'
        je      UPClab2
        cmp     al,'‡'
        je      UPClab3
        cmp     al,'a'
        jb      UPClab1
        cmp     al,'z'
        ja      UPClab1
        sub     al,'a'-'A'
UPClab1:
        ret
UPClab2:
        mov     al,'¥'
        ret
UPClab3:
        mov     al,'€'
        ret
        endp

FormatString	proc
		mov		WriteCharToString_offset,edi
		mov		CharCallback,offset WriteCharToString
		call 	PrintFormatted_
		mov		edi,WriteCharToString_offset
		mov		byte ptr [edi],0
		ret
		endp
		
PrintFormatted	proc
		mov		CharCallback,offset PrintChar
		call	PrintFormatted_
		ret
		endp
		
PrintFormatted_ proc
        push    eax ebx ecx edx esi
        fnstcw  word ptr entero                 ; B52 - Setting rounding methode for float conversion
        mov     ax,word ptr entero
        mov     old_control_word,ax
        or      word ptr entero,110000000000b   ; B52 - chop (truncate)
        fldcw   word ptr entero                 ; B52
PRFlab1:
        lodsb
        cmp     al,0
        je      PRFlab2
        cmp     al,'%'
        je      PRFlab3

PRFlab16:

        call    [CharCallback]
        jmp     PRFlab1
PRFlab2:
        pop     esi edx ecx ebx eax
        fldcw   old_control_word                ; B52 - Restore rounding control
        ret
PRFlab3:
        lodsb

        call    UpperCase

        cmp     al,0
        je      PRFlab2

        cmp     al,'S'
        je      PRFlab4

        cmp     al,'U'
        je      PRFlab6

        cmp     al,'D'
        je      PRFlab13

        cmp     al,'W'
        je      PRFlab14

        cmp     al,'B'
        je      PRFlab15                

        cmp     al,'%'
        je      PRFlab16


        jmp     prflab1

PRFlab4:        ; Imprimir una cadena
        lodsd
        mov     ebx,eax
PRFlab5:
        mov     al,[ebx]
        inc     ebx
        cmp     al,0
        je      PRFlab1
        push    ebx
        call    [CharCallback]
        pop     ebx
        jmp     PRFlab5
PRFlab6:        ; Imprimir una cadena en Uppercase
        lodsb
        lodsd
        mov     ebx,eax
PRFlab7:
        mov     al,[ebx]
        inc     ebx
        cmp     al,0
        je      PRFlab1
        push    ebx
        call    UpperCase
        call    [CharCallback]
        pop     ebx
        jmp     PRFlab7

PRFlab13:
        xor     edx,edx
        or      edx,1b          ; Imprimir un Dword
        jmp     PRFlab30
PRFlab14:
        xor     edx,edx
        or      edx,10b         ; Imprimir un word
        jmp     PRFlab30
PRFlab15:
        xor     edx,edx         ; Imprimir un byte
        or      edx,100b
PRFlab30:
        lodsb
        cmp     al,'+'          ; Salta a tomar valor con signo y mostrar
        je      PRFlab17        ; siempre el signo
        cmp     al,'-'          ; Salta a tomar valor con signo
        je      PRFlab18
        dec     esi
        jmp     PRFlab19
PRFlab17:
        or      edx,1000b       ; Mostrar siempre signo y valor con signo
        jmp     PRFlab19
PRFlab18:
        or      edx,10000b      ; Valor con signo
PRFlab19:
        lodsb
        cmp     al,'0'          ; Salta a rellenar con ceros
        je      PRFlab20
        dec     esi
        jmp     PRFlab21
PRFlab20:
        or      edx,100000b     ; Rellenar con ceros
PRFlab21:
        call    GetInteger      ; Comprueba si existe un numero en la posicion
        lodsb                   ; indicada, y lo devuelve en ecx
        call    UpperCase
        cmp     al,'H'          ; Salta a imprimir en hexadecimal
        je      PRFlab22
        cmp     al,'O'          ; Salta a imprimir en octal
        je      PRFlab23
        cmp     al,'I'          ; Salta a imprimir en binario
        je      PRFlab24
        cmp     al,'F'          ; B52 - Salta a imprimir en float
        je      PRFlab52        ; B52
        cmp		al,'C'
        je		PRFlab25
        dec     esi
        jmp     PRFlab25
PRFlab22:
        or      edx,1000000b    ; Imprimir en hexadecimal
        jmp     PRFlab25
PRFlab23:
        or      edx,10000000b   ; Imprimir en octal
        jmp     PRFlab25
PRFlab24:
        or      edx,100000000b  ; Imprimir en binario
        jmp     PRFlab25        ; B52
PRFlab52:
        or      edx,1000000000b ; B52 - Imprimir en float
PRFlab25:
        lodsb
        call    UpperCase
        cmp     al,'N'          ; Comprueba k se kiere imprimir un numero
        jne     PRFlab1         ; Si no aborta la impresion
        lodsd                   ; Carga la direccion del numero
        mov     ebx,eax

        test    edx,1000000000b ; B52 - Salta si hay que imprimir en float
        jnz     PRFlab521       ; B52

        test    edx,11000b      ; Saltar si no hay k tomar el valor con signo
        jz      PRFlab26

        test    edx,1
        jz      PRFlab27
        mov     eax,[ebx]
        jmp     PRFlab29
PRFlab27:
        test    edx,10b
        jz      PRFlab28
        movsx   eax,word ptr [ebx]
        jmp     PRFlab29
PRFlab28:
        test    edx,100b
        jz      PRFlab29
        movsx   eax,byte ptr [ebx]
PRFlab29:
        cmp     eax,0
        jz      PRFlab34        ; saltar si es cero
        jl      PRFlab31        ; Imprimir el signo negativo
        test    edx,1000b       ; Comprobar si hay k poner el signo
                                ; con numeros positivos
        jz      PRFlab33
        push    eax
        mov     al,'+'
        call    [CharCallback]
        pop     eax
        jmp     PRFlab33
PRFlab31:
        push    eax
        mov     al,'-'
        call    [CharCallback]
        pop     eax
        neg     eax
        jmp     PRFlab33
PRFlab33:
        jmp     PRFlab34

PRFlab26:
        test    edx,1
        jz      PRFlab35
        mov     eax,[ebx]
        jmp     PRFlab37
PRFlab35:
        test    edx,10b
        jz      PRFlab36
        movzx   eax,word ptr [ebx]
        jmp     PRFlab37
PRFlab36:
        test    edx,100b
        jz      PRFlab37
        movzx   eax,byte ptr [ebx]
PRFlab37:
PRFlab34:
        push    esi

        mov     ebx,10
        test    edx,1000000b
        jz      prflab38
        mov     ebx,16
prflab38:
        test    edx,10000000b
        jz      prflab39
        mov     ebx,8
prflab39:
        test    edx,100000000b
        jz      prflab40
        mov     ebx,2
prflab40:
        or      eax,eax
        jnz     prflab44
        or      edx,10000000000b
prflab44:
        mov     esi,offset prfbuff
        call    TransToBase

        or      ecx,ecx
        jz      prflab41

        mov     eax,ecx
        mov     esi,offset prfbuff
        call    StringLength

        cmp     eax,ecx
        jle     prflab11
        neg     ecx
        add     ecx,eax

        test    edx,100000b
        jnz     prflab43
        test    edx,10000000000b
        jz      prflab43
        dec     ecx
prflab43:

        mov     al,' '
        test    edx,100000b
        jz      prflab42
        mov     al,'0'
prflab42:
        call    [CharCallback]
        loop    prflab42

        test    edx,100000b
        jnz     prflab46
        test    edx,10000000000b
        jz      prflab46
        mov     al,'0'
        call    [CharCallback]
prflab46:


PRFlab11:

        mov     esi,offset prfbuff

PRFlab45:
        lodsb
        cmp     al,0
        je      PRFlab12
        call    [CharCallback]
        jmp     PRFlab45

PRFlab12:
        pop     esi
        jmp     PRFlab1

prflab41:       ; Si no hay justificacion
        mov     esi,offset prfbuff
        call    StringLength
        or      ecx,ecx
        jnz     prflab11
        mov     al,'0'
        call    [CharCallback]
        pop     esi
        jmp     prflab1

; -B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-
PRFlab521:
        push    eax ebx ecx edx esi
		fld		qword ptr [ebx]
		fxam
		fstp	st(0)
		fstsw	ax
		fwait
		sahf
		jz		c3_is_1
		jpe		c2_is_1
		jc		is_nan
		jmp		finite_number
		is_nan:
				mov		esi,offset msg_nan
				jmp		print_type_name
		c2_is_1:
				jnc		finite_number
				mov		esi,offset msg_inf
				test 	ah,2
				jz		print_plus
				jmp		print_minus				
		c3_is_1:
				jc		is_empty
				jpe		is_denormal
				jmp		finite_number	; 0 value
		is_empty:
				mov		esi,offset msg_empty
				jmp		print_type_name
		is_denormal:
				mov		esi,offset msg_denorm
				test	ah,2
				jz		print_plus
		print_minus:
				mov		al,'-'
				call	[CharCallback]
				jmp		print_type_name
		print_plus:
				mov		al,'+'
				call	[CharCallback]
		print_type_name:
				mov		al,[esi]
				test	al,al
				jz		float_done
				call	[CharCallback]
				inc		esi
				jmp		print_type_name
		finite_number:
        ; Convert double to int format as integer.decimals
		mov		eax,factor_decimal
		test	eax,eax
		jnz		factor_is_precalculated
				push	ebx
				mov		ebx,10
				xor		edx,edx
				xor		eax,eax
				inc		eax
				mov		ecx,DOUBLE_STRING_NUM_DECIMAL_DIGITS
				AssertD	ecx,_gtu,0
				factor_precalc_loop:
						mul		ebx
				loop	factor_precalc_loop
				mov		factor_decimal,eax
				pop		ebx
		factor_is_precalculated:
        fld     qword ptr [ebx]
        fist    entero
        fisub   entero
        fimul   factor_decimal
        fistp   mantisa
        mov     eax,entero
        mov     ebx,10
        mov     esi,offset PRFbuff
        call    TransToBase
        mov     esi,offset PRFbuff
        call    StringLength
        mov     esi,offset PRFbuff
        print_entero:
                lodsb
                push    esi
                call    [CharCallback]
                pop     esi
        loop    print_entero
        mov     al,'.'
        call    [CharCallback]
        mov     eax,mantisa
        mov     ebx,10
        mov     esi,offset PRFbuff
        call    TransToBase
        mov     esi,offset PRFbuff
        call    StringLength
        mov     esi,offset PRFbuff
		cmp		ecx,6
		jae		print_mantisa
		push	ecx
		sub		ecx,6
		neg		ecx
		mov		al,'0'		
		print_zeros:
			push	esi
			call	[CharCallback]
			pop		esi
		loop	print_zeros
		pop		ecx
        print_mantisa:
                lodsb
                push    esi
                call    [CharCallback]
                pop     esi
        loop    print_mantisa
		float_done:
        pop     esi edx ecx ebx eax
        jmp     PRFlab1

entero                  dd ?
mantisa                 dd ?
factor_decimal          dd 0
old_control_word        dw ?
CharCallback			dd ?
msg_nan					db "NaN",0
msg_inf					db "inf",0
msg_empty				db "empty",0
msg_denorm				db "denormalized",0
; -B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-B52-
PRFbuff db      33      dup (0)         ; buffer para la impresion interna
                                        ; de los numeros
        endp

StringLength    proc
        push    eax esi
        xor     ecx,ecx
        dec     ecx
STLlab1:
        inc     ecx
        lodsb
        or      al,al
        jnz     stllab1
        pop     esi eax
        ret
        endp

GetInteger      proc
        push    eax ebx
        xor     eax,eax
        xor     ecx,ecx

        mov     al,[esi]
        cmp     al,'0'
        jb      ISNlab3
        cmp     al,'9'
        ja      ISNlab3

ISNlab1:
        lodsb
        cmp     al,'0'
        jb      ISNlab2
        cmp     al,'9'
        ja      ISNlab2
        mov     ebx,ecx
        fastimul ecx,ebx,10
        sub     al,'0'
        add     ecx,eax
        jmp     isnlab1
ISNlab2:
        dec     esi
        pop     ebx eax
        clc
        ret
ISNlab3:
        stc
        pop     ebx eax
        ret
        endp

TransToBase     proc
        push    eax ecx edx
        mov     dl,0
        call    PushToString
        or      eax,eax                 ; B52
        jnz     TTDlab1                 ; B52
        mov     dl,'0'                  ; B52
        call    PushToString            ; B52
        jmp     TTDlab2                 ; B52
TTDlab1:
        xor     edx,edx
        or      eax,eax
        jz      TTDlab2
        div     ebx
        cmp     dl,10
        jae     TTDlab3
        add     dl,'0'
        jmp     TTDlab4
TTDlab3:
        add     dl,'A'-10
TTDlab4:
        call    PushToString
        jmp     TTDlab1
TTDlab2:
        pop     edx ecx eax
        ret
        endp

PushToString    proc
        push    edx esi
PTSlab1:
        cmp     dl,0
        jz      PTSlab2
        xchg    [esi],dl
        inc     esi
        jmp     PTSlab1
PTSlab2:
        xchg    [esi],dl
        pop     esi edx
        ret
        endp

PrintChar       proc
        push    ebx edx ecx eax
        mov     PRCbuff,al
        mov     bx,1
        mov     ah,40h
        mov     edx,offset PRCbuff
        mov     ecx,1
        int     21h
        pop     eax ecx edx ebx
        ret
PRCbuff db      ?
        endp

WriteCharToString	proc
		push	edi
		mov		edi,WriteCharToString_offset
		mov		[edi],al
		inc		edi
		mov		WriteCharToString_offset,edi
		pop		edi
		ret
WriteCharToString_offset	dd ?
		endp

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Acaba el programa
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

public HandleError, HESMLAB001, EndOfProgram

HandleError:
        mov     ax,3
        int     10h
        mov     esi, 12345678h
HESMLAB001:
        call    PrintFormatted
EndOfProgram:
        mov     ah,4ch
        mov     al,ReturnCode
        int     21h

.data
ReturnCode      db 0
        
end

