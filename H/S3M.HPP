#ifndef __S3M_CPP_HEADER__
#define __S3M_CPP_HEADER__

#include "s3m.h"

typedef ES3MInstrumentType S3MInstrumentType;
typedef ES3MInstrumentPacking S3MInstrumentPacking;
typedef ES3MTrackerID S3MTrackerID;
typedef ES3MSamplesFormat S3MSamplesFormat;

#define kEndRowIndex	-1

/*class S3MRowIterator {
public:
	friend class S3MPattern;

	S3MPatternRowIterator operator++();
	void operator+=(int offset);
	void operator-=(int offset);
	S3MPatternRowIterator &operator=(int row);

private:
	S3MPatternRowIterator(const S3MPattern *pattern, int row);
	int current_row_;
	S3MPattern *pattern_;
};*/

class S3MCell {
public:
	friend class S3MCellIterator;
	
	BYTE ChannelNumber() const;
	
	bool HasNoteAndInstrument() const;
	BYTE Note() const;
	char NoteLetter() const;
	bool IsSemitone() const;
	BYTE Octave() const;
	void GetNoteName(char *name) const;
	BYTE Instrument() const;
	
	bool HasVolume() const;
	BYTE Volume() const;

	bool HasEffect() const;
	char Effect() const;
	BYTE EffectValue() const;

protected:
	S3MCell(const BYTE *cell);
	
private:
	const BYTE *cell_;
};

class S3MCellIterator {
public:
	friend class S3MRow;

	S3MCellIterator operator++(int);	
	void operator+=(int increment);
	bool operator==(const S3MCellIterator &it) const;
	bool operator!=(const S3MCellIterator &it) const;
	S3MCell Cell() const;

protected:
	S3MCellIterator(int num_bytes, const BYTE *cells, int byte_index);

private:
	int byte_index_;
	int num_bytes_;
	const BYTE *cells_;
};

class S3MRow {
public:
	friend class S3MSong;

	S3MCellIterator begin() const;
	S3MCellIterator end() const;

private:
	int num_bytes_;
	const BYTE *cells_;
};

class S3MPattern {
public:
	friend class S3MSong;
	
	int NumRows() const;
	const S3MRow *Row(int row_index) const;
	
protected:
	const TS3MPattern &Pattern() const;

private:
	TS3MSong *song_;
	int index_;
	S3MRow rows_[64];
};

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
	
	const BYTE Order(const int order_index) const;	
	const S3MPattern *Pattern(const int pattern_index) const;
	const S3MInstrument *Instrument(const int instrument_index) const;
		
private:
	TS3MSong *song_;
	S3MInstrument *instruments_;
	S3MPattern *patterns_;
};

#endif