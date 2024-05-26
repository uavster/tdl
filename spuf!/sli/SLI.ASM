;���������������������������������������������������������������������������
;�  [tDR], 1999                                    Copyright the DarkRising
;���������������������������������������������������������������������������
;�                                      Coded by:             B52 & Nitro!
;�  SLI routines
;�
;���������������������������������������������������������������������������
;�  DATE         REVISION           AUTHOR & COMMENTS
;�  ��������     �������������      ����������������������������������������
;�  18-5-99      Version 1.0        Nitro! : Comienza la comida de tarro
;�  20-5-99      1.0 cont.          B52 : Sigue el papeo de olla
;�
;���������������������������������������������������������������������������
;���������������������������������������������������������������������������
    .386p
    .model  flat
    jumps
    .code
;���������������������������������������������������������������������������
;���������������������������������������������������������������������������
;�  Needed includes
;���������������������������������������������������������������������������
;���������������������������������������������������������������������������
    include     newsgl.inc
    include     dpmi.inc
    include     utils.inc
    include     alloc.inc
    include     memcpy.inc
    include     stderror.inc
    include     sli.inc
    include		sync.inc
    include		assert.inc
;���������������������������������������������������������������������������
;���������������������������������������������������������������������������
;� AllocateSLI:         aloja una estructura SLI
;���������������������������������������������������������������������������
;�      Entrada:        EAX = N�mero de frames
;���������������������������������������������������������������������������
;�      Salida:         CF = 0 si ok
;�                              EAX = NULL
;�                              EBX = puntero al SLI vac�o
;�                      CF = 1 si error
;�                              EAX = error code
;���������������������������������������������������������������������������
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

;�����������������������������������������������������������������������������
; Comprueba que el n�mero de bits del SLI es correcto y lo convierte a bytes
;
; INPUT  : ECX = N�mero de bits
;
; OUTPUT : CF = 0 si ok
;               ECX = N�mero de bytes correspondiente
;          CF = 1 si error
;               EAX = Error code (INVALID_COLOR_DEPTH)
;�����������������������������������������������������������������������������
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

;�����������������������������������������������������������������������������
; Sets size and default clip
;
; INPUT  : EAX = X size
;          EBX = Y size
;          ECX = Color bytes
;          EDX = Number of frames
;          EDI -> SLI
;
;�����������������������������������������������������������������������������
SetDefProperties        proc
        mov     [SLI ptr edi.SLIXSize], eax
        mov     [SLI ptr edi.SLIYSize], ebx
        push    eax
        imul    eax,ecx
        mov     [SLI ptr edi.SLIPitch], eax
        pop     eax
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
		mov		[SLI ptr edi.SLISBufferNfo],0
		mov		[SLI ptr edi.SLIIntegralImage],0
        ret
SetDefProperties        endp

;�����������������������������������������������������������������������������
; Pone la lista de punteros a frame
;
; INPUT  : EAX = X size
;          EBX = Y size
;          ECX = Bytes per pixel
;          EDX = Frames
;          EDI -> SLI
;		   ESI = Pointer to memory block holding all frames data. If NULL, 
;				 the SLI header will point to the memory right after the
;				 header and the frame pointer array.
;
; OUTPUT : ESI -> First frame
;�����������������������������������������������������������������������������
SetFramePointers        proc
        test    edx,edx
        jz      no_frames
		push	ebp
        ; Need to set frame pointers
        push    eax ebx ecx edx
		lea		edx,[edi+size SLI]
        mov		[edi.SLIPImages],edx
		pop		edx
		push	edx
        mov     ebp,edx
        mul     ebx
        mul     ecx
        mov     ecx,eax
		mov		eax,[edi.SLIPImages]
		; Set frame pointers to passed memory block, or to area after header if not passed. 
		test	esi,esi
		jz		no_ptr_given
				mov		edx,esi
				jmp		set_ptr_to_frames
		no_ptr_given:
				lea     edx,[eax+ebp*4]
		set_ptr_to_frames:
        mov     [edi.SLIFramePtr],edx
        xor     ebx,ebx
        SetFramePtrs:
                mov     [eax+ebx*4],edx
                inc     ebx
                add     edx,ecx
        dec     ebp
        jnz     SetFramePtrs
        pop     edx ecx ebx eax
        mov     esi,[edi.SLIFramePtr]
		pop		ebp
        no_frames:
        ret
