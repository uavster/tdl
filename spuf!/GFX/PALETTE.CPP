#include "list.hpp"
#include "palette.hpp"

class LuminanceComparableARGB {
public:
	LuminanceComparableARGB() {}
	LuminanceComparableARGB(int color_index, DWORD argb);
	bool operator<(const LuminanceComparableARGB &l) const;
	DWORD argb() const;
	int color_index() const;
	
private:
	DWORD argb_;
	DWORD luminance_;
	int color_index_;
};

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

void DieIfSLIHasNoPalette(const SLI *sli) {
	if (sli->SLIColorBits != 1) {
		throw Exception("The SLI does not have a color palette.");
	}
}

void UpdateSLIPixelsToNewPalette(SLI *sli, const vector<int> &new_index_from_old_index) {
	DieIfSLIHasNoPalette(sli);
	
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

void SortSLIPaletteByLuminance(SLI *sli) {
	DieIfSLIHasNoPalette(sli);
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
	
	UpdateSLIPixelsToNewPalette(sli, new_index_from_old_index);
}

class MixableARGB {
public:
	MixableARGB() : a_(0), r_(0), g_(0), b_(0), num_samples_(0) {}
	MixableARGB(DWORD argb) : a_((argb >> 24) & 0xff), r_((argb >> 16) & 0xff), g_((argb >> 8) & 0xff), b_(argb & 0xff), num_samples_(1) {}
	int a() const { return a_; }
	int r() const { return r_; }
	int g() const { return g_; }
	int b() const { return b_; }
	int num_samples() const { return num_samples_; }
	
	DWORD MeanARGB() {
		return ((a_ / num_samples_) << 24) | ((r_ / num_samples_) << 16) | ((g_ / num_samples_) << 8) | (b_ / num_samples_);
	}
	
	MixableARGB &operator+=(const MixableARGB &color) {
		a_ += color.a();
		r_ += color.r();
		g_ += color.g();
		b_ += color.b();
		num_samples_ += color.num_samples();
		return *this;
	}

private:
	DWORD a_;
	DWORD r_;
	DWORD g_;
	DWORD b_;
	DWORD num_samples_;
};

void CompressSLIPalette(SLI *sli, int in_range_first, int in_range_last, int out_range_first, int out_range_last) {
	DieIfSLIHasNoPalette(sli);
	if (in_range_first < 0 || in_range_first > 255) {
		throw Exception("in_range_first should be in [0, 255]");
	}
	if (in_range_last < 0 || in_range_last > 255) {
		throw Exception("in_range_last should be in [0, 255]");
	}
	if (out_range_first < 0 || out_range_first > 255) {
		throw Exception("out_range_first should be in [0, 255]");
	}
	if (out_range_last < 0 || out_range_last > 255) {
		throw Exception("out_range_last should be in [0, 255]");
	}
	if (out_range_last < 0 || out_range_last > 255) {
		throw Exception("out_range_last should be in [0, 255]");
	}
	
	const int out_range_len = out_range_last - out_range_first + 1;
	const int in_range_len = in_range_last - in_range_first + 1;
	if (in_range_len < out_range_len) {
		throw Exception("Palette range expansion is not supported; only compression.");
	}

	vector<int> new_index_from_old_index;
	new_index_from_old_index.reserve(256);
	for (int j = 0; j < 256; ++j) {
		new_index_from_old_index.push_back(j);
	}
	
	vector<MixableARGB> output_colors(out_range_len, MixableARGB());
	for (int i = 0; i < in_range_len; ++i) {
		const int old_index = in_range_first + i;
		const int new_index = (i * out_range_len) / in_range_len;
		new_index_from_old_index[old_index] = new_index + out_range_first;
		output_colors[new_index] += MixableARGB(sli->SLIPalette[old_index]);
	}

	for (int k = 0; k < output_colors.size(); ++k) {
		sli->SLIPalette[k + out_range_first] = output_colors[k].MeanARGB();
	}
	
	UpdateSLIPixelsToNewPalette(sli, new_index_from_old_index);
}

static void UnpackARGB(DWORD color, DWORD *a, DWORD *r, DWORD *g, DWORD *b) {
	*a = color >> 24;
	*r = (color >> 16) & 0xff;
	*g = (color >> 8) & 0xff;
	*b = color & 0xff;
}

static DWORD PackARGB(DWORD a, DWORD r, DWORD g, DWORD b) {
	return (a << 24) | (r << 16) | (g << 8) | b;
}

static DWORD Saturate(int n, int min, int max) {
	if (n < min) { return min; }
	if (n > max) { return max; }
	return n;
}

void MixWithSLIPalette(SLI *sli, DWORD *palette_to_mix) {
	for (int i = 0; i < 256; ++i) {
		DWORD a, r, g, b;
		UnpackARGB(palette_to_mix[i], &a, &r, &g, &b);
		DWORD as, rs, gs, bs;
		UnpackARGB(sli->SLIPalette[i], &as, &rs, &gs, &bs);
		r = ((255 - a) * rs + a * r) >> 8;
		g = ((255 - a) * gs + a * g) >> 8;
		b = ((255 - a) * bs + a * b) >> 8;
		sli->SLIPalette[i] = 0xff000000 | (r << 16) | (g << 8) | b;
	}
}

void CreateColorRamp(DWORD *palette, int first_index, DWORD first_color, int last_index, DWORD last_color) {
	int index_diff = last_index - first_index;
	if (index_diff < 0) {
		throw Exception("first_index must be lower than last_index.");
	}
	DWORD a0, r0, g0, b0;
	UnpackARGB(first_color, &a0, &r0, &g0, &b0);
	DWORD a1, r1, g1, b1;
	UnpackARGB(last_color, &a1, &r1, &g1, &b1);

	int a_diff = static_cast<int>(a1) - static_cast<int>(a0);
	int r_diff = static_cast<int>(r1) - static_cast<int>(r0);
	int g_diff = static_cast<int>(g1) - static_cast<int>(g0);
	int b_diff = static_cast<int>(b1) - static_cast<int>(b0);
	for (int i = 0; i < index_diff + 1; ++i) {
		palette[i + first_index] = PackARGB(Saturate((i * a_diff) / index_diff + static_cast<int>(a0), 0, 255), 
											Saturate((i * r_diff) / index_diff + static_cast<int>(r0), 0, 255), 
											Saturate((i * g_diff) / index_diff + static_cast<int>(g0), 0, 255),
											Saturate((i * b_diff) / index_diff + static_cast<int>(b0), 0, 255));
	}
}