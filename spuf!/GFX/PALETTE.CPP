#include "list.hpp"
#include "palette.hpp"

using namespace std;

LuminanceComparableARGB::LuminanceComparableARGB(DWORD argb) : argb_(argb) {
	DWORD r = (argb >> 16) & 0xff;
	DWORD g = (argb >> 8) & 0xff;
	DWORD b = argb & 0xff;
	luminance_ = 0.299f * r * r + 0.587f * g * g + 0.114f * b * b;
}

bool LuminanceComparableARGB::operator<(const LuminanceComparableARGB &l) const {
	return luminance_ < l.luminance_;
}

DWORD LuminanceComparableARGB::argb() const { return argb_; }

void SortSLIPaletteLuminance(SLI *sli) {
	list<LuminanceComparableARGB> palette;
	for (int i = 0; i < 256; ++i) {
		palette.push_back(LuminanceComparableARGB(sli->SLIPalette[i]));
	}
	palette.sort();
	for (list<LuminanceComparableARGB>::const_iterator it = palette.cbegin(); it != palette.cend(); ++it) {
		sli->SLIPalette[i] = it->argb();
	}
}