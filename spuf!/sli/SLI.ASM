;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  [tDR], 1999                                    Copyright the DarkRising
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³                                      Coded by:             B52 & Nitro!
;³  SLI routines
;³
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  DATE         REVISION           AUTHOR & COMMENTS
;³  ÄÄÄÄÄÄÄÄ     ÄÄÄÄÄÄÄÄÄÄÄÄÄ      ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  18-5-99      Version 1.0        Nitro! : Comienza la comida de tarro
;³  20-5-99      1.0 cont.          B52 : Sigue el papeo de olla
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    .386p
    .model  flat
    jumps
    .code
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Needed includes
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    include     newsgl.inc
    include     dpmi.inc
    include     utils.inc
    include     alloc.inc
    include     memcpy.inc
    include     stderror.inc
    include     sli.inc
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ AllocateSLI:         aloja una estructura SLI
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX = N£mero de frames
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         CF = 0 si ok
;³                              EAX = NULL
;³                              EBX = puntero al SLI vac¡o
;³                      CF = 1 si error
;³                              EAX = error code
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
AllocateSLI     proc
                lea     ecx,[size SLI+eax*4]
                push    eax
                call    malloc
                pop     ecx
                ErrorCode MALLOC_ERROR
                lea     eax,[ebx+size SLI]
                mov     [ebx.SLIPImages],eax
                shl     ecx,16
                mov     [ebx.SLITotalFrames],ecx
                xor     eax,eax
                ret
                endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Comprueba que el n£mero de bits del SLI es correcto y lo convierte a bytes
;
; INPUT  : ECX = N£mero de bits
;
; OUTPUT : CF = 0 si ok
;               ECX = N£mero de bytes correspondiente
;          CF = 1 si error
;               EAX = Error code (INVALID_COLOR_DEPTH)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets size and default clip
;
; INPUT  : EAX = X size
;          EBX = Y size
;          ECX = Color bytes
;          EDX = Number of frames
;          EDI -> SLI
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetDefProperties        proc
        mov     [SLI ptr edi.SLIXSize], eax
        mov     [SLI ptr edi.SLIYSize], ebx
        mov     [SLI ptr edi.SLIPitch], eax
        shl     edx,16
        mov     [SLI ptr edi.SLITotalFrames], edx
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
        ret
SetDefProperties        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Pone la lista de punteros a frame
;
; INPUT  : EAX = X size
;          EBX = Y size
;          ECX = Bytes per pixel
;          EDX = Frames
;          EDI -> SLI
;
; OUTPUT : ESI -> First frame
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ CreateSLI:           aloja una animaci¢n vacia en SLI
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX : Size X
;³                      EBX : Size Y
;³                      ECX : ColorBits
;³                      EDX : Number of frames
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         EBX = puntero al SLI
;³                      EAX = NULL
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CreateSLI       proc
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
                ErrorCodePOP MALLOC_ERROR, ebp
                mov     edi, ebx

                pop     edx ecx ebx eax

                call    SetDefProperties

                call    SetFramePointers

                push    edi

                mov     edi, esi
                mul     edx
                mul     ebx
                mul     ecx
                mov     ecx, eax
                mov     ebx, ecx
                shr     ecx, 2
                xor     eax, eax
                rep     stosd
                mov     ecx, ebx        ; por si acaso no es m£ltiplo de 4
                and     ecx,3
                or      ecx,ecx
                jz      no_stosb
                rep     stosb
                no_stosb:

                pop     ebx
                xor     eax,eax
                pop     ebp
                clc
                ret
                endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ CreateVoidSLI:       aloja una animaci¢n vacia en SLI sin buffer
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX : Size X
;³                      EBX : Size Y
;³                      ECX : ColorBits
;³                      EDX : Number of frames
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         EBX = puntero al SLI
;³                      EAX = NULL
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CreateVoidSLI   proc
                call    NormalizeBits
                ErrorCode eax
                push    eax ebx ecx edx
                mov     eax,edx
                call    AllocateSLI
                mov     edi,ebx
                pop     edx ecx ebx eax
                ErrorCode edi
                mov     [SLI ptr edi.SLIFramePtr], 0

                call    SetDefProperties

                mov     ebx,edi
                xor     eax,eax
                clc
                ret
                endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ DestroySLI:          libera un SLI de memoria
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX : puntero al SLI
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         CF = 0 if ok
;³                              EAX = NULL
;³                      CF = 1 if error
;³                              EAX = Error Code
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DestroySLI      proc
                mov     ebx, eax
                call    free
                ErrorCode FREE_ERROR
                xor     eax,eax
                clc
                ret
                endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ CreateVideoSLI:      Crea la superficie de video SLI
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX : Size X
;³                      EBX : Size Y
;³                      ECX : ColorBits
;³      Nota:           Si ECX+SGL_MemoryBuffer se fuerza a un buffer en
;³                      memoria principal
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         CF = 0 if ok
;³                              EAX = NULL
;³                      CF = 1 if error
;³                              EAX = Error Code
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

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
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ GetVideoSLI:         Obtiene la superficie de video SLI
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        nada.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         EAX : ptr to Video SLI
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetVideoSLI     proc
                call    GetAvailPage
                mov     edi, VideoSLI
                mov     [SLI ptr edi.SLIFramePtr], eax
                mov     eax, edi
                ret
                endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ DestroyVIdeoSLI:          desaloja el VideoSLI
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX <> 0 modo de video a seleccionar
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         CF = 0 if ok
;³                              EAX = NULL
;³                      CF = 1 if error
;³                              EAX = Error Code
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ ShowVideoSLI:        Muestra la superficie de video SLI
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        nada.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         nada.
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ShowVideoSLI    proc
                push    ebp
                call    ShowPage
                call    GetAvailPage
                mov     edi, VideoSLI
                mov     [SLI ptr edi.SLIFramePtr], eax
                pop     ebp
                ret
                endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ SetPalette:          Pone el puntero a una paleta B:G:R:0
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX -> SLI
;³                      EBX -> Palette
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         nada.
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetPalette      proc
        test    ebx,ebx
        jz      no_palette
        mov     esi,ebx
        lea     edi,[eax.SLIPalette]
        mov     ecx,256
        rep     movsd
        no_palette:
        ret
        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Devuelve el n£mero de frame actual
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX = Frame
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetFrame        proc
        mov     eax,[eax.SLIFrame]
        shr     eax,16
        ret
