#include "stddef.h"
#include "sli.h"
#include "vector.hpp"

using namespace std;

void UpdateSLIPixelsToNewPalette(SLI *sli, const vector<int> &new_index_from_old_index);
void SortSLIPaletteByLuminance(SLI *sli);
void CompressSLIPalette(SLI *sli, int in_range_first, int in_range_last, int out_range_first, int out_range_low);