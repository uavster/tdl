/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
   Include file for keyboard extensions
   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */

#ifndef _KEYB_INCLUDED_
#define _KEYB_INCLUDED_

#include "stddef.h"

#ifdef __cplusplus
  extern "C" {
#endif

/*
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Sets the routine to be called by a keyboard event

 INPUT : sc  - keyboard scancode
         pFn - routine to be called when the scancode is received
		 If the routine returns !=0, the default keyboard ISR is chained.
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void add_key(int (*pFn)(),char sc);
#pragma aux add_key "*" parm [ebx] [eax]\
                        modify [eax ebx ecx edx ebp esi edi];

/*
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Removes the routine called by a keyboard event

 INPUT : sc - keyboard scancode
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void remove_key(char sc);
#pragma aux remove_key "*"      parm [al]\
                                modify [eax ebx ecx edx ebp esi edi];

/*
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 Tells if the passed key is pressed.

 INPUT : sc - keyboard scancode
 OUTPUT : !=0 if pressed; ==0, otherwise.
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
int is_key_pressed(int sc);
#pragma aux is_key_pressed "*"  parm [eax]\
                                modify [eax]\
								value [eax];

#define Key_Home        0x47
#define Key_Up          0x48
#define Key_PageUp      0x49
#define Key_Left        0x4b
#define Key_Right       0x4d
#define Key_End         0x4f
#define Key_Down        0x50
#define Key_PageDown    0x51
#define Key_ESC         0x1
#define Key_f1          0x3b
#define Key_f2          0x3c
#define Key_f3          0x3d
#define Key_f4          0x3e
#define Key_f5          0x3f
#define Key_f6          0x40
#define Key_f7          0x41
#define Key_f8          0x42
#define Key_f9          0x43
#define Key_f10         0x44
#define Key_f11         0x85
#define Key_f12         0x86
#define Key_SPACE       0x39
#define Key_1			2
#define Key_2			3
#define Key_3			4
#define Key_4			5
#define Key_5			6
#define Key_6			7
#define Key_7			8
#define Key_8			9
#define Key_9			10
#define Key_Q			10h
#define Key_A			1eh
#define Key_W			11h
#define Key_S			1fh

#ifdef __cplusplus
  };
#endif

#endif
