#include "stdio.h"
#include "string.h"

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
	char str[128];
	{
		NewTest("No formatting characters.");
		const char format[] = "hello, world.";
		sprintf(str, format);
		EXPECT_EQ(str, format);
	}
	{
		NewTest("Format one positive integer in decimal.");
		sprintf(str, "hello %dn", 12345);
		EXPECT_EQ(str, "hello 12345");
	}
	{
		NewTest("Format one negative integer in decimal.");
		sprintf(str, "hello %d-n", -12345);
		EXPECT_EQ(str, "hello -12345");
	}
	{
		NewTest("Format one positive integer in hexadecimal.");
		sprintf(str, "hello %dhn", 0xcafe9876);
		EXPECT_EQ(str, "hello CAFE9876");
	}
	{
		NewTest("Format one positive float.");
		sprintf(str, "hello %dfn", 1.2345);
		EXPECT_EQ(str, "hello 1.234499");
	}
	{
		NewTest("Format one negative float.");
		sprintf(str, "hello %dfn", -1.2345);
		EXPECT_EQ(str, "hello -1.234499");
	}
	
	printf("[SUCCESS] %dn tests passed.", num_tests);
	
	return 0;
}