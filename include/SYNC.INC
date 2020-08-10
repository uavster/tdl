;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Definiciones y macros de sincronismo
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

INCLUDE sync.def
;INCLUDE sgl.inc

; --------------------------MACROS DE SINCRONISMO-----------------------------
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Espera un punto de sincronismo deteniendo la ejecuci¢n
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WaitSync        MACRO
LOCAL   wait_sync
        wait_sync:
if MUSIC
        call    Check4Sync
        jc      wait_sync
        dec     eax
        jnz     wait_sync
else
        if KEYSYNC
                test    changeFX,1
                jz      wait_sync
                mov     changeFX,0
        endif
endif
ENDM

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Si se ha pasado un punto de sincronismo, pone a 1 el flag indicado
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WaitSyncFlag    MACRO flag
LOCAL   wait_sync,sync_end,sync_flag,callit,sync_ends_after_call
if MUSIC
        call    Check4Sync
        jc      sync_end
        dec     eax
        jnz     sync_end
else
        if KEYSYNC
                test    changeFX,1
                jz      sync_end
                mov     changeFX,0
        endif
endif
        callit:
                mov     flag,1
        sync_end:
ENDM

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; A partir de un punto de sincronismo se ejecuta la rutina cada vez que
; se pasa por la macro
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WaitSyncExec   MACRO address
LOCAL   wait_sync,sync_end,sync_flag,callit,sync_ends_after_call
        test    sync_flag,1
        jnz     callit
        jmp     wait_sync
                sync_flag       db 0
        wait_sync:
if MUSIC
        call    Check4Sync
        jc      sync_end
        dec     eax
        jnz     sync_end
        mov     sync_flag,1
else
        if KEYSYNC
                test    changeFX,1
                jz      sync_end
                mov     sync_flag,1
                mov     changeFX,0
        endif
endif
        callit:
                call    address
                jmp     sync_ends_after_call
        sync_end:
        clc
        sync_ends_after_call:
ENDM

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; A partir de un punto de sincronismo, se ejecuta la rutina una sola vez
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WaitSyncExecOnce   MACRO address
LOCAL   wait_sync,sync_end,sync_flag,callit,sync_ends_after_call
if MUSIC
        call    Check4Sync
        jc      sync_end
        dec     eax
        jnz     sync_end
else
        if KEYSYNC
                test    changeFX,1
                jz      sync_end
                mov     changeFX,0
        endif
endif
        callit:
                call    address
                jmp     sync_ends_after_call
        sync_end:
        clc
        sync_ends_after_call:
ENDM

; --------------------------MACROS DE VIRTUAL FRAME RATE----------------------
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Macro para incrementar contadores a un framerate constante (virtual)
;
; Par metros:
;       TIMEADD    contador,incremento
;
; Descripci¢n:
;       Suma el incremento al contador en cada frame. Si han pasado N frames
; le sumar  INCREMENTO * N.
;       NOTA: los flags los devuelve como los de una suma normal.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
timeadd    MACRO counter,increment
LOCAL   prev_time,skip_prev_time,first_time_execution,skip_virtual_control
        jmp     skip_prev_time
first_time_execution    db 0
prev_time               dd 0
        skip_prev_time:
        push    eax ecx edx
        mov     eax,increment
        test    first_time_execution,1  ; si no se ha ejecutado nunca...
        jz      skip_virtual_control    ; ...no tenemos datos de tiempo previo
                mov     ecx,time
                sub     ecx,prev_time   ; EAX = variaci¢n de tiempo
                mul     ecx
        skip_virtual_control:
        add     counter,eax
        mov     first_time_execution,1  ; se ha ejecutado ya una vez
        mov     eax,time
        mov     prev_time,eax           ; nos guardamos el tiempo
        pop     edx ecx eax
