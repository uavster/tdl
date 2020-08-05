;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё  [tDR], 1998                                    Copyright the DarkRising
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Т Т  Т                          Coded by:              Nitro!
;Ё New! Ё Ё© Ё  Version 1.10b           Support & BugFixed by: Teknik, B52
;Ё      У юы ю
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё  DATE         REVISION           AUTHOR & COMMENTS
;Ё  дддддддд     ддддддддддддд      дддддддддддддддддддддддддддддддддддддддд
;Ё  08-11-98     Version 1.10b      Nitro! : Code Reorganization
;Ё
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
    .386p
    .model  flat
    jumps
    .code
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё  Needed includes
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
    include     newsgl.inc
    include     dpmi.inc
    include     utils.inc
    include     alloc.inc
    include     memcpy.inc
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё  Macros
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;д Macro para debugging дддддддддддддддддддддддддддддддддддддддддддддддддддд
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
;д Macro para textos de inicio ддддддддддддддддддддддддддддддддддддддддддддд
iprint      macro text1
    local   skipthis
    test    SGLOptions, SSO_QuietInit
    jnz     skipthis
    print   text1
skipthis:
    endm

;д Macro para textos de salida ддддддддддддддддддддддддддддддддддддддддддддд
eprint      macro text1
    local   skipthis
    test    SGLOptions, SSO_QuietFinish
    jnz     skipthis
    print   text1
skipthis:
    endm

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё  д DRIVERS DISPONIBLES дддддддддддддддддддддддддддддддддддддддддддддддддд
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;    include     newsgl\DRVGA.asm     ; Driver VGA
;    include     newsgl\DRVBE.asm     ; Driver VBE
    include     DRVGA.asm     ; Driver VGA
    include     DRVBE.asm     ; Driver VBE
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд


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
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      InitSGL:        Funcion para inicializar el interfaz de video.
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        Nada.
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         Si hay carry
;Ё                           Error al iniciar la libreria
;Ё                      EAX :   SGL_DRIVER  No hay ningun driver soportado
;Ё                              SGL_NOMEM   No hay memoria suficiente
;Ё                              SGL_FILE    Error en lectura de archivos
;Ё                              SGL_REINIT  SGL ya inicializada
;Ё                      Si no hay carry
;Ё                      EAX =   SGL_OK
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
.data?
    Almost1driver   db  ?
.data
    InsideSGL       db  0
    InsideMode      db  0
SGL_text1   db '[New!SGL] : New Shade Graphic Library      Version 1.10b      Coded by Nitro! ',13,10
            db 'Copyright the DarkRising [tDR] : 1999      Aditional code by:  B52  &  Teknik ',13,10
            db '< http://fly.to/thedarkrising >            mail: group@thedarkrising.ddns.org ',13,10,13,10,0
SGL_text2   db '   Ч Launching drivers...',13,10,0
SGL_text3   db '   Ч Library initialized with %dn'
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


;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      AddMode:        Funcion para a╓adir un modo a la lista general de
;Ё      (interna)       modos soportados
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        ESI : Puntero a TMODE a incluir
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         Si hay carry
;Ё                           Error al incluir el modo
;Ё                      EAX =   SGL_ERROR
;Ё                      Si no hay carry
;Ё                      EAX =   SGL_OK
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
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

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё    UnInitSGL:        Funcion para desinicializar el interfaz de video.
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        Nada.
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         Si hay carry
;Ё                           Error al finalizar la libreria
;Ё                      EAX :   SGL_NOINIT  SGL no inicializada
;Ё                      Si no hay carry
;Ё                      EAX =   SGL_OK
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
.data
SGL_text4   db '   Ч Shutting down drivers...',13,10,0
SGL_text5   db '   Ч SGL uninstalled ok!',13,10,0
.code
UnInitSGL   proc
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
            mov     eax, 3  ; modo texto 80x25
            call    UnSetVideoMode
            dont_reset_mode:                            ; B52

; Imprimimos esos textos explicativos mu chulis
            eprint   SGL_text1
            eprint   SGL_text4

; Inicializamos todos los drivers disponibles

            Call    DRIVER_VGA_UnInit
            jc      SGL_ErrorExit
            Call    DRIVER_VBE_UnInit
            jc      SGL_ErrorExit
;            Call    DRIVER_VBEAF_UnInit
;            jc      SGL_ErrorExit

            eprint   SGL_text5

            mov     InsideSGL, 0
            mov     eax, SGL_OK
            clc
            pop     ebp
            ret
            endp
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё SearchBestVideoMode: Busca el modo especificado utilizando en mejor driver
;Ё                      (Busca en direccion contraria en la lista)
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX = Resolucion X
;Ё                      EBX = Resolucion Y
;Ё                      ECX = Bits de color
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         Si EAX = SGL_OK
;Ё                      ESI =   Ptr al modo en la lista de modos
;Ё                      si no se encontro el modo
;Ё                      EAX = SGL_ERROR
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
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
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё SetVideoMode:        Inicializa el modo de video
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX = Resolucion X
;Ё                      EBX = Resolucion Y
;Ё                      ECX = Bits de color
;Ё      Nota:           Si ECX+SGL_MemoryBuffer se fuerza a un buffer en
;Ё                      memoria principal
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         Si hay carry
;Ё                           Error al inicializar el modo
;Ё                      EAX =   SGL_ERROR
;Ё                      Si no hay carry
;Ё                      EAX =   SGL_OK
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
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
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё UnSetVideoMode:      Desinicializa el modo de video
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        Si EAX = 0 Mantiene el modo actual
;Ё                      Si EAX <>0 Pone el modo indicado (con la BIOS)
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         Si hay carry
;Ё                           Error al inicializar el modo
;Ё                      EAX =   SGL_ERROR
;Ё                      Si no hay carry
;Ё                      EAX =   SGL_OK
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
UnSetVideoMode  proc
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
            jmp     [UnSetVideoMode_]
            endp
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё GetAvailPage:        Obtiene la direccion de la pagina actual
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        nada.
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         Si hay carry
;Ё                      EAX =   0
;Ё                      Si no hay carry
;Ё                      EAX =   Direccion de la pagina actual
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
GetAvailPage    proc
                jmp     [GetAvailPage_]
                endp
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      ShowPage:       Indica que la pagina actual esta acabada.
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        nada.
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         nada.
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
ShowPage        proc
                inc     FrameCounter
                jmp     [ShowPage_]
                endp
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      WaitRetrace:    Espera al retrazo
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        nada.
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         nada.
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
WaitRetrace     proc
                jmp     [WaitRetrace_]
                endp
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      GetMemoryPtr:   Obtiene el puntero de acceso directo a memoria
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        nada.
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         Si no hay carry
;Ё                          EAX : Puntero a la memoria de video
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
GetMemoryPtr    proc
                jmp     [GetMemoryPtr_]
                endp
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё SetSGLOptions:       Funcion para seleccionar las opciones de la SGL
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX : Banderas de opciones
;Ё                          EAX + SSO_QuietInit
;Ё                          EAX + SSO_QuietFinish
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         nada.
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetSGLOptions   proc
                mov     SGLOptions, eax
                ret
                endp
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё CalcSizeDD:          Calcula el tama╓o en dwords de la pagina
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX : tama╓o X
;Ё                      EBX : tama╓o Y
;Ё                      ECX : bits de color
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         EAX : tama╓o en DoubleWords
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
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
