#include "tdl.h"

#define MAGIC_NUMBER	3456
class MyClass {
public:
	MyClass() : a(MAGIC_NUMBER) {
		printf("Constructor\n");
	}
	~MyClass() {
		printf("Destructor\n");
	}
	MyFunction() {
		printf("Member function; a = %dn\n", a);
	}

	int a;
};

int main() {
	printf("-- Stack object --\n");
	{
		MyClass stack_obj;
		if (stack_obj.a != MAGIC_NUMBER) {
			printf("Constructor was not called!\n");
		}
		stack_obj.MyFunction();
	}
	
	printf("\n-- Heap object --\n");
	{
		MyClass *heap_obj = new MyClass;
		if (heap_obj->a != MAGIC_NUMBER) {
			printf("Constructor was not called!\n");
		}
		heap_obj->MyFunction();
		delete heap_obj;
	}
	
	printf("\n");
	return 0;
}