;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; file: dpmi.asm
;
;  DPMI interface routines.
;
;       by C굎ar Guirao Robles, a.k.a. Nitro! / #Trouble# Team
;       (RealCall by Ignacio Mellado Bataller, a.k.a. B52 / #TROUBLE# Team);)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

global  DataSelector    : WORD
global  ProgramPSP      : DWORD
global  EXEName         : DWORD
global  ENVPtr          : DWORD

global  LockMem         : near
global  UnlockMem       : near
global  RealCall        : near
global  RealInterrupt   : near
global  MapMemory       : near
global  RealAddress     : near
global  InitDPMIVariables: NEAR 

global  stack_param     : word
global  RealStackCopy   : dword
global  RealDSSegment   : word
global  RealESSegment   : word
global  RealGSSegment   : word
global  RealFSSegment   : word

RCall   MACRO real_proc
        push    seg real_proc
        push    offset real_proc
        call    RealCall
ENDM
