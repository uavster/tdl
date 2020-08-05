;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; 3D object loader
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / The DarkRising)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.386p
.model flat
.code

        INCLUDE uniload.inc
        INCLUDE 3ds.inc
        INCLUDE stderror.inc
        INCLUDE 3d.inc

NUM_UNIVERSE_LOAD_PROCS EQU 1
UNIVERSE_LOAD_PROCS     EQU offset Procs3DS

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Loads a 3d world
;
; INPUT  : EAX -> File name
; OUTPUT : CF = 0 if ok
;               EAX -> RENDERWORLD structure
;          CF = 1 if error
;               EAX = NULL
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
LoadUniverse    proc
        push    ebp
        mov     edx,eax
        mov     ecx,NUM_UNIVERSE_LOAD_PROCS
        xor     esi,esi
        search_format:
                mov     eax,[esi*4+UniverseLoadProcs]
                push    ecx esi eax edx
                call    [eax.UNITestProc]
                pop     edx eax esi ecx
                jnc     found_format
                inc     esi
        loop    search_format
        mov     eax,INVALID_FORMAT
        pop     ebp
        xor     eax,eax
        stc
        ret

        found_format:
        ; We've found the file format
        push    [eax.UNIEndProc]
        call    [eax.UNILoadProc]
        pop     ebx
        jc      error_loading
                mov     [eax.WorldDestructor],ebx   ; EAX -> RENDERWORLD
        pop     ebp
        ret

        error_loading:
        xor     eax,eax
        pop     ebp
        ret
LoadUniverse    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Destroys a 3D world
;
; INPUT  : EAX -> RENDERWORLD
;
; OUTPUT : CF = 0 if success
;               EAX = 0
;          CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DestroyUniverse proc
        push    ebp
        call    [eax.WorldDestructor]
        pop     ebp
        ret
DestroyUniverse endp

UniverseLoadProcs       dd UNIVERSE_LOAD_PROCS
end 
