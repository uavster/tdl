;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様邑
;�  new!SpanBuffer                              Coded by Nitro! / [tDR] �
;突様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様裕
;�  INCLUDE                                                             �
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳潰

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様邑
;�  Estructura de los SPAN's                                            �
;突様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様裕
;�  SPAN con soporte de 8 variables de interpolacion                    �
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳潰
SPAN_MAX_INTERPOLATE_VARS equ 4

	SPT_PERSPECTIVE_CORRECTED	EQU 100h
	
    SPAN    struc
       SPNext       dd  ?   ; Puntero al siguiente span en la cadena
       SPBack       dd  ?   ; Puntero al span anterior en la cadena
       SPTexture    dd  ?   ; Puntero a la textura
       SPLightMap   dd  ?   ; Puntero a la tabla de conversion o paleta
       SPAlpha      dd  ?   ; Puntero al canal Alpha
       SPType       dd  ?   ; Informacion del tipo de poly
                            ; 1 - Flat poly salida en 32 bits
                            ; 2 - Textured poly UV en 32 bits textura 8 bits
                            ; 3 - Gouraud poly UVL en 32 bits textura 8 bits 
                            ; 4 - SemiPhong UVL1L2 en 32 bits textura 8 bits Foco 8 bits
                            ; 5 - Texture + 50% alphaEnvironment UV EU EV, textura y env.
                            ; 6 - Texture poly UV en 32 bits textura 32 bits
                            ; 7 - Flat poly alpha constante en 32 bits
                            ; 8 - Textured poly UV alpha constante en 32 bits textura 8 bits
                            ; 9 - Textured poly con canal alpha UV AU AV en 32 bits textura y alpha 8 bits
                            ; 10 - Textured poly con mascara color UV en 32 bits textura en 8 bits
                            ; 11 - Gouraud poly con mascara color UVL en 32 bits textura en 8 bits
                            ; 12 - Color RGB 
                            ; SPT_PERSPECTIVE_CORRECTED Bandera para el calculo con correcion de perspectiva
                            ; SPT_ANTIALIASED    Bandera para bordes antialiaseados
                            ; SPT_BILINEAR_FILTERING Bandera para el filtro bilineal
                            ; SPT_TRANS_OR_MASK  Bandera para indicar algun tipo de transparencia
       SPX1         dd  ?   ; X inicial del segmento
       SPX2         dd  ?   ; X final del segmento
       SPN          dd  ?   ; Numero de variables a interpolar+1
       SPiZ         dd  ?   ; Inverso de Z inicial del segmento
       SPdiZ        dd  ?   ; Incremento del inverso de Z
       SPVars       dd  SPAN_MAX_INTERPOLATE_VARS*2 dup (?)   ; Variables + Incrementos
    SPAN    ends

;敖陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;� CreateSbufferSLI:    aloja un SBufferSLI en 32bits
;団陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;�      Entrada:        EAX : Size X
;�                      EBX : Size Y
;団陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;�      Salida:         EBX : puntero al SLI
;�                      EAX : ErrorCode
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
    GLOBAL      CreateSBufferSLI : near
;敖陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;� SLI2SBuffer:         Prepara un SLI para ser un SBuffer
;団陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;�      Entrada:        EAX : Puntero al SLI de 32bits a convertir
;団陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;�      Salida:         EAX : Standard ErrorCode
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
    GLOBAL      SLI2SBuffer : near
;敖陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;� InitSBufferSLI:      Prepara un SLI para ser un SBuffer
;団陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;�      Entrada:        EAX : Puntero al SBufferSLI
;団陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;�      Salida:         nada.
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
    GLOBAL      InitSBufferSLI : near

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様邑
;�  InsertSpan: Inserta un Span       [Internal use only]               �
;突様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様裕
;�         Entrada   :   EAX - Puntero al SpanBufferSLI                 �
;�                       EBX - Puntero al Span                          �
;�                       ECX - Scanline donde insertar el Span          �
;�          Salida   :   nada.                                          �
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳潰
    GLOBAL      InsertSpan : near

;敖陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;� InitSBufferSLI:      Inicializa el SBufferSLI para generar un nuevo frame
;団陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;�      Entrada:        EAX : Puntero al SBufferSLI
;団陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;�      Salida:         nada.
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
    GLOBAL      InitSBufferSLI : near

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様邑
;�  RenderSBufferSLI :   Renderiza el SBufferSLI                        �
;突様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様裕
;�         Entrada   :   EAX - Puntero al SpanBufferSLI                 �
;�          Salida   :   nada.                                          �
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳潰
    GLOBAL      RenderSBufferSLI:near

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様邑
;�  GenericTriangleMapper : Genera un triangulo                         �
;突様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様裕
;�         Entrada   :   EAX - Puntero al SpanBufferSLI                 �
;�                       EDX - puntero al RENDERPOLY                    �
;�          Salida   :   nada.                                          �
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳潰
    GLOBAL      GenericTriangleMapper_:near

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様邑
;�  GetFirstSpanPtr :   Returns pointer to first span in a line         �
;突様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様裕
;�         Entrada   :   EAX - Pointer to SpanBufferSLI                 �
;�                       EBX - Line index                               �
;�          Salida   :   EAX - Pointer to SPAN                          �
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳潰
	GLOBAL		GetFirstSpanInLine:near

    GenericTriangleMapper       EQU GenericTriangleMapper_
