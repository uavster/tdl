;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Loader for 8 bits FLI/FLC files
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / The DarkRising)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 
JUMPS
.386p
.model flat
.code

        INCLUDE     loader.inc
        INCLUDE		fli.inc
        INCLUDE     alloc.inc
        INCLUDE     filesys.inc
        INCLUDE     stderror.inc
        INCLUDE		assert.inc
		INCLUDE		utils.inc
HEADER_START    equ 0

FLIHeader STRUC

        FLIsize         dd ?            ; Length of file
        FLImagic        dw ?            ; Set to hex AF11
        FLIframes       dw ?            ; Number of frames in FLI
        FLIwidth        dw ?            ; Screen width
        FLIheight       dw ?            ; Screen height
        FLIdepth        dw ?            ; Depth of a pixel (8)
        FLIflags        dw ?            ; Must be 0
        FLIspeed        dw ?            ; Number of video ticks between frames
        FLInext         dd ?            ; Set to 0
        FLIfrit         dd ?            ; Set to 0
        FLIexpand       db 102 dup(?)   ; All zeroes -- for future enhancement

        ENDS

FRMHeader STRUC

        FRMsize         dd ?            ; Bytes in this frame
        FRMmagic        dw ?            ; Always hexadecimal F1FA
        FRMchunks       dw ?            ; Number of 'chunks' in frame
        FRMexpand       db 8 dup(?)     ; Space for future enhancements. All zeros

        ENDS

CHKHeader STRUC

        CHKsize         dd ?            ; Bytes in this chunk
        CHKtype         dw ?            ; Type of chunk (see below)
        CHKdata         LABEL

     ENDS

FLI_CHUNK_256_COLOR   equ 4
FLI_CHUNK_DELTA       equ 7
FLI_CHUNK_COLOR       equ 11            ; Compressed color map
FLI_CHUNK_LC          equ 12            ; Line compressed -- the most common type
                                        ; of compression for any but the first
                                        ; frame.  Describes the pixel difference
                                        ; from the previous frame.
FLI_CHUNK_BLACK       equ 13            ; Set whole screen to color 0 (only occurs
                                        ; on the first frame).
FLI_CHUNK_BRUN        equ 15            ; Bytewise run-length compression -- first
                                        ; frame only
FLI_CHUNK_COPY        equ 16            ; Indicates uncompressed 64000 bytes soon
                                        ; to follow.  For those times when
                                        ; compression just doesn't work!
FLI_CHUNK_MINI        equ 18

DELTAPacket STRUC
        
ENDS

LCPacket STRUC

        LCskip_count    db ?            ; Skipped pixels
        LCsize_count    db ?            ; >0 That many bytes of data follow to be copied
                                        ; <0 One byte follows and must be repeated
        LCdata          LABEL           ; The data

ENDS

BRUNPacket STRUC

        BRsize_count    db ?            ; >0 That many bytes of data follow to be copied
                                        ; <0 One byte follows and must be repeated
        BRdata          LABEL           ; The data
        
