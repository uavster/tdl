#include "tdl.h"

class MyClass {
public:
	MyClass() {
		printf("Constructor\n");
	}
	~MyClass() {
		printf("Destructor\n");
	}
	MyFunction() {
		printf("Member function\n");
	}
};

int main() {
	MyClass my_class;
	my_class.MyFunction();
	return 0;
}