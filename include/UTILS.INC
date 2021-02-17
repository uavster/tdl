;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; file: utils.inc
;
;  Some utility routines.
;
;       by C‚sar Guirao Robles, a.k.a. Nitro! / #Trouble# Team
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
INCLUDE         dpmi.inc
INCLUDE         alloc.inc
INCLUDE         init.def

extrn HandleError: near
extrn HESMLAB001: near
extrn EndOfProgram: near

if STANDARD_INIT
		INCLUDE irq.inc
        INCLUDE newsgl.inc
        INCLUDE alpha.inc
        INCLUDE player.inc
        INCLUDE timer.inc
        INCLUDE dma.inc
        INCLUDE sync.inc
        INCLUDE keyb.inc
endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Waits for a key
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WaitKey MACRO
        xor     ah,ah
        int     16h
ENDM

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Macro for filling 32 bit registers with floating point numbers
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
movf    MACRO register,float
LOCAL   temp_float,skip_float
        mov     register,temp_float
        jmp     skip_float
temp_float      dd float
        skip_float:
ENDM

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Macro to fill the stack of the coprocessor with an immediate 32-bit float
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
fldf    MACRO float
LOCAL   temp_float,skip_float
        fld     temp_float
        jmp     skip_float
temp_float      dd float
        skip_float:
ENDM

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets an long integer from a hexadecimal string
;
; INPUT  -> DS:EAX -> ASCIIZ hexadecimal string
;
; OUTPUT -> CF = 0 if success
;               EAX = integer
;           CF = 1 if error
;               AL = error code
;                       01h -> invalid character in string
;                       02h -> invalid string length
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        extrn   GetHexInteger: NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Looks for the value of an environment variable
;
; INPUT ->  DS:EAX -> ASCIIZ variable name
;
; OUTPUT -> CF = 0 if variable found
;               DS:EAX -> ASCIIZ variable contents
;           CF = 1 if variable not found
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        extrn   GetEnvironmentVar: NEAR

GetEnvVar       MACRO   env_var
LOCAL           var_entorno,skip_getenvvar
        mov     eax,offset var_entorno
        call    GetEnvironmentVar
        jmp     skip_getenvvar
var_entorno     db env_var,0
skip_getenvvar:
ENDM

GetCommandLineLength	MACRO
		mov		eax,ProgramPSP
		movzx	eax,byte ptr [eax+80h]
ENDM

GetCommandLineOffset	MACRO
		mov		eax,ProgramPSP
		lea		eax,[eax+81h]
ENDM

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
        extrn   SkipCharacters: NEAR

SkipChar        MACRO   character,string_ptr
        mov     al,character
        mov     ebx,string_ptr
        call    SkipCharacters
ENDM

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Rutina para obtener cada uno de los parametros de la linea de
;       comandos.
;       ( B52: Ahora se puede usar para leer par metros de una cadena
;         gen‚rica, p.ej., los de una variable de entorno )
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI   puntero a la linea de commandos del psp
;                       EDI   puntero donde guardar el parametro
;       Salida:         [EDI] parametro acabado en 0
;                       ECX   tama¤o en bytes del parametro
;                             Si es cero no hay mas parametros
;                       ESI   puntero para volver a llamar a la funcion
;                             para obtener el siguiente parametro

        extrn           GetCommandParam:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Rutina para imprimir cadenas con subcadenas o numeros...
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI   puntero a la cadena a imprimir
;          '%us',dword puntero
;          Imprime una cadena, la u hace que el texto sea mostrado en
;          mayusculas.
;          '%(d,w,b)[+,-][0][numero][h,o,i,c]n',dword puntero
;          Imprime el numero apuntado por el puntero. Seguido se debe
;          poner uno de los identificadores de tama¤o. El mas y el menos
;          indica que el numero es un numero con signo. El mas hace que
;          aunque el numero sea positivo se ponga el signo en pantalla.
;          El cero indica que los espacios de relleno que se indican a
;          continuacion se han de rellenar con ceros en vez de con espacios
;          Las letras h o i indican la base, si no se pone nada es en
;          base decimal. La h es hexadecimal, la o octal, la i binario y
;		   la c decimal.
;       Salida:         Nada.

        extrn           PrintFormatted:near     ; B52 (C compatibility)
        extrn			FormatString:near
		
        printf          EQU printformatted      ; B52 (C compatibility)

Print   macro   etiqueta
        push    esi
        mov     esi,offset etiqueta
        call    printf
        pop     esi
        endm

LPrintS macro   cadena
LOCAL   string, skip_cadena
		pushf
		pushad
        mov     esi,offset string
        call    printf
        jmp     skip_cadena
string  db cadena,13,10,0
        skip_cadena:
        popad
        popf
        endm

PrintS  macro   cadena
LOCAL   string, skip_cadena
        mov     esi,offset string
        call    printf
        jmp     skip_cadena