ENDM

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Macro para decrementar contadores a un framerate constante (virtual)
;
; Par metros:
;       TIMESUB    contador,decremento
;
; Descripci¢n:
;       Resta el incremento al contador en cada frame. Si han pasado N frames
; le restar  DECREMENTO * N.
;       NOTA: los flags los devuelve como los de una resta normal.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
timesub    MACRO counter,increment,safe
LOCAL   prev_time,skip_prev_time,first_time_execution,skip_virtual_control
FT_VAR_POS=$
        jmp     skip_prev_time
FT_VAR_POS=$-FT_VAR_POS
first_time_execution    db 0
prev_time               dd 0
        skip_prev_time:
        push    eax ecx edx
        mov     eax,increment
        test    first_time_execution,1  ; si no se ha ejecutado nunca...
        jz      skip_virtual_control    ; ...no tenemos datos de tiempo previo
                mov     ecx,time
                sub     ecx,prev_time   ; EAX = variaci¢n de tiempo
                mul     ecx
        skip_virtual_control:
        sub     counter,eax
        mov     first_time_execution,1  ; se ha ejecutado ya una vez
        mov     eax,time
        mov     prev_time,eax           ; nos guardamos el tiempo
        pop     edx ecx eax
ENDM

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Resetea la cuenta de frames de una macro 'timeadd' o 'timesub'
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
timereset       MACRO macro_entry_point
        mov     byte ptr macro_entry_point+FT_VAR_POS,0
ENDM

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Inicializa el contador de frames a la frecuencia del refresco de pantalla
;
; INPUT  -> AL = Screen sync. flag
;                (0 : don't synchronize , 1 : synchronize with vert. retrace)
;
; OUTPUT -> CF = 0 if success
;           CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  InitVirtualFrameRate: NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Fuerza el controlador de virtual frame rate a funcionar a una frecuencia
; concreta
; INPUT  -> EAX = 32 bit floating point frequency
; OUTPUT -> CF = 0 if success
;           CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  ForceVirtualFrameRate: NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the frequency of the internal VFR timer.
;
; OUTPUT : EAX -> Timer frequency (float)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global	GetSyncTimerBaseFreqFloat: NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the frequency of the internal VFR timer.
;
; OUTPUT : EAX -> Timer frequency (fixed point 16.16)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global	GetSyncTimerBaseFreqFixedPoint: NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the elapsed ticks since the internal VFR timer was started.
;
; OUTPUT : EAX -> Timer ticks
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global	GetSyncTimerTicks: NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Finaliza el controlador de virtual frame rate
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  EndVirtualFrameRate: NEAR

global  GetElapsedTime: NEAR

global  IncFloat: NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Contador de frames
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  time: DWORD

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Macro de tratamiento est ndar de error de sincronismo bajo Win95+
; OUTPUT -> CF = 0 if user wants to continue
;           CF = 1 if user wants to abort execution
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Win95SyncError  MACRO
LOCAL   skip_err_msg,win95err_msg
        mov     eax,3
        call    UnsetVideoMode
        mov     esi,offset win95err_msg
        call    printf
        wait_answer:
                xor     ah,ah
                int     16h
                cmp     al,'y'
                jz      continue
                cmp     al,'Y'
                jz      continue
                cmp     al,'n'
                jz      abort_exec
                cmp     al,'N'
                jz      abort_exec
        jmp     wait_answer
        continue:
        movf    eax,70.0
        call    ForceVirtualFrameRate
        ErrorExit "Error: Unable to initialize Virtual Frame Rate system"
        clc
        jmp     skip_err_msg
        abort_exec:
        stc
        jmp     skip_err_msg
win95err_msg    db "The program is unable to determine the video refresh rate for 320x200x16bit mode",13,10
                db "This is probably because you are under a system like Windows 95 or later which",13,10
                db "is virtualizing the ports.",13,10,10
                db "If you choose to continue, a refresh rate of 70.0 Hz will be assumed and maybe",13,10
                db "you will see problems with synchronization during the demo or it will fail.",13,10
                db "If it happens, please run the demo in DOS mode by resetting your machine or by",13,10
                db "creating a direct access for DOS mode under Windows 95+.",13,10,10
                db "Do you want to continue? (Y/N) ",0
        skip_err_msg:
ENDM