ENDS

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Tests if the given file has FLI/FLC animation file format
;
; INPUT  : EDX -> file name
; OUTPUT : CF = 0 if file is FLI/FLC type
;               EAX = Frame X size
;               EBX = Frame Y size
;               ECX = Bytes per pixel
;               EDX = Total frames to decode
;               ESI = Actual image frames
;				EBP = Frames per second in fixed point (16.16)
;          CF = 1 if not
;               EAX = Error code (MALLOC_ERROR, FREE_ERROR, INVALID_FORMAT or any FILE_ERROR)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FLITestFile     proc
		mov		ftf_file_name,edx
        push    edx
        mov     ecx,size FLIHeader
        call    malloc
        pop     edx
        ErrorCode MALLOC_ERROR
        mov     TestPool,ebx
        mov     ecx,size FLIHeader
        mov     edi,ebx
        mov     esi,HEADER_START
        call    load_data_chunk
        ErrorCode eax
        mov		esi,TestPool
        cmp     [esi.FLIdepth],8
        jnz     invalid_fli
        cmp     [esi.FLImagic],0AF11h
        jz      valid_fli
        cmp     [esi.FLImagic],0AF12h
        jnz     invalid_fli

        valid_fli:
        push	esi
        mov     ebx,TestPool
        call    free
        pop		esi
        ErrorCode FREE_ERROR
        ; Frame rate
        xor		ebx,ebx
        mov		bx,[esi.FLIspeed] ; ticks per frame
        cmp     [esi.FLImagic],0AF11h
        jz      dont_scale_ticks
				shr ebx,4
        dont_scale_ticks:
        ; fps = (ticks/second)/(ticks/frame)        
        mov		eax,(70 SHL 16)
        xor		edx,edx
        div		ebx
        mov		ebp,eax

        movzx	eax,word ptr [esi.FLIwidth]
        movzx	ebx,word ptr [esi.FLIheight]
        movzx	ecx,word ptr [esi.FLIdepth]
        shr		ecx,3
        movzx	edx,word ptr [esi.FLIframes]
        push	eax ebx ecx edx ebp
        mov		edx,ftf_file_name
        call    ttl_load_file
        ErrorCode FILE_ERROR   
        mov     FilePool,ebx
        mov     FLen,ecx
        mov		esi,ebx
        call	CountActualFrames
        push	ecx
        mov		ebx,esi
        call	free
        pop		esi
        pop		ebp edx ecx ebx eax
        ErrorCode FREE_ERROR
        clc
        ret

        invalid_fli:
        mov     ebx,TestPool
        call    free
        ErrorCode FREE_ERROR
        mov     eax,INVALID_FORMAT
        stc
        ret
ftf_file_name	dd ?
FLITestFile     endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Tells whether the current frame should be skipped
;
; INPUT  : EDX -> Encoded frame
; OUTPUT : CF = 1 if frame should be skipped
;		   CF = 0 if frame should not be skipped
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ShouldSkipFrame	proc
        cmp     word ptr [edx.FRMmagic],0F1FAh
		jnz     skip_frame  ; Not a normal frame
		cmp		[edx.FRMchunks],0
		je      skip_frame
		clc
		ret
		skip_frame:
		stc
		ret
		endp
		
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Counts the actual number of frames after skipping invalid ones
;
; INPUT  : ESI -> FLI/FLC file contents
; OUTPUT : ECX = Actual number of frames (non-skipped)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CountActualFrames	proc
		movzx	ebx,word ptr [esi.FLIframes]
        lea     edx,[esi+size FLIHeader]
        xor		ecx,ecx
		gaf_loop:
				call	ShouldSkipFrame
				jc		gaf_skip_frame
						inc	ecx
		        gaf_skip_frame:
		        add     edx,[edx.FRMsize]        
        dec		ebx
        jnz		gaf_loop
        ret
		endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Init procedure
;
; INPUT : EDX -> File name
; OUTPUT : CF = 0 if success
;          CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
StartProc       proc
		; Load FLI file
        call    ttl_load_file
        ErrorCode FILE_ERROR        
        mov     FilePool,ebx
        mov     FLen,ecx
        ; Cache width and height        
        mov		esi,FilePool
        xor		edx,edx        
        mov		dx,word ptr [esi.FLIwidth]
        mov		frame_width,edx
        mov		dx,word ptr [esi.FLIheight]
        mov		frame_height,edx
        ; Frame size in bytes
        mov     eax,frame_width
        mov  	ecx,frame_height
        mul		ecx
        mov     frame_size,eax
        ; Pointer to current frame encoded data
        mov		eax,FilePool
        lea     eax,[eax+size FLIHeader]
        mov		cur_frame_encoded_data,eax
        ; Initialize color table (format 0:B:G:R)
		xor		eax,eax
        mov		edi,offset cur_palette
        mov		ecx,256
        rep		stosd
		; Allocate memory for frame decoding
        mov		ecx,frame_size
        call    malloc
        ErrorCode MALLOC_ERROR
        mov		decoded_frame,ebx
        clc
        ret
