;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Wave mixer 
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / the DarkRising)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

SPECIFIC_CHANNEL		EQU 0
ANY_FREE_CHANNEL		EQU 80h

; Sound digital channel structure
TChannel        STRUC
        ChanWave        dd ?    ; Pointer to TWave structure or NULL if not active
		SampleIncrement	dd ?	; Fixed point 24.8
        CurrentSample   dd ?	; Fixed point 24.8
		Volume			dd ?	; Volume from 0 (silent) to 64 (original volume)
ENDS

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes mixer with a given channel number
;
; INPUT  : EAX = Mixing frequency
;		   BL = Bits per sample
;		   BH = Number of output channels
;		   CL = Maximum number of input channels
;		   EDX = Output buffer size (samples)
;
; OUTPUT : CF = 0 if ok
;               EAX = 0
;          CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  OpenMixer : NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Frees memory used by the mixer
;
; OUTPUT : CF = 0 if ok
;               EAX = NO_ERROR
;          CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  CloseMixer : NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Fills a channel with the given wave
;
; This function may be called from an IRQ, but it is not reentrant.
; TODO: make it reentrant with atomic allocation of channels, so that a module
; can be played, while triggering sounds with the keyboard, for instance.
;
; INPUT  : EAX -> TWave structure
;		   If BH == SPECIFIC_CHANNEL, BL contains the channel number on which to play.
;		   If BH == ANY_FREE_CHANNEL, the sound is played on any free channel greater 
;		   or equal than BL.
;		   ECX = Frequency multiplier (fixed point 8.24)
;		   EDX = Volume multiplier (0-64)
;		   ESI = Sample offset
;
; OUTPUT : CF = 0 if no error
;               EAX = NO_ERROR
;				BL = Channel playing the sound
;          CF = 1 if error
;               EAX = Error code
;					NO_FREE_CHANNELS: No available channels
;					FREQUENCY_TOO_HIGH: Base frequency * multiplier > 16,776,960 Hz
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  WUFPlaySound : NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Plays sound (interfaces with C++)
;
; INPUT  : EAX -> TWave structure
;		   If BH == SPECIFIC_CHANNEL, BL contains the channel number on which to play.
;		   If BH == ANY_FREE_CHANNEL, the sound is played on any free channel greater 
;		   or equal than BL.
;		   ECX = Frequency multiplier (fixed point 8.24)
;		   EDX = Volume multiplier (0-64)
;		   ESI = Sample offset
;		   EDI = Pointer to output error code, or NULL if not needed
;
; OUTPUT : If no error,
;				EBX = Channel playing the sound
;				Input pointee = NO_ERROR
;          If error,
;				EBX = -1
;				Input pointee =
;					NO_FREE_CHANNELS: No available channels
;					FREQUENCY_TOO_HIGH: Base frequency * multiplier > 16,776,960 Hz
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  PlaySound_cpp : NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Mixes all active channels
;
; INPUT  : EAX -> Output buffer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  MixChannels : NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets a callback that will be called periodically from the playback IRQ
;
; INPUT  : ST0 = Callback period in seconds
; 		   EBX -> Callback function, or NULL to disable
;				  Callback input is EDX -> Channel pool (TChannel elements),
;				  and EAX = Num. channels
; NOTE: It's important that arguments of the callback follow Watcom's register
; calling convention (from left to right arguments): EAX, EDX, EBX, ECX.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  SetMixerCallback : NEAR
