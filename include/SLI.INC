;�����������������������������������������������������������������������������
; Definitions for SPUF!
;�����������������������������������������������������������������������������

SLI_TEMP_VARS   EQU 8   ; No puede ser 0 (necesarias para rutinas de blitting)

; Blitting basic methodes
SLIBlitCopy      	EQU 0
SLIBlitAlpha     	EQU 1
SLIBlitAlphaMap  	EQU 2
SLIBlitAddSaturate	EQU 3

SLIMaskedColor   EQU 4
SLIScaled        EQU 4*2

; Animation modes
SLIAnimNormal		EQU 0
SLIAnimForwardLoop	EQU 1
SLIAnimPingPongLoop EQU 2

;���������������������������������������������������������������������������
;� CreateSLI:           aloja una animaci�n vacia en SLI
;���������������������������������������������������������������������������
;�      Entrada:        EAX : Size X
;�                      EBX : Size Y
;�                      ECX : ColorBits
;�                      EDX : Number of frames
;���������������������������������������������������������������������������
;�      Salida:         EAX : puntero al SLI o NULL
;���������������������������������������������������������������������������
global  CreateSLI : NEAR

;���������������������������������������������������������������������������
;� CreateVoidSLI:       aloja una animaci�n vacia en SLI sin buffer
;���������������������������������������������������������������������������
;�      Entrada:        EAX : Size X
;�                      EBX : Size Y
;�                      ECX : ColorBits
;�                      EDX : Number of frames
;���������������������������������������������������������������������������
;�      Salida:         EAX : puntero al SLI
;���������������������������������������������������������������������������
global  CreateVoidSLI : NEAR

;���������������������������������������������������������������������������
;� SetFrameData:       Set frame pointers to the given memory buffer. 
;					   The memory is owned by the caller and must be large
;					   enough to hold all frames.
;					   Frames must be contiguous in memory.
;���������������������������������������������������������������������������
;�      Entrada:        EDI : SLI pointer
;						ESI : Pointer to frame memory.
;���������������������������������������������������������������������������
global	SetFrameData : NEAR

;���������������������������������������������������������������������������
;� DestroySLI:          Desaloja una imagen vacia en SLI
;���������������������������������������������������������������������������
;�      Entrada:        EAX : puntero al SLI
;���������������������������������������������������������������������������
;�      Salida:         nada.
;���������������������������������������������������������������������������
global  DestroySLI : NEAR

;���������������������������������������������������������������������������
;� CreateVideoSLI:      Crea la superficie de video SLI
;���������������������������������������������������������������������������
;�      Entrada:        EAX : Size X
;�                      EBX : Size Y
;�                      ECX : ColorBits
;�      Nota:           Si ECX+SGL_MemoryBuffer se fuerza a un buffer en
;�                      memoria principal
;���������������������������������������������������������������������������
;�      Salida:         Error si hay Carry
;���������������������������������������������������������������������������
global  CreateVideoSLI : NEAR

;���������������������������������������������������������������������������
;� GetVideoSLI:         Obtiene la superficie de video SLI
;���������������������������������������������������������������������������
;�      Entrada:        nada.
;���������������������������������������������������������������������������
;�      Salida:         EAX : ptr to Video SLI
;���������������������������������������������������������������������������
global  GetVideoSLI : NEAR

;���������������������������������������������������������������������������
;� ShowVideoSLI:        Muestra la superficie de video SLI
;���������������������������������������������������������������������������
;�      Entrada:        nada.
;���������������������������������������������������������������������������
;�      Salida:         nada.
;���������������������������������������������������������������������������
global   ShowVideoSLI : NEAR

;���������������������������������������������������������������������������
;� DestroyVIdeoSLI:          desaloja el VideoSLI
;���������������������������������������������������������������������������
;�      Entrada:        EAX <> 0 modo de video a seleccionar
;���������������������������������������������������������������������������
;�      Salida:         nada.
;���������������������������������������������������������������������������
global  DestroyVideoSLI : NEAR

;���������������������������������������������������������������������������
;� SetPalette:          Pone el puntero a una paleta B:G:R:0
;���������������������������������������������������������������������������
;�      Entrada:        EAX -> SLI
;�                      EBX -> Palette
;���������������������������������������������������������������������������
;�      Salida:         nada.
;���������������������������������������������������������������������������
global  SetPalette : NEAR

;�����������������������������������������������������������������������������
; Devuelve el n�mero total de frames
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EBX = N�mero de frames
;�����������������������������������������������������������������������������
global  GetNumFrames : NEAR

;�����������������������������������������������������������������������������
; Devuelve el n�mero de frame actual
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX = Frame
;�����������������������������������������������������������������������������
global  GetFrame : NEAR

