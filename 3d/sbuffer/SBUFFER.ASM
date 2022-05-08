;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  new!SpanBuffer                              Coded by Nitro! / [tDR] ³
;ÆÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍµ
;³  Codigo renovado                                                     ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
.386p
.model flat
.data
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Includes                                                            ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
    include alloc.inc
    include sbuffer.inc
    include sli.inc
    include stderror.inc
    include utils.inc
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Defines                                                             ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
    MAX_SPAN equ  50 ; spans por linea de media
;Ä Macro para debugging ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
breakp      macro text1, regi
    local   debugtext, debugreg, skipthis
    pushfd
    pushad
    mov     debugreg, regi
    print   debugtext
;    xor     ah,ah
;    int     16h
    popad
    popfd
    jmp     skipthis
    debugreg    dd ?
    debugtext   db text1
                db '[%d+n'
                dd offset debugreg
                db '][0%dhn'
                dd offset debugreg
                db 'h]',13, 10
                db 0
skipthis:
    endm

.code
;        assume  cs:@code, ds:@data, es:@data

SpanBuffer  struc
            SBOutputSLI dd  ?
            SBScanlines dd  ?
            SBWidth     dd  ?
            SBScanPtr   dd  ?
            ; SBScanlines*4 :  Punteros al primer span de cada linea
            ; MAX_SPAN*SBScanlines:  Spans libres para ir alojando
            ends

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Funciones y macros del manager de spans                             ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ CreateSbufferSLI:    aloja un SBufferSLI en 32bits
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX : Size X
;³                      EBX : Size Y
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         EBX : puntero al SLI
;³                      EAX : ErrorCode
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.data?
CSBSizeX    dd  ?
CSBSizeY    dd  ?
CSBSLIPtr   dd  ?
.code
CreateSBufferSLI  proc
        mov     CSBSizeX, eax
        mov     CSBSizeY, ebx
        mov     edx, 1
        mov     ecx, 32
        call    CreateSLI
        ErrorCode eax


        mov     eax, CSBSizeY
        imul    ebx, eax, MAX_SPAN * (size SPAN)
        lea     ecx, [ebx+eax*4+4]
        call    malloc
        ErrorCode MALLOC_ERROR

        mov     edi, CSBSLIPtr
        mov     [SLI ptr edi.SLISBufferNfo], ebx
        xor     eax, eax
        clc
        ret
        endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ SLI2SBuffer:         Prepara un SLI para ser un SBuffer
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX : Puntero al SLI de 32bits a convertir
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         EAX : Standard ErrorCode
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.code
SLI2SBuffer     proc
        mov     CSBSLIPtr, eax

        mov     eax, [SLI ptr eax.SLIYSize]
        imul    ebx, eax, MAX_SPAN * (size SPAN)
        lea     ecx, [ebx+eax*4+4]
        call    malloc
        ErrorCode MALLOC_ERROR

        mov     edi, CSBSLIPtr
        mov     [SLI ptr edi.SLISBufferNfo], ebx

        xor     eax, eax
        clc
        ret
        endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ InitSBufferSLI:      Inicializa el SBufferSLI para generar un nuevo frame
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX : Puntero al SBufferSLI
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         nada.
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
InitSBufferSLI proc
        mov     ecx, [SLI ptr eax.SLIYSize]
        mov     edi, [SLI ptr eax.SLISbufferNfo]
        push    edi ecx
        mov     eax, -1
        add     edi, 4
        rep     stosd
        pop     ecx edi
        lea     ebx, [edi+ecx*4+4]
        mov     [edi], ebx
        ret
        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;    AllocateSpan   :   Aloja un Span
;         Entrada   :   EAX - Puntero al SBuffer
;          Salida   :   EBX - Puntero al Span
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
AllocateSpan    macro
        mov     ebx, [eax]
        add     dword ptr [eax], (size SPAN)
        endm

comment ¤
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;        FreeSpan   :   Libera un Span
;         Entrada   :   EAX - Puntero al SpanBuffer
;                       EBX - Puntero al Span
;          Salida   :   EBX - Puntero al siguiente Span
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FreeSpan        proc
        push    eax
        mov     ecx, [eax]
        mov     [SPAN ptr ebx.SPType], -1
        mov     edi, [SPAN ptr ebx.SPBack]
        mov     ebx, [SPAN ptr ebx.SPNext]
        mov     [SPAN ptr edi.SPNext], ebx
        cmp     ebx, -1
        je      FS001
        mov     [SPAN ptr ebx.SPBack], edi
FS001:
        pop     eax
        ret
        endp
        ¤

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  InsertSpan: Inserta un Span                                         ³
;ÆÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍµ
;³         Entrada   :   EAX - Puntero al SpanBufferSLI                 ³
;³                       EBX - Puntero al Span                          ³
;³                       ECX - Scanline donde insertar el Span          ³
;³          Salida   :   nada.                                          ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
.data?
TempSpan    SPAN    ?
ISSLIPtr    dd  ?
.code
InsertSpan      proc
        push    ebp
;   Cogemos el primer span de la lista en el scanline dado

        mov     ISSLIPtr, eax
        mov     eax, [SLI ptr eax.SLISBufferNfo]
        lea     edi, [eax+ecx*4+4]

