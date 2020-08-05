;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Definitions for SPUF!
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд

SLI_TEMP_VARS   EQU 8   ; No puede ser 0 (necesarias para rutinas de blitting)

; Blitting basic methodes
SLIBlitCopy      EQU 0
SLIBlitAlpha     EQU 1
SLIBlitAlphaMap  EQU 2

SLIMaskedColor   EQU 4
SLIScaled        EQU 4*2

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё CreateSLI:           aloja una animaci╒n vacia en SLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX : Size X
;Ё                      EBX : Size Y
;Ё                      ECX : ColorBits
;Ё                      EDX : Number of frames
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         EAX : puntero al SLI
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  CreateSLI : NEAR

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё CreateVoidSLI:       aloja una animaci╒n vacia en SLI sin buffer
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX : Size X
;Ё                      EBX : Size Y
;Ё                      ECX : ColorBits
;Ё                      EDX : Number of frames
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         EAX : puntero al SLI
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  CreateVoidSLI : NEAR

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё DestroySLI:          Desaloja una imagen vacia en SLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX : puntero al SLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         nada.
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  DestroySLI : NEAR

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё CreateVideoSLI:      Crea la superficie de video SLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX : Size X
;Ё                      EBX : Size Y
;Ё                      ECX : ColorBits
;Ё      Nota:           Si ECX+SGL_MemoryBuffer se fuerza a un buffer en
;Ё                      memoria principal
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         Error si hay Carry
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  CreateVideoSLI : NEAR

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё GetVideoSLI:         Obtiene la superficie de video SLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        nada.
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         EAX : ptr to Video SLI
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  GetVideoSLI : NEAR

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё ShowVideoSLI:        Muestra la superficie de video SLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        nada.
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         nada.
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global   ShowVideoSLI : NEAR

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё DestroyVIdeoSLI:          desaloja el VideoSLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX <> 0 modo de video a seleccionar
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         nada.
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  DestroyVideoSLI : NEAR

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё SetPalette:          Pone el puntero a una paleta B:G:R:0
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX -> SLI
;Ё                      EBX -> Palette
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         nada.
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  SetPalette : NEAR

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Devuelve el nёmero de frame actual
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX = Frame
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  GetFrame : NEAR

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el nёmero de frame actual
;
; INPUT  : EAX -> SLI
;          EBX = Frame
;
; OUTPUT : CF = 0 si ok
;               EAX = NULL
;          CF = 1 si error
;               EAX = Error code (INVALID_FRAME)
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  SetFrame : NEAR

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
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
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  GetFramePtr : NEAR

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el puntero a un frame determinado
;
; INPUT  : EAX -> SLI
;          EBX = Nёmero de frame
;          ECX -> Frame
;
; OUTPUT : CF = 0 si ok
;               EAX = NULL
;          CF = 1 si el frame no existe
;               EAX = Error code
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  SetFramePtr : NEAR

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Devuelve el puntero al frame actual
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX -> Frame actual
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  GetCurrentFramePtr : NEAR

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Devuelve las dimensiones (con escalado) del SLI
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX = X size
;          EBX = Y size
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  GetDimensions : NEAR

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el color de m═scara
;
; INPUT : EAX -> SLI
;         EBX = Color de m═scara en formato B:G:R:0
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  SetMaskColor : NEAR

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el m┌todo de blitting
;
; INPUT : EAX -> SLI
;         EBX = Tipo de blit ('SLIBlitCopy', 'SLIBlitAlpha', 'SLIBlitAlphaMap'
;                             y los mismos con '+ SLIMaskedColor' para poner
;                             con m═scara)
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  SetBlitType : NEAR

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el rect═ngulo de clipping
;
; INTPUT : EAX = x1
;          EBX = y1
;          ECX = x2
;          EDX = y2
;          EDI -> SLI
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  SetClip : NEAR

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone la posicion
;
; INTPUT : EAX = x1
;          EBX = y1
;          EDI -> SLI
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  SetPos : NEAR

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё ClearCurrentFrame:   Borra el frame actual al color dado
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX -> SLI
;Ё                      EBX -> color en el formato del SLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         nada.
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  ClearCurrentFrame : NEAR

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el campo de alpha
;
; INPUT : EAX -> SLI
;         EBX = Alpha constante o puntero al mapa de alphas
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
global  SetAlpha : NEAR

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
    SLIMethode      dd  ?   ; M┌todos de la imagen

    SLIPos          SLR <>  ; Rect═ngulo del sprite en destino
    SLIRef          SLP <>  ; Posicion de referencia dentro del sprite
    SLIClip         SLR <>  ; Zona de clipping (en coordenadas de pantalla)

    SLIXSize        dd  ?   ; Ancho
    SLIYSize        dd  ?   ; Alto

    SLIPitch        dd  ?   ; ancho de la imagen que la contiene
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
                            ; (Si es NULL con SLIBltAlphaMap, el alpha est═ como B:G:R:A)

    SLIMask         dd  ?   ; Color de m═scara

    SLIFrame        dd  ?   ; Frame actual de la animacion 16.16
    SLITotalFrames  dd  ?   ; Numero de frames de la animacion 16.16
    SLIFrameRate    dd  ?   ; Incremento de frames en 16.16
    SLIFramePtr     dd  ?   ; Puntero al frame actual

    SLIPImages      dd  ?   ; puntero a la lista de punteros de frames

    SLITemp         dd  SLI_TEMP_VARS dup(?)    ; Espacio para variables temporales (reservado)

    SLIPalette      dd  256 dup(?)   ; paleta asociada si no la tiene = NULL
    SLILitTable     dd  ?            ; puntero a una tabla de conversion si no la tiene = NULL
    SLISBufferNfo   dd  ?            ; Datos para los SbufferSLI
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


