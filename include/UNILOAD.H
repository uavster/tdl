/*
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Loads a 3d world
;
; INPUT  : EAX -> File name
; OUTPUT : CF = 0 if ok
;               EAX -> RENDERWORLD structure
;          CF = 1 if error
;               EAX = Error code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
*/
RENDERWORLD *LoadUniverse(char *);
#pragma aux LoadUniverse "*" parm [eax] \
                             modify [eax ebx ecx edx ebp esi edi] \
                             value [eax];
/*
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Destroys a 3D world
;
; INPUT  : EAX -> RENDERWORLD
;
; OUTPUT : CF = 0 if success
;               EAX = 0
;          CF = 1 if error
;               EAX = Error code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
*/
int DestroyUniverse(RENDERWORLD *);
#pragma aux DestroyUniverse "*" parm [eax] \
                             modify [eax ebx ecx edx ebp esi edi] \
                             value [eax];

