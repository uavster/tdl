;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё  [tDR], 1999                                    Copyright the DarkRising
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё                                      Coded by:             B52 & Nitro!
;Ё  SLI routines
;Ё
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё  DATE         REVISION           AUTHOR & COMMENTS
;Ё  дддддддд     ддддддддддддд      дддддддддддддддддддддддддддддддддддддддд
;Ё  18-5-99      Version 1.0        Nitro! : Comienza la comida de tarro
;Ё  20-5-99      1.0 cont.          B52 : Sigue el papeo de olla
;Ё
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
    .386p
    .model  flat
    jumps
    .code
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё  Needed includes
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
    include     newsgl.inc
    include     dpmi.inc
    include     utils.inc
    include     alloc.inc
    include     memcpy.inc
    include     stderror.inc
    include     sli.inc
    include		sync.inc
    include		assert.inc
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё AllocateSLI:         aloja una estructura SLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX = Nёmero de frames
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         CF = 0 si ok
;Ё                              EAX = NULL
;Ё                              EBX = puntero al SLI vac║o
;Ё                      CF = 1 si error
;Ё                              EAX = error code
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
AllocateSLI     proc
                lea     ecx,[size SLI+eax*4]
                push    eax
                call    malloc
                pop     ecx
                ErrorCode MALLOC_ERROR
                lea     eax,[ebx+size SLI]
                mov     [SLI ptr ebx.SLIPImages],eax
                shl     ecx,16
                mov     [SLI ptr ebx.SLITotalFrames],ecx
                xor     eax,eax
                ret
                endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Comprueba que el nёmero de bits del SLI es correcto y lo convierte a bytes
;
; INPUT  : ECX = Nёmero de bits
;
; OUTPUT : CF = 0 si ok
;               ECX = Nёmero de bytes correspondiente
;          CF = 1 si error
;               EAX = Error code (INVALID_COLOR_DEPTH)
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
NormalizeBits   proc
        cmp     ecx,8
        jz      bits_ok
        cmp     ecx,16
        jz      bits_ok
        cmp     ecx,24
        jz      bits_ok
        cmp     ecx,32
        jz      bits_ok
        cmp     ecx,32*3 ; para tablas  !!!!!!!!!!!!!!!!!!!!!!!!!!!!
        jz      bits_ok  ; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        mov     eax,INVALID_COLOR_DEPTH
        stc
        ret
        bits_ok:
        shr     ecx,3
        clc
        ret
NormalizeBits   endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Sets size and default clip
;
; INPUT  : EAX = X size
;          EBX = Y size
;          ECX = Color bytes
;          EDX = Number of frames
;          EDI -> SLI
;
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetDefProperties        proc
        mov     [SLI ptr edi.SLIXSize], eax
        mov     [SLI ptr edi.SLIYSize], ebx
        mov     [SLI ptr edi.SLIPitch], eax
        shl     edx,16
        mov     [SLI ptr edi.SLITotalFrames], edx
        mov		[SLI ptr edi.SLILoopEnd],edx
		sub		[SLI ptr edi.SLILoopEnd],010000h
        shr     edx,16
        mov     [SLI ptr edi.SLIColorBits], ecx
        mov     [edi.SLIPos.SLRR1.SLPX],0
        mov     [edi.SLIPos.SLRR1.SLPY],0
        mov     [edi.SLIClip.SLRR1.SLPX],0
        mov     [edi.SLIClip.SLRR1.SLPY],0
        dec     eax
        dec     ebx
        mov     [edi.SLIPos.SLRR2.SLPX],eax
        mov     [edi.SLIPos.SLRR2.SLPY],ebx
        mov     [edi.SLIClip.SLRR2.SLPX],eax
        mov     [edi.SLIClip.SLRR2.SLPY],ebx
        inc     eax
        inc     ebx
        mov     [SLI ptr edi.SLIRef.SLPX], 0
        mov     [SLI ptr edi.SLIRef.SLPY], 0
        mov     [SLI ptr edi.SLIBlitType], SLIBlitCopy
        mov     [SLI ptr edi.SLIAlpha], 0
        mov     [SLI ptr edi.SLIMask], 0
        mov     [SLI ptr edi.SLIFrame], 0
        mov     [SLI ptr edi.SLIFrameRate], 1 SHL 16
        mov     [SLI ptr edi.SLILitTable], 0
        mov		[SLI ptr edi.SLIAnimMode], 0
        mov		[SLI ptr edi.SLILoopStart], 0
        mov		[SLI ptr edi.SLIPlayingBackwards],0
        ret