SetFramePointers        endp

;���������������������������������������������������������������������������
;� CreateSLI:           aloja una animaci�n vacia en SLI
;���������������������������������������������������������������������������
;�      Entrada:        EAX : Size X
;�                      EBX : Size Y
;�                      ECX : ColorBits
;�                      EDX : Number of frames
;���������������������������������������������������������������������������
;�      Salida:         EBX = puntero al SLI or NULL
;���������������������������������������������������������������������������
CreateSLI       proc
;mov cbits,ecx
                push    ebp ebx
                call    NormalizeBits
				mov		ebx,0
                ErrorCodePOP eax, ecx ebp
				pop		ebx
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
				xor		esi,esi
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
                mov     ecx, ebx        ; por si acaso no es m�ltiplo de 4
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
;���������������������������������������������������������������������������
;� CreateVoidSLI:       aloja una animaci�n vacia en SLI sin buffer
;���������������������������������������������������������������������������
;�      Entrada:        EAX : Size X
;�                      EBX : Size Y
;�                      ECX : ColorBits
;�                      EDX : Number of frames
;���������������������������������������������������������������������������
;�      Salida:         EBX = puntero al SLI
;�                      EAX = NULL
;���������������������������������������������������������������������������
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

;���������������������������������������������������������������������������
;� SetFrameData:       Set frame pointers to the given memory buffer. 
;					   The memory is owned by the caller and must be large
;					   enough to hold all frames.
;					   Frames must be contiguous in memory.
;���������������������������������������������������������������������������
;�      Entrada:        EDI : SLI pointer
;						ESI : Pointer to frame memory.
;���������������������������������������������������������������������������
SetFrameData	proc
				mov		eax,[SLI ptr edi.SLIXSize]
				mov		ebx,[SLI ptr edi.SLIYSize]
				mov		ecx,[SLI ptr edi.SLIColorBits]		; SLIColorBits is actualy bytes per pixel
				mov		edx,[SLI ptr edi.SLITotalFrames]	; Number of frames is 16.16
				shr		edx,16
				call	SetFramePointers
				ret
				endp

DestroyIntegralImage proc
        mov		ebx,[SLI ptr eax.SLIIntegralImage]
        test	ebx,ebx
        jz		no_integral_image
            call	free
            ErrorCode FREE_ERROR
        no_integral_image:
        ret
endp

;���������������������������������������������������������������������������
;� DestroySLI:          libera un SLI de memoria
;���������������������������������������������������������������������������
;�      Entrada:        EAX : puntero al SLI
;���������������������������������������������������������������������������
;�      Salida:         CF = 0 if ok
;�                              EAX = NULL
;�                      CF = 1 if error
;�                              EAX = Error Code
;���������������������������������������������������������������������������
DestroySLI      proc
				; Free the SBuffer structure if allocated
				mov		ebx,[SLI ptr eax.SLISBufferNfo]
				or		ebx,ebx
				jz		no_sbuffer
						push	eax
						call	free
						pop		eax
						ErrorCode FREE_ERROR
				no_sbuffer:
				; Free the integral image.
        push  eax
        call  DestroyIntegralImage
        pop   ebx
        call    free
        ErrorCode FREE_ERROR
        xor     eax,eax
        clc
        ret
        endp

;���������������������������������������������������������������������������
;� CreateVideoSLI:      Crea la superficie de video SLI
;���������������������������������������������������������������������������
;�      Entrada:        EAX : Size X
;�                      EBX : Size Y
;�                      ECX : ColorBits
;�      Nota:           Si ECX+SGL_MemoryBuffer se fuerza a un buffer en
;�                      memoria principal
;���������������������������������������������������������������������������
;�      Salida:         CF = 0 if ok
;�                              EAX = NULL
;�                      CF = 1 if error
;�                              EAX = Error Code
;���������������������������������������������������������������������������

