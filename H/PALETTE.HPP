#include "stddef.h"
#include "sli.h"
#include "vector.hpp"

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
