/*����������������������������������������������������������������������������
 WUF! C interface
 Author: Ignacio Mellado Bataller a.k.a. B52 / the DarkRising
����������������������������������������������������������������������������*/

#ifndef _WUF_INCLUDED_
#define _WUF_INCLUDED_

#include <stddef.h>

#ifdef __cplusplus
  extern "C" {
#endif

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
;�����������������������������������������������������������������������������
; Initializes all the stuff needed by wUf!
;
; OUTPUT -> CF = 0 if ok
;               EAX = NULL
;           CF = 1 if error
;               EAX = Error code
;�����������������������������������������������������������������������������
*/
int WUFInit(void);
#pragma aux WUFInit "*" modify [eax ebx ecx edx esi edi ebp] \
                        value  [eax];

/*
;�����������������������������������������������������������������������������
; Unitializes wUf!
;
; OUTPUT : CF = 0 if ok
;              EAX = NULL
;          CF = 1 if error
;              EAX = Error code
;�����������������������������������������������������������������������������
*/
int WUFClose(void);
#pragma aux WUFClose "*" modify [eax ebx ecx edx esi edi ebp] \
                          value  [eax];

/*
;�����������������������������������������������������������������������������
; Gets the underlying hardware capabilities
;
; INPUT : EAX -> SoundHardwareCapabilities structure to fill with playback capabilities, or NULL
;		  EBX -> SoundHardwareCapabilities structure to fill with recording capabilities, or NULL
;�����������������������������������������������������������������������������
*/
void WUFGetHardwareCapabilities(const SoundHardwareCapabilities *play_caps, const SoundHardwareCapabilities *rec_caps);
#pragma aux WUFGetHardwareCapabilities "*" 	parm [eax] [ebx]\
											modify [eax ebx ecx edx esi edi ebp];

/*
;�����������������������������������������������������������������������������
; Gets playback and recording properties
;
; INPUT : EAX -> SoundProperties structure to fill with playback properties, or NULL
;		  EBX -> SoundProperties structure to fill with recording properties, or NULL
;�����������������������������������������������������������������������������
*/
void WUFGetProperties(SoundProperties *play_props, SoundProperties *rec_props);
#pragma aux WUFGetProperties "*"	parm [eax] [ebx]\
									modify [eax ebx ecx edx esi edi ebp];

/*
;�����������������������������������������������������������������������������
; Sets playback and recording properties
;
; INPUT  : EAX -> Playback SoundProperties structure, or NULL
;		   EBX -> Recording SoundProperties structure, or NULL
;
; OUTPUT : CF = 0 if ok
;               EAX = 0
;          CF = 1 if hardware capabilities exceeded or device not responding
;               EAX = Error code
;�����������������������������������������������������������������������������
*/
int WUFSetProperties(const SoundProperties *play_props, const SoundProperties *rec_props);
#pragma aux WUFSetProperties "*"	parm [eax] [ebx]\
									modify [eax ebx ecx edx esi edi ebp]\
									value [eax];

typedef struct {
        DWORD WaveType;		// bit 0 : 8/16 bits ,  bit 1 : Mono/Stereo
        void *WavePtr;		// Sound data
        DWORD WaveLen;		// Sound length in samples
        DWORD BaseRate;		// Base sample rate
} TWave;

typedef struct {
        TWave *ChanWave;			// Pointer to TWave structure or NULL if not active
		DWORD SampleIncrement;		// Fixed point 24.8
        DWORD CurrentSample;		// Fixed point 24.8
} TChannel;

/*
;�����������������������������������������������������������������������������
; Sets a callback that will be called periodically from the playback IRQ
;
; INPUT  : EAX = Callback period in seconds (float)
; 		   EBX -> Callback function, or NULL to disable
;				  Callback input is EBX -> Channel pool (TChannel elements),
;				  and ECX = Num. channels
;�����������������������������������������������������������������������������
*/
void WUFSetMixerCallback(float period_s, void (*callback)(int num_channels, TChannel *channels));
#pragma aux WUFSetMixerCallback "*"	parm [eax] [ebx]\
									modify [eax ebx ecx edx esi edi ebp];

#ifdef __cplusplus
  };
#endif

#endif
