.386p
.model flat
.stack 1000h
.code
        INCLUDE utils.inc
        INCLUDE wuf!.inc
        INCLUDE dma.inc

        INCLUDE sounddev.inc
        INCLUDE mixer.inc
        INCLUDE waveload.inc
		include assert.inc

KeyHandler	proc
		sub		eax,2
        mov     eax,[wav_ptr+eax*4]
        call    PlaySound
		ret
		endp
		
EscHandler	proc
		mov		exit_loop,1
		ret
		endp

start:
        InitDPMI
		
		mov		al,1
		mov		ebx,offset EscHandler
		call	add_key
		mov		al,2
		mov		ebx,offset KeyHandler
		call	add_key
		mov		al,3
		mov		ebx,offset KeyHandler
		call	add_key
		mov		al,4
		mov		ebx,offset KeyHandler
		call	add_key
		mov		al,5
		mov		ebx,offset KeyHandler
		call	add_key

        call    WUFInit
        ErrorExit "Error initializing wuF!"

		xor		esi,esi
		load_files:		
				mov     eax,[esi*4+wav_files]
				test	eax,eax
				jz		loading_done
				push	esi
				call    LoadWAVE
				pop		esi
				ErrorExit "Error: Can't load WAVE file"				
				mov     [wav_ptr+esi*4],eax
				mov	    ebx,[eax.WaveType]
				mov		ecx,ebx
				and		ecx,1
				inc		ecx
				shl		ecx,3
				mov		wbps,ecx
				shr		ebx,1
				and		ebx,1
				inc		ebx
				mov		wcps,ebx
				lea     ebx,[eax.BaseRate]
				mov     wrate,ebx
				lea     ebx,[eax.WaveLen]
				mov     wlen,ebx
				push	esi
				mov     esi,offset info_msg
				call    Printf
				pop		esi		
				inc		esi
		jmp		load_files

		loading_done:
		LPrintS ""
		LPrintS "Press keys 1-4 to mix the four different samples above. ESC to quit."
		
        wait_loop:
		cmp		exit_loop,0
        jz	    wait_loop

        call    WUFClose
        ErrorExit "Error closing wuF!"

        Exit

.data

wav_files		dd offset fname8mono, offset fname8stereo, offset fname16mono, offset fname16stereo,0

fname8mono   	db "W8M22K.WAV",0
fname8stereo   	db "W8S8K.WAV",0
fname16mono		db "W16M8K.WAV",0
fname16stereo	db "W16S44K.WAV",0

info_msg        db 13,10,"WAV type: %dn"
				dd offset wbps
				db " bits, %dn"
				dd offset wcps
				db " channel(s)"
                db 13,10,"Length: %dn"
wlen            dd ?
				db " samples"
                db 13,10,"Sampling rate: %dn"
wrate           dd ?
				db " Hz"
                db 13,10,0                        
wbps			dd ?
wcps			dd ?
exit_loop		db 0

comment #
sound_struc     TWave <0,offset my_sound,50000,44000,?>
sound_struc1     TWave <0,offset my_sound1,50000,44000,?>

my_sound LABEL
I=0
REPT 5000
db I,0,0,0,0,0,0,0,0,0,0
I=I XOR -1
ENDM

my_sound1 LABEL
I=0
REPT 625
db I,79 dup(0)
I=I XOR -1
ENDM
#
.data?
wav_ptr			dd ?,?,?,?

end start