SetDefProperties        endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone la lista de punteros a frame
;
; INPUT  : EAX = X size
;          EBX = Y size
;          ECX = Bytes per pixel
;          EDX = Frames
;          EDI -> SLI
;
; OUTPUT : ESI -> First frame
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetFramePointers        proc
        test    edx,edx
        jz      no_frames
        ; Need to set frame pointers
        push    eax ebx ecx edx
        lea     esi,[edi+size SLI]
        mov     [edi.SLIPImages],esi
        mov     ebp,edx
        mul     ebx
        mul     ecx
        mov     ecx,eax
        lea     edx,[esi+ebp*4]
        mov     [edi.SLIFramePtr],edx
        xor     ebx,ebx
        SetFramePtrs:
                mov     [esi+ebx*4],edx
                inc     ebx
                add     edx,ecx
        dec     ebp
        jnz     SetFramePtrs
        pop     edx ecx ebx eax
        mov     esi,[edi.SLIFramePtr]
        no_frames:
        ret
SetFramePointers        endp

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё CreateSLI:           aloja una animaci╒n vacia en SLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX : Size X
;Ё                      EBX : Size Y
;Ё                      ECX : ColorBits
;Ё                      EDX : Number of frames
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         EBX = puntero al SLI or NULL
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
CreateSLI       proc
;mov cbits,ecx
                push    ebp
                call    NormalizeBits
                ErrorCodePOP eax, ebp
                push    eax ebx ecx edx
                mul     edx
                mul     ebx
                mul     ecx

                mov     ecx, eax
                add     ecx, size SLI
                pop     eax
                push    eax
                shl     eax,2
                add     ecx,eax         ; + size LISTA_PUNTEROS_FRAME
                call    malloc
                ErrorCodePOP MALLOC_ERROR, edx ecx ebx eax ebp
                mov     edi, ebx

                pop     edx ecx ebx eax

                call    SetDefProperties
				push	eax ebx ecx edx edi
                call    SetFramePointers
                pop		eax
                push	eax
                ; Start animation at frame 0      
                xor		ebx,ebx 
                call	SetFrame
                pop		edi edx ecx ebx eax
                push    edi

				; Clear frame with zeros
                mov     edi, esi
                mul     edx
                mul     ebx
                mul     ecx
                mov     ecx, eax
                mov     ebx, ecx
                shr     ecx, 2
                xor     eax, eax
                rep     stosd
                mov     ecx, ebx        ; por si acaso no es mёltiplo de 4
                and     ecx,3
                or      ecx,ecx
                jz      no_stosb
                rep     stosb
                no_stosb:

                pop     ebx
                pop     ebp
                clc
                ret
                endp
;cbits dd ?
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё CreateVoidSLI:       aloja una animaci╒n vacia en SLI sin buffer
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX : Size X
;Ё                      EBX : Size Y
;Ё                      ECX : ColorBits
;Ё                      EDX : Number of frames
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         EBX = puntero al SLI
;Ё                      EAX = NULL
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
CreateVoidSLI   proc
                call    NormalizeBits
                ErrorCode eax
                push    eax ebx ecx edx
                mov     eax,edx
                call    AllocateSLI
                ErrorCodePOP eax, edx ecx ebx edi
                mov     edi,ebx
                pop     edx ecx ebx eax
                mov     [SLI ptr edi.SLIFramePtr], 0

                call    SetDefProperties

                mov     ebx,edi
                xor     eax,eax
                clc
                ret
                endp

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё DestroySLI:          libera un SLI de memoria
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX : puntero al SLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         CF = 0 if ok
;Ё                              EAX = NULL
;Ё                      CF = 1 if error
;Ё                              EAX = Error Code
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
DestroySLI      proc
                mov     ebx, eax
                call    free
                ErrorCode FREE_ERROR
                xor     eax,eax
                clc
                ret
                endp

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё CreateVideoSLI:      Crea la superficie de video SLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX : Size X
;Ё                      EBX : Size Y
;Ё                      ECX : ColorBits
;Ё      Nota:           Si ECX+SGL_MemoryBuffer se fuerza a un buffer en
;Ё                      memoria principal
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         CF = 0 if ok
;Ё                              EAX = NULL
;Ё                      CF = 1 if error
;Ё                              EAX = Error Code
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд

