;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  [tDR], 1998                                    Copyright the DarkRising
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      ô ô  ô                          Coded by:              Nitro!
;³ New! ³ ³¿ ³  Version 1.10b           Support & BugFixed by: Teknik, B52
;³      õ ÀÙ À
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  DATE         REVISION           AUTHOR & COMMENTS
;³  ÄÄÄÄÄÄÄÄ     ÄÄÄÄÄÄÄÄÄÄÄÄÄ      ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  08-11-98     Version 1.10b      Nitro! : Code Reorganization
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    .386p
    .model  flat
    jumps
    .code
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Needed includes
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    include     newsgl.inc
    include     dpmi.inc
    include     utils.inc
    include     alloc.inc
    include     memcpy.inc
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Macros
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;Ä Macro para debugging ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
breakp      macro text1, regi
    local   debugtext, debugreg, skipthis
    pushfd
    pushad
    mov     debugreg, regi
    print   debugtext
    xor     ah,ah
    int     16h
    popad
    popfd
    jmp     skipthis
    debugreg    dd ?
    debugtext   db text1
                db '%dn'
                dd offset debugreg
                db 13,10,0
skipthis:
    endm
;Ä Macro para textos de inicio ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
iprint      macro text1
    local   skipthis
    test    SGLOptions, SSO_QuietInit
    jnz     skipthis
    print   text1
skipthis:
    endm

;Ä Macro para textos de salida ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
eprint      macro text1
    local   skipthis
    test    SGLOptions, SSO_QuietFinish
    jnz     skipthis
    print   text1
skipthis:
    endm

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Ä DRIVERS DISPONIBLES ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;    include     newsgl\DRVGA.asm     ; Driver VGA
;    include     newsgl\DRVBE.asm     ; Driver VBE
    include     DRVGA.asm     ; Driver VGA
    include     DRVBE.asm     ; Driver VBE
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ


.data?
    ModeList    TMODE   MAX_MODES dup (?)
    ModeTemp    TMODE   ?
    ModePtr     dd      ?
    TotalModes  dd      ?
    ActualModePtr   dd  ?
    ActualMode  TMODE   ?
    FrameCounter    dd  ?
    SLIScreenPtr    dd  ?

; Funciones generales
    GetAvailPage_   dd  ?
    ShowPage_       dd  ?
    BlankPage_      dd  ?
    UnSetVideoMode_ dd  ?
    WaitRetrace_    dd  ?
    GetMemoryPtr_   dd  ?
.data
    SGLOptions      dd  0
.code
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      InitSGL:        Funcion para inicializar el interfaz de video.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        Nada.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         Si hay carry
;³                           Error al iniciar la libreria
;³                      EAX :   SGL_DRIVER  No hay ningun driver soportado
;³                              SGL_NOMEM   No hay memoria suficiente
;³                              SGL_FILE    Error en lectura de archivos
;³                              SGL_REINIT  SGL ya inicializada
;³                      Si no hay carry
;³                      EAX =   SGL_OK
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.data?
    Almost1driver   db  ?
.data
    InsideSGL       db  0
    InsideMode      db  0
SGL_text1   db '[New!SGL] : New Shade Graphic Library      Version 1.10b      Coded by Nitro! ',13,10
            db 'Copyright the DarkRising [tDR] : 1999      Aditional code by:  B52  &  Teknik ',13,10
            db '< http://fly.to/thedarkrising >            mail: group@thedarkrising.ddns.org ',13,10,13,10,0
SGL_text2   db '   þ Launching drivers...',13,10,0
SGL_text3   db '   þ Library initialized with %dn'
            dd offset TotalModes
            db ' modes.',13,10,0

.code
InitSGL     proc
; Evitamos k se modifike EBP para ser compatible con C
            push    ebp

; Evitamos mulitples inicializaciones
            cmp     InsideSGL, 0
            je      INSGL000
            mov     eax, SGL_REINIT
            jmp     SGL_ErrorExit
    INSGL000:

; Imprimimos esos textos explicativos mu chulis
            iprint   SGL_text1
            iprint   SGL_text2

; Inicializamos las variables necesarias
            mov     Almost1driver, 0
            mov     TotalModes, 0
            mov     ModePtr, offset Modelist

; Inicializamos todos los drivers disponibles

            Call    DRIVER_VGA_Init
            jc      SGL_ErrorExit
            cmp     eax, SGL_OK
            jne     INSGL001
            mov     Almost1driver, 1
    INSGL001:
            Call    DRIVER_VBE_Init
            jc      SGL_ErrorExit
            cmp     eax, SGL_OK
            jne     INSGL002
            mov     Almost1driver, 1
    INSGL002:

