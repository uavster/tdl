#include "stddef.h"
#include "sli.h"
#include "vector.hpp"

#ifndef PALETTE_INCLUDED_
#define PALETTE_INCLUDED_

using namespace std;

void UpdateSLIPixelsToNewPalette(SLI *sli, const vector<int> &new_index_from_old_index);
void SortSLIPaletteByLuminance(SLI *sli);
void CompressSLIPalette(SLI *sli, int in_range_first, int in_range_last, int out_range_first, int out_range_last);
void ExpandSLIPalette(SLI *sli, int in_range_first, int in_range_last, int out_range_first, int out_range_last);

// Mixes each color in palette_to_mix with the corresponding color in the SLI palette.
// The resulting color is: 
// SLIPalette[color_index].rgb = (1 - palette_to_mix[color_index].alpha) * SLIPalette[color_index].rgb + palette_to_mix[color_index].alpha * palette_to_mix[color_index].rgb
void MixWithSLIPalette(SLI *sli, DWORD *palette_to_mix);

void CreateColorRamp(DWORD *palette, int first_index, DWORD first_color, int last_index, DWORD last_color);

void ExpandAlphaMaskRange(SLI *alpha_mask);

class Color {
public:
  Color(DWORD abgr) : abgr_(abgr) {}
  BYTE r() const { return static_cast<BYTE>(abgr_); }
  BYTE g() const { return static_cast<BYTE>(abgr_ >> 8); }
  BYTE b() const { return static_cast<BYTE>(abgr_ >> 16); }
  BYTE a() const { return static_cast<BYTE>(abgr_ >> 24); }

private:
  DWORD abgr_;
};

class ColorMutableView {
public:
  ColorMutableView(DWORD *abgr) : abgr_(abgr) {}

  BYTE &r() const { return *reinterpret_cast<BYTE *>(abgr_); }
  BYTE &g() const { return *reinterpret_cast<BYTE *>(abgr_[1]); }
  BYTE &b() const { return *reinterpret_cast<BYTE *>(abgr_[2]); }
  BYTE &a() const { return *reinterpret_cast<BYTE *>(abgr_[3]); }

private:
  DWORD *abgr_;
};

class PaletteView {
public:
  // The passed buffer contains one DWORD per color in ABGR format.
  // It must be 256 DWORDs long.
  PaletteView(const DWORD *palette_buffer) : palette_buffer_(palette_buffer) {}

  Color operator[](int color_index) const;

  operator const DWORD*() { return palette_buffer_; }

private:
  const DWORD *const palette_buffer_;
};

class PaletteMutableView {
public:
  // The passed buffer contains one DWORD per color in ABGR format.
  // It must be 256 DWORDs long.
  PaletteMutableView(DWORD *palette_buffer) : palette_buffer_(palette_buffer) {}

  ColorMutableView operator[](int color_index) const;

  operator DWORD*() { return palette_buffer_; }

private:
  DWORD *palette_buffer_;
};
#endif