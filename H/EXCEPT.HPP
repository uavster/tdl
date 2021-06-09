#ifndef __EXCEPT_HEADER__
#define __EXCEPT_HEADER__

class Exception {
public:
	Exception(const char *description);
	virtual ~Exception();

	const char *Description() const;
	
private:
	char *description_;
};

#endif