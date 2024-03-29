;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; wUf! - Wave Buffer
;       Ignacio Mellado Bataller ( B52 / the DarkRising )
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

include mixer.inc
include waveload.inc

MAX_MIXER_CHANNELS		EQU 64

SoundBuffer		STRUC
        Pointer			dd ?
        NumBytes	    dd ?
ENDS

SoundProperties STRUC
        SPSamplingRate        		dd ?
		SPBitsPerSample				db ?
		SPNumChannels				db ?
ENDS

SoundCapability STRUC
		SCMinSamplingRate			dd ?
        SCMaxSamplingRate    		dd ?
		SCBitsPerSample				db ?
		SCNumChannels				db ?
ENDS

SoundHardwareCapabilities   STRUC
		NumCapabilities				db ?
		Capabilities				dd ?	; Offset of array of SoundCapability
ENDS

; Wave structure
TWave           STRUC
        WaveType        dd ?    ; bit 0 : 8/16 bits ,  bit 1 : Mono/Stereo
        WavePtr         dd ?    ; -> Sound data
        WaveLen         dd ?    ; Sound length in samples
        BaseRate        dd ?    ; Base sample rate
		BaseVolume		dd ?	; Base sample volume
		LoopStart		dd ?	; Sample index where loop starts (included); -1 and -2 are reserved values.
		LoopEnd			dd ?	; Sample index where loop ends (not included); no loop if LoopStart==LoopEnd==-1; -1 and -2 are reserved values.
ENDS

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Initializes all the stuff needed by wUf!
;
; OUTPUT -> CF = 0 if ok
;               EAX = NULL
;           CF = 1 if error
;               EAX = Error code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global  WUFInit : NEAR

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Unitializes wUf!
;
; OUTPUT : CF = 0 if ok
;              EAX = NULL
;          CF = 1 if error
;              EAX = Error code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global  WUFClose : NEAR

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Gets the underlying hardware capabilities
;
; INPUT : EAX -> SoundHardwareCapabilities structure to fill with playback capabilities, or NULL
;		  EBX -> SoundHardwareCapabilities structure to fill with recording capabilities, or NULL
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global WUFGetHardwareCapabilities : NEAR

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Gets playback and recording properties
;
; INPUT : EAX -> SoundProperties structure to fill with playback properties, or NULL
;		  EBX -> SoundProperties structure to fill with recording properties, or NULL
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global  WUFGetProperties : NEAR

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Sets playback and recording properties
;
; INPUT  : EAX -> Playback SoundProperties structure, or NULL
;		   EBX -> Recording SoundProperties structure, or NULL
;
; OUTPUT : CF = 0 if ok
;               EAX = 0
;          CF = 1 if hardware capabilities exceeded or device not responding
;               EAX = Error code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global  WUFSetProperties : NEAR