;�����������������������������������������������������������������������������
; Pone el n�mero de frame actual
;
; INPUT  : EAX -> SLI
;          EBX = Frame
;
; OUTPUT : CF = 0 si ok
;               EAX = NULL
;          CF = 1 si error
;               EAX = Error code (INVALID_FRAME)
;�����������������������������������������������������������������������������
global  SetFrame : NEAR

;�����������������������������������������������������������������������������
; Updates a SLI animation with the current synchronization timer ticks.
;
; INPUT  : ESI -> SLI
;�����������������������������������������������������������������������������
global	AnimateSLI : NEAR

;�����������������������������������������������������������������������������
; Sets the frame rate of a multiframe SLI.
;
; INPUT  : ESI -> SLI
;		   EAX = Timer ticks
;�����������������������������������������������������������������������������
global	AnimateSLIWithTicks : NEAR

;�����������������������������������������������������������������������������
; Sets the frame rate of a multiframe SLI.
;
; INPUT  : EAX -> SLI
;          EBX = Fixed point (16.16) frame rate in frames per second
;
; OUTPUT : CF = 0 if ok
;				EAX = NULL
;		   CF = 1 if error
;				EAX = Error code				
;�����������������������������������������������������������������������������
global SetFrameRate : NEAR

;�����������������������������������������������������������������������������
; Devuelve el puntero a un frame determinado
;
; INPUT  : EAX -> SLI
;          EBX = Frame
;
; OUTPUT : CF = 0 si ok
;               EAX = NULL
;               EBX -> Frame
;          CF = 1 si el frame no existe
;               EAX = Error code
;�����������������������������������������������������������������������������
global  GetFramePtr : NEAR

;�����������������������������������������������������������������������������
; Pone el puntero a un frame determinado
;
; INPUT  : EAX -> SLI
;          EBX = N�mero de frame
;          ECX -> Frame
;
; OUTPUT : CF = 0 si ok
;               EAX = NULL
;          CF = 1 si el frame no existe
;               EAX = Error code
;�����������������������������������������������������������������������������
global  SetFramePtr : NEAR

;�����������������������������������������������������������������������������
; Devuelve el puntero al frame actual
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX -> Frame actual
;�����������������������������������������������������������������������������
global  GetCurrentFramePtr : NEAR

;�����������������������������������������������������������������������������
; Devuelve las dimensiones (con escalado) del SLI
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX = X size
;          EBX = Y size
;�����������������������������������������������������������������������������
global  GetDimensions : NEAR

;�����������������������������������������������������������������������������
; Pone el color de m�scara
;
; INPUT : EAX -> SLI
;         EBX = Color de m�scara en formato B:G:R:0
;�����������������������������������������������������������������������������
global  SetMaskColor : NEAR

;�����������������������������������������������������������������������������
; Pone el m�todo de blitting
;
; INPUT : EAX -> SLI
;         EBX = Tipo de blit ('SLIBlitCopy', 'SLIBlitAlpha', 'SLIBlitAlphaMap', 'SLIBlitAddSaturate'
;                             y los mismos con '+ SLIMaskedColor' para poner
;                             con m�scara)
;�����������������������������������������������������������������������������
global  SetBlitType : NEAR

;�����������������������������������������������������������������������������
; Pone el rect�ngulo de clipping
;
; INTPUT : EAX = x1
;          EBX = y1
;          ECX = x2
;          EDX = y2
;          EDI -> SLI
;�����������������������������������������������������������������������������
global  SetClip : NEAR

;�����������������������������������������������������������������������������
; Pone la posicion
;
; INTPUT : EAX = x1
;          EBX = y1
;          EDI -> SLI
;�����������������������������������������������������������������������������
global  SetPos : NEAR

;���������������������������������������������������������������������������
;� ClearCurrentFrame:   Borra el frame actual al color dado
;���������������������������������������������������������������������������
;�      Entrada:        EAX -> SLI
;�                      EBX -> color en el formato del SLI
;���������������������������������������������������������������������������
;�      Salida:         nada.
;���������������������������������������������������������������������������
global  ClearCurrentFrame : NEAR

;�����������������������������������������������������������������������������
; Pone el campo de alpha
;
; INPUT : EAX -> SLI
;         EBX = Alpha constante o puntero al mapa de alphas
;�����������������������������������������������������������������������������
global  SetAlpha : NEAR

;�����������������������������������������������������������������������������
; Pone el modo de animaci�n
;
; INPUT : EAX -> SLI
;         BL = Modo de animaci�n
;�����������������������������������������������������������������������������
global  SetAnimMode : NEAR