StartProc       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; End procedure
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CloseProc       proc
		; Free frame decoding buffer
		mov		ebx,decoded_frame
		call	free
		ErrorCode FREE_ERROR
        mov     ebx,FilePool
        call    free
        mov     eax,FREE_ERROR
        ret
CloseProc       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Reads and decompresses a FLI/FLC file into memory
;
; OUTPUT : CF = 0 if success
;               EAX -> Image data buffer (Image+Palette)
;               EBX = Pointer to 8 bit palette or NULL if image is true-color
;				ECX = Skipped frames
;          CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
LoadFLIFrame    proc
		; Decode next frame		
        mov     esi,cur_frame_encoded_data
        mov		edi,decoded_frame
        call    DecodeFLIFrame
        mov		ecx,eax
        mov		eax,decoded_frame
        mov		ebx,offset cur_palette
        mov		cur_frame_encoded_data,esi
        ret        
LoadFLIFrame    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Decodes next FLI frame into memory
;
; INPUT  : ESI -> Encoded frame data
;          EDI -> Destination buffer to decompress frame
;
; OUTPUT : CF = 0 if OK
;				EAX = 0 if frame was decoded
;				EAX = 1 if frame was skipped
;          CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DecodeFLIFrame  proc
        push    esi
        
		mov		edx,esi
		call	ShouldSkipFrame
		mov		eax,1	; Frame was skipped
		jc		no_more_chunks
		
		decode_frame:
		xor		eax,eax
		mov		ax,[edx.FRMchunks]
        mov     chunks,eax
        add     edx,size FRMHeader
        decode_chunks:
                xor     ebx,ebx
                mov     bx,[edx.CHKtype]
                mov     eax,[chunk_ptrs + ebx*4]
                lea     esi,[edx.CHKdata]                
                test    eax,eax
                push    edx edi
                jz      cont_decoding
                        jmp     eax
                cont_decoding:
                pop     edi edx
                add     edx,[edx.CHKsize]
        dec     chunks
        jnz     decode_chunks
		xor		eax,eax ; Frame was decoded
		
        no_more_chunks:
        pop     esi
        add     esi,[esi.FRMsize]
        clc
        ret

chunks          dd ?

; Pointers to chunk decoding routines
chunk_ptrs      dd 0,0,0,0,offset FLI_256_COLOR,0,0,offset FLI_DELTA,0,0,0
                dd offset FLI_COLOR,offset FLI_LC,offset FLI_BLACK
                dd 0,offset FLI_BRUN,offset FLI_COPY,0,0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
fli_delta:
		xor     edx,edx
        mov     dx,[esi]
        add     esi,2
        decode_delta_line:
                movsx   ecx,word ptr [esi]
                add     esi,2
                or      ecx,ecx
                js      skip_delta_lines
                mov     ebp,edi
                mov     ebx,ecx
                or      bl,bl
                jz      next_delta_line
                decode_delta_packets:
                        xor     ecx,ecx
                        mov     cl,[esi]
                        add     edi,ecx
                        movsx   ecx,byte ptr [esi+1]
                        or      cl,cl
                        jns     delta_cl_bytes_copied
                                mov     ax,[esi+2]
                                or      cl,cl
                                jz      dont_copy_delta_byte
                                neg     ecx
                                rep     stosw
                                dont_copy_delta_byte:
                                add     esi,4
                                jmp     delta_packet_done
                        delta_cl_bytes_copied:
                                add     esi,2
                                or      cl,cl
                                jz      delta_packet_done
                                rep     movsw
                delta_packet_done:
                dec     bl
                jnz     decode_delta_packets
                next_delta_line:
                mov     edi,ebp
                add     edi,frame_width
        delta_line_ends:
        dec     edx
        jnz     decode_delta_line

        jmp     cont_decoding

        skip_delta_lines:
        neg     ecx
        imul    ecx,frame_width
        add     edi,ecx
        jmp     decode_delta_line

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
fli_lc:
        movzx eax,word ptr [esi]
        mul frame_width
        add edi,eax
        mov dx,[esi+2]
        add esi,4
        decode_lc_line:
                mov bl,[esi]
                inc esi
                or bl,bl
                jz next_line
                mov ebp,edi
                decode_lc_packets:
                        movzx ecx,byte ptr [esi]
                        add edi,ecx
                        movzx ecx,byte ptr [esi+1]
                        or cl,cl
                        jns lc_cl_bytes_copied
                                mov al,[esi+2]
                                or cl,cl
                                jz dont_copy_lc_byte
                                neg cl
                                rep stosb
                                dont_copy_lc_byte:
                                add esi,3
                                jmp lc_packet_done
                        lc_cl_bytes_copied:
                                add esi,2
                                or cl,cl
                                jz lc_packet_done
                                rep movsb
                lc_packet_done:
                dec bl
                jnz decode_lc_packets
                mov edi,ebp
                next_line:
                add edi,frame_width
        lc_line_ends:
        dec dx
        jnz decode_lc_line
