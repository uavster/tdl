/* 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
   Include file for virtual frame rate synchronization routines
   컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴� */

#ifndef _SYNC_INCLUDED_
#define _SYNC_INCLUDED_

#ifdef __cplusplus
  extern "C" {
#endif

/*
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
 Fuerza el controlador de virtual frame rate a funcionar a una frecuencia
 concreta
 INPUT  : freq - Frecuencia a la que se quiere forzar el controlador
 OUTPUT : 0 si ok
          no 0 si error
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/
void  ForceVirtualFrameRate(float freq);
#pragma aux ForceVirtualFrameRate "*" parm   [eax] \
                             modify [eax ebx ecx edx esi edi ebp] \
                             value [eax];

/*
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
 Gets elpased time from last call to routine
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
*/
void GetElapsedTime(void);
#pragma aux  GetElapsedTime "*" modify [eax ebx ecx edx esi edi ebp];

/*
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Increments a float with virtual frame rate
;
; INPUT : out  - pointer to a float variable
;         incr - increment
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
 */
void IncFloat (float *out, float *incr);
#pragma aux  IncFloat "*" parm [eax] [ebx]\
                          modify [eax ebx ecx edx esi edi ebp];

#ifdef __cplusplus
  };
#endif

#endif

