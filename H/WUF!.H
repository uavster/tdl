/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 WUF! C interface
 Author: Ignacio Mellado Bataller a.k.a. B52 / the DarkRising
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/

#ifndef _WUF_INCLUDED_
#define _WUF_INCLUDED_

#include <stddef.h>
#include "waveload.h"

#ifdef __cplusplus
  extern "C" {
#endif

#define kWUFChannelAutoFree		4

typedef struct {
        DWORD SPSamplingRate;
		BYTE SPBitsPerSample;
		BYTE SPNumChannels;
} SoundProperties;

typedef struct {
		DWORD SCMinSamplingRate;
        DWORD SCMaxSamplingRate;
		BYTE SCBitsPerSample;
		BYTE SCNumChannels;
} SoundCapability;

typedef struct {
		BYTE NumCapabilities;
		SoundCapability *Capabilities;
} SoundHardwareCapabilities;

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes all the stuff needed by wUf!
;
; OUTPUT -> CF = 0 if ok
;               EAX = NULL
;           CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
int WUFInit(void);
#pragma aux WUFInit "*" modify [eax ebx ecx edx esi edi ebp] \
                        value  [eax];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Unitializes wUf!
;
; OUTPUT : CF = 0 if ok
;              EAX = NULL
;          CF = 1 if error
;              EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
int WUFClose(void);
#pragma aux WUFClose "*" modify [eax ebx ecx edx esi edi ebp] \
                          value  [eax];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the underlying hardware capabilities
;
; INPUT : EAX -> SoundHardwareCapabilities structure to fill with playback capabilities, or NULL
;		  EBX -> SoundHardwareCapabilities structure to fill with recording capabilities, or NULL
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void WUFGetHardwareCapabilities(const SoundHardwareCapabilities *play_caps, const SoundHardwareCapabilities *rec_caps);
#pragma aux WUFGetHardwareCapabilities "*" 	parm [eax] [ebx]\
											modify [eax ebx ecx edx esi edi ebp];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets playback and recording properties
;
; INPUT : EAX -> SoundProperties structure to fill with playback properties, or NULL
;		  EBX -> SoundProperties structure to fill with recording properties, or NULL
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void WUFGetProperties(SoundProperties *play_props, SoundProperties *rec_props);
#pragma aux WUFGetProperties "*"	parm [eax] [ebx]\
									modify [eax ebx ecx edx esi edi ebp];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets playback and recording properties
;
; INPUT  : EAX -> Playback SoundProperties structure, or NULL
;		   EBX -> Recording SoundProperties structure, or NULL
;
; OUTPUT : CF = 0 if ok
;               EAX = 0
;          CF = 1 if hardware capabilities exceeded or device not responding
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
int WUFSetProperties(const SoundProperties *play_props, const SoundProperties *rec_props);
#pragma aux WUFSetProperties "*"	parm [eax] [ebx]\
									modify [eax ebx ecx edx esi edi ebp]\
									value [eax];

typedef struct {
        TWave *ChanWave;			// Pointer to TWave structure or NULL if not active
		DWORD SampleIncrement;		// Fixed point 24.8
        DWORD CurrentSample;		// Fixed point 24.8
} TChannel;

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets a callback that will be called periodically from the playback IRQ
;
; INPUT  : EAX = Callback period in seconds (float)
; 		   EBX -> Callback function, or NULL to disable
;				  Callback input is EBX -> Channel pool (TChannel elements),
;				  and ECX = Num. channels
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void WUFSetMixerCallback(float period_s, void (*callback)(int num_channels, TChannel *channels));
#pragma aux WUFSetMixerCallback "*"	parm [8087] [ebx]\
									modify [eax ebx ecx edx esi edi ebp 8087];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Allocates a channel at or above a given number
;
; INPUT  : EAX = Flags: MIXER_CHANNEL_AUTO_FREE
; OUTPUT : CF = 0 if channel allocated
;				EBX -> Free channel's TChannel structure
;          CF = 1 if no free channels
;				EBX = NULL
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
TChannel *WUFAllocateChannel(int flags);
#pragma aux WUFAllocateChannel "*"	parm [eax]\
									modify [eax ebx ecx edx esi edi ebp]\
									value [ebx];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Frees a channel
;
; INPUT  : EBX -> TChannel to free
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void WUFFreeChannel(TChannel *channel);
#pragma aux WUFFreeChannel "*"	parm [ebx]\
								modify [eax ebx ecx edx esi edi ebp];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Plays a sound in a channel
;
; INPUT  : EAX -> TWave structure of sample to play in channel
;		   EBX -> TChannel where to play sound
;		   ECX = Frequency multiplier (fixed point 8.24)
;		   EDX = Volume multiplier (0-64)
;		   ESI = Sample offset
;
; OUTPUT : CF = 0 if no error
;               EAX = NO_ERROR
;          CF = 1 if error
;               EAX = Error code
;					FREQUENCY_TOO_HIGH: Base frequency * multiplier > 16,776,960 Hz
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
int WUFPlaySound(const TWave *wave, TChannel *channel, DWORD freq_multiplier, DWORD volume, DWORD sample_offset);
#pragma aux WUFPlaySound "*"	parm [eax] [ebx] [ecx] [edx] [esi] [edi]\
								modify [eax ebx ecx edx esi edi ebp]\
								value [eax];

#ifdef __cplusplus
  };
#endif

#endif