.data
VideoSLI        dd 0

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
;���������������������������������������������������������������������������
;� GetVideoSLI:         Obtiene la superficie de video SLI
;���������������������������������������������������������������������������
;�      Entrada:        nada.
;���������������������������������������������������������������������������
;�      Salida:         EAX : ptr to Video SLI
;���������������������������������������������������������������������������
GetVideoSLI     proc
                call    GetAvailPage
                mov     edi, VideoSLI
                mov     [SLI ptr edi.SLIFramePtr], eax
                mov     eax, edi
                ret
                endp

;���������������������������������������������������������������������������
;� DestroyVIdeoSLI:          desaloja el VideoSLI
;���������������������������������������������������������������������������
;�      Entrada:        EAX <> 0 modo de video a seleccionar
;���������������������������������������������������������������������������
;�      Salida:         CF = 0 if ok
;�                              EAX = NULL
;�                      CF = 1 if error
;�                              EAX = Error Code
;���������������������������������������������������������������������������
DestroyVideoSLI proc
                push    ebp
                call    UnsetVideoMode
                mov     ebx, VideoSLI
				test	ebx,ebx
				jz		skip_free
						call    free
				skip_free:
                pop     ebp
                ErrorCode FREE_ERROR
                xor     eax,eax
                clc
                ret
                endp

;���������������������������������������������������������������������������
;� ShowVideoSLI:        Muestra la superficie de video SLI
;���������������������������������������������������������������������������
;�      Entrada:        nada.
;���������������������������������������������������������������������������
;�      Salida:         nada.
;���������������������������������������������������������������������������
ShowVideoSLI    proc
                push    ebp
                call    ShowPage
                call    GetAvailPage
                mov     edi, VideoSLI
                mov     [SLI ptr edi.SLIFramePtr], eax
                pop     ebp
                ret
                endp

;���������������������������������������������������������������������������
;� SetPalette:          Pone el puntero a una paleta B:G:R:0
;���������������������������������������������������������������������������
;�      Entrada:        EAX -> SLI
;�                      EBX -> Palette
;���������������������������������������������������������������������������
;�      Salida:         nada.
;���������������������������������������������������������������������������
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

;�����������������������������������������������������������������������������
; Devuelve el n�mero total de frames
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EBX = N�mero de frames
;�����������������������������������������������������������������������������
GetNumFrames	proc
		mov 	ebx,[eax.SLITotalFrames]
        shr     ebx,16
		ret
GetNumFrames	endp

;�����������������������������������������������������������������������������
; Devuelve el n�mero de frame actual
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX = Frame
;�����������������������������������������������������������������������������
GetFrame        proc
        mov     eax,[eax.SLIFrame]
        shr     eax,16
        ret
GetFrame        endp

;�����������������������������������������������������������������������������
; Pone el n�mero de frame actual
;
; INPUT  : EAX -> SLI
;          EBX = Frame
;
; OUTPUT : CF = 0 si ok
;               EAX = NULL
;          CF = 1 si error
;               EAX = Error code (INVALID_FRAME)
;�����������������������������������������������������������������������������
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

        push    eax
        call    DestroyIntegralImage
        pop     eax
        mov     [eax.SLIIntegralImage],0
        
        xor     eax,eax
        clc
        ret

        setframe_error:
        mov     eax,INVALID_FRAME
        stc
        ret
        endp

;�����������������������������������������������������������������������������
; Sets the frame rate of a multiframe SLI.
;
; INPUT  : EAX -> SLI
;          EBX = Fixed point frame rate in frames per second
;
; OUTPUT : CF = 0 if ok
;				EAX = NULL
;		   CF = 1 if error
;				EAX = Error code				
;�����������������������������������������������������������������������������
SetFrameRate    proc
		mov		[eax.SLIFrameRate], ebx
        xor     eax,eax
        clc
        ret
        endp

;�����������������������������������������������������������������������������
; Updates a SLI animation with the current synchronization timer ticks.
;
; INPUT  : ESI -> SLI
;�����������������������������������������������������������������������������
AnimateSLI	proc
		; cur_frame = start_frame + ((cur_ticks - start_ticks) * frames_per_second) / ticks_per_second
		call	GetSyncTimerTicks
		call	AnimateSLIWithTicks
		ret
		endp

;�����������������������������������������������������������������������������
; Updates a SLI animation with the passed timer ticks.
;
; INPUT  : ESI -> SLI
;		   EAX = Timer ticks
;�����������������������������������������������������������������������������
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
        