string  db cadena,0
        skip_cadena:
        endm

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Rutina para imprimir un caracter
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        AL
;       Salida:         Nada.

        extrn           PrintChar:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Rutina para convertir un numero a string en una base determinada
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        EAX     Numero a convertir
;                       ESI     String donde copiar el numero convertido
;                       EBX     Base en la que convertir el numero
;       Salida:         Nada.

        extrn           TransToBase:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Transforma una cadena numerica a un integer
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI     String donde buscar el numero
;       Salida:         ECX     Numero obtenido
;                               Carry activado si no hay numero
;                               Si no Carry desactivado
        extrn           GetInteger:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Inserta en la posicion indicada el caracter dado
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI     String donde insertar el caracter
;                       DL      Caracter a insertar
;       Salida:         Nada.
;

        extrn           PushToString:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Copia una cadena sobre otra
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI     String fuente
;                       EDI     String destino
;       Salida:         Nada.
;

        extrn           CopyString:near

CopyS   macro   destino,fuente
        mov     edi,offset destino
        mov     esi,offset fuente
        call    CopyString
        endm

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Busca el tama¤o de una cadena
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI     String
;       Salida:         ECX     Tama¤o
;

        extrn           StringLength:near
strlen  macro   string
        mov     esi,offset string
        call    StringLength
        endm

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Copia el nombre de un archivo sobre otro pero sin la unidad ni
;       la ruta.
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI     Nombre de fichero fuente
;                       EDI     Nombre de fichero destino
;       Salida:         Nada.
;

        extrn           CopyFilename:near
CopyFN  macro   destino,fuente
        mov     edi,offset destino
        mov     esi,offset fuente
        call    CopyFilename
        endm

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Busca la extension del archivo
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI     Nombre de fichero fuente
;       Salida:         AL      0  Si el archivo no tiene extension
;                               -1 Si el archivo si tiene extension
;                       ESI     Si el archivo tiene extension apunta
;                               a la extension, sino apunta al final
;                               del nombre del fichero.
;

        extrn           SearchExtension:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Lee una linea de texto del archivo
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        BX      Handle del archivo
;                       EDI     Buffer donde escribir
;                       ECX     Tama¤o maximo del buffer
;       Salida:         Carry=1 Error en la lectura
;                       ECX =-1 La linea era mayor de lo permitido
;                       ECX =-2 Se ha llegado al final del archivo

        extrn           ReadLine:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Pasa a mayusculas
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        AL      Car cter a convertir
;       Salida:         Nada.

        extrn           UpperCase:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Compara dos cadenas
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI     Cadena 1
;                       EDI     Cadena 2
;       Salida:         carry = 0  Si son iguales
;                       carry = 1  Si son diferentes
;

        extrn           CompareString:near

        global          ReturnCode : BYTE

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Inicializa las variables generales
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
InitDPMI        macro
        local   asmmain,fname,salta_name
        jmp     short asmmain
        db      "WATCOM"        ; Esta linea es necesaria para poder ejecutar
                                ; el programa con el DOS4GW y con el debugger

        asmmain:
        cld
        sti
        call    InitDPMIVariables
        call    init_c_heap
if STANDARD_INIT
		call	IRQInit
		ErrorExit "Error: Unable to initialize IRQ library"
        call    InitSGL
        ErrorExit "Error: Unable to initialize graphic system"
        call    InitAlphaFX
        ErrorExit "Error: Not enough memory for alpha tables"
        call    InitDMA
        ErrorExit "Error: Unable to initialize DMA extensions"
        call    enable_keyb
        xor     al,al
        call    InitVirtualFrameRate
        ErrorExit "Error: Unable to start virtual frame-rate"
endif
        fninit
endm

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ErrorExit       MACRO ErrorMsg
Local           ErrorTxt,no_error,ErrorCode,ErrorCodeOffset
		mov		ErrorCode,eax
        mov     dword ptr [HESMLAB001-4], offset ErrorTxt
        jc      HandleError
        jmp     no_error
ErrorTxt        db ErrorMsg, " (error code: 0x%dhn"
ErrorCodeOffset	dd offset ErrorCode
				db ")"
				db 0
ErrorCode		dd ?
        no_error:
ENDM

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ExitAfterCall    MACRO FinalCall
        call    EndVirtualFrameRate
        ErrorExit "Error: Unable to uninitialize virtual frame-rate"
        call    disable_keyb
        call    CloseDMA
        ErrorExit "Error: Unable to uninitialize DMA extensions"
        call    UnInitSGL
        ErrorExit "Error: Unable to uninitialize graphic system"
		call	IRQUninit
		ErrorExit "Error: Unable to uninitialize IRQ library"
        call	FinalCall
        jmp     EndOfProgram
ENDM

Exit	MACRO
Local	empty_call
		ExitAfterCall empty_call		
empty_call:
		ret
ENDM		

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

