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

// Channel flags									
#define kMixerChannelAllocated		1
#define kMixerChannelEdited			2
#define kMixerChannelAutoFree		4
									
typedef struct {
		DWORD Flags;			 	// Channel flags (see above)
        TWave *ChanWave;			// Pointer to TWave structure or NULL if not active
		DWORD FreqMultiplier; 		// Fixed point 8.24
		DWORD SampleIncrement;		// Fixed point 24.8
        DWORD CurrentSample;		// Fixed point 24.8
		DWORD Volume;				// Volume from 0 (silent) to 64 (original volume)
} TChannel;

typedef void * HMixerCallback;
#define kHMixerCallbackInvalid	NULL

/*
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
*/
HMixerCallback WUFAddMixerCallback(DWORD period_s, void (*callback)(HMixerCallback callback_handler, void *user_pointer), void *user_pointer);
#pragma aux WUFAddMixerCallback "*"	parm [eax] [ebx] [edx]\
									modify [eax ebx ecx edx esi edi ebp]\
									value [eax];

/*									
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
*/
void WUFSetMixerCallbackPeriod(HMixerCallback hMixerCallback, DWORD period_s);
#pragma aux WUFSetMixerCallbackPeriod 	"*"	parm [ebx] [eax]\
										modify [eax ebx ecx edx esi edi ebp];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Deletes a callback 
;
; This function can be called from any IRQ.
;
; INPUT  : EAX = TMixerCallback structure of callback to delete
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void WUFDeleteMixerCallback(HMixerCallback hMixerCallback);
#pragma aux WUFDeleteMixerCallback	"*"	parm [eax]\
									modify [eax ebx ecx edx esi edi ebp];
									
/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Allocates a channel at or above a given number
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
*/
TChannel *WUFAllocateChannel(int flags);
#pragma aux WUFAllocateChannel "*"	parm [eax]\
									modify [eax ebx ecx edx esi edi ebp]\
									value [ebx];

/*
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
;		   EDI -> TChannel pointer array with ECX or more capacity
; OUTPUT : CF = 0 if channel allocated
;		   		EAX = 0
;          CF = 1 if no free channels
;				EAX = Error code (NO_FREE_CHANNELS)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
int WUFAllocateChannels(int flags, int num_channels, TChannel **channels);
#pragma aux WUFAllocateChannels "*"	parm [eax] [ecx] [edi]\
									modify [eax ebx ecx edx esi edi ebp]\
									value [eax];

/*
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
*/
void WUFFreeChannel(TChannel *channel);
#pragma aux WUFFreeChannel "*"	parm [ebx]\
								modify [eax ebx ecx edx esi edi ebp];

/*
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
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void WUFFreeChannels(int num_channels, TChannel **channels);
#pragma aux WUFFreeChannels "*"	parm [ecx] [ebx]\
								modify [eax ebx ecx edx esi edi ebp];

/*
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
; INPUT  : EAX -> TWave structure of sample to play in channel, or NULL to leave as is.
;				  Setting a new sample sets the offset to zero.
;		   EBX -> TChannel where to play sound.
;		   ECX = Frequency multiplier (fixed point 8.24).
;		   		 -1 plays the sound with the current channel frequency multiplier.
;		   EDX = Volume multiplier, from 0 (silent) to 64 (as is). 
;				 -1 plays the sound with the current channel volume.
;		   ESI = New wave offset (fixed point 24.8), or -1 to leave as is. 
;				 The sound won't loop if the offset is beyond the loop end. 
;				 No sound is played if the offset is beyond the sound end.
;
; OUTPUT : CF = 0 if no error
;               EAX = NO_ERROR
;          CF = 1 if error
;               EAX = Error code
;					FREQUENCY_TOO_HIGH: Base frequency * multiplier > 16,776,960 Hz
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
int WUFPlaySound(const TWave *wave, TChannel *channel, DWORD freq_multiplier, DWORD volume, DWORD sample_offset);
#pragma aux WUFPlaySound "*"	parm [eax] [ebx] [ecx] [edx] [esi]\
								modify [eax ebx ecx edx esi edi ebp]\
								value [eax];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Pauses the current sound in a channel
;
; It is safe to call this function from main code and IRQs.
;
; INPUT  : EBX -> TChannel where sound is playing
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void WUFPauseSound(TChannel *channel);
#pragma aux WUFPauseSound "*"	parm [ebx];
								
/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Returns a handler to a channel that may be used from inside a callback.
;
; INPUT  : EBX -> Allocated TChannel
; OUTPUT : EBX -> TChannel that can be used with WUFPlaySound from inside a
;			      callback
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
TChannel *WUFChannelInCallback(const TChannel *channel);
#pragma aux WUFChannelInCallback "*"	parm [ebx]\
										modify [ebx]\
										value [ebx];
								
#ifdef __cplusplus
  };
#endif

#endif

