;�����������������������������������������������������������������������������
; Loader for 8 and 24 bits PCX files
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / The DarkRising)
;�����������������������������������������������������������������������������

HEADER_START    EQU 0

JUMPS
.386p
.model flat
.code

        INCLUDE     loader.inc
        INCLUDE     pcx.inc
        INCLUDE     alloc.inc
        INCLUDE     filesys.inc
        INCLUDE     stderror.inc

PCXHeader STRUC
        Manufacturer db ?               ; Constant Flag, 10 = ZSoft .pcx 
        PCXVersion   db ?               ; Version information 
                                        ; 0 = Version 2.5 of PC Paintbrush 
                                        ; 2 = Version 2.8 w/palette information 
                                        ; 3 = Version 2.8 w/o palette information 
                                        ; 4 = PC Paintbrush for Windows(Plus for
                                        ;     Windows uses Ver 5) 
                                        ; 5 = Version 3.0 and > of PC Paintbrush
                                        ;     and PC Paintbrush +, includes
                                        ;     Publisher's Paintbrush . Includes
                                        ;     24-bit .PCX files 
        Encoding      db ?              ; 1 = .PCX run length encoding 
        BitsPerPixel  db ?              ; Number of bits to represent a pixel
                                        ; (per Plane) - 1, 2, 4, or 8 
        XMin          dw ?              ; Image Dimensions: Xmin,Ymin,Xmax,Ymax
        YMin          dw ?
        XMax          dw ?
        YMax          dw ?

        HDpi          dw ?              ; Horizontal Resolution of image in DPI
        VDpi          dw ?              ; Vertical Resolution of image in DPI 
        Colormap      db 48 dup(?)      ; Color palette setting, see text 
        Reserved      db ?              ; Should be set to 0. 
        NPlanes       db ?              ; Number of color planes 
        BytesPerLine  dw ?              ; Number of bytes to allocate for a scanline
                                        ; plane.  MUST be an EVEN number.  Do NOT
                                        ; calculate from Xmax-Xmin. 
        PaletteInfo   dw ?              ; How to interpret palette- 1 = Color/BW,
                                        ; 2 = Grayscale (ignored in PB IV/ IV +) 
        HScreenSize   dw ?              ; Horizontal screen size in pixels. New field
                                        ; found only in PB IV/IV Plus 
        VScreenSize   dw ?              ; Vertical screen size in pixels. New field
                                        ; found only in PB IV/IV Plus 
        Filler        db 54 dup(?)      ; Blank to fill out 128 byte header.  Set all
                                        ; bytes to 0 
ENDS

;�����������������������������������������������������������������������������
; Tests if the given file has PCX image format
;
; INPUT  : EDX -> file name
; OUTPUT : CF = 0 if file is PCX type
;               EAX = Frame X size
;               EBX = Frame Y size
;               ECX = Bytes per pixel
;               EDX = Total frames to decode (1)
;               ESI = Actual image frames (1)
;				EBP = Frames per second in fixed point (16.16) (0)
;          CF = 1 if not
;               EAX = Error code (MALLOC_ERROR, FREE_ERROR, INVALID_FORMAT or any FILE_ERROR)
;�����������������������������������������������������������������������������
PCXTestFile     proc
        push    edx
        mov     ecx,size PCXHeader
        call    malloc
        pop     edx
        ErrorCode MALLOC_ERROR
        mov     TestPool,ebx
        mov     ecx,size PCXHeader
        mov     edi,ebx
        mov     esi,HEADER_START
        call    load_data_chunk
        ErrorCode eax

        ; We test if it is a valid PCX file
        mov     esi,TestPool
        cmp     [esi.Manufacturer],0Ah  ; ZSoft ?
        jnz     sig_error
        cmp     [esi.PCXVersion],5      ; Version<=5 ?
        ja      sig_error
        cmp     [esi.Encoding],1        ; run-length PCX ?
        jnz     sig_error
        cmp     [esi.BitsPerPixel],8    ; 8 bits per pixel plane ?
        jnz     sig_error
        cmp     [esi.NPlanes],1         ; 1 color planes ?
        jz      its_a_pcx
        cmp     [esi.NPlanes],3         ; maybe 3 color planes ?
        jnz     sig_error
        its_a_pcx:                      ; everything is ok...

        xor     eax,eax
        xor     ebx,ebx
        mov     ax,[esi.XMax]
        mov     bx,[esi.XMin]
        sub     eax,ebx
        inc     eax
        push    eax
        xor     eax,eax
        xor     ebx,ebx
        mov     ax,[esi.YMax]
        mov     bx,[esi.YMin]
        sub     eax,ebx
        inc     eax
        push    eax
        xor     eax,eax
        mov     al,[esi.NPlanes]
        push    eax

        mov     ebx,TestPool
        call    free
        pop     ecx ebx eax
        ErrorCode FREE_ERROR
        mov     edx,1           ; 1 frame to decode
        mov		esi,1			; 1 visual frame
        xor		ebp,ebp			; 0 fps
        clc
        ret

        sig_error:
        mov     ebx,TestPool
        call    free
        stc
        mov     eax,INVALID_FORMAT
        ret