InsertSpanLoop:
        mov     ebp, [SPAN ptr edi.SPNext]
;
;   Si la lista esta vacia insertamos el Span directamente
;
        cmp     ebp, -1         ; no apunta a ningun otro span
        jne     IsNotVoidScan


        lea     esi, [ebx+8]

        AllocateSpan

        mov     [SPAN ptr edi.SPNext], ebx    ; Ponemos en el Span anterior
                                        ; el puntero al actual
        mov     edx, edi

        mov     ecx, (size SPAN) /4 -2

        lea     edi, [ebx+8]            ; lo copiamos del Span temporal
        rep     movsd                   ; al Span actual

        mov     [SPAN ptr ebx.SPNext], -1 ; Ponemos el Span actual como ultimo
                                        ; Span de la lista

        mov     [SPAN ptr ebx.SPBack], edx ; Ponemos en el Span actual el
                                        ; puntero al span anterior
        pop     ebp
        ret

IsNotVoidScan:


;   Ya sabemos que el Scanline no se ha acabado
;   y cogemos el primer span disponible
        mov     edi, ebp

    NewSpan equ     ebx
    CurSpan equ     edi

;       El span actual esta a la derecha del nuevo span?
        mov     esi, [SPAN ptr NewSpan.SPx1]
        cmp     esi, [SPAN ptr CurSpan.SPx2]
        jle     IsNotRightCur
;       vayamos al siguiente span
        jmp     InsertSpanLoop

IsNotRightCur:

;       El span actual esta totalmente a la izquierda del nuevo span?

        mov     esi, [SPAN ptr NewSpan.SPx2]
        cmp     esi, [SPAN ptr CurSpan.SPx1]
        jge     IsNotLeftCur

        mov     esi, NewSpan

        AllocateSpan

        mov     ecx, [SPAN ptr CurSpan.SPBack]
        mov     [SPAN ptr CurSpan.SPBack], ebx
        mov     [SPAN ptr ecx.SPNext], ebx

        mov     [SPAN ptr ebx.SPNext], edi
        mov     [SPAN ptr ebx.SPBack], ecx

        lea     esi, [esi+8]    ; SPAN a insertar
        lea     edi, [ebx+8]    ; Nuevo SPAN alojado
        mov     ecx, (size SPAN)/4 -2
        rep     movsd
        pop     ebp
        ret

IsNotLeftCur:

;<------------
        mov     esi, [SPAN ptr CurSpan.SPx1]
        cmp     esi, [SPAN ptr NewSpan.SPx1]
        jle     IsNotNewBeforeCur

        mov     edx, ebx
        mov     ebp, edi

        AllocateSpan
        mov     ecx, ds:[SPAN ptr ebp.SPBack]
        mov     [SPAN ptr ebx.SPBack], ecx
        mov     [SPAN ptr ecx.SPNext], ebx
        mov     [SPAN ptr ebx.SPNext], ebp
        mov     ds:[SPAN ptr ebp.SPBack], ebx

        lea     esi, [edx+8]
        lea     edi, [ebx+8]
        mov     ecx, ((size Span)/4) - 2
        rep     movsd

        mov     ecx, ds:[SPAN ptr ebp.SPx1]
        mov     [SPAN ptr edx.SPx1], ecx
        dec     ecx
        mov     [SPAN ptr ebx.SPx2], ecx

        fild    [SPAN ptr edx.SPx1]     ; <-- si falla el calc puede ser por ;modi
        fisub   [SPAN ptr ebx.SPx1]       ; falta de un 1
        mov     ebx, edx
        mov     cl, byte ptr [SPAN ptr ebx.SPN]

MakeMulps001:
        fld     st
        fmul    [SPAN ptr edx.SPdiZ]
        fadd    [SPAN ptr edx.SPiz]
        fstp    [SPAN ptr edx.SPiz]
        add     edx, 8
        dec     cl
        jnz     MakeMulps001
        fstp    st
        mov     edi, ebp

IsNotNewBeforeCur:

        mov     esi, [SPAN ptr NewSpan.SPx1]
        cmp     esi, [SPAN ptr CurSpan.SPx1]
        jle     IsNotCurBeforeNew

        push    ebx
        push    edi
        AllocateSpan
        mov     ecx, [SPAN ptr edi.SPBack]
        mov     [SPAN ptr ebx.SPBack], ecx
        mov     [SPAN ptr ecx.SPNext], ebx
        mov     [SPAN ptr ebx.SPNext], edi
        mov     [SPAN ptr edi.SPBack], ebx
        lea     esi, [edi+8]
        lea     edi, [ebx+8]
        mov     ecx, ((size Span)/4) -2
        rep     movsd
        mov     esi, ebx
        pop     edi
        pop     ebx

        mov     ecx, [SPAN ptr ebx.SPx1]
        mov     [SPAN ptr edi.SPx1], ecx
        dec     ecx
        mov     [SPAN ptr esi.SPx2], ecx

        fild    [SPAN ptr edi.SPx1]       ; <-- si falla el calc puede ser por
        fisub   [SPAN ptr esi.SPx1]       ; falta de un 1

        mov     esi, edi
        mov     cl, byte ptr [SPAN ptr esi.SPN]
