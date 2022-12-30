#include "tdl.h"
// #include "tsignal.hpp"
// #include "nn.hpp"
// #include "linear.hpp"
#include "cubic.hpp"

using namespace std;

int main() {
	TimeSignal<float> signal;	
	{
		signal.addKeyPoint(2.3f, 2.0f);
		signal.addKeyPoint(0.4f, 0.8f);

		CubicCatmullRomInterpolator<float> cubic_interpolator(signal);
		for (float t = 0; t < 2.9f; t += 0.3f) {
			printf("%dfn:%dfn ", t, cubic_interpolator.getValue(t));
		}
		printf("\n\n");
	}
	{
		TimeSignal<float> signal_periodic = signal;
		signal_periodic.setPeriodic(/*last_to_first_keypoint_time=*/0.7f);

		CubicCatmullRomInterpolator<float> cubic_interpolator_periodic(signal_periodic);
		for (float t = 0.4f; t < 3 * (1.9f + 0.7f) + 0.4f; t += 0.2f) {
			printf("%dfn:%dfn ", t, cubic_interpolator_periodic.getValue(t));
		}
		printf("\n");
	}
	return 0;
}