GetFrame        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Pone el n£mero de frame actual
;
; INPUT  : EAX -> SLI
;          EBX = Frame
;
; OUTPUT : CF = 0 si ok
;               EAX = NULL
;          CF = 1 si error
;               EAX = Error code (INVALID_FRAME)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetFrame        proc
        mov     ecx,[eax.SLITotalFrames]
        shr     ecx,16
        cmp     ebx,ecx
        jae     setframe_error

        mov     ecx,[eax.SLIPImages]
        mov     edx,[ecx+ebx*4]
        mov     [eax.SLIFramePtr],edx
        shl     ebx,16
        mov     [eax.SLIFrame],ebx
        xor     eax,eax
        clc
        ret

        setframe_error:
        mov     eax,INVALID_FRAME
        stc
        ret
        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Pone el puntero a un frame determinado
;
; INPUT  : EAX -> SLI
;          EBX = N£mero de frame
;          ECX -> Frame
;
; OUTPUT : CF = 0 si ok
;               EAX = NULL
;          CF = 1 si el frame no existe
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Devuelve el puntero al frame actual
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX -> Frame actual
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetCurrentFramePtr      proc
        mov     eax,[eax.SLIFramePtr]
        ret
GetCurrentFramePtr      endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Pone el color de m scara
;
; INPUT : EAX -> SLI
;         EBX = Color de m scara en formato B:G:R:0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetMaskColor    proc
        mov     [eax.SLIMask],ebx
        ret
SetMaskColor    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Pone el m‚todo de blitting
;
; INPUT : EAX -> SLI
;         EBX = Tipo de blit ('SLIBlitCopy', 'SLIBlitAlpha', 'SLIBlitAlphaMap'
;                             y los mismos con '+ SLIMaskedColor' para poner
;                             con m scara)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetBlitType     proc
        mov     [eax.SLIBlitType],ebx
        ret
SetBlitType     endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Pone el rect ngulo de clipping
;
; INTPUT : EAX = x1
;          EBX = y1
;          ECX = x2
;          EDX = y2
;          EDI -> SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetClip         proc
        mov     [edi.SLIClip.SLRR1.SLPX],eax
        mov     [edi.SLIClip.SLRR1.SLPY],ebx
        mov     [edi.SLIClip.SLRR2.SLPX],ecx
        mov     [edi.SLIClip.SLRR2.SLPY],edx
        ret
SetClip         endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Desplaza el rect ngulo de destino al punto especificado
;
; INPUT : EAX = x1
;         EBX = y1
;         EDI -> SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Devuelve las dimensiones (con escalado) del SLI
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX = X size
;          EBX = Y size
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Pone el campo de alpha
;
; INPUT : EAX -> SLI
;         EBX = Alpha constante o puntero al mapa de alphas
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetAlpha        proc
        mov     [eax.SLIAlpha],ebx
        ret
SetAlpha        endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ ClearCurrentFrame:   Borra el frame actual al color dado
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX -> SLI
;³                      EBX -> color en el formato del SLI
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         nada.
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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
