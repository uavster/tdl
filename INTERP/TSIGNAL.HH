#include "list.hpp"
#include "except.hpp"
#include "tinymath.h"

#define TIME_SIGNAL_TIME_INC_OUTSIDE_BOUNDS		1.0f

#define template_def	template<class _T>
#define TimeSignal_		TimeSignal<_T>

template_def TimeSignal_::TimeSignal() : dirty(false), currentKeyPoint(keypoints.cend()) {}

template_def TimeSignal_::~TimeSignal() {
}

template_def void TimeSignal_::sort(bool defer) {
	if (!defer) {
		keypoints.sort();
		if (currentKeyPoint == keypoints.cend()) currentKeyPoint = keypoints.cbegin();
	}
	dirty = defer;
}

template_def void TimeSignal_::addKeyPoint(float time, const _T &value, bool deferredSort) {
	addKeyPoint(KeyPoint(time, value), deferredSort);
}

template_def void TimeSignal_::addKeyPoint(const KeyPoint &keyPoint, bool deferredSort) {
	keypoints.push_back(keyPoint);
	sort(deferredSort);
}

template_def void TimeSignal_::addKeyPoints(list<KeyPoint> &keyPoints, bool deferredSort) {
	for(list<KeyPoint>::const_iterator it = keyPoints.cbegin(); it != keyPoints.cend(); ++it) {
		keypoints.push_back(*it);
	}
	sort(deferredSort);
}

template_def void TimeSignal_::removeKeyPoint(float time) {
	for (list<KeyPoint>::const_iterator it = keypoints.cbegin(); it != keypoints.cend(); ++it) {
		if (it->time == time) {
			// Relocate the current key point
			if (currentKeyPoint == it) {
				++currentKeyPoint;
				if (currentKeyPoint == keypoints.cend()) {
					currentKeyPoint = it;
					if (currentKeyPoint == keypoints.cbegin()) currentKeyPoint = keypoints.cend();
					else --currentKeyPoint;
				}
			}
			keypoints.erase(it);
			return;
		}
	}
}

template_def void TimeSignal_::removeAllKeyPoints() {
	keypoints.clear();
	currentKeyPoint = keypoints.cend();
}

