;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  [tDR], 1998                                    Copyright the DarkRising
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      ô ô  ô                          Coded by:              Nitro!
;³ New! ³ ³¿ ³  Version 1.10b           Support & BugFixed by: Teknik, B52
;³      õ ÀÙ À
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ INCLUDE FILE
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;  EQUATES
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    MAX_MODES   equ  200

    NULL        equ  0

    SGL_OK      equ  0
    SGL_DRIVER  equ  1
    SGL_NOMEM   equ  2
    SGL_FILE    equ  3
    SGL_REINIT  equ  4
    SGL_NOINIT  equ  5
    SGL_ERROR   equ  -1

;    SGL_OneBuffer equ 1 shl 31
    SGL_MemoryBuffer equ 80000000h

    DRIVER_Supported equ  0

    DR_VGA          equ  0
    DR_VBE          equ  1
    DR_VBEAF        equ  2
    DR_DIRECTDRAW   equ  3

    MT_Emulated     equ      1b
    MT_Accelerated  equ     10b

    ET_Resolution   equ      1b
    ET_AdapResolution equ   10b
    ET_Color        equ    100b

    SSO_QuietInit   equ      1b
    SSO_QuietFinish equ     10b

;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;  TYPES
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
TMODE   struc
    Driver      db  ?   ; Actually supported
                        ; 00 - VGA/EGA driver
                        ; 01 - VBE 1.0 / 1.1 / 1.2 / 2.0 / 3.0
                        ; 02 - VBE/AF 2.0
                        ; 03 - DirectDraw 5.0????
    XResolution dd  ?
    YResolution dd  ?
    ColorBits   dd  ?
    BytesPerPixel dd ?
    DDSize      dd  ?

    NPages      db  ?
    ModeType    db  ?   ; MT_Emulated
                        ; MT_Accelerated
    EmulType    db  ?   ; ET_Resolution
                        ; ET_AdapResolution (Scaled)
                        ; ET_Color
    RealX       dd  ?
    RealY       dd  ?
    RealC       dd  ?
    RealBPP     dd  ?
    DriverData  db  32 dup (?)
TMODE   ends

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;  GLOBAL DEFINITIONS
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    global      InitSGL             : near
    global      UnInitSGL           : near
	global		UnInitSGLSilently	: near
    global      SetVideoMode        : near
    global      UnSetVideoMode      : near
    global      GetAvailPage        : near
    global      ShowPage            : near
    global      SetSGLOptions       : near
    global      ActualMode          : TMODE
    global      WaitRetrace         : near
    global      GetMemoryPtr        : near
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;  MACROS
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    VerticalRStart  macro
                    endm
    VerticalREnd    macro
                    call    WaitRetrace
                    endm
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
