;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Wave mixer 
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / the DarkRising)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

; Flags in TChannel.Flags
MIXER_CHANNEL_ALLOCATED		EQU 1
MIXER_CHANNEL_EDITED		EQU 2
MIXER_CHANNEL_AUTO_FREE		EQU 4
MIXER_CHANNEL_IS_LOOPING	EQU 8

; Sound digital channel structure
TChannel        STRUC
		Flags			dd ?	; Channel flags (see above)
        ChanWave        dd ?    ; Pointer to TWave structure or NULL if not active
		FreqMultiplier	dd ?	; Fixed point 8.24
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
; Allocates a channel
;
; It is safe to call this function from main code and IRQs. Channel data races
; are avoided by disabling interrupts.
;
; Allocating a new channel from outside the mixer callback will not take
; effect until the next tick, so please do not play a sound in the new channel
; from the callback until it is effectively allocated.
;
; INPUT  : EAX = Flags: MIXER_CHANNEL_AUTO_FREE
; OUTPUT : CF = 0 if channel allocated
;				EBX -> Free channel's TChannel structure
;          CF = 1 if no free channels
;				EBX = NULL
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global	WUFAllocateChannel : NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Allocates a number of channels
;
; It is safe to call this function from main code and IRQs. Channel data races
; are avoided by disabling interrupts.
;
; Allocating a new channel from outside the mixer callback will not take
; effect until the next tick, so please do not play a sound in the new channel
; from the callback until it is effectively allocated.
;
; INPUT  : EAX = Flags: MIXER_CHANNEL_AUTO_FREE
;		   ECX = Number of channels to allocate
;		   EDI -> TChannel array with ECX or more capacity
; OUTPUT : CF = 0 if channel allocated
;		   		EAX = 0
;          CF = 1 if no free channels
;				EAX = Error code (NO_FREE_CHANNELS)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global WUFAllocateChannels : NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Frees a channel
;
; It is safe to call this function from main code and IRQs. Channel data races
; are not possible with a single atomic instruction.
;
; Freeing a channel from outside the mixer callback will not take effect until
; the next tick, so please keep the active sound in memory until then.
;
; INPUT  : EBX -> TChannel to free
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global	WUFFreeChannel : NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Frees channels
;
; It is safe to call this function from main code and IRQs. Channel data races
; are not possible with a single atomic instruction.
;
; Freeing a channel from outside the mixer callback will not take effect until
; the next tick, so please keep the active sound in memory until then.
;
; INPUT  : EBX -> TChannel pointer array
;		   ECX = Number of channel pointers in array
; OUTPUT : Freed channels pointer in input array are NULLed.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global	WUFFreeChannels : NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Plays a sound in a channel
;
; It is safe to call this function from main code and IRQs. Channel data races
; are avoided by disabling interrupts.
;
; Playing a new sound on a channel from outside the mixer callback will not take
; effect until the next tick, so please keep the active sound in memory until
; then.
;
; INPUT  : EAX -> TWave structure of sample to play in channel, or NULL to leave as is
;		   EBX -> TChannel where to play sound
;		   ECX = Frequency multiplier (fixed point 8.24)
;		   		 -1 plays the sound with the current channel frequency multiplier
;		   EDX = Volume multiplier, from 0 (silent) to 64 (as is). 
;				 -1 plays the sound with the current channel volume.
;		   ESI = Sample offset
;
; OUTPUT : CF = 0 if no error
;               EAX = NO_ERROR
;          CF = 1 if error
;               EAX = Error code
;					FREQUENCY_TOO_HIGH: Base frequency * multiplier > 16,776,960 Hz
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  WUFPlaySound : NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Returns a handler to a channel that may be used from inside a callback.
;
; INPUT  : EBX -> Allocated TChannel
; OUTPUT : EBX -> TChannel that can be used with WUFPlaySound from inside a
;			      callback
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global	WUFChannelInCallback : NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Mixes all active channels
;
; INPUT  : EAX -> Output buffer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  MixChannels : NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Adds a callback that will be called periodically from the playback IRQ
;
; This function can be called from any IRQ.
;
; INPUT  : EAX = Callback period in audio seconds (fixed point 16.16)
;				 Value must be lower than (2^32 - 1) / output_sampling_frequency
; 		   EBX -> Callback function
;				  Callback input is EDX -> Channel pool (TChannel elements),
;				  and EAX = Num. channels
;		   EDX = User-defined pointer
; NOTE: It's important that arguments of the callback follow Watcom's register
; calling convention (from left to right arguments): EAX, EDX, EBX, ECX.
;
; OUTPUT : CF = 0 if success
;		 		EAX -> TMixerCallback structure
;		   CF = 1 if error
;				EAX = NULL
;
; NOTE   : The audio period is not real time; the callback interrupts the 
;		   generation of the output audio buffer every number of samples 
; 		   corresponding to the callback period in seconds. If any channges
; 		   affecting the audio output are made in the callback, they will be 
;		   heard as periodic with one sampling period resolution, but the 
;		   callback may be called at any moment in real time.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  WUFAddMixerCallback : NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the period of a callback
;
; This function can be called from any IRQ.
;
; INPUT  : EBX = TMixerCallback structure of callback
;		   EAX = Callback period in audio seconds (fixed point 16.16)
;				 Value must be lower than (2^32 - 1) / (output_sampling_frequency * 256)
;
; NOTE   : The audio period is not real time; the callback interrupts the 
;		   generation of the output audio buffer every number of samples 
; 		   corresponding to the callback period in seconds. If any channges
; 		   affecting the audio output are made in the callback, they will be 
;		   heard as periodic with one sampling period resolution, but the 
;		   callback may be called at any moment in real time.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global	WUFSetMixerCallbackPeriod : NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Deletes a callback 
;
; This function can be called from any IRQ.
;
; INPUT  : EAX = TMixerCallback structure of callback to delete
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global	WUFDeleteMixerCallback	: NEAR

