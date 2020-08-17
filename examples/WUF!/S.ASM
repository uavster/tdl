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

start:
        InitDPMI

        call    InitWUF
        ErrorExit "Error initializing wuF!"

;        mov     ecx,50000000
;        otro_bucle:
;        loop    otro_bucle
;
;        call    GetWUFProperties
;        shr     [eax.PlayRate],1
;        call    SetWUFProperties
;        ErrorExit "Error setting sound properties"

        mov     eax,offset fname8mono
        call    LoadWAVE
        ErrorExit "Error: Can't load WAVE file"
        mov     wave8m_ptr,eax

        mov     eax,offset fname16stereo
        call    LoadWAVE
        ErrorExit "Error: Can't load WAVE file"
        mov     wave16s_ptr,eax
		
        lea     ebx,[eax.WaveType]
        mov     wtype,ebx
        lea     ebx,[eax.BaseRate]
        mov     wrate,ebx
        lea     ebx,[eax.WavePtr]
        mov     wptr,ebx
        lea     ebx,[eax.WaveLen]
        mov     wlen,ebx
        mov     esi,offset info_msg
        call    Printf
        jmp     skip_msg

info_msg        db 13,10,"Wave type: %dn"
wtype           dd ?
                db 13,10,"Wave pointer: %dhn"
wptr            dd ?
                db "h",13,10,"Wave length: %dn"
wlen            dd ?
                db 13,10,"Wave sample rate: %dn"
wrate           dd ?
                db 13,10,0                        

        skip_msg:

;        mov     eax,offset sound_struc
;        call    PlaySound

;        mov     eax,offset sound_struc1
;        call    PlaySound

        mov     eax,wave16s_ptr
        call    PlaySound
				
        wait_bucle:		
        in      al,60h                
        dec     al
        jnz     wait_bucle

		mov		eax,wave8m_ptr
        call    PlaySound

        wait_bucle2:		
        in      al,60h
        cmp		al,2
        jnz     wait_bucle2
		
        call    CloseWUF
        ErrorExit "Error closing wuF!"

        Exit

.data

fname8mono   	db "demo8.wav",0
fname16stereo	db "demo16.wav",0

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
wave8m_ptr	dd ?
wave16s_ptr	dd ?

end start
