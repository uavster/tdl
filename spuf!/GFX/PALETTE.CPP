#include "list.hpp"
#include "palette.hpp"

using namespace std;

LuminanceComparableARGB::LuminanceComparableARGB(int color_index, DWORD argb) : argb_(argb), color_index_(color_index) {
	DWORD r = (argb >> 16) & 0xff;
	DWORD g = (argb >> 8) & 0xff;
	DWORD b = argb & 0xff;
	luminance_ = 0.299f * r * r + 0.587f * g * g + 0.114f * b * b;
}

bool LuminanceComparableARGB::operator<(const LuminanceComparableARGB &l) const {
	return luminance_ < l.luminance_;
}

DWORD LuminanceComparableARGB::argb() const { return argb_; }

int LuminanceComparableARGB::color_index() const { return color_index_; }

void SortSLIPaletteLuminance(SLI *sli) {
	if (sli->SLIColorBits != 1) {
		throw Exception("The SLI does not have a color palette.");
	}
	// Build a list with the palette colors to sort by luminance.
	list<LuminanceComparableARGB> palette;
	for (int i = 0; i < 256; ++i) {
		palette.push_back(LuminanceComparableARGB(i, sli->SLIPalette[i]));
	}
	palette.sort();
	
	// Create a mapping from old to new color indices to remap pixels.
	vector<int> new_index_from_old_index(palette.size());
	int new_index = 0;
	for (list<LuminanceComparableARGB>::const_iterator it = palette.cbegin(); it != palette.cend(); ++it, ++new_index) {
		sli->SLIPalette[new_index] = it->argb();
		new_index_from_old_index[it->color_index()] = new_index;
	}
	
	// Change color indices for all pixels in every frame.
	for (int f = 0; f < GetNumFrames(sli); ++f) {		
		BYTE *ptr = static_cast<BYTE *>(GetFramePtr(sli, f));
		for (int j = 0; j < sli->SLIYSize; ++j) {
			for (int i = 0; i < sli->SLIXSize; ++i, ++ptr) {
				*ptr = new_index_from_old_index[*ptr];
			}
			ptr += sli->SLIPitch - sli->SLIXSize;
		}
	}
}