.data?
VideoSLI        dd ?

.code
CreateVideoSLI  proc
                push    ebp
                push    eax ebx ecx
                call    SetVideoMode
                pop     ecx ebx eax
                ErrorCodePOP VIDEO_ERROR, ebp
                and     ecx,0ffffh
                call    NormalizeBits
                ErrorCodePOP eax, ebp
                push    eax ebx ecx
                mov     eax,1   ; 1 frame
                call    AllocateSLI
                mov     edi,ebx
                pop     ecx ebx eax
                ErrorCodePOP edi, ebp

                mov     edx,1
                call    SetDefProperties

                call    GetAvailPage
                mov     [SLI ptr edi.SLIFramePtr], eax

                mov     VideoSLI,edi
                xor     eax,eax
                pop     ebp
                clc
                ret
                endp
;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё GetVideoSLI:         Obtiene la superficie de video SLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        nada.
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         EAX : ptr to Video SLI
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
GetVideoSLI     proc
                call    GetAvailPage
                mov     edi, VideoSLI
                mov     [SLI ptr edi.SLIFramePtr], eax
                mov     eax, edi
                ret
                endp

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё DestroyVIdeoSLI:          desaloja el VideoSLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX <> 0 modo de video a seleccionar
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         CF = 0 if ok
;Ё                              EAX = NULL
;Ё                      CF = 1 if error
;Ё                              EAX = Error Code
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
DestroyVideoSLI proc
                push    ebp
                call    UnsetVideoMode
                mov     ebx, VideoSLI
                call    free
                pop     ebp
                ErrorCode FREE_ERROR
                xor     eax,eax
                clc
                ret
                endp

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё ShowVideoSLI:        Muestra la superficie de video SLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        nada.
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         nada.
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
ShowVideoSLI    proc
                push    ebp
                call    ShowPage
                call    GetAvailPage
                mov     edi, VideoSLI
                mov     [SLI ptr edi.SLIFramePtr], eax
                pop     ebp
                ret
                endp

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё SetPalette:          Pone el puntero a una paleta B:G:R:0
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX -> SLI
;Ё                      EBX -> Palette
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         nada.
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetPalette      proc
        test    ebx,ebx
        jz      no_palette
        mov     esi,ebx
        lea     edi,[SLI ptr eax.SLIPalette]
        mov     ecx,256
        rep     movsd
        no_palette:
        ret
        endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Devuelve el nёmero de frame actual
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX = Frame
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
GetFrame        proc
        mov     eax,[eax.SLIFrame]
        shr     eax,16
        ret
GetFrame        endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el nёmero de frame actual
;
; INPUT  : EAX -> SLI
;          EBX = Frame
;
; OUTPUT : CF = 0 si ok
;               EAX = NULL
;          CF = 1 si error
;               EAX = Error code (INVALID_FRAME)
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetFrame		proc
		shl		ebx,16
		call	SetFrameFP16
		ret
		endp
		
SetFrameFP16	proc
		; Reset animation start time
		push	eax
		call	GetSyncTimerTicks
		mov		ecx,eax
		pop		eax
		mov		[eax.SLIStartTicks],ecx
		; Call internal function
		mov		[eax.SLIStartFrame],ebx
		call	SetFrame_
		ret
		endp

