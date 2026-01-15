/* �����������������������������������������������������������
   Include file for virtual frame rate synchronization routines
   ����������������������������������������������������������� */

#ifndef _SYNC_INCLUDED_
#define _SYNC_INCLUDED_

#ifdef __cplusplus
  extern "C" {
#endif

/*
 �����������������������������������������������������������������������������
 Fuerza el controlador de virtual frame rate a funcionar a una frecuencia
 concreta
 INPUT  : freq - Frecuencia a la que se quiere forzar el controlador
 OUTPUT : 0 si ok
          no 0 si error
 �����������������������������������������������������������������������������*/
void  ForceVirtualFrameRate(float freq);
#pragma aux ForceVirtualFrameRate "*" parm   [eax] \
                             modify [eax ebx ecx edx esi edi ebp] \
                             value [eax];

/*
 �����������������������������������������������������������������������������
 Gets elpased time from last call to routine
 �����������������������������������������������������������������������������
*/
void GetElapsedTime(void);
#pragma aux  GetElapsedTime "*" modify [eax ebx ecx edx esi edi ebp];

/*
;�����������������������������������������������������������������������������
; Increments a float with virtual frame rate
;
; INPUT : out  - pointer to a float variable
;         incr - increment
;�����������������������������������������������������������������������������
 */
void IncFloat (float *out, float *incr);
#pragma aux  IncFloat "*" parm [eax] [ebx]\
                          modify [eax ebx ecx edx esi edi ebp];

/*
;�����������������������������������������������������������������������������
; Gets the frequency of the internal VFR timer.
;
; OUTPUT : EAX -> Pointer to timer frequency (float)
;�����������������������������������������������������������������������������
*/
float *GetSyncTimerBaseFreqPtr();
#pragma  aux  GetSyncTimerBaseFreqPtr "*"\
                            value [eax];


#ifdef __cplusplus
  };
#endif

#endif

