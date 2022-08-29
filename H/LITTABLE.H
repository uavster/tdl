/*
;��������������������������������������������������������������������������Ŀ
;�file: littable.inc                                                        �
;��������������������������������������������������������������������������Ĵ
;� Creates a lighting table.                                                �
;�                                                                          �
;�      by C�sar Guirao Robles, a.k.a. Nitro! / [tDR], 1999                 �
;����������������������������������������������������������������������������
*/

#ifndef _LITTABLE_INCLUDED_
#define _LITTABLE_INCLUDED_

#include <stddef.h>

#ifdef __cplusplus
  extern "C" {
#endif

/*
;���������������������������������������������������������������������������
;�  CreateLitTable32:   Crea una tabla de iluminacion en 32 bits de color
;�                      a partir de una paleta ARGB 8 bits/canal.
;���������������������������������������������������������������������������
;�  Entrada:            ESI : Paleta 256 colores ARGB
;�                      EDI : Buffer donde insertar la tabla
;�                      EAX : Tipo de tabla de iluminacion
;�                            00  0 - Original .... 31 - Blanco
;�                            01  0 - Negro    .... 31 - Original
;�                            02  0 - Negro ... 15 - Original ... 31 - Blanco
;�                            03  0 - Original
;�                            >3  0 - Original
;�                      ECX : niveles de iluminacion
;���������������������������������������������������������������������������
;�  Salida:             EDI : rellenado
;���������������������������������������������������������������������������
*/
BYTE *CreateLitTable32(BYTE *palette, BYTE *table, int table_type, int lighting_levels);
#pragma aux CreateLitTable32 "*" parm   [esi] [edi] [eax] [ecx] \
							modify [eax ebx ecx edx esi edi ebp] \
							value [edi];

/*
;���������������������������������������������������������������������������
;�  CreateLitTable16:   Crea una tabla de iluminacion en 16 bits de color
;�                      a partir de una paleta.
;���������������������������������������������������������������������������
;�  Entrada:            ESI : Paleta 256 colores.
;�                      EDI : Buffer donde insertar la tabla
;�                      EAX : Tipo de tabla de iluminacion
;�                            00  0 - Original .... 31 - Blanco
;�                            01  0 - Negro    .... 31 - Original
;�                            02  0 - Negro ... 15 - Original ... 31 - Blanco
;�                            03  0 - Original
;�                            >3  0 - Original
;���������������������������������������������������������������������������
;�  Salida:             EDI : rellenado
;���������������������������������������������������������������������������
*/
BYTE *CreateLitTable16(BYTE *palette, BYTE *table, int table_type);
#pragma aux CreateLitTable16 "*" parm   [esi] [edi] [eax] \
							modify [eax ebx ecx edx esi edi ebp] \
							value [edi];

#ifdef __cplusplus
  };
#endif

#endif