;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Loader for 8 bits FLI/FLC files
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / The DarkRising)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
 
JUMPS
.386p
.model flat
.code

        INCLUDE     loader.inc
        INCLUDE     alloc.inc
        INCLUDE     filesys.inc
        INCLUDE     stderror.inc

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Tests if the given file has FLI/FLC animation file format
;
; INPUT  : EDX -> file name
; OUTPUT : CF = 0 if file is PCX type
;               EAX = Frame X size
;               EBX = Frame Y size
;               ECX = Bytes per pixel
;               EDX = Frames
;          CF = 1 if not
;               EAX = Error code (MALLOC_ERROR, FREE_ERROR, INVALID_FORMAT or any FILE_ERROR)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
FLITestFile     proc
        ret
FLITestFile     endp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Reads and decompresses a FLI/FLC file into memory
;
; INPUT  -> EDX -> ASCIIZ file name
;
; OUTPUT -> CF = 0 if success
;               EAX -> Image data buffer
;               EBX = Pointer to 8 bit palette
;           CF = 1 if error
;               EAX = Error code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
LoadFLIFile     proc
        ret
LoadFLIFile     endp

end