MakeMulps002:
        fld     st
        fmul    [SPAN ptr esi.SPDiZ]
        fadd    [SPAN ptr esi.SPiZ]
        fstp    [SPAN ptr esi.SPiZ]
        add     esi, 8
        dec     cl
        jnz     MakeMulps002
        fstp    st

IsNotCurBeforeNew:

        mov     esi, [SPAN ptr NewSpan.SPx2]
        cmp     esi, [SPAN ptr CurSpan.SPx2]
        jle     IsNotCurInsideNew

; facil

        push    edi
        mov     esi, ebx
        mov     edi, offset TempSpan
        mov     ecx, (size Span)/4
        rep     movsd
        pop     edi

        mov     ecx, [SPAN ptr edi.SPx2]
        mov     [TempSpan.SPx2], ecx
        inc     ecx
        mov     [SPAN ptr ebx.SPx1], ecx

        fild    [SPAN ptr ebx.SPx1] ; <-- si falla el calc puede ser por
        fisub   [SPAN ptr edi.SPx1]       ; falta de un 1
        mov     esi, ebx
        mov     cl, byte ptr [SPAN ptr ebx.SPN]
MakeMulps003:
        fld     st
        fmul    [SPAN ptr esi.SPDiZ]
        fadd    [SPAN ptr esi.SPiZ]
        fstp    [SPAN ptr esi.SPiZ]
        add     esi, 8
        dec     cl
        jnz     MakeMulps003
        fstp    st

        push    eax

        fld     [TempSpan.SPiZ]
        fcomp   [SPAN ptr edi.SPiZ]
        fnstsw  ax
        test    ah, 40h
        je      ReadyToCompare001
        fild    [SPAN ptr edi.SPx2]
        fisub   [SPAN ptr edi.SPx1]
        fmul    [SPAN ptr edi.SPDiZ]
        fadd    [SPAN ptr edi.SPiZ]
        fcomp   [SPAN ptr ebx.SPiZ]
        fnstsw  ax
ReadyToCompare001:
        shr     ah, 1
        jc      ZcSmallerZn001
;ReadyToCompare001:
        push    edi
        mov     esi, Offset TempSpan + 8
        mov     ecx, (size Span)/4 - 2
        lea     edi, [edi+8]
        rep     movsd
        pop     edi
ZcSmallerZn001:
        pop     eax
        jmp     InsertSpanLoop
IsNotCurInsideNew:

        mov     esi, [SPAN ptr NewSpan.SPx2]
        cmp     esi, [SPAN ptr CurSpan.SPx2]
        je      IsNotNewInsideCur
        mov     edx, ebx
        push    edi
        AllocateSpan
        lea     esi, [edi+8]
        lea     edi, [ebx+8]
        mov     ecx, (size span)/4 -2
        rep     movsd
        pop     edi

        mov     ecx, [SPAN ptr edi.SPBack]
        mov     [SPAN ptr ebx.SPBack], ecx
        mov     [SPAN ptr ecx.SPNext], ebx
        mov     [SPAN ptr ebx.SPNext], edi
        mov     [SPAN ptr edi.SPBack], ebx    ; hoy!!

        mov     ecx, [SPAN ptr edx.SPx2]
        mov     [SPAN ptr ebx.SPx2], ecx
        inc     ecx
        mov     [SPAN ptr edi.SPx1], ecx


        fild    [SPAN ptr edi.SPx1]       ; <-- si falla el calc puede ser por
        fisub   [SPAN ptr edx.SPx1]       ; falta de un 1

        mov     esi, edi
        mov     cl, byte ptr [SPAN ptr edi.SPN]
MakeMulps004:
        fld     st
        fmul    [SPAN ptr esi.SPDiZ]
        fadd    [SPAN ptr esi.SPiZ]
        fstp    [SPAN ptr esi.SPiZ]
        add     esi, 8
        dec     cl
        jnz     MakeMulps004
        fstp    st

        fld     [SPAN ptr edx.SPiZ]
        fcomp   [SPAN ptr ebx.SPiZ]
        fnstsw  ax
        test    ah, 40h
        je      ReadyToCompare002
        fild    [SPAN ptr edx.SPx2]
        fisub   [SPAN ptr edx.SPx1]
        fmul    [SPAN ptr edx.SPDiZ]
        fadd    [SPAN ptr edx.SPiZ]
        fcomp   [SPAN ptr edi.SPiZ]
        fnstsw  ax
ReadyToCompare002:
        shr     ah, 1
        jc      ZcSmallerZn002
        lea     esi, [edx+8]
        lea     edi, [ebx+8]
        mov     ecx, (size Span)/4 -2
        rep     movsd
ZcSmallerZn002:
ifdef   CarryOutput
        clc
endif
        pop     ebp
        ret

IsNotNewInsideCur:
        fld     [SPAN ptr ebx.SPiZ]
        fcomp   [SPAN ptr edi.SPiZ]
        fnstsw  ax
        test    ah, 40h
        je      ReadyToCompare003
        fild    [SPAN ptr ebx.SPx2]
        fisub   [SPAN ptr ebx.SPx1]
        fmul    [SPAN ptr ebx.SPDiZ]
        fadd    [SPAN ptr ebx.SPiZ]

        fild    [SPAN ptr edi.SPx2]
        fisub   [SPAN ptr edi.SPx1]
        fmul    [SPAN ptr edi.SPDiZ]
        fadd    [SPAN ptr edi.SPiZ]
        fcompp
        fnstsw  ax