;            Call    DRIVER_VBEAF_Init
;            jc      SGL_ErrorExit
;            cmp     eax, SGL_OK
;            jne     INSGL003
;            mov     Almost1driver, 1
    INSGL003:

            cmp     Almost1driver, 1
            je      INSGL004
            mov     eax, SGL_DRIVER
            jmp     SGL_ErrorExit
    INSGL004:

            iprint   SGL_text3
            mov     InsideSGL, -1
            mov     eax, SGL_OK
            clc
            pop     ebp
            ret
SGL_ErrorExit:
            stc
            pop     ebp
            ret
            endp


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      AddMode:        Funcion para a¤adir un modo a la lista general de
;³      (interna)       modos soportados
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        ESI : Puntero a TMODE a incluir
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         Si hay carry
;³                           Error al incluir el modo
;³                      EAX =   SGL_ERROR
;³                      Si no hay carry
;³                      EAX =   SGL_OK
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
AddMode     proc
            cmp     TotalModes, MAX_MODES
            je      ADDMODE_ErrorExit
            mov     edi, ModePtr
            mov     ecx, size TMODE
            rep     movsb
            inc     TotalModes
            add     ModePtr, size TMODE
            mov     eax, SGL_OK
            clc
            ret
ADDMODE_ErrorExit:
            stc
            mov     eax, SGL_ERROR
            ret
            endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³    UnInitSGL:        Funcion para desinicializar el interfaz de video.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        AL = 0 for verbose output, or 1 for silent output.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         Si hay carry
;³                           Error al finalizar la libreria
;³                      EAX :   SGL_NOINIT  SGL no inicializada
;³                      Si no hay carry
;³                      EAX =   SGL_OK
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.data
SGL_text4   db '   þ Shutting down drivers...',13,10,0
SGL_text5   db '   þ SGL uninstalled ok!',13,10,0
.code

; Default verbose uninitialization
UnInitSGL	proc
			xor		al,al
			call	UnInitSGL_
			ret
			endp

UnInitSGLSilently	proc
			mov		al,1
			call	UnInitSGL_
			ret
			endp
			
UnInitSGL_  proc
; Evitamos k se modifike EBP para ser compatible con C
            push    ebp

; Evitamos una desinicializacion sin inicializacion
            cmp     InsideSGL, -1
            je      UNINSGL000
            mov     eax, SGL_NOINIT
            jmp     SGL_ErrorExit
    UNINSGL000:

; Si hay un modo de video activo lo desactivamos y volvemos a modo texto

            cmp     insideMode, -1                      ; B52
            jne     dont_reset_mode                     ; B52
			push	eax
            mov     eax, 3  ; modo texto 80x25
            call    UnSetVideoMode
			pop		eax
            dont_reset_mode:                            ; B52

			or		al,al
			jnz		silent_uninit0
; Imprimimos esos textos explicativos mu chulis
			push	eax
            eprint   SGL_text1
            eprint   SGL_text4
			pop		eax
			silent_uninit0:
; Inicializamos todos los drivers disponibles

			push	eax
            Call    DRIVER_VGA_UnInit
			pop		eax
            jc      SGL_ErrorExit
			push	eax
            Call    DRIVER_VBE_UnInit
			pop		eax
            jc      SGL_ErrorExit
;            Call    DRIVER_VBEAF_UnInit
;            jc      SGL_ErrorExit

			or		al,al
			jnz		silent_uninit1
            eprint   SGL_text5
			silent_uninit1:
			
            mov     InsideSGL, 0
            mov     eax, SGL_OK
            clc
            pop     ebp
            ret
            endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ SearchBestVideoMode: Busca el modo especificado utilizando en mejor driver
;³                      (Busca en direccion contraria en la lista)
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX = Resolucion X
;³                      EBX = Resolucion Y
;³                      ECX = Bits de color
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         Si EAX = SGL_OK
;³                      ESI =   Ptr al modo en la lista de modos
;³                      si no se encontro el modo
;³                      EAX = SGL_ERROR
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SearchBestVideoMode     proc
            and         ecx, 0ffh
            mov         esi, ModePtr
Searchloop:
            sub         esi, size TMODE
            test        [TMODE ptr esi.ModeType], MT_EMULATED
            jne         notthemode
            cmp         [TMODE ptr esi.Xresolution], eax
            jne         notthemode
            cmp         [TMODE ptr esi.Yresolution], ebx
            jne         notthemode
            cmp         [TMODE ptr esi.ColorBits], ecx
            je          foundmode
notthemode:
            cmp         esi, offset ModeList
            jne         Searchloop

            mov         esi, ModePtr