;�����������������������������������������������������������������������������
; Pone el inicio del loop de animaci�n
;
; INPUT : EAX -> SLI
;         EBX = Frame inicial del loop
;�����������������������������������������������������������������������������
global  SetAnimLoopStartFrame : NEAR

;�����������������������������������������������������������������������������
; Pone el final del loop de animaci�n
;
; INPUT : EAX -> SLI
;         EBX = Frame final del loop
;�����������������������������������������������������������������������������
global  SetAnimLoopEndFrame : NEAR

;�����������������������������������������������������������������������������
; Creates a deep copy of a SLI
;
; All non-pointer SLI header fields are copied. Only those pointees in the SLI header that are intrinsically tied to
; the image data are deep-copied.
; Fields that are deep-copied: image frame pointers, integral image pointer.
; Fields that are not deep-copied: span buffer pointer, lighting table pointer, alpha map pointer.
; The fields that are not copied are not considered part of the image state.
;
; INPUT : EAX -> Source SLI
; OUTPUT: EAX -> Deep copy of source SLI
;�����������������������������������������������������������������������������
global  CreateSLIDeepCopy : NEAR

;   Estructura de punto
SLP struc
    SLPX    dd ?
    SLPY    dd ?
    ends

;   Estructura de rectangulo
SLR struc
    SLRR1   SLP <>
    SLRR2   SLP <>
    ends

SLI struc
    SLIMethode      dd  ?   ; M�todos de la imagen

    SLIPos          SLR <>  ; Rect�ngulo del sprite en destino
    SLIRef          SLP <>  ; Posicion de referencia dentro del sprite
    SLIClip         SLR <>  ; Zona de clipping (en coordenadas de pantalla)

    SLIXSize        dd  ?   ; Ancho
    SLIYSize        dd  ?   ; Alto

    SLIPitch        dd  ?   ; ancho en bytes de cada línea
    SLIColorBits    dd  ?   ; densidad de color
                            ; para  8, 16, 24, 32 bits
                            ; valor 1,  2,  3,  4

    SLIBlitType     dd  ?   ; 0 - SLIBlitCopy
                            ; 1 - SLIBlitAlpha
                            ; 2 - SLIBlitAlphaMap
                            ; 3 - Reserved
                            ;
                            ; 4 - SLIBlitCopy Masked
                            ; 5 - SLIBlitAlpha Masked
                            ; 6 - SLIBlitAlphaMap Masked
                            ; 7 - Reserved

    SLIAlpha        dd  ?   ; Puntero al canal alpha o al alpha constante
                            ; (Si es NULL con SLIBltAlphaMap, el alpha est� como B:G:R:A)

    SLIMask         dd  ?   ; Color de m�scara

    SLIFrame        dd  ?   ; Frame actual de la animacion 16.16
    SLITotalFrames  dd  ?   ; Numero de frames de la animacion 16.16
    SLIFrameRate    dd  ?   ; Incremento de frames en 16.16
    SLIStartTicks	dd	?	; Valor del timer la �ltima vez que se cambi� el frame actual manualmente o la velocidad de reproducci�n
    SLIStartFrame	dd	?	; Frame de inicio de animaci�n en 16.16
    SLILoopStart	dd  ?	; Frame de inicio del loop de animaci�n
    SLILoopEnd		dd	?	; Frame final del loop de animaci�n
    SLIFramePtr     dd  ?   ; Puntero al frame actual

    SLIPImages      dd  ?   ; puntero a la lista de punteros de frames

    SLITemp         dd  SLI_TEMP_VARS dup(?)    ; Espacio para variables temporales (reservado)

    SLIPalette      dd  256 dup(?)   ; paleta asociada si no la tiene = NULL
    SLILitTable     dd  ?            ; puntero a una tabla de conversion si no la tiene = NULL
    SLISBufferNfo   dd  ?            ; Datos para los SbufferSLI
	SLIIntegralImage	dd ?		 ; Points at integral image, or NULL if not allocated
  SLIIntegralImageMultiplier dd ? ; Factor by which entries are multiplied in the integral image
	; Loops will not work well when the end of the loop in fixed point 16.16
	; is above the range of a signed dword (2^31-1). That's 32,768 frames.
	SLIAnimMode		db  ?   ; 0 - Normal
							; 1 - Forward loop
							; 2 - Ping pong loop							
	SLIPlayingBackwards	db	?
    ends

; Estructura para tratar temporales
TMP struc
        tmp1    dd ?
        tmp2    dd ?
        tmp3    dd ?
        tmp4    dd ?
        tmp5    dd ?
        tmp6    dd ?
        tmp7    dd ?
        tmp8    dd ?
ends