ReadyToCompare003:
        shr     ah, 1
        jc      ZcSmallerZn003
        lea     esi, [ebx+8]
        add     edi, 8
        mov     ecx, (size Span)/4 -2
        rep     movsd
ZcSmallerZn003:
ifdef   CarryOutput
        clc
endif
        pop     ebp
        ret
        endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  RenderSBufferSLI :   Renderiza el SBufferSLI                        ³
;ÆÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍµ
;³         Entrada   :   EAX - Puntero al SpanBufferSLI                 ³
;³          Salida   :   nada.                                          ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
.data?
RSBSSLIPtr  dd  ?
RSBSWidth   dd  ?
RSBSScanLines dd ?
.code
RenderSBufferSLI    proc
        push    ebp
        mov     RSBSSLIPtr, eax
        mov     edi, [SLI ptr eax.SLIFramePtr]
        mov     ebx, [SLI ptr eax.SLIPitch]
        shl     ebx, 2
        mov     RSBSWidth, ebx
        mov     ebx, [SLI ptr eax.SLIYSize]
        mov     RSBSScanLines, ebx
        xor     ebp, ebp
RSB001:
        push    ecx ebp edi
        mov     eax, RSBSSLIPtr
        mov     eax, [SLI ptr eax.SLISBufferNfo]
        mov     ebp, ds:[eax+ebp*4+4]
RSB002:
        cmp     ebp, -1
        je      RSB003

        push    offset RSB004

		test	ds:[SPAN ptr ebp.SPType],SPT_PERSPECTIVE_CORRECTED
		jnz		perspective_corrected_loops
		
        cmp     byte ptr ds:[SPAN ptr ebp.SPType], 1
        je      RenderFlatScanline
        cmp     byte ptr ds:[SPAN ptr ebp.SPType], 2
        je      RenderTexmapScanline
        cmp     byte ptr ds:[SPAN ptr ebp.SPType], 3
        je      RenderTexmapGouraudScanLine
        cmp     byte ptr ds:[SPAN ptr ebp.SPType], 12
        je      RenderGouraudColorScanLine
        cmp     byte ptr ds:[SPAN ptr ebp.SPType], 4
        je      RenderTexmapFakePhongScanLine
		
		perspective_corrected_loops:
        cmp     byte ptr ds:[SPAN ptr ebp.SPType], 1
        je      RenderFlatScanline
        cmp     byte ptr ds:[SPAN ptr ebp.SPType], 2
        je      RenderTexmapScanline_PerspectiveCorrected
        cmp     byte ptr ds:[SPAN ptr ebp.SPType], 3
        je      RenderTexmapGouraudScanLine
        cmp     byte ptr ds:[SPAN ptr ebp.SPType], 12
        je      RenderGouraudColorScanLine
        cmp     byte ptr ds:[SPAN ptr ebp.SPType], 4
        je      RenderTexmapFakePhongScanLine

        ret
RSB004:
        mov     ebp, ds:[SPAN ptr ebp.SPNext]
        jmp     RSB002

RSB003:
        pop     edi ebp ecx
        add     edi, RSBSWidth
        inc     ebp
        cmp     ebp, RSBSScanLines
        jnz     RSB001
        pop     ebp
        ret
        endp


RenderFlatScanline  proc
        push    edi
        mov     eax, ds:[SPAN ptr ebp.SPx1]
        lea     edi, [edi+eax*4]
        mov     ecx, ds:[SPAN ptr ebp.SPx2]
        sub     ecx, eax
        inc     ecx
        mov     eax, ds:[SPAN ptr ebp.SPTexture]

        lea     edi, [edi+ecx*4]
        xor     ecx, -1
        inc     ecx
bucleflat:
        mov     [edi+ecx*4], eax
        inc     ecx
        jnz     bucleflat

        pop     edi
        ret
        endp


        align   32
        dw  0
tempdv  dd  ?
        dw  0
tempv   dd  ?
        dw  0
tempdu  dd  ?
        dw  0
tempu   dd  ?
        dw  0

RenderTexmapScanLine    proc
        push    edi ebp
        fld     ds:[SPAN ptr ebp.SPVars]
        fld     ds:[SPAN ptr ebp.SPVars+4]
        fld     ds:[SPAN ptr ebp.SPVars+8]
        fld     ds:[SPAN ptr ebp.SPVars+12]
        fistp   [tempdv]
        fistp   [tempv]
        fistp   [tempdu]
        fistp   [tempu]
        mov     ecx, ds:[SPAN ptr ebp.SPx2]
        mov     eax, ds:[SPAN PTR ebp.SPx1]
        sub     ecx, eax
        lea     edi, [edi+eax*4]
        inc     ecx
        mov     eax, dword ptr [tempdu-2]
        lea     edi, [edi+ecx*4]
        xor     ecx, -1
        mov     ebx, dword ptr [tempdv-2]
        inc     ecx
        mov     dword ptr [RTS_AMC001-4], eax
        mov     dword ptr [RTS_AMC002-4], ebx
        mov     al, byte ptr [tempdu+2]
        mov     bl, byte ptr [tempdv+2]
        mov     byte ptr [RTS_AMC003-1], al
        mov     byte ptr [RTS_AMC004-1], bl

        mov     eax, ds:[SPAN ptr ebp.SPTexture]
        mov     ebx, ds:[SPAN ptr ebp.SPLightMap]
        mov     dword ptr [RTS_AMC005-4], eax
        mov     dword ptr [RTS_AMC006-4], ebx

        xor     ebx, ebx
        xor     edx, edx
        mov     bl, byte ptr [tempu+2]
        mov     bh, byte ptr [tempv+2]
        mov     ebp, dword ptr [tempu-2]
        mov     esi, dword ptr [tempv-2]