Searchloop_emul:
            sub         esi, size TMODE
            cmp         [TMODE ptr esi.Xresolution], eax
            jne         notthemode_emul
            cmp         [TMODE ptr esi.Yresolution], ebx
            jne         notthemode_emul
            cmp         [TMODE ptr esi.ColorBits], ecx
            je          foundmode
notthemode_emul:
            cmp         esi, offset ModeList
            jne         Searchloop_emul

            mov         eax, SGL_ERROR
            stc
            ret
foundmode:
            mov         eax, SGL_OK
            clc
            ret
            endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ SetVideoMode:        Inicializa el modo de video
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX = Resolucion X
;³                      EBX = Resolucion Y
;³                      ECX = Bits de color
;³      Nota:           Si ECX+SGL_MemoryBuffer se fuerza a un buffer en
;³                      memoria principal
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         Si hay carry
;³                           Error al inicializar el modo
;³                      EAX =   SGL_ERROR
;³                      Si no hay carry
;³                      EAX =   SGL_OK
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetVideoMode    proc
            cmp     InsideMode, -1
            jne     notbeforesetv
                push    eax ebx ecx
                xor     eax, eax
                call    UnSetVideoMode
                pop     ecx ebx eax
notbeforesetv:

            mov     FrameCounter, 0
            push    ecx
            Call    SearchBestVideoMode
            pop     ecx
            jc      SVM_ErrorExit
            push    ecx esi
            mov     ActualModePtr, esi
            mov     edi, offset ActualMode
            mov     ecx, size TMODE
            rep     movsb
            pop     esi ecx

            cmp     [ActualMode.driver], DR_VGA
            jne     SVM0001
            call    DRIVER_VGA_SetVideoMode
            jc      SVM_ErrorExit
SVM0001:

            cmp     [ActualMode.driver], DR_VBE
            jne     SVM0002
            call    DRIVER_VBE_SetVideoMode
            jc      SVM_ErrorExit
SVM0002:

            clc
            mov     eax, SGL_OK
            mov     insideMode, -1
            ret
SVM_ErrorExit:
            stc
            mov     eax, SGL_ERROR
            mov     insideMode, 0
            ret
            endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ UnSetVideoMode:      Desinicializa el modo de video
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        Si EAX = 0 Mantiene el modo actual
;³                      Si EAX <>0 Pone el modo indicado (con la BIOS)
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         Si hay carry
;³                           Error al inicializar el modo
;³                      EAX =   SGL_ERROR
;³                      Si no hay carry
;³                      EAX =   SGL_OK
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
UnSetVideoMode  proc
			push	ebp
            cmp     insideMode, -1 ;miramos si hay un modo puesto
            je      UnSetVideoMode_Inmode
            mov     eax, SGL_ERROR
            jmp     SGL_ErrorExit
UnSetVideoMode_Inmode:
            or      eax, eax
            jz      dontunsetvideom
            and     eax, 0ffh
            int     10h
dontunsetvideom:
            call    [UnSetVideoMode_]
			jc		unset_video_mode_error
					; Mode unset successfully
					mov		insideMode, 0
			unset_video_mode_error:
			pop		ebp
			ret
            endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ GetAvailPage:        Obtiene la direccion de la pagina actual
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        nada.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         Si hay carry
;³                      EAX =   0
;³                      Si no hay carry
;³                      EAX =   Direccion de la pagina actual
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetAvailPage    proc
                jmp     [GetAvailPage_]
                endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      ShowPage:       Indica que la pagina actual esta acabada.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        nada.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         nada.
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ShowPage        proc
                inc     FrameCounter
                jmp     [ShowPage_]
                endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      WaitRetrace:    Espera al retrazo
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        nada.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         nada.
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WaitRetrace     proc
                jmp     [WaitRetrace_]
                endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      GetMemoryPtr:   Obtiene el puntero de acceso directo a memoria
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        nada.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         Si no hay carry
;³                          EAX : Puntero a la memoria de video
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetMemoryPtr    proc
                jmp     [GetMemoryPtr_]
                endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ SetSGLOptions:       Funcion para seleccionar las opciones de la SGL
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX : Banderas de opciones
;³                          EAX + SSO_QuietInit
;³                          EAX + SSO_QuietFinish
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         nada.
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetSGLOptions   proc
                mov     SGLOptions, eax
                ret
                endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ CalcSizeDD:          Calcula el tama¤o en dwords de la pagina
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX : tama¤o X
;³                      EBX : tama¤o Y
;³                      ECX : bits de color
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         EAX : tama¤o en DoubleWords
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CalcSizeDD      proc
                cmp     ecx, 15
                jne     CSDD_SkipCompensate15bits
                mov     ecx, 16
CSDD_SkipCompensate15bits:
                imul    ecx
                imul    ebx
                shr     eax, 3+2
                ret
                endp
end
