/*
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³file: littable.inc                                                        ³
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;³ Creates a lighting table.                                                ³
;³                                                                          ³
;³      by C‚sar Guirao Robles, a.k.a. Nitro! / [tDR], 1999                 ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/

#ifndef _LITTABLE_INCLUDED_
#define _LITTABLE_INCLUDED_

#include <stddef.h>

#ifdef __cplusplus
  extern "C" {
#endif

/*
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  CreateLitTable32:   Crea una tabla de iluminacion en 32 bits de color
;³                      a partir de una paleta ARGB 8 bits/canal.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Entrada:            ESI : Paleta 256 colores ARGB
;³                      EDI : Buffer donde insertar la tabla
;³                      EAX : Tipo de tabla de iluminacion
;³                            00  0 - Original .... 31 - Blanco
;³                            01  0 - Negro    .... 31 - Original
;³                            02  0 - Negro ... 15 - Original ... 31 - Blanco
;³                            03  0 - Original
;³                            >3  0 - Original
;³                      ECX : niveles de iluminacion
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Salida:             EDI : rellenado
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
BYTE *CreateLitTable32(BYTE *palette, BYTE *table, int table_type, int lighting_levels);
#pragma aux CreateLitTable32 "*" parm   [esi] [edi] [eax] [ecx] \
							modify [eax ebx ecx edx esi edi ebp] \
							value [edi];

/*
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  CreateLitTable16:   Crea una tabla de iluminacion en 16 bits de color
;³                      a partir de una paleta.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Entrada:            ESI : Paleta 256 colores.
;³                      EDI : Buffer donde insertar la tabla
;³                      EAX : Tipo de tabla de iluminacion
;³                            00  0 - Original .... 31 - Blanco
;³                            01  0 - Negro    .... 31 - Original
;³                            02  0 - Negro ... 15 - Original ... 31 - Blanco
;³                            03  0 - Original
;³                            >3  0 - Original
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Salida:             EDI : rellenado
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
BYTE *CreateLitTable16(BYTE *palette, BYTE *table, int table_type);
#pragma aux CreateLitTable16 "*" parm   [esi] [edi] [eax] \
							modify [eax ebx ecx edx esi edi ebp] \
							value [edi];

#ifdef __cplusplus
  };
#endif

#endif