;�����������������������������������������������������������������������������
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
;�����������������������������������������������������������������������������
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
		xor		ebx,ebx
        stc
        ret
GetFramePtr     endp

;�����������������������������������������������������������������������������
; Pone el puntero a un frame determinado
;
; INPUT  : EAX -> SLI
;          EBX = N�mero de frame
;          ECX -> Frame
;
; OUTPUT : CF = 0 si ok
;               EAX = NULL
;          CF = 1 si el frame no existe
;               EAX = Error code
;�����������������������������������������������������������������������������
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

;�����������������������������������������������������������������������������
; Devuelve el puntero al frame actual
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX -> Frame actual
;�����������������������������������������������������������������������������
GetCurrentFramePtr      proc
        mov     eax,[eax.SLIFramePtr]
        ret
GetCurrentFramePtr      endp

;�����������������������������������������������������������������������������
; Pone el color de m�scara
;
; INPUT : EAX -> SLI
;         EBX = Color de m�scara en formato B:G:R:0
;�����������������������������������������������������������������������������
SetMaskColor    proc
        mov     [eax.SLIMask],ebx
        ret
SetMaskColor    endp

;�����������������������������������������������������������������������������
; Pone el m�todo de blitting
;
; INPUT : EAX -> SLI
;         EBX = Tipo de blit ('SLIBlitCopy', 'SLIBlitAlpha', 'SLIBlitAlphaMap'
;                             y los mismos con '+ SLIMaskedColor' para poner
;                             con m�scara)
;�����������������������������������������������������������������������������
SetBlitType     proc
        mov     [SLI ptr eax.SLIBlitType],ebx
        ret
SetBlitType     endp

;�����������������������������������������������������������������������������
; Pone el rect�ngulo de clipping
;
; INTPUT : EAX = x1
;          EBX = y1
;          ECX = x2
;          EDX = y2
;          EDI -> SLI
;�����������������������������������������������������������������������������
SetClip         proc
        mov     [edi.SLIClip.SLRR1.SLPX],eax
        mov     [edi.SLIClip.SLRR1.SLPY],ebx
        mov     [edi.SLIClip.SLRR2.SLPX],ecx
        mov     [edi.SLIClip.SLRR2.SLPY],edx
        ret
SetClip         endp

;�����������������������������������������������������������������������������
; Desplaza el rect�ngulo de destino al punto especificado
;
; INPUT : EAX = x1
;         EBX = y1
;         EDI -> SLI
;�����������������������������������������������������������������������������
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

;�����������������������������������������������������������������������������
; Devuelve las dimensiones (con escalado) del SLI
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX = X size
;          EBX = Y size
;�����������������������������������������������������������������������������
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

;�����������������������������������������������������������������������������
; Pone el campo de alpha
;
; INPUT : EAX -> SLI
;         EBX = Alpha constante o puntero al mapa de alphas
;�����������������������������������������������������������������������������
SetAlpha        proc
        mov     [SLI ptr eax.SLIAlpha],ebx
        ret
SetAlpha        endp

;�����������������������������������������������������������������������������
; Pone el modo de animaci�n
;
; INPUT : EAX -> SLI
;         BL = Modo de animaci�n
;�����������������������������������������������������������������������������
SetAnimMode proc
		movzx	ebx,bl
		AssertD ebx,_leu,SLIAnimPingPongLoop
		mov		[eax.SLIAnimMode],bl
		ret
SetAnimMode endp

;�����������������������������������������������������������������������������
; Pone el inicio del loop de animaci�n
;
; INPUT : EAX -> SLI
;         EBX = Frame inicial del loop
; OUTPUT: CF = 0 si ok
;         CF = 1 si error
;�����������������������������������������������������������������������������
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

;�����������������������������������������������������������������������������
; Pone el final del loop de animaci�n
;
; INPUT : EAX -> SLI
;         EBX = Frame final del loop
; OUTPUT: CF = 0 si ok
;         CF = 1 si error
;�����������������������������������������������������������������������������
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

;���������������������������������������������������������������������������
;� ClearCurrentFrame:   Borra el frame actual al color dado
;���������������������������������������������������������������������������
;�      Entrada:        EAX -> SLI
;�                      EBX -> color en el formato del SLI
;���������������������������������������������������������������������������
;�      Salida:         nada.
;���������������������������������������������������������������������������
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

