#ifndef __IRQ_INCLUDED__
#define __IRQ_INCLUDED__

#ifdef __cplusplus
  extern "C" {
#endif

/*
;-----------------------------------------------------------------
; Returns the InDOS and ErrorMode flags.
;
; If the InDOS flags is not zero, the IRQ can only call DOS
; services 01h thru 0Ch safely. If the ErrorMode flag is not zero,
; the IRQ must not call any DOS services.
;
; OUTPUT:
;   AL = ErrorMode flag
;   AH = InDOS flag
;	Upper EAX word is 0
;	All other registers are preserved
;-----------------------------------------------------------------
*/
int IRQDOSFlags();
#pragma aux IRQDOSFlags "*"	modify [eax ebx ecx edx esi edi ebp]\
							value [eax];

#ifdef __cplusplus
	};
#endif

#endif