SetFrame_       proc
        mov     ecx,[eax.SLITotalFrames]
        cmp     ebx,ecx
        jae     setframe_error

        mov     [eax.SLIFrame],ebx
        shr		ebx,16
        mov     ecx,[eax.SLIPImages]
        mov     edx,[ecx+ebx*4]
        mov     [eax.SLIFramePtr],edx
        xor     eax,eax
        clc
        ret

        setframe_error:
        mov     eax,INVALID_FRAME
        stc
        ret
        endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Sets the frame rate of a multiframe SLI.
;
; INPUT  : EAX -> SLI
;          EBX = Fixed point frame rate in frames per second
;
; OUTPUT : CF = 0 if ok
;				EAX = NULL
;		   CF = 1 if error
;				EAX = Error code				
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetFrameRate    proc
		mov		[eax.SLIFrameRate], ebx
        xor     eax,eax
        clc
        ret
        endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Updates a SLI animation with the current synchronization timer ticks.
;
; INPUT  : ESI -> SLI
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
AnimateSLI	proc
		; cur_frame = start_frame + ((cur_ticks - start_ticks) * frames_per_second) / ticks_per_second
		call	GetSyncTimerTicks
		call	AnimateSLIWithTicks
		ret
		endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Updates a SLI animation with the passed timer ticks.
;
; INPUT  : ESI -> SLI
;		   EAX = Timer ticks
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
AnimateSLIWithTicks	proc
		sub		eax,[esi.SLIStartTicks]		
		mul		[esi.SLIFrameRate]	
		push	eax edx	
		call	GetSyncTimerBaseFreqFixedPoint
		mov		ebx,eax
		pop		edx eax
		; EDX:EAX = (cur_ticks - start_ticks) * (frames_per_second << 16)
		; EBX = ticks_per_second << 16
		shld	edx,eax,16
		shl		eax,16
		; EDX:EAX = ((cur_ticks - start_ticks) * frames_per_second) << 32
		div		ebx
		; EDX:EAX = (((cur_ticks - start_ticks) * frames_per_second) / ticks_per_second) << 16
		; We only take EAX. Therefore, the maximum frame span for 30 fps animation is 65535/30 = 36 min.
		cmp		[esi.SLIPlayingBackwards],0
		jne		play_backwards
			add		eax,[esi.SLIStartFrame]	; Frame # in 16.16 fixed point
			jmp		after_frame_update
		play_backwards:
			sub		eax,[esi.SLIStartFrame]
			neg		eax
		after_frame_update:
		; Prepare EAX and EBX to call SetFrameFP16 and SetFrame_
		mov		ebx,eax
		mov		eax,esi
		; If it's a loop, handle loop ends and resync with timer
		cmp		[esi.SLIAnimMode],SLIAnimNormal
		jne		no_anim_normal
				cmp		ebx,[esi.SLITotalFrames]
				jb		no_resync
						mov	ebx,[esi.SLITotalFrames]
						sub	ebx,010000h
						call SetFrameFP16
						ret
		no_anim_normal:
		cmp		[esi.SLIAnimMode],SLIAnimForwardLoop
		jne		no_fw_loop
				cmp		ebx,[esi.SLILoopEnd]
				jbe		no_resync
						sub	ebx,[esi.SLILoopEnd]
						add ebx,[esi.SLILoopStart]
						call SetFrameFP16												
						ret
		no_fw_loop:
		cmp		[esi.SLIAnimMode],SLIAnimPingPongLoop
		jne		no_resync
				cmp		[esi.SLIPlayingBackwards],0
				jne		pp_loop_bw
						; Forward part of the loop
						cmp		ebx,[esi.SLILoopEnd]
						jle		no_resync
								sub	ebx,[esi.SLILoopEnd]
								neg	ebx
								mov [esi.SLIPlayingBackwards],1
								add ebx,[esi.SLILoopEnd]
								call SetFrameFP16
								ret										
				pp_loop_bw:
						; Backwards part of the loop
						cmp		ebx,[esi.SLILoopStart]
						jge		no_resync
								sub	ebx,[esi.SLILoopStart]
								neg	ebx
								mov	[esi.SLIPlayingBackwards],0
								add ebx,[esi.SLILoopStart]
								call SetFrameFP16										
								ret
		no_resync:
		; No loop ends: set the frame without resyncing with timer
		call	SetFrame_
		ret
		endp
        
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Devuelve el puntero a un frame determinado
;
; INPUT  : EAX -> SLI
;          EBX = Frame
;
; OUTPUT : CF = 0 si ok
;               EAX = NULL
;               EBX -> Frame
;          CF = 1 si el frame no existe
;               EAX = Error code
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
GetFramePtr     proc
        mov     ecx,[eax.SLITotalFrames]
        shr     ecx,16
        cmp     ebx,ecx
        jae     getframe_error
        mov     ecx,[eax.SLIPImages]
        mov     ebx,[ecx+ebx*4]
        clc
        ret

        getframe_error:
        mov     eax,INVALID_FRAME
        stc
        ret