;�����������������������������������������������������������������������������
; Creates a deep copy of a SLI
;
; All non-pointer SLI header fields are copied. Only those pointees in the SLI header that are intrinsically tied to
; the image data are deep-copied.
; Fields that are deep-copied: image frame pointers, integral image pointer.
; Fields that are not deep-copied: span buffer pointer, lighting table pointer, alpha map pointer.
; The fields that are not copied are not considered part of the image state and are left with their default values
; after CreateSLI.
;
; INPUT : EAX -> Source SLI
; OUTPUT : CF = 0 if ok
;               EAX = NO_ERROR
;               EBX -> SLI deep copy
;          CF = 1 si error
;               EAX = Error code
;               EBX = NULL
;�����������������������������������������������������������������������������
CreateSLIDeepCopy proc
    ; Create a new SLI with the same basic properties.
    push  eax
    mov		ebx,[SLI ptr eax.SLIYSize]
    mov		ecx,[SLI ptr eax.SLIColorBits]		; SLIColorBits is actualy bytes per pixel
    shl   ecx,3
    mov		edx,[SLI ptr eax.SLITotalFrames]	; Number of frames is 16.16
    shr		edx,16
    mov		eax,[SLI ptr eax.SLIXSize]
    call  CreateSLI
    pop   esi
    jnc   create_sli_deep_copy_ok
          ret

    create_sli_deep_copy_ok:
    ; Copy all frames.
    push  esi ebx
    mov   ecx,[SLI ptr esi.SLIPitch]
    imul  ecx,[SLI ptr esi.SLIYSize]
    mov   eax,[SLI ptr esi.SLIPImages]
    mov   ebx,[SLI ptr ebx.SLIPImages]
    mov   edx,[SLI ptr esi.SLITotalFrames]
    shr   edx,16
    lea   eax,[eax+edx*4]
    lea   ebx,[ebx+edx*4]
    neg   edx
    cld
    copy_sli_frames:
          push  ecx
          mov   esi,[eax+edx*4]
          mov   edi,[ebx+edx*4]
          shr   ecx,2
          rep   movsd
          mov   ecx,ss:[esp]
          and   ecx,NOT 3
          sub   ecx,ss:[esp]
          neg   ecx
          rep   movsb
          pop   ecx
    inc   edx
    jnz   copy_sli_frames
    pop   ebx esi

    ; Copy all other non-pointer properties.
    ; esi -> source SLI, ebx -> destination SLI.
    ; SLIMethode
    mov   eax,[SLI ptr esi.SLIMethode]
    mov   [SLI ptr ebx.SLIMethode],eax
    ; SLIPos
    mov   eax,[SLI ptr esi.SLIPos.SLRR1.SLPX]
    mov   [SLI ptr ebx.SLIPos.SLRR1.SLPX],eax
    mov   eax,[SLI ptr esi.SLIPos.SLRR1.SLPY]
    mov   [SLI ptr ebx.SLIPos.SLRR1.SLPY],eax
    mov   eax,[SLI ptr esi.SLIPos.SLRR2.SLPX]
    mov   [SLI ptr ebx.SLIPos.SLRR2.SLPX],eax
    mov   eax,[SLI ptr esi.SLIPos.SLRR2.SLPY]
    mov   [SLI ptr ebx.SLIPos.SLRR2.SLPY],eax
    ; SLIRef
    mov   eax,[SLI ptr esi.SLIRef.SLPX]
    mov   [SLI ptr ebx.SLIRef.SLPX],eax
    mov   eax,[SLI ptr esi.SLIRef.SLPY]
    mov   [SLI ptr ebx.SLIRef.SLPY],eax
    ; SLIClip
    mov   eax,[SLI ptr esi.SLIClip.SLRR1.SLPX]
    mov   [SLI ptr ebx.SLIClip.SLRR1.SLPX],eax
    mov   eax,[SLI ptr esi.SLIClip.SLRR1.SLPY]
    mov   [SLI ptr ebx.SLIClip.SLRR1.SLPY],eax
    mov   eax,[SLI ptr esi.SLIClip.SLRR2.SLPX]
    mov   [SLI ptr ebx.SLIClip.SLRR2.SLPX],eax
    mov   eax,[SLI ptr esi.SLIClip.SLRR2.SLPY]
    mov   [SLI ptr ebx.SLIClip.SLRR2.SLPY],eax
    ; SLIBlitType
    mov   eax,[SLI ptr esi.SLIBlitType]
    mov   [SLI ptr ebx.SLIBlitType],eax
    ; SLIAlpha
    mov   eax,[SLI ptr esi.SLIAlpha]
    mov   [SLI ptr ebx.SLIAlpha],eax
    ; SLIMask
    mov   eax,[SLI ptr esi.SLIMask]
    mov   [SLI ptr ebx.SLIMask],eax
    ; SLIFrame
    mov   eax,[SLI ptr esi.SLIFrame]
    mov   [SLI ptr ebx.SLIFrame],eax
    ; SLIFrameRate
    mov   eax,[SLI ptr esi.SLIFrameRate]
    mov   [SLI ptr ebx.SLIFrameRate],eax
    ; SLIStartTicks
    mov   eax,[SLI ptr esi.SLIStartTicks]
    mov   [SLI ptr ebx.SLIStartTicks],eax
    ; SLIStartFrame
    mov   eax,[SLI ptr esi.SLIStartFrame]
    mov   [SLI ptr ebx.SLIStartFrame],eax
    ; SLILoopStart
    mov   eax,[SLI ptr esi.SLILoopStart]
    mov   [SLI ptr ebx.SLILoopStart],eax
    ; SLILoopEnd
    mov   eax,[SLI ptr esi.SLILoopEnd]
    mov   [SLI ptr ebx.SLILoopEnd],eax
    ; SLIFramePtr
    push  ebx esi
    mov   ebx,[SLI ptr ebx.SLIFrame]
    call SetFrame_
    pop   esi ebx
    ; SLITemp
    push  esi
    lea   esi,[SLI ptr esi.SLITemp]
    lea   edi,[SLI ptr ebx.SLITemp]
    mov   ecx,SLI_TEMP_VARS
    cld
    rep   movsd
    pop   esi
    ; SLIPalette
    push  esi
    lea   esi,[SLI ptr esi.SLIPalette]
    lea   edi,[SLI ptr ebx.SLIPalette]
    mov   ecx,256
    cld
    rep   movsd
    pop   esi
    ; SLIAnimMode
    mov   al,[SLI ptr esi.SLIAnimMode]
    mov   [SLI ptr ebx.SLIAnimMode],al
    ; SLIPlayingBackwards
    mov   al,[SLI ptr esi.SLIPlayingBackwards]
    mov   [SLI ptr ebx.SLIPlayingBackwards],al
    ; SLIIntegralImageMultiplier
    mov   eax,[SLI ptr esi.SLIIntegralImageMultiplier]
    mov   [SLI ptr ebx.SLIIntegralImageMultiplier],eax

    ; Deep-copy integral image.
    cmp   [SLI ptr esi.SLIIntegralImage],0
    jz    no_integral_image_to_copy
    ; ecx = integral image size in bytes.
    mov		ecx,[SLI ptr esi.SLIXSize]
    imul	ecx,[SLI ptr esi.SLIYSize]
    imul  ecx,[SLI ptr esi.SLIColorBits]
    shl   ecx,2
    ; Allocate space for integral image deep copy.
    push	esi ebx ecx
    call	malloc
    pop		ecx edx esi
    jnc   integral_image_allocated
          ; Destroy the SLI before leaving.
          mov   eax,edx
          call  DestroySLI
          mov   eax,MALLOC_ERROR
          xor   ebx,ebx
          stc
          ret
    integral_image_allocated:
    ; Deep-copy the integral image.
    mov		[SLI ptr edx.SLIIntegralImage],ebx
    mov   esi,[SLI ptr esi.SLIIntegralImage]
    mov   edi,ebx
    shr   ecx,2   ; The integral image size is always a multiple of 4.
    cld
    rep   movsd

    ; Output is ebx -> deep copy.
    mov   ebx,edx

    no_integral_image_to_copy:
    mov   eax,NO_ERROR
    clc
    ret
endp

END