RTS_mainbucle:
        mov     dl, [ebx+1234000h] ; textura         ;u
RTS_AMC005:
        add     ebp, 1234000h ; incu                 ;v
RTS_AMC001:
        adc     bl, 129       ; incu                 ;u <-solo u
RTS_AMC003:
        mov     eax, [edx*4+1234000h] ; paleta       ;v
RTS_AMC006:
        add     esi, 1234000h ; incv                 ;u
RTS_AMC002:
        mov     [edi+ecx*4], eax ; poner en pantalla ;v
        adc     bh, 129       ; incv                 ;u <-solo u
RTS_AMC004:
        inc     ecx                                  ;v
        jnz     RTS_mainbucle                        ;v
        ; total cycles on Pentium = 5 per pixel (32 bits)
        pop     ebp edi
        ret
        endp


		align	32
		
tempiz	dd	?
tempdiz	dd	?

persp_corr_u	dd ?
persp_corr_v	dd ?

persp_num_loops			db ?
persp_num_loops_last	db ?

RenderTexmapScanLine_PerspectiveCorrected    proc
        push    edi ebp
        fld     ds:[SPAN ptr ebp.SPVars]
        fld     ds:[SPAN ptr ebp.SPVars+4]
        fld     ds:[SPAN ptr ebp.SPVars+8]
        fld     ds:[SPAN ptr ebp.SPVars+12]
        fistp   [tempdv]
        fistp   [tempv]
        fistp   [tempdu]
        fistp   [tempu]
		fld		ds:[SPAN ptr ebp.SPiZ]
		fistp	tempiz	; 65536 / z
		fld		ds:[SPAN ptr ebp.SPdiZ]
		fistp	tempdiz
        mov     ecx, ds:[SPAN ptr ebp.SPx2]
        mov     eax, ds:[SPAN PTR ebp.SPx1]
        sub     ecx, eax
        lea     edi, [edi+eax*4]
        inc     ecx
		mov		eax,ecx
		shr		eax,4
		mov		persp_num_loops,al
		and		cl,0fh
		mov		persp_num_loops_last,cl
        mov     eax, dword ptr [tempdu-2]
        mov     ebx, dword ptr [tempdv-2]
        mov     dword ptr [RTSP_AMC001-4], eax
        mov     dword ptr [RTSP_AMC002-4], ebx
        mov     al, byte ptr [tempdu+2]
        mov     bl, byte ptr [tempdv+2]
        mov     byte ptr [RTSP_AMC003-1], al
        mov     byte ptr [RTSP_AMC004-1], bl

        mov     eax, ds:[SPAN ptr ebp.SPTexture]
        mov     ebx, ds:[SPAN ptr ebp.SPLightMap]
        mov     dword ptr [RTSP_AMC005-4], eax
        mov     dword ptr [RTSP_AMC006-4], ebx

        xor     ebx, ebx
        xor     edx, edx
        mov     bl, byte ptr [tempu+2]
        mov     bh, byte ptr [tempv+2]
        mov     ebp, dword ptr [tempu-2]
        mov     esi, dword ptr [tempv-2]
		
		; tempu and tempv are u and v divided by z
		; Perspective correction is done every 16 pixels

		; ebp = (u/z) / (1/z) = u [16.16]
		mov		eax,tempu
		mov		edx,eax
		sar		edx,16
		sal		eax,16
mov ebx,tempiz
		idiv	tempiz
		mov		ebp,eax
		
		; esi = (v/z) / (1/z) = v [16.16]
		mov		eax,tempv
		mov		edx,eax
		sar		edx,16
		sal		eax,16
mov ebx,tempiz
		idiv	tempiz
		mov		esi,eax

		
		cmp		persp_num_loops,0
		jnz 	RTSP_outer_loop
		
		; Linear interpolation in the last piece of span of fewer than 16 pixels
		RTSP_outer_loop_last:
		xor		ecx,ecx
		mov		cl,persp_num_loops_last
		test	cl,cl
		jz		RTSP_leave
		
		mov		eax,tempdiz
		imul	ecx
		add		tempiz,eax
		
		mov		eax,tempdu
		imul	ecx
		add		tempu,eax
		
		mov		eax,tempdv
		imul	ecx
		add		tempv,eax

		; u = (u/z) / (1/z) [16.16]
		mov		eax,tempu
		mov		edx,eax
		sar		edx,16
		sal		eax,16