PCXTestFile     endp

;�����������������������������������������������������������������������������
; Decodes an RLE compressed line
;
; INPUT  : ESI -> PCX file data
;          EBP = Offset from PCX file data to the scanline compressed data
;          EDI -> Destination of decompressed scanline
;
; OUTPUT : ESI unmodified
;          EBP = Offset from PCX file data to next scanline compressed data
;          EDI -> Next decompressed scanline destination
;�����������������������������������������������������������������������������
DecodeLine      proc
        xor     edx,edx
        mov     dx,[esi.BytesPerLine]
        xor     eax,eax
        mov     al,[esi.NPlanes]       
        imul    edx,eax                 ; scanline length in bytes
        decoding_loop:
                mov     al,[esi.ebp]
                and     al,11000000b
                cmp     al,11000000b
                jnz     non_repeating
                        ; We found a repeating code
                        xor     ecx,ecx
                        mov     cl,[esi.ebp]
                        and     cl,00111111b
                        mov     al,[esi.ebp.1]
                        mov     bl,al
                        mov     ah,al
                        shl     eax,16
                        mov     al,bl
                        mov     ah,bl
                        add     ebp,2
                        mov     ebx,ecx
                        shr     ecx,2
                        jz      no_dwords
                        rep     stosd
                        no_dwords:
                        mov     ecx,ebx
                        and     ecx,3
                        jz      no_bytes
                        rep     stosb
                        no_bytes:
        sub     edx,ebx
        jc      rle_finished
        jnz     decoding_loop
        jmp     rle_finished

                non_repeating:
                        ; We found a non-repeating code
                        mov     al,[esi.ebp]
                        inc     ebp
                        mov     [edi],al
                        inc     edi
        dec     edx  
        jnz     decoding_loop

        rle_finished:
        ret
DecodeLine      endp

;�����������������������������������������������������������������������������
; Decodes an RLE compressed image
;
; INPUT  : ESI -> PCX file data
;          EDI -> Destination buffer (Size=NPlanes*BytesPerLine*(YMax-YMin+1))
;
; OUTPUT : CF = 0 if ok
;               ESI unmodified
;               EDI buffer filled with image
;               EBP points behind image data (palette if 8 bit image)
;          CF = 1 if error (no space for temporary buffer)
;               EAX = Error code
;�����������������������������������������������������������������������������
DecodeImage     proc
        xor     ecx,ecx
        xor     eax,eax
        mov     cx,[esi.BytesPerLine]
        mov     al,[esi.NPlanes]
        mul     ecx
        mov     ecx,eax
        push    esi edi
        call    malloc
        pop     edi esi
        ErrorCode MALLOC_ERROR
        mov     TempBuffer,ebx

        mov     ebp,size PCXHeader
        xor     ecx,ecx
        mov     cx,[esi.YMax]
        sub     cx,[esi.YMin]
        inc     ecx
        decode_all_lines:
                push    ecx edi
                mov     edi,TempBuffer
                call    DecodeLine
                pop     edi ecx

                xor     edx,edx
                mov     dx,[esi.XMax]
                sub     dx,[esi.XMin]           ; scanline length in pixels
                inc     edx
                mov     ebx,TempBuffer
                cmp     [esi.NPlanes],1
                jz      only_1_plane
                push    ebp
                xor     ebp,ebp
                mov     bp,[esi.BytesPerLine]
                convert_pixels:
                        mov     al,[ebx+ebp*2]
                        mov     [edi],al
                        mov     al,ds:[ebx+ebp]
                        mov     [edi+1],al
                        mov     al,ds:[ebx]
                        mov     [edi+2],al
                        add     edi,3
                        inc     ebx
                dec     edx
                jnz     convert_pixels
                pop     ebp
                jmp     next_line

                only_1_plane:
                push    esi ecx
                mov     esi,ebx
                mov     ecx,edx
                shr     ecx,2
                rep     movsd
                mov     ecx,edx
                and     ecx,3
                rep     movsb
                pop     ecx esi

        next_line:
        loop    decode_all_lines

        push    edi                
        mov     ebx,TempBuffer
        call    free
        pop     edi
        ErrorCode FREE_ERROR
        clc
        ret
