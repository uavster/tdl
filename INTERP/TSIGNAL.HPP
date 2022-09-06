#ifndef TIMESIGNAL_H_
#define TIMESIGNAL_H_

#include "list.hpp"

using namespace std;

template<class _T> class TimeSignal {
public:
	TimeSignal();
	virtual ~TimeSignal();

	class KeyPoint {
	public:
		float time;
		_T value;

		inline KeyPoint(float time, _T value) { this->time = time; this->value = value; }
		inline KeyPoint() { this->time = 0.0; }
		inline bool operator < (const KeyPoint &kp) { return time < kp.time; }
	};

	void addKeyPoint(float time, const _T &value, bool deferredSort = true);
	void addKeyPoint(const KeyPoint &keyPoint, bool deferredSort = true);
	void addKeyPoints(list<KeyPoint> &keyPoints, bool deferredSort = true);
	void removeKeyPoint(float time);
	void removeAllKeyPoints();

	bool getKeyPoint(float time, KeyPoint *kp = NULL);

	// WARNING: const is omitted for flexibility, but if any key point time is changed in outer code, the list MUST be resorted
	inline list<KeyPoint> &getKeyPoints() { if (dirty) sort(false); return keypoints; }

	void getNeighborKeyPoints(float time, int numNeighbors, KeyPoint *neighbors);

protected:
	void sort(bool defer);
private:
	list<KeyPoint> keypoints;
	list<KeyPoint>::const_iterator currentKeyPoint;
	bool dirty;		// If true, the list needs to be sorted
};

#include "tsignal.hh"

#endif /* TIMESIGNAL_H_ */