GetFramePtr     endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el puntero a un frame determinado
;
; INPUT  : EAX -> SLI
;          EBX = Nёmero de frame
;          ECX -> Frame
;
; OUTPUT : CF = 0 si ok
;               EAX = NULL
;          CF = 1 si el frame no existe
;               EAX = Error code
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetFramePtr     proc
        mov     edx,[eax.SLITotalFrames]
        shr     edx,16
        cmp     ebx,edx
        jae     setframeptr_error
        mov     edx,[eax.SLIPImages]
        mov     [edx+ebx*4],ecx
        clc
        ret

        setframeptr_error:
        mov     eax,INVALID_FRAME
        stc
        ret
SetFramePtr     endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Devuelve el puntero al frame actual
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX -> Frame actual
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
GetCurrentFramePtr      proc
        mov     eax,[eax.SLIFramePtr]
        ret
GetCurrentFramePtr      endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el color de m═scara
;
; INPUT : EAX -> SLI
;         EBX = Color de m═scara en formato B:G:R:0
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetMaskColor    proc
        mov     [eax.SLIMask],ebx
        ret
SetMaskColor    endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el m┌todo de blitting
;
; INPUT : EAX -> SLI
;         EBX = Tipo de blit ('SLIBlitCopy', 'SLIBlitAlpha', 'SLIBlitAlphaMap'
;                             y los mismos con '+ SLIMaskedColor' para poner
;                             con m═scara)
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetBlitType     proc
        mov     [SLI ptr eax.SLIBlitType],ebx
        ret
SetBlitType     endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el rect═ngulo de clipping
;
; INTPUT : EAX = x1
;          EBX = y1
;          ECX = x2
;          EDX = y2
;          EDI -> SLI
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetClip         proc
        mov     [edi.SLIClip.SLRR1.SLPX],eax
        mov     [edi.SLIClip.SLRR1.SLPY],ebx
        mov     [edi.SLIClip.SLRR2.SLPX],ecx
        mov     [edi.SLIClip.SLRR2.SLPY],edx
        ret
SetClip         endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Desplaza el rect═ngulo de destino al punto especificado
;
; INPUT : EAX = x1
;         EBX = y1
;         EDI -> SLI
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetPos         proc
        mov     ecx,[edi.SLIPos.SLRR2.SLPX]
        sub     ecx,[edi.SLIPos.SLRR1.SLPX]
        mov     edx,[edi.SLIPos.SLRR2.SLPY]
        sub     edx,[edi.SLIPos.SLRR1.SLPY]
        mov     [edi.SLIPos.SLRR1.SLPX],eax
        mov     [edi.SLIPos.SLRR1.SLPY],ebx
        add     eax,ecx
        add     ebx,edx
        mov     [edi.SLIPos.SLRR2.SLPX],eax
        mov     [edi.SLIPos.SLRR2.SLPY],ebx
        ret
