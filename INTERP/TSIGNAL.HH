#include "list.hpp"
#include "except.hpp"
#include "tinymath.h"

#define TIME_SIGNAL_TIME_INC_OUTSIDE_BOUNDS		1.0f

#define template_def	template<class _T>
#define TimeSignal_		TimeSignal<_T>

template_def TimeSignal_::TimeSignal() : currentKeyPoint(keypoints.cend()), dirty(false), back_to_front_time(-1) {}

template_def TimeSignal_::TimeSignal(const TimeSignal &other) : keypoints(other.keypoints), currentKeyPoint(keypoints.size() == 0 ? keypoints.cend() : keypoints.cbegin()), dirty(other.dirty), back_to_front_time(other.back_to_front_time) {
}

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

template_def void TimeSignal_::getNeighborKeyPoints(float time0, int numNeighbors, KeyPoint *neighbors) {
	if (keypoints.size() == 0) throw Exception("[TimeSignal::getNeighborKeyPoints] No keypoints in this signal");

	if (keypoints.size() == 1) {
		float t = time0 - TIME_SIGNAL_TIME_INC_OUTSIDE_BOUNDS * (numNeighbors / 2 - 1);
		for (int i = 0; i < numNeighbors; ++i) {
			neighbors[i] = keypoints.front();
			neighbors[i].time = t;
			t += TIME_SIGNAL_TIME_INC_OUTSIDE_BOUNDS;
		}
		return;
	}

	if (dirty) sort(false);
	
	float time = time0;
	int num_periods = 0;
	float period = keypoints.back().time - keypoints.front().time + back_to_front_time;
	if (back_to_front_time >= 0) {
		if (time0 >= keypoints.front().time) {
			num_periods = floor((time0 - keypoints.front().time) / period);
			time = keypoints.front().time + fmod(time0 - keypoints.front().time, period);
		} else {
			num_periods = floor((keypoints.front().time - time0) / period);
			time = keypoints.back().time + back_to_front_time - fmod(keypoints.front().time - time0, period);
		}
	}
	
	// Time is inside bounds
	if (time >= keypoints.front().time && time <= keypoints.back().time + (back_to_front_time < 0 ? 0 : back_to_front_time)) {
		// Find nearest key point
		if (time > currentKeyPoint->time) {
			while(currentKeyPoint != keypoints.cend() && time > currentKeyPoint->time) ++currentKeyPoint;
			if (currentKeyPoint == keypoints.cend()) {
				--currentKeyPoint;
			} else {
				// Select closest key point in time between next and previous
				list<KeyPoint>::const_iterator it = currentKeyPoint;
				--it;
				if (time - it->time < currentKeyPoint->time - time) {
					--currentKeyPoint;
				}
			}
		} else if (time < currentKeyPoint->time) {
			while(currentKeyPoint != keypoints.cbegin() && time < currentKeyPoint->time) --currentKeyPoint;
			if (time < currentKeyPoint->time) {
				// Time is before first keypoint.
				if (back_to_front_time >= 0) {
					// Periodic signal. Is first or last closer?
					if (keypoints.front().time - time > back_to_front_time * 0.5) {
						currentKeyPoint = keypoints.cend();
						--currentKeyPoint;
					}					
				}
			} else {
				// Select closest key point in time between next and previous
				list<KeyPoint>::const_iterator it = currentKeyPoint;
				++it;
				if (it->time - time < time - currentKeyPoint->time) {
					++currentKeyPoint;
				}
			}
		}
		// Select the output vector index that corresponds to the closest key point, so the current time is as centered as possible in the interval
		int midIndex;
		if (time >= currentKeyPoint->time) {
			midIndex = ceil(0.5f * static_cast<float>(numNeighbors)) - 1;
		} else {
			midIndex = floor(0.5f * static_cast<float>(numNeighbors));
		}
	
		// Copy previous key points to the output buffer
		if (back_to_front_time < 0) {
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
			list<KeyPoint>::const_iterator it = currentKeyPoint;
			float kpt = it->time + num_periods * period;
			for (int i = midIndex - 1; i >= 0; --i) {
				if (it == keypoints.cbegin()) { it = keypoints.cend(); }
				float t0 = it->time;
				--it;
				kpt -= (it->time <= t0 ? t0 - it->time : back_to_front_time);
				neighbors[i] = *it;
				neighbors[i].time = kpt;
			}
			it = currentKeyPoint;
			kpt = it->time + num_periods * period;
			for (i = midIndex; i < numNeighbors; ++i) {			
				neighbors[i] = *it;
				neighbors[i].time = kpt;
				float t0 = it->time;
				++it;
				if (it == keypoints.cend()) { it = keypoints.cbegin(); }
				kpt += (it->time >= t0 ? it->time - t0 : back_to_front_time);
			}
		}
	} else {

		// Time is out of bounds. Generate time vector maintaining the time sequence.
		if (time < keypoints.front().time) {
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
			list<KeyPoint>::const_reverse_iterator it = keypoints.crbegin();
			bool gotOffset = false; float offset = 0.0f; int offsetIndex = 0;
			for (int i = numNeighbors - 1; i >= 0; --i) {
				neighbors[i] = *it;
				if (t > keypoints.back().time) {
					neighbors[i].time = t;
					t -= TIME_SIGNAL_TIME_INC_OUTSIDE_BOUNDS;
				} else {
					if (!gotOffset) { offset = keypoints.back().time - t; offsetIndex = i; gotOffset = true; }
					++it;
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