mov ebx,tempiz
		idiv	tempiz

		; du = u1 - u0
		sub		eax,ebp	; eax = du [16.16]
		mov		edx,eax
		sar		edx,31
		idiv	ecx
		mov		ebx,eax
		sal		eax,16
		mov		dword ptr [RTSP_AMC001-4],eax
		sar		ebx,16		
		mov		byte ptr [RTSP_AMC003-1],bl
		
		; v = (v/z) / (1/z) [16.16]
		mov		eax,tempv
		mov		edx,eax
		sar		edx,16
		sal		eax,16
mov ebx,tempiz
		idiv	tempiz

		; dv = v1 - v0
		sub		eax,esi	; eax = dv [16.16]
		mov		edx,eax
		sar		edx,31
		idiv	ecx
		mov		ebx,eax
		sal		eax,16
		mov		dword ptr [RTSP_AMC002-4],eax
		sar		ebx,16		
		mov		byte ptr [RTSP_AMC004-1],bl
		
		jmp		RTSP_cont
		
		
		; Linear interpolation in the first N pieces of span of 16 pixels each
		RTSP_outer_loop:				
		mov		cl,16
		
		; 1/z += 16*d(1/z) [16.16]
		mov		eax,tempdiz
		sal		eax,4	; *16
		add		tempiz,eax
		
		; u/z += 16*d(u/z) [16.16]
		mov		eax,tempdu
		sal		eax,4
		add		tempu,eax
		
		; v/z += 16*d(v/z) [16.16]
		mov		eax,tempdv
		sal		eax,4
		add		tempv,eax

		; u = (u/z) / (1/z) [16.16]
		mov		eax,tempu
		mov		edx,eax
		sar		edx,16
		sal		eax,16
mov ebx,tempiz
		idiv	tempiz
		mov		persp_corr_u,eax		; save u1 as starting point for next outer loop 

		; du = u1 - u0
		sub		eax,ebp	; eax = du [16.16]
		sar		eax,4
		mov		ebx,eax
		shl		eax,16
		mov		dword ptr [RTSP_AMC001-4],eax
		shr		ebx,16		
		mov		byte ptr [RTSP_AMC003-1],bl
		
		; v = (v/z) / (1/z) [16.16]
		mov		eax,tempv
		mov		edx,eax
		sar		edx,16
		sal		eax,16
mov ebx,tempiz
		idiv	tempiz
		mov		persp_corr_v,eax		; save v1 as starting point for next outer loop 
		
		; dv = v1 - v0
		sub		eax,esi	; eax = dv [16.16]
		sar		eax,4
		mov		ebx,eax
		shl		eax,16
		mov		dword ptr [RTSP_AMC002-4],eax
		shr		ebx,16		
		mov		byte ptr [RTSP_AMC004-1],bl				
		
				
		RTSP_cont:
		; Set loop registers to interpolate u and v
		mov		ebx,ebp
		sal		ebp,16
		sar		ebx,16
		mov		eax,esi
		sal		esi,16
		sar		eax,16
		mov		bh,al
		
		xor		edx,edx

RTSP_mainbucle:
        mov     dl, [ebx+1234000h] ; textura         ;u
RTSP_AMC005:
        add     ebp, 1234000h ; incu                 ;v
RTSP_AMC001:
        adc     bl, 129       ; incu                 ;u <-solo u
RTSP_AMC003:
        mov     eax, [edx*4+1234000h] ; paleta       ;v
RTSP_AMC006:
        add     esi, 1234000h ; incv                 ;u
RTSP_AMC002:
        mov     dword ptr [edi], eax ; poner en pantalla ;v
        adc     bh, 129       ; incv                 ;u <-solo u
RTSP_AMC004:
		add		edi,4								 ;v
        dec     cl 	                                 ;u
        jnz     RTSP_mainbucle                       ;u
        ; total cycles on Pentium = 6 per pixel (32 bits)
		
		mov		al,persp_num_loops
		test	al,al
		jz		RTSP_leave
		; Restore v1 and u1 as v0 and u0 for the next outer loop
		mov		ebp,persp_corr_u
		mov		esi,persp_corr_v	
		dec		al
		mov		persp_num_loops,al
		jz		RTSP_outer_loop_last
		jmp		RTSP_outer_loop
		
		RTSP_leave:
        pop     ebp edi
        ret
        endp
		
        align   32
        dw  0
tempdl  dd  ?
        dw  0
templ   dd  ?
        dw  0