jmp cont_decoding
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
fli_brun:
        mov edx,frame_height
        decode_brun:
                push edi
                mov bl,[esi]
                inc esi
                decode_brun_line:
                        movsx ecx,byte ptr [esi]
                        or ecx,ecx
                        js brun_cl_bytes_copied
                                mov al,[esi+1]
                                rep stosb
                                add esi,2
                                jmp brun_packet_done
                        brun_cl_bytes_copied:
                                inc esi
                                neg ecx
                                rep movsb
                brun_packet_done:                        
                dec bl
                jnz decode_brun_line
                pop edi
                add edi,frame_width
        dec edx
        jnz decode_brun
jmp cont_decoding
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
fli_color:
        xor eax,eax
        mov dx,[esi]    ; number of packets        
        add esi,2
        decode_colors:
				; Update color index
				xor ecx,ecx
				mov cl,[esi]
                add eax,ecx
                mov cl,[esi+1]
                add	esi,2
                ; Set RGB values for consecutive color indices
                put_rgbs:
						AssertD eax, _LEu, 255
						mov	bl,[esi]
						shl	bl,2
						mov	byte ptr [cur_palette+eax*4+2],bl
						mov	bl,[esi+1]
						shl	bl,2
						mov	byte ptr [cur_palette+eax*4+1],bl
						mov	bl,[esi+2]
						shl	bl,2
						mov	byte ptr [cur_palette+eax*4],bl
						add esi,3
						inc	eax
                dec cl
                jnz put_rgbs
        dec dx
        jnz decode_colors        
jmp cont_decoding
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
fli_256_color:
        xor eax,eax
        mov dx,[esi]    ; number of packets
        add esi,2
        decode_256_colors:
				; Update color index
				xor ecx,ecx
				mov cl,[esi]
                add eax,ecx
                mov cl,[esi+1]
                add esi,2
                ; Set RGB values for consecutive color indices
                put_256_rgbs:
						AssertD eax, _LEu, 255
                        mov bl,[esi]
                        mov byte ptr [cur_palette+eax*4+2],bl
                        mov bl,[esi+1]
                        mov byte ptr [cur_palette+eax*4+1],bl
                        mov bl,[esi+2]
                        mov byte ptr [cur_palette+eax*4],bl
                        add esi,3
                        inc	eax
                dec cl
                jnz put_256_rgbs
        dec dx
        jnz decode_256_colors
jmp cont_decoding
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
fli_copy:
        mov edx,frame_height
        copy_fli_frame:
                mov ecx,frame_width
                shr ecx,1
                rep movsw
        dec edx
        jnz copy_fli_frame
jmp cont_decoding
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
fli_black:
        xor eax,eax
        mov edx,frame_height
        put_black_fli:
                mov ecx,frame_width
                shr ecx,1
                rep stosw
        dec edx
        jnz put_black_fli
jmp cont_decoding
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        ret
        
DecodeFLIFrame  endp

.data
FLIProcs        Loader <offset FLITestFile, offset StartProc, offset LoadFLIFrame, offset CloseProc>

.data?
TestPool        dd ?
FilePool        dd ?
FLen            dd ?
frame_size		dd ?
frame_width		dd ?
frame_height	dd ?
cur_frame_encoded_data	dd ?
decoded_frame	dd ?
cur_palette		dd 256 dup(?)
end
