;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; WAV file loader
;       Ignacio Mellado Bataller ( B52 / the DarkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code

        INCLUDE wav.inc
        INCLUDE waveload.inc
        INCLUDE filesys.inc
        INCLUDE stderror.inc
        INCLUDE alloc.inc
        INCLUDE wuf!.inc

FORMAT_TAG_PCM	EQU 1

WAVFile STRUC
        rID             db "    "       ; "RIFF" signature
        rLen            dd ?

        rData           LABEL
        wID             db "    "       ; "WAVE" signature

        FormatChunk     LABEL
        fID             db "    "       ; "fmt " signature
        fLen            dd ?
        wFormatTag      dw ?
        nChannels       dw ?
        nSamplesPerSec  dd ?
        nAvgBytesPerSec dd ?
        nBlockAlign     dw ?
        FormatSpecific  dw ?

        WAVEDataChunk   LABEL
        dID             db "    "       ; "data" signature
        dLen            dd ?

        dData           LABEL
ENDS

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Tests if the given file is a WAV file
;
; INPUT  : EAX -> ASCIIZ file name
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
TestWAV proc
        mov     edx,eax
        mov     ecx,size WAVFile
        xor     esi,esi
        mov     edi,offset TestBuffer
        call    load_data_chunk
        ErrorCode eax

        cmp     dword ptr TestBuffer.rID,'FFIR'
        jnz     format_error_label
        cmp     dword ptr TestBuffer.wID,'EVAW'
        jnz     format_error_label
        cmp     dword ptr TestBuffer.fID,' tmf'
        jnz     format_error_label
        cmp     dword ptr TestBuffer.dID,'atad'
        jnz     format_error_label
        clc
        ret

        format_error_label:
        mov     eax,INVALID_FORMAT
        stc
        ret

TestBuffer      WAVFile <>
TestWAV endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Loads a WAV file into memory
;
; INPUT  : EAX -> ASCIIZ file name
;
; OUTPUT : CF = 0 if ok
;               EAX -> TWave structure
;          CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
LoadWAV proc
        mov     ecx,TestBuffer.dLen
        add     ecx,size TWave
        push    eax
        call    malloc
        pop     edx
        ErrorCode MALLOC_ERROR
        lea     edi,[ebx+size TWave]
        mov     ecx,TestBuffer.dLen
        mov     esi,offset dData
        push    ebx
        call    load_data_chunk
        pop     ebx
        ErrorCode eax
		
		cmp		TestBuffer.wFormatTag, FORMAT_TAG_PCM
		jz		is_pcm
				mov	eax,INVALID_FORMAT
				stc
				ret

		is_pcm:
        lea     eax,[ebx+size TWave]
        mov     [ebx.WavePtr],eax
        mov     eax,TestBuffer.nSamplesPerSec
        mov     [ebx.BaseRate],eax
		mov		[ebx.BaseVolume],64

        movzx   edi,TestBuffer.nChannels
		dec		edi
		cmp		edi,1
		jbe		num_channels_ok
				mov	eax,INVALID_FIELD
				stc
				ret

		num_channels_ok:
		shl		edi,1
        movzx   eax,TestBuffer.FormatSpecific	; This is bits per sample, if PCM
		shr		eax,3
		dec		eax
        or      eax,edi
        mov     [ebx.WaveType],eax

		xor		edx,edx
		mov     eax,TestBuffer.dLen
		movzx	ecx,TestBuffer.nChannels
		div		ecx
		movzx	ecx,TestBuffer.FormatSpecific
		shr		ecx,3
		div		ecx
        mov     [ebx.WaveLen],eax
		mov		[ebx.LoopStart],-1
		mov		[ebx.LoopEnd],-1

        mov     eax,ebx
        ret
LoadWAV endp

.data
WAVFileLoader   WAVELoader <offset TestWAV, offset LoadWAV>

end
