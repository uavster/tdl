;ีออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  new!SpanBuffer                              Coded by Nitro! / [tDR] ณ
;ฦออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออต
;ณ  INCLUDE                                                             ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

;ีออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  Estructura de los SPAN's                                            ณ
;ฦออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออต
;ณ  SPAN con soporte de 8 variables de interpolacion                    ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
SPAN_MAX_INTERPOLATE_VARS equ 4

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
                            ; SPT_PERS_CORRECTED Bandera para el calculo con correcion de perspectiva
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

;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
;ณ CreateSbufferSLI:    aloja un SBufferSLI en 32bits
;รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
;ณ      Entrada:        EAX : Size X
;ณ                      EBX : Size Y
;รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
;ณ      Salida:         EBX : puntero al SLI
;ณ                      EAX : ErrorCode
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
    GLOBAL      CreateSBufferSLI : near
;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
;ณ SLI2SBuffer:         Prepara un SLI para ser un SBuffer
;รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
;ณ      Entrada:        EAX : Puntero al SLI de 32bits a convertir
;รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
;ณ      Salida:         EAX : Standard ErrorCode
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
    GLOBAL      SLI2SBuffer : near
;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
;ณ InitSBufferSLI:      Prepara un SLI para ser un SBuffer
;รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
;ณ      Entrada:        EAX : Puntero al SBufferSLI
;รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
;ณ      Salida:         nada.
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
    GLOBAL      InitSBufferSLI : near

;ีออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  InsertSpan: Inserta un Span       [Internal use only]               ณ
;ฦออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออต
;ณ         Entrada   :   EAX - Puntero al SpanBufferSLI                 ณ
;ณ                       EBX - Puntero al Span                          ณ
;ณ                       ECX - Scanline donde insertar el Span          ณ
;ณ          Salida   :   nada.                                          ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
    GLOBAL      InsertSpan : near

;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
;ณ InitSBufferSLI:      Inicializa el SBufferSLI para generar un nuevo frame
;รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
;ณ      Entrada:        EAX : Puntero al SBufferSLI
;รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
;ณ      Salida:         nada.
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
    GLOBAL      InitSBufferSLI : near

;ีออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  RenderSBufferSLI :   Renderiza el SBufferSLI                        ณ
;ฦออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออต
;ณ         Entrada   :   EAX - Puntero al SpanBufferSLI                 ณ
;ณ          Salida   :   nada.                                          ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
    GLOBAL      RenderSBufferSLI:near

;ีออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  GenericTriangleMapper : Genera un triangulo                         ณ
;ฦออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออต
;ณ         Entrada   :   EAX - Puntero al SpanBufferSLI                 ณ
;ณ                       EDX - puntero al RENDERPOLY                    ณ
;ณ          Salida   :   nada.                                          ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
    GLOBAL      GenericTriangleMapper_:near

    GenericTriangleMapper       EQU GenericTriangleMapper_
