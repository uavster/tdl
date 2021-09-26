#include "tdl.h"
#include "list.hpp"

void PrintList(PointerList<int> &list) {
	printf("Elements:");
	list.Restart();
	int *next = list.Next();
	if (next == NULL) {
		return;
	}
	printf("%dn", *next);
	while((next = list.Next()) != NULL) {
		printf(",%dn", *next);
	}
	printf("\n");
}

int main() {
	int numbers[] = { 1, 2, 3, 4, 5};
	
	printf("Creating list...\n");
	PointerList<int> list;
	PrintList(list);
	
	printf("Inserting 2 at end...\n");
	list.Insert(&numbers[1]);
	PrintList(list);

	printf("Inserting 4 at end...\n");
	list.Insert(&numbers[3]);
	PrintList(list);

	printf("Inserting 3 after 2...\n");
	list.Insert(&numbers[2], 1);
	PrintList(list);
	
	printf("Inserting 1 at start...\n");
	list.Insert(&numbers[0], 0);
	PrintList(list);
	
	printf("Deleting 2...\n");
	list.Erase(&numbers[1]);
	PrintList(list);
	
	return 0;
}