#include "except.hpp"
#include "stdio.h"

int num_tests = 0;

void NewTest(const char *name) {
	++num_tests;
	printf("Test %dn: ", num_tests);
	printf(name);
}

void CheckResult(const char *actual, const char *expected) {
	for (size_t i = 0; expected[i] == actual[i] && expected[i] != '\0'; ++i) {}	
	if (expected[i] == actual[i]) {
		printf(" [OK]\n");
	} else {
		printf(" [ERROR]\nExpected: ");
		printf(expected);
		printf("\nActual:   ");
		printf(actual);
		printf("\n");
		exit(1);
	}
}

#define EXPECT_EQ(actual, expected) { \
	CheckResult(actual, expected); \
}

int main() {
	{
		NewTest("ExceptionWithoutContext has correct description.");
		EXPECT_EQ(ExceptionWithoutContext().Description(), "Unknown exception");
	}
	{
		NewTest("MallocException has correct description.");
		EXPECT_EQ(MallocException().Description(), "Unable to allocate memory");
	}
	{
		NewTest("Exception has correct description.");
		EXPECT_EQ(Exception("foo").Description(), "foo");
	}
	
	printf("[SUCCESS] %dn tests passed.", num_tests);
	
	return 0;
}