/*
;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様邑
;�  new!SpanBuffer                              Coded by Nitro! / [tDR] �
;突様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様裕
;�  INCLUDE                                                             �
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳潰
*/

#ifndef _SBUFFER_INCLUDED_
#define _SBUFFER_INCLUDED_

#include <stddef.h>
#include <sli.h>
#include <sbuffer.def>
#include <3d.h>

#ifdef __cplusplus
  extern "C" {
#endif

#define kSptPerspectiveCorrected	0x100

/*
;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様邑
;�  Estructura de los SPAN's                                            �
;突様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様裕
;�  SPAN con soporte de n variables de interpolacion                    �
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳潰
 */
typedef struct
{
       BYTE *SPNext       ;// Puntero al siguiente span en la cadena
       BYTE *SPBack       ;// Puntero al span anterior en la cadena
       BYTE *SPTexture    ;// Puntero a la textura
       BYTE *SPLightMap   ;// Puntero a la tabla de conversion o paleta
       BYTE *SPAlpha      ;// Puntero al canal Alpha
       DWORD SPType       ;// Informacion del tipo de poly
/*                            ; 1 - Flat poly salida en 32 bits
                            ; 2 - Textured poly UV en 32 bits textura 8 bits
                            ; 3 - Gouraud poly UVL en 32 bits textura 8 bits (tabla de 7 bits)
                            ; 4 - SemiPhong UVL1L2 en 32 bits textura 8 bits Foco 7 bits (packed in 8)
                            ; 5 - Texture + 50% alphaEnvironment UV EU EV, textura y env. 7 bits (packed in 8)
                            ; 6 - Texture poly UV en 32 bits textura 32 bits
                            ; 7 - Flat poly alpha constante en 32 bits
                            ; 8 - Textured poly UV alpha constante en 32 bits textura 8 bits
                            ; 9 - Textured poly con canal alpha UV AU AV en 32 bits textura y alpha 8 bits
                            ; 10 - Textured poly con mascara color UV en 32 bits textura en 8 bits
                            ; 11 - Gouraud poly con mascara color UVL en 32 bits textura en 8 bits
                            ; SPT_PERSPECTIVE_CORRECTED Bandera para el calculo con correcion de perspectiva
                            ; SPT_ANTIALIASED    Bandera para bordes antialiaseados
                            ; SPT_BILINEAR_FILTERING Bandera para el filtro bilineal
                            ; SPT_TRANS_OR_MASK  Bandera para indicar algun tipo de transparencia
 */
       int   SPX1         ;// X inicial del segmento
       int   SPX2         ;// X final del segmento
       DWORD SPN          ;// Numero de variables a interpolar+1
       float SPVars[(SPAN_MAX_INTERPOLATE_VARS+1)*2]; // Variables + Incrementos
}    SPAN;
/*
;敖陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;� CreateSbufferSLI:    aloja un SBufferSLI en 32bits
;団陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;�      Entrada:        EAX : Size X
;�                      EBX : Size Y
;団陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;�      Salida:         EBX : puntero al SLI
;�                      EAX : ErrorCode
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
    GLOBAL      CreateSBufferSLI : near*/
SLI *CreateSBufferSLI(int x, int y);
#pragma aux CreateSBufferSLI "*" parm   [eax] [ebx] \
                              modify [eax ebx ecx edx esi edi ebp] \
                              value  [ebx];
/*
;敖陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;� SLI2SBuffer:         Prepara un SLI para ser un SBuffer
;団陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;�      Entrada:        EAX : Puntero al SLI de 32bits a convertir
;団陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;�      Salida:         EAX : Standard ErrorCode
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
    GLOBAL      SLI2SBuffer : near
 */
int SLI2SBuffer(SLI *slip);
#pragma aux SLI2SBuffer "*" parm   [eax] \
                            modify [eax ebx ecx edx esi edi ebp] \
                            value  [eax];
/*
;敖陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;� InitSBufferSLI:      Prepara un SLI para ser un SBuffer
;団陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;�      Entrada:        EAX : Puntero al SBufferSLI
;団陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
;�      Salida:         nada.
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�
    GLOBAL      InitSBufferSLI : near
*/
void InitSBufferSLI(SLI *slip);
#pragma aux InitSBufferSLI "*" parm   [eax] \
                              modify [eax ebx ecx edx esi edi ebp];
/*
;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様邑
;�  InsertSpan: Inserta un Span       [Internal use only]               �
;突様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様裕
;�         Entrada   :   EAX - Puntero al SpanBufferSLI                 �
;�                       EBX - Puntero al Span                          �
;�                       ECX - Scanline donde insertar el Span          �
;�          Salida   :   nada.                                          �
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳潰
    GLOBAL      InsertSpan : near
*/
void InsertSpan(SLI *slip, SPAN *spanp, int y);
#pragma aux InsertSpan  "*" parm   [eax] [ebx] [ecx] \
                            modify [eax ebx ecx edx esi edi ebp];
/*
;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様邑
;�  RenderSBufferSLI :   Renderiza el SBufferSLI                        �
;突様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様裕
;�         Entrada   :   EAX - Puntero al SpanBufferSLI                 �
;�          Salida   :   nada.                                          �
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳潰
    GLOBAL      RenderSBufferSLI:near
*/

void RenderSBufferSLI(SLI *slip);
#pragma aux RenderSBufferSLI "*" parm [eax] \
                                 modify [eax ebx ecx edx esi edi ebp];

/*
;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様邑
;�  GetFirstSpanPtr :   Returns pointer to first span in a line         �
;突様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様裕
;�         Entrada   :   EAX - Pointer to SpanBufferSLI                 �
;�                       EBX - Line index                               �
;�          Salida   :   EAX - Pointer to SPAN                          �
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳潰
	GLOBAL		GetFirstSpanInLine:near
*/
SPAN *GetFirstSpanInLine(SLI *slip, int line_index);
#pragma aux GetFirstSpanInLine "*" parm [eax] [ebx] \
								   modify [eax] \
								   value [eax];

void GenericTriangleMapper(SLI *sbuffer, RENDERPOLY *p);

extern SLI *OS;

#ifdef __cplusplus
  };
#endif

#endif