RenderTexmapGouraudScanLine    proc
        push    edi ebp
        fld     ds:[SPAN ptr ebp.SPVars]
        fld     ds:[SPAN ptr ebp.SPVars+4]
        fld     ds:[SPAN ptr ebp.SPVars+8]
        fld     ds:[SPAN ptr ebp.SPVars+12]
        fld     ds:[SPAN ptr ebp.SPVars+16]
        fld     ds:[SPAN ptr ebp.SPVars+20]
        fistp   [tempdl]
        fistp   [templ]
        fistp   [tempdv]
        fistp   [tempv]
        fistp   [tempdu]
        fistp   [tempu]
        mov     ecx, ds:[SPAN ptr ebp.SPx2]
        mov     eax, ds:[SPAN PTR ebp.SPx1]
        sub     ecx, eax
        lea     edi, [edi+eax*4]
        inc     ecx
        mov     eax, dword ptr [tempdu-2]
        lea     edi, [edi+ecx*4]
        xor     ecx, -1
        mov     ebx, dword ptr [tempdv-2]
        mov     edx, dword ptr [tempdl-2]
        inc     ecx
        mov     dword ptr [RTG_AMC001-4], eax
        mov     dword ptr [RTG_AMC002-4], ebx
        mov     dword ptr [RTG_AMC007-4], edx
        mov     al, byte ptr [tempdu+2]
        mov     bl, byte ptr [tempdv+2]
        mov     dl, byte ptr [tempdl+2]
        mov     byte ptr [RTG_AMC003-1], al
        mov     byte ptr [RTG_AMC004-1], bl
        mov     byte ptr [RTG_AMC008-1], dl

        mov     eax, ds:[SPAN ptr ebp.SPTexture]
        mov     ebx, ds:[SPAN ptr ebp.SPLightMap]
        mov     dword ptr [RTG_AMC005-4], eax
        mov     dword ptr [RTG_AMC006-4], ebx

        xor     ebx, ebx
        mov     edx, dword ptr [templ-2]
        xor     dh,  dh
        mov     dl,  byte ptr [templ+2]

        mov     bl, byte ptr [tempu+2]
        mov     bh, byte ptr [tempv+2]
        mov     ebp, dword ptr [tempu-2]
        mov     esi, dword ptr [tempv-2]
RTG_mainbucle:
        xor     eax, eax                             ;u
        mov     ah, dl                               ;v
        ;and     ah, 1111111b                         ;u
        shr     ah, 1

        mov     al, [ebx+1234000h] ; textura         ;v
RTG_AMC005:

        add     ebp, 1234000h ; incu                 ;u
RTG_AMC001:

        mov     eax, [eax*4+1234000h] ; paleta       ;v
RTG_AMC006:

        adc     bl, 129       ; incu                 ;u <-solo u
RTG_AMC003:

        add     edx, 1234000h                        ;v
RTG_AMC007:

        adc     dl, 129                              ;u <-solo u
RTG_AMC008:

        add     esi, 1234000h ; incv                 ;v
RTG_AMC002:

        adc     bh, 129       ; incv                 ;u <-solo u
RTG_AMC004:

        mov     [edi+ecx*4], eax ; poner en pantalla ;v

        inc     ecx                                  ;u
        jnz     RTG_mainbucle                        ;v
        ; total cycles = 7 per pixel (32 bits)
        ;mov     eax, [edi+ecx*4]
        ;shr     eax, 1
        ;and     eax, 7f7f7fh
        ;mov     ebx, [edi+ecx*4+4]
        ;shr     ebx, 1
        ;and     ebx, 7f7f7fh
        ;add     eax, ebx
        ;mov     [edi+ecx*4+4], eax
        pop     ebp edi
        ret
        endp

        align   32
        dw  0
tempdl1 dd  ?
        dw  0
templ1  dd  ?
        dw  0
RenderTexmapFakePhongScanLine    proc
        push    edi ebp
        fld     ds:[SPAN ptr ebp.SPVars]
        fld     ds:[SPAN ptr ebp.SPVars+4]
        fld     ds:[SPAN ptr ebp.SPVars+8]
        fld     ds:[SPAN ptr ebp.SPVars+12]
        fld     ds:[SPAN ptr ebp.SPVars+16]
        fld     ds:[SPAN ptr ebp.SPVars+20]
        fld     ds:[SPAN ptr ebp.SPVars+24]
        fld     ds:[SPAN ptr ebp.SPVars+28]
        fistp   [tempdl1]
        fistp   [templ1]
        fistp   [tempdl]
        fistp   [templ]
        fistp   [tempdv]
        fistp   [tempv]
        fistp   [tempdu]
        fistp   [tempu]

        mov     eax, ds:[SPAN ptr ebp.SPTexture]
        mov     ebx, ds:[SPAN ptr ebp.SPLightMap]
        mov     ecx, ds:[SPAN ptr ebp.SPAlpha]

        mov     dword ptr [RFP_AMC005-4], eax
        mov     dword ptr [RFP_AMC006-4], ebx
        mov     dword ptr [RFP_AMC009-4], ecx

        mov     eax, ds:[SPAN PTR ebp.SPx1];
        lea     edx, [edi+eax*4]        ; a¤adimos inicio

        mov     ebp, ds:[SPAN ptr ebp.SPx2];
        sub     ebp, eax                ;
        inc     ebp                     ; calculamos ancho

        lea     edx, ds:[edx+ebp*4]
        mov     dword ptr [RFP_pantalla-4],edx ; ponemos la direccion final
                                               ; en pantalla

        xor     ebp, -1                        ; ecx=-ecx
        inc     ebp                            ;

        mov     eax, dword ptr [tempdu-2]
        mov     ebx, dword ptr [tempdv-2]
        mov     edx, dword ptr [tempdl-2]
        mov     ecx, dword ptr [tempdl1-2]

        mov     dword ptr [RFP_AMC001-4], eax
        mov     dword ptr [RFP_AMC002-4], ebx
        mov     dword ptr [RFP_AMC007-4], edx
        mov     dword ptr [RFP_AMC010-4], ecx

        mov     al, byte ptr [tempdu+2]
        mov     bl, byte ptr [tempdv+2]
        mov     dl, byte ptr [tempdl+2]
        mov     dh, byte ptr [tempdl1+2]

        mov     byte ptr [RFP_AMC003-1], al
        mov     byte ptr [RFP_AMC004-1], bl
        mov     byte ptr [RFP_AMC008-1], dl
        mov     byte ptr [RFP_AMC011-1], dh

        xor     ebx, ebx
        mov     edx,    dword ptr [templ-2]
        mov     ecx,    dword ptr [templ1-2]
        mov     edi,    dword ptr [tempu-2]
        mov     esi,    dword ptr [tempv-2]

        mov     dl,     byte ptr [templ+2]
        mov     cl,     byte ptr [templ1+2]
        mov     bl,     byte ptr [tempu+2]
        mov     bh,     byte ptr [tempv+2]

        xor     dh,  dh
        xor     ch,  ch

