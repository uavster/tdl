;�����������������������������������������������������������������������������
; Graphics loader
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / The DarkRising)
;�����������������������������������������������������������������������������
.386p
.model flat
.code
        INCLUDE loader.inc
        INCLUDE stderror.inc
        INCLUDE sli.inc
        INCLUDE blitter.inc
        INCLUDE pcx.inc
        INCLUDE fli.inc

GRAPHIC_FORMATS EQU 2
LOAD_PROCS      EQU offset PCXProcs, offset FLIProcs

CleanUpTemp proc
		    ; Free temporary SLI        
        mov     eax,source_sli
        test    eax,eax
        jz      no_source_sli
        call    DestroySLI
        no_source_sli:
        
		    ; Clean up after format handler
        mov     edi,format_handler
        call    [Loader ptr edi.EndProc]

        ret
endp

CleanUpOutputSLI proc
        mov     eax,our_sli
        test    eax,eax
        jz      no_our_sli
        call    DestroySLI
        no_our_sli:
        ret
endp

;�����������������������������������������������������������������������������
; Loads a graphic file into a memory SLI
;
; INPUT  : EAX -> GFX file name
;          EBX = Output SLI color depth (number of bits)
;
; OUTPUT : CF = 0 if success
;               EAX = NULL
;               EBX -> Memory SLI
;          CF = 1 if error
;               EAX = Error code
;               EBX = NULL
;�����������������������������������������������������������������������������
LoadGFX proc
        push    ebp
        mov     source_sli,0
        mov     our_sli,0

        mov     sli_c,ebx
        mov     ecx,GRAPHIC_FORMATS
        xor     esi,esi
        try_formats:
                push    ecx eax esi
                mov     edx,eax
                mov     edi,[LoadProcs+esi*4]
                push    edi
                call    [Loader ptr edi.TestProc]
                mov     real_x,eax
                mov     real_y,ebx
                mov     real_c,ecx
                mov     real_frames,esi
                mov		encoded_frames,edx
                mov		real_fps,ebp
                pop     edi
                pop     esi ebx ecx
                jnc     found_format
                cmp     eax,INVALID_FORMAT
                jnz     load_error
				mov		eax,ebx
                inc     esi
        loop    try_formats
        mov     eax,INVALID_FORMAT
        xor     ebx,ebx
        stc
        pop     ebp
        ret

        found_format:       
        mov     format_handler,edi
        mov     edx,ebx
        call    [Loader ptr edi.InitProc]
        jc      load_error

        mov     eax,real_x
        mov     ebx,real_y
        mov     ecx,real_c
        shl     ecx,3
        mov     edx,1
        call    CreateVoidSLI
        jc      load_error
        mov     source_sli,ebx

        mov     eax,real_x
        mov     ebx,real_y
        mov     ecx,sli_c        
        mov     edx,real_frames
        call    CreateSLI
        jc      load_error
        mov     our_sli,ebx

        ; Set fps
        mov		eax,our_sli
        mov		ebx,real_fps
        call	SetFrameRate
        jc		load_error

        mov		cur_frame, 0
        mov		decoded_frame,0
        decompress_frames:
				; Load image
                mov     edi, format_handler
                mov		ecx, cur_frame	; Frame number to decompress
                call    [Loader ptr edi.LoadProc]
                jc      load_error             
                
                ; If frame was skipped, don't do anything with it
                test	ecx,ecx
                jz		no_skipped_frames
						add	cur_frame,ecx
				        jmp	decode_next_frame
				no_skipped_frames:
				        
                ; Set palette, if any
                push    eax
                mov     eax, source_sli
                call    SetPalette
                pop     ecx
                
                ; Set frame pointer
                mov     eax,source_sli
                xor		ebx, ebx	; Use frame 0 of temporary SLI
                call    SetFramePtr
				jc		load_error
                
                ; Set current frame for blitting
                mov     eax,source_sli
                xor		ebx, ebx
                call    SetFrame
				jc		load_error				
                
                ; Set frame number of destination SLI
                mov     eax,our_sli
                mov		ebx, decoded_frame	; Current frame number
                call    SetFrame
				jc		load_error
                
                ; Blit source SLI to destination SLI
                mov     esi, source_sli
                mov     edi, our_sli
                call    Blit
                jc      load_error
                
                mov		eax,our_sli
                mov		eax,[eax.SLIFramePtr]
                inc		decoded_frame
		        inc		cur_frame
                
        decode_next_frame:
        mov		eax, encoded_frames
        cmp     cur_frame, eax
        jnz     decompress_frames
        
        ; Set destination SLI to first frame
        mov     eax,our_sli
        xor     ebx,ebx
        call    SetFrame

        call    CleanUpTemp

    		; Return values
        mov     ebx,our_sli
        clc
        pop     ebp
        ret

        load_error:
        call    CleanUpTemp
        call    CleanUpOutputSLI
        xor     ebx,ebx
        stc
        pop     ebp
        ret
LoadGFX endp

.data
LoadProcs       dd LOAD_PROCS

.data?
sli_c           dd ?
real_x          dd ?
real_y          dd ?
real_c          dd ?
real_frames     dd ?
encoded_frames  dd ?
real_fps		dd ?
source_sli      dd ?
our_sli         dd ?
format_handler  dd ?
cur_frame		dd ?
decoded_frame	dd ?

end
