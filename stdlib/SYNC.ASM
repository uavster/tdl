;�����������������������������������������������������������������������������
; Rutinas de sincronismo para frame rate virtual
;�����������������������������������������������������������������������������
.386p
.model flat
.code
        INCLUDE timer.inc
        INCLUDE sgl.inc
        INCLUDE utils.inc
        INCLUDE sync.inc

        DEFAULT_TIMMING EQU 100.0

;�����������������������������������������������������������������������������
; Inicializa el contador de frames a la frecuencia del refresco de pantalla
;  si AL es 1, o a 100 Hz si AL es 0.
;
; INPUT  -> AL = Screen sync. flag
;                (0 : don't synchronize , 1 : synchronize with vert. retrace)
;
; OUTPUT -> CF = 0 if success
;           CF = 1 if error
;               AL = error code
;                       01h - no room for timers
;                       02h - sync error (we are under Windows 95+)
;�����������������������������������������������������������������������������
InitVirtualFrameRate    proc
        mov     vr_sync,al
        movf    eax,18.2
        call    enable_timer
        mov     al,1
        jc      init_error
        test    vr_sync,1
        jz      dont_sync
        ; contamos el tiempo que tarda el refresco de pantalla
        movf    eax,10000.0     ; 10 Khz
        mov     ebx,offset frame_count
        call    add_timer
        mov     al,1
        jc      init_error

        ; contamos el tiempo entre dos principios de retrazo vertical
        VerticalREnd
        VerticalRStart
        ; tiempo a 0
        mov     time,0
        ; sincronizamos con el timer
        mov     ebx,offset frame_count
        call    sync_timer
        VerticalREnd
        VerticalRStart
        mov     eax,time
        mov     ticks,eax
        mov     ebx,offset frame_count
        call    remove_timer

        ; ponemos el contador de refrescos a la frecuencia aproximada
        ; (no tiene por qu� ir sincronizado con el retrazo)
        ; frec. = 10KHz / num.ticks
        fldf    10000.0
        fidiv   ticks
        fst     ticks
        fistp   temp
        cmp     temp,INCORRECT_SRF_UPPER
        mov     al,2
        ja      init_error
        cmp     temp,INCORRECT_SRF_LOWER
        mov     al,2
        jb      init_error
        mov     eax,ticks
        call    ForceVirtualFrameRate
        jc      init_error
        clc
        ret

        dont_sync:
        movf    eax,DEFAULT_TIMMING
        mov     ebx,offset frame_count
        call    add_timer
        mov     al,1
        jc      init_error
        movf	eax,DEFAULT_TIMMING
        call	SetSyncTimerBaseFreqFloat
        ret

        init_error:
        push    eax
        call    disable_timer
        pop     eax
        stc
        ret
ticks           dd ?
temp            dd ?
vr_sync         db ?
InitVirtualFrameRate    endp

;�����������������������������������������������������������������������������
; Fuerza el controlador de virtual frame rate a funcionar a una frecuencia
; concreta
; INPUT  -> EAX = 32 bit floating point frequency
; OUTPUT -> CF = 0 if success
;               EAX = 0
;           CF = 1 if error
;               EAX = no 0
;�����������������������������������������������������������������������������
ForceVirtualFrameRate   proc
        push    eax
        mov     ebx,offset frame_count
        call    remove_timer
        pop     eax
        test    vr_sync,1
        jz      dont_wait_vr
        push    eax
        VerticalRStart
        VerticalREnd
        pop     eax
        dont_wait_vr:
        mov     time,0
        mov     ebx,offset frame_count
        push	eax
        call    add_timer
        pop		eax
        jc      force_error
        call	SetSyncTimerBaseFreqFloat
        xor     eax,eax
        clc
        ret

        force_error:
        mov     eax,-1
        stc
        ret
ForceVirtualFrameRate   endp

;�����������������������������������������������������������������������������
; Finaliza el controlador de virtual frame rate
; OUTPUT -> CF = 0, if success
; 			CF = 1, if error
; 				EAX = Error code
;�����������������������������������������������������������������������������
EndVirtualFrameRate     proc
        call    disable_timer
        ret
EndVirtualFrameRate     endp

;�����������������������������������������������������������������������������
; Contador de frames
;�����������������������������������������������������������������������������
frame_count   proc
        inc     time
        ret
time    dd 0
frame_count   endp

;�����������������������������������������������������������������������������
; Gets elpased time from last call to routine
;�����������������������������������������������������������������������������
GetElapsedTime  proc
        mov     eax,time
        sub     eax,TimeStamp
        mov     ElapsedTime,eax
        mov     eax,time
        mov     TimeStamp,eax
        ret
GetElapsedTime  endp

;�����������������������������������������������������������������������������
; Increments a float with virtual frame rate
;
; INPUT : EAX -> Float
;         EBX -> Float increment
;�����������������������������������������������������������������������������
IncFloat        proc
        fld     dword ptr [ebx] ; (Watcom compatibility)
        fimul   ElapsedTime
        fadd    dword ptr [eax]
        fstp    dword ptr [eax]
        ret
IncFloat        endp

;�����������������������������������������������������������������������������
; Gets the frequency of the internal VFR timer.
;
; OUTPUT : EAX -> Timer frequency (float)
;�����������������������������������������������������������������������������
GetSyncTimerBaseFreqFloat	proc
		movf	eax,VFRFreqFloat
		ret
GetSyncTimerBaseFreqFloat	endp

;�����������������������������������������������������������������������������
; Gets the frequency of the internal VFR timer.
;
; OUTPUT : EAX -> Pointer to timer frequency (float)
;�����������������������������������������������������������������������������
GetSyncTimerBaseFreqPtr proc
  mov eax, offset VFRFreqFloat
  ret
GetSyncTimerBaseFreqPtr endp

;�����������������������������������������������������������������������������
; Stores the frequency of the internal VFR timer in float (VFRFreqFloat), and
; fixed point 16.16 format (VFRFreqFixedPoint).
;
; INPUT : EAX -> Timer frequency (float)
;�����������������������������������������������������������������������������
SetSyncTimerBaseFreqFloat	proc
		mov		VFRFreqFloat,eax
		fld		VFRFreqFloat
		mov		VFRFreqFixedPoint,010000h
		fimul	VFRFreqFixedPoint
		fistp	VFRFreqFixedPoint
		ret
SetSyncTimerBaseFreqFloat	endp

;�����������������������������������������������������������������������������
; Gets the frequency of the internal VFR timer.
;
; OUTPUT : EAX -> Timer frequency (fixed point 16.16)
;�����������������������������������������������������������������������������
GetSyncTimerBaseFreqFixedPoint	proc
		mov		eax,VFRFreqFixedPoint
		ret
GetSyncTimerBaseFreqFixedPoint	endp

;�����������������������������������������������������������������������������
; Gets the elapsed ticks since the internal VFR timer was started.
;
; OUTPUT : EAX -> Timer ticks
;�����������������������������������������������������������������������������
GetSyncTimerTicks	proc
		mov		eax,time
		ret
GetSyncTimerTicks	endp

.data
TimeStamp       dd 0
ElapsedTime     dd 0
VFRFreqFloat	dd 0
VFRFreqFixedPoint dd 0

.data?
trash           dd ?

end