DecodeImage     endp

;�����������������������������������������������������������������������������
; Reads and decompresses a PCX file into memory
; NOTE: 8 bits files are stored as 8 bits + palette (B:G:R:0)
;       24 bits (3 planes) files are stored as 24 bits (B:G:R:0)
;
; INPUT  -> ECX = Number of frame to decompress
;
; OUTPUT : CF = 0 if success
;               EAX -> Image data buffer (Image+Palette)
;               EBX = Pointer to 8 bit palette or NULL if image is true-color
;				ECX = Skipped frames
;          CF = 1 if error
;               EAX = Error code
;�����������������������������������������������������������������������������
LoadPCXFile     proc
        mov     edx,fname
        call    ttl_load_file
        ErrorCode FILE_ERROR
        mov     FilePool,ebx
        mov     esi,ebx
        mov     FLen,ecx

        ; image size = (YMax-YMin+1)*(XMax-XMin+1)*NPlanes + 256*4
        xor     ecx,ecx
        mov     cl,[esi.NPlanes]
        xor     eax,eax
        mov     ax,[esi.YMax]
        sub     ax,[esi.YMin]
        inc     eax
        mul     ecx
        mov     cx,[esi.XMax]
        sub     cx,[esi.XMin]
        inc     ecx
        mul     ecx
        mov     ecx,eax
        cmp     [esi.NPlanes],1
        jnz     non_paletted
                add     ecx,256*4
        non_paletted:
        push    esi
        call    malloc
        mov     DecodedBuffer,ebx
        pop     esi
        ErrorCode MALLOC_ERROR

        mov     edi,DecodedBuffer
        call    DecodeImage
        ErrorCode eax
        xor     ebx,ebx
        ; If there is a palette, we convert it to B:G:R:0
        cmp     [esi.NPlanes],1
        jnz     no_pal
                add     esi,FLen
                sub     esi,256*3
                xor     dl,dl
                mov     ebx,edi
                convert_colors:
                        xor     ah,ah
                        mov     al,[esi]
                        shl     eax,16
                        mov     ah,ds:[esi+1]
                        mov     al,ds:[esi+2]
                        mov     [edi],eax
                        add     edi,4
                        add     esi,3
                dec     dl
                jnz     convert_colors
        no_pal:
        xor     ecx,ecx
        mov     eax,DecodedBuffer
        clc
        ret

LoadPCXFile     endp

;�����������������������������������������������������������������������������
; Init procedure
;
; INPUT : EDX -> File name
;�����������������������������������������������������������������������������
StartProc       proc
        mov     FilePool,0
        mov     DecodedBuffer,0
        mov     fname,edx
        clc
        ret
StartProc       endp

;�����������������������������������������������������������������������������
; End procedure
;�����������������������������������������������������������������������������
CloseProc       proc
        mov     ebx,FilePool
        test    ebx,ebx
        jz      no_file_pool
                call    free
                ErrorCode FREE_ERROR
        no_file_pool:
        mov     ebx,DecodedBuffer
        test    ebx,ebx
        jz      no_decoded_buffer
                call    free
                ErrorCode FREE_ERROR
        no_decoded_buffer:
        clc
        ret
CloseProc       endp

.data
PCXProcs        Loader <offset PCXTestFile, offset StartProc, offset LoadPCXFile, offset CloseProc>

.data?
TestPool        dd ?
TempSize        dd ?
TempBuffer      dd ?
FLen            dd ?
fname           dd ?
FilePool        dd ?
DecodedBuffer   dd ?
end
