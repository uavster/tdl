/* 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
   Include file for random related routines
   컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 */

#ifndef _RANDOM_INCLUDED_
#define _RANDOM_INCLUDED_

#ifdef __cplusplus
  extern "C" {
#endif

short int random(short int maxvalue);
#pragma aux random "*" parm [ax] \
                            modify [eax ebx ecx edx esi edi ebp]\
                            value [ax];

#ifdef __cplusplus
  };
#endif

#endif

