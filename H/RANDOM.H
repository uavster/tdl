/* 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
   Include file for random related routines
   컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 */

#ifndef _RANDOM_INCLUDED_
#define _RANDOM_INCLUDED_

#ifdef __cplusplus
  extern "C" {
#endif

// Returns a random value in [0, maxvalue], where maxvalue is in [0, 65535].
int random(int maxvalue);
#pragma aux random "*" parm [eax] \
                            modify [eax ebx ecx edx esi edi ebp]\
                            value [eax];

#ifdef __cplusplus
  };
#endif

#endif

