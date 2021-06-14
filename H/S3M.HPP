#ifndef __S3M_CPP_HEADER__
#define __S3M_CPP_HEADER__

#include "s3m.h"

typedef ES3MInstrumentType S3MInstrumentType;
typedef ES3MInstrumentPacking S3MInstrumentPacking;
typedef ES3MTrackerID S3MTrackerID;
typedef ES3MSamplesFormat S3MSamplesFormat;

class S3MInstrument {
public:
	friend class S3MSong;

	const char *Name() const;
	const S3MInstrumentType Type() const;
	int DefaultVolume() const;
	bool HasLoop() const;
	DWORD LoopStart() const;
	DWORD LoopEnd() const;
	bool IsStereo() const;
	bool Is16Bit() const;
	S3MInstrumentPacking Packing() const;
	DWORD C2Frequency() const;
	DWORD NumSamples() const;
	void *Samples() const;

protected:
	const TS3MInstrument &Instrument() const;

private:	
	TS3MSong *song_;
	int index_;
};

typedef union {
	WORD value;
	struct {
		BYTE major;
		BYTE minor;
	} parts;
} S3MTrackerVersion;

class S3MSong {
public:
	S3MSong(const char *file_path);
	virtual ~S3MSong();
	
	bool IsLoaded() const;
	
	const char *Name() const;
	
	int NumOrders() const;
	int NumInstruments() const;
	int NumPatterns() const;
	
	bool HasVolumeOptimization() const;
	bool HasAmigaLimits() const;

	S3MTrackerID TrackerID() const;
	const char *TrackerName() const;
	S3MTrackerVersion TrackerVersion() const;
	
	S3MSamplesFormat SamplesFormat() const;
	bool AreSamplesSigned() const;
	BYTE GlobalVolume() const;
	BYTE MasterVolume() const;
	BYTE InitialSpeed() const;
	BYTE InitialTempo() const;
	bool IsStereo() const;
	bool HasCustomPan() const;
	
	const S3MInstrument *Instrument(const int instrument_index) const;
	
	const BYTE Order(const int order_index) const;
	
private:
	TS3MSong *song_;
	S3MInstrument *instruments_;
};

#endif