RFP_mainbucle:
        xor     eax, eax                             ;u
        mov     ah, cl                               ;v
        mov     al, dl                               ;u

        mov     ah, byte ptr [eax+dword ptr 81234567h] ; foco            ;v
RFP_AMC009:
        shr     ah, 1                                ;u

        mov     al, [ebx+1234000h] ; textura         ;v
RFP_AMC005:

        add     edi, 1234000h ; incu                 ;u
RFP_AMC001:

        mov     eax, ds:[eax*4+1234000h] ; paleta       ;v
RFP_AMC006:

        adc     bl, 129       ; incu                 ;u <-solo u
RFP_AMC003:

        add     edx, 1234000h                        ;v
RFP_AMC007:

        adc     dl, 129                              ;u <-solo u
RFP_AMC008:

        add     esi, 1234000h ; incv                 ;v
RFP_AMC002:

        adc     bh, 129       ; incv                 ;u <-solo u
RFP_AMC004:

        add     ecx, 1234000h                        ;v
RFP_AMC010:

        adc     cl, 129                              ;u <-solo u
RFP_AMC011:

        mov     ds:[ebp*4+123456], eax ; poner en pantalla ;v
RFP_pantalla:
        inc     ebp                                  ;u
        jnz     RFP_mainbucle                        ;v
        ; total cycles = 7 per pixel (32 bits)
        pop     ebp edi
        ret
        endp

RenderGouraudColorScanLine    proc
        push    edi ebp
        fld     ds:[SPAN ptr ebp.SPVars]
        fld     ds:[SPAN ptr ebp.SPVars+4]
        fld     ds:[SPAN ptr ebp.SPVars+8]
        fld     ds:[SPAN ptr ebp.SPVars+12]
        fld     ds:[SPAN ptr ebp.SPVars+16]
        fld     ds:[SPAN ptr ebp.SPVars+20]
        fistp   [tempdl]
        fistp   [templ]
        fistp   [tempdv]
        fistp   [tempv]
        fistp   [tempdu]
        fistp   [tempu]
        mov     ecx, ds:[SPAN ptr ebp.SPx2]
        mov     eax, ds:[SPAN PTR ebp.SPx1]
        sub     ecx, eax
        lea     edi, [edi+eax*4]
        inc     ecx
        mov     eax, dword ptr [tempdu-2]
        lea     edi, [edi+ecx*4]
        xor     ecx, -1
        mov     ebx, dword ptr [tempdv-2]
        mov     edx, dword ptr [tempdl-2]
        inc     ecx
        mov     dword ptr [RGC_AMC001-4], eax
        mov     dword ptr [RGC_AMC002-4], ebx
        mov     dword ptr [RGC_AMC007-4], edx
        mov     al, byte ptr [tempdu+2]
        mov     bl, byte ptr [tempdv+2]
        mov     dl, byte ptr [tempdl+2]
        mov     byte ptr [RGC_AMC003-1], al
        mov     byte ptr [RGC_AMC004-1], bl
        mov     byte ptr [RGC_AMC008-1], dl

        xor     ebx, ebx
        mov     edx, dword ptr [templ-2]
        xor     dh,  dh
        mov     dl,  byte ptr [templ+2]

        mov     bl, byte ptr [tempu+2]
        mov     bh, byte ptr [tempv+2]
        mov     ebp, dword ptr [tempu-2]
        mov     esi, dword ptr [tempv-2]
RGC_mainbucle:
        xor     eax, eax                             ;u
        mov     al, dl                               ;v
        shl     eax, 16                              ;u
        add     eax, ebx                             ;v

RGC_AMC005:

        add     edx, 1234000h                        ;v
RGC_AMC007:

        adc     dl, 129                              ;u <-solo u
RGC_AMC008:

        add     ebp, 1234000h ; incu                 ;u
RGC_AMC001:

        adc     bl, 129       ; incu                 ;u <-solo u
RGC_AMC003:

        add     esi, 1234000h ; incv                 ;v
RGC_AMC002:

        adc     bh, 129       ; incv                 ;u <-solo u
RGC_AMC004:

        mov     [edi+ecx*4], eax ; poner en pantalla ;v

        inc     ecx                                  ;u
        jnz     RGC_mainbucle                        ;v

        ; total cycles = 7 per pixel (32 bits)
        pop     ebp edi
        ret
        endp

END