template_def void TimeSignal_::getNeighborKeyPoints(float time, int numNeighbors, KeyPoint *neighbors) {
	if (keypoints.size() == 0) throw Exception("[TimeSignal::getNeighborKeyPoints] No keypoints in this signal");

	if (keypoints.size() == 1) {
		float t = time - TIME_SIGNAL_TIME_INC_OUTSIDE_BOUNDS * (numNeighbors / 2 - 1);
		for (int i = 0; i < numNeighbors; ++i) {
			neighbors[i] = keypoints.front();
			neighbors[i].time = t;
			t += TIME_SIGNAL_TIME_INC_OUTSIDE_BOUNDS;
		}
		return;
	}

	if (dirty) sort(false);

	// Time is inside bounds
	if (time >= keypoints.cbegin()->time && time <= keypoints.back().time) {

		// Find nearest key point
		if (time > currentKeyPoint->time) {
			while(currentKeyPoint != keypoints.cend() && time > currentKeyPoint->time) ++currentKeyPoint;
			if (currentKeyPoint == keypoints.cend()) --currentKeyPoint;
			else {
				// Select closest key point in time between next and previous
				list<KeyPoint>::const_iterator it = currentKeyPoint;
				--it;
				if (fabs(time - it->time) < fabs(currentKeyPoint->time - time)) {
					--currentKeyPoint;
				}
			}
		} else if (time < currentKeyPoint->time) {
			while(currentKeyPoint != keypoints.cbegin() && time < currentKeyPoint->time) --currentKeyPoint;
			// Select closest key point in time between next and previous
			list<KeyPoint>::const_iterator it = currentKeyPoint;
			++it;
			if (fabs(it->time - time) < fabs(time - currentKeyPoint->time)) {
				++currentKeyPoint;
			}
		}

		// Select the output vector index that corresponds to the closest key point, so the current time is as centered as possible in the interval
		int midIndex;
		if (time >= currentKeyPoint->time)
			midIndex = ceil(0.5f * static_cast<float>(numNeighbors)) - 1;
		else
			midIndex = floor(0.5f * static_cast<float>(numNeighbors));

		// Copy previous key points to the output buffer
		list<KeyPoint>::const_iterator it = currentKeyPoint;
		float inc = 0.0f;
		for (int i = midIndex - 1; i >= 0; --i) {
			if (it == keypoints.cbegin()) it = keypoints.cend();
			else if (it != keypoints.cend()) --it;

			if (it != keypoints.cend()) {
				neighbors[i] = *it;
			} else {
				neighbors[i] = keypoints.front();
				inc -= TIME_SIGNAL_TIME_INC_OUTSIDE_BOUNDS;
				neighbors[i].time += inc;
			}
		}
		// Copy current and next key points to the output buffer
		it = currentKeyPoint;
		inc = 0.0f;
		for (i = midIndex; i < numNeighbors; ++i) {
			if (it != keypoints.cend()) {
				neighbors[i] = *it;
			} else {
				neighbors[i] = keypoints.back();
				inc += TIME_SIGNAL_TIME_INC_OUTSIDE_BOUNDS;
				neighbors[i].time += inc;
			}

			if (it != keypoints.cend()) ++it;
		}

	} else {

		// Time is out of bounds. Generate time vector maintaining the time sequence.
		if (time < keypoints.cbegin()->time) {
			currentKeyPoint = keypoints.cbegin();
			float t = time - TIME_SIGNAL_TIME_INC_OUTSIDE_BOUNDS * (numNeighbors / 2 - 1);
			list<KeyPoint>::const_iterator it = keypoints.cbegin();
			bool gotOffset = false; float offset = 0.0f; int offsetIndex = 0;
			for (int i = 0; i < numNeighbors; ++i) {
				neighbors[i] = *it;
				if (t < keypoints.cbegin()->time) {
					neighbors[i].time = t;
					t += TIME_SIGNAL_TIME_INC_OUTSIDE_BOUNDS;
				} else {
					if (!gotOffset) { offset = keypoints.cbegin()->time - t; offsetIndex = i; gotOffset = true; }
					++it;
				}
			}
			if (gotOffset) for (int i = 0; i < offsetIndex; ++i) neighbors[i].time += offset;
		} else {
			currentKeyPoint = --keypoints.cend();
			float t = time + TIME_SIGNAL_TIME_INC_OUTSIDE_BOUNDS * (numNeighbors / 2 - 1);
			list<KeyPoint>::const_iterator it = --keypoints.cend();
			bool gotOffset = false; float offset = 0.0f; int offsetIndex = 0;
			for (int i = numNeighbors - 1; i >= 0; --i) {
				neighbors[i] = *it;
				if (t > keypoints.back().time) {
					neighbors[i].time = t;
					t -= TIME_SIGNAL_TIME_INC_OUTSIDE_BOUNDS;
				} else {
					if (!gotOffset) { offset = keypoints.back().time - t; offsetIndex = i; gotOffset = true; }
					--it;
				}
			}
			if (gotOffset) for (int i = offsetIndex + 1; i < numNeighbors; ++i) neighbors[i].time += offset;
		}

	}
}

template_def bool TimeSignal_::getKeyPoint(float time, TimeSignal_::KeyPoint *kp) {
	for (list<KeyPoint>::const_iterator it = keypoints.cbegin(); it != keypoints.cend(); ++it) {
		if (it->time == time) { 
			if (kp != NULL) (*kp) = (*it);
			return true; 
		}
	}
	return false;
}

#undef TIME_SIGNAL_TIME_INC_OUTSIDE_BOUNDS
#undef template_def
#undef TimeSignal_