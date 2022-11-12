#include "stddef.h"
#include "sli.h"

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

void SortSLIPaletteLuminance(SLI *sli);