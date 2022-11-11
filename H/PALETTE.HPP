#include "stddef.h"
#include "sli.h"

class LuminanceComparableARGB {
public:
	LuminanceComparableARGB() {}
	LuminanceComparableARGB(DWORD argb);
	bool operator<(const LuminanceComparableARGB &l) const;
	DWORD argb() const;
	
private:
	DWORD argb_;
	DWORD luminance_;
};

void SortSLIPaletteLuminance(SLI *sli);