SetPos         endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Devuelve las dimensiones (con escalado) del SLI
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX = X size
;          EBX = Y size
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
GetDimensions   proc
        mov     ecx,eax
        mov     eax,[ecx.SLIPos.SLRR2.SLPX]
        sub     eax,[ecx.SLIPos.SLRR1.SLPX]
        mov     ebx,[ecx.SLIPos.SLRR2.SLPY]
        sub     ebx,[ecx.SLIPos.SLRR1.SLPY]
        inc     eax
        inc     ebx
        ret
GetDimensions   endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el campo de alpha
;
; INPUT : EAX -> SLI
;         EBX = Alpha constante o puntero al mapa de alphas
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetAlpha        proc
        mov     [SLI ptr eax.SLIAlpha],ebx
        ret
SetAlpha        endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el modo de animaciСn
;
; INPUT : EAX -> SLI
;         BL = Modo de animaciСn
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetAnimMode proc
		movzx	ebx,bl
		AssertD ebx,_leu,SLIAnimPingPongLoop
		mov		[eax.SLIAnimMode],bl
		ret
SetAnimMode endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el inicio del loop de animaciСn
;
; INPUT : EAX -> SLI
;         EBX = Frame inicial del loop
; OUTPUT: CF = 0 si ok
;         CF = 1 si error
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetAnimLoopStartFrame	proc
		shl	ebx,16
		cmp	ebx,[eax.SLITotalFrames]
		jb salsf_not_above_upper_limit
			mov	ebx,[eax.SLITotalFrames]
			sub	ebx,010000h
			mov [eax.SLILoopStart],ebx
			stc
			ret
		salsf_not_above_upper_limit:
		mov [eax.SLILoopStart],ebx
		clc
		ret
SetAnimLoopStartFrame	endp

;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
; Pone el final del loop de animaciСn
;
; INPUT : EAX -> SLI
;         EBX = Frame final del loop
; OUTPUT: CF = 0 si ok
;         CF = 1 si error
;ддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
SetAnimLoopEndFrame	proc
		shl	ebx,16
		cmp	ebx,[eax.SLITotalFrames]
		jb salef_not_above_upper_limit
			mov	ebx,[eax.SLITotalFrames]
			sub	ebx,010000h
			mov [eax.SLILoopEnd],ebx
			stc
			ret
		salef_not_above_upper_limit:
		mov [eax.SLILoopEnd],ebx
		clc
		ret
SetAnimLoopEndFrame	endp

;здддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё ClearCurrentFrame:   Borra el frame actual al color dado
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Entrada:        EAX -> SLI
;Ё                      EBX -> color en el formato del SLI
;цдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
;Ё      Salida:         nada.
;юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд
ClearCurrentFrame       proc
        mov     ecx, [SLI ptr eax.SLIColorBits]
        mov     edi, [SLI ptr eax.SLIFramePtr]
        mov     esi, [SLI ptr eax.SLIYSize]
        imul    esi, [SLI ptr eax.SLIXSize]

        cmp     ecx, 3
        jne     CCF000

        mov     edx, ebx
        shr     edx, 16
    CCF003:
        mov     [edi], bx
        mov     [edi+2], dl
        add     edi, 3
        dec     esi
        jnz     CCF003
        ret
    CCF000:
        cmp     ecx, 1
        jne     CCF001
        mov     eax, ebx
        shl     eax, 8
        mov     al, bl
        shl     eax, 8
        mov     al, bl
        shl     eax, 8
        mov     al, bl

        mov     ecx, esi
        push    ecx
        shr     ecx, 2
        rep     stosd
        pop     ecx
        and     ecx, 11b
        or      ecx, ecx
        jz      CCF004
        rep     stosb
    CCF004:
        ret

    CCF001:
        cmp     ecx, 2
        jne     CCF002
        mov     eax, ebx
        shl     eax, 16
        mov     ax, bx

        mov     ecx, esi
        push    ecx
        shr     ecx, 1
        rep     stosd
        pop     ecx
        and     ecx, 1b
        or      ecx, ecx
        jz      CCF005
        rep     stosw
    CCF005:
        ret
    CCF002:
        mov     eax, ebx
        mov     ecx, esi
        rep     stosd
        ret
        endp

END
