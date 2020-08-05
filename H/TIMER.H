/* 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
   Include file for timer extensions
   컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 */

#ifndef _TIMER_INCLUDED_
#define _TIMER_INCLUDED_

#ifdef __cplusplus
  extern "C" {
#endif

void enable_timer(float fOldHandlerFreq);
#pragma aux enable_timer "*" parm   [eax] \
                             modify [eax ebx ecx edx esi edi];

void disable_timer(void);
#pragma aux disable_timer "*" modify [eax ebx ecx edx esi edi];

void add_timer(float fFreq, void (*pFn)());
#pragma aux add_timer "*" parm   [eax] [ebx] \
                          modify [eax ebx ecx edx esi edi];

void remove_timer(void (*pFn)());
#pragma aux remove_timer "*" parm   [ebx] \
                             modify [eax ebx ecx edx esi edi];

void force_frequency(float fFreq);
#pragma aux force_frequency "*" parm   [eax] \
                                modify [eax ebx ecx edx esi edi];

#ifdef __cplusplus
  };
#endif

#endif
