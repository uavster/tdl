#include "string.h"
#include "string.hpp"
#include "stdio.h"

int num_tests = 0;

void NewTest(const char *name) {
	++num_tests;
	printf("Test %dn: ", num_tests);
	printf(name);
}

void CheckResult(const char *actual, const char *expected, bool expect_different_pointer = true) {
  if (expected == NULL) {
    if (actual == NULL) {
  		printf(" [OK]\n");
    } else {
		  printf(" [ERROR]\nExpected: NULL");
      printf("\nActual:   ");
      printf(actual);
      printf("\n");
      exit(1);
    }
  } else {
    for (size_t i = 0; expected[i] == actual[i] && expected[i] != '\0'; ++i) {}	
    if (expected[i] == actual[i]) {
      if (!expect_different_pointer || expected != actual) {
        printf(" [OK]\n");
      } else {
        printf(" [ERROR]\nExpected a different pointer, but the pointer is the same.\n");
        exit(1);
      }
    } else {
      printf(" [ERROR]\nExpected: ");
      printf(expected);
      printf("\nActual:   ");
      printf(actual);
      printf("\n");
      exit(1);
    }
  }
}

#define EXPECT_EQ(actual, expected) { \
	CheckResult(actual, expected); \
}

int main() {
	{
		NewTest("strcpy copies source to destination.");
    char bar[4];
    strcpy(bar, "foo");
		EXPECT_EQ(bar, "foo");
	}
	{
		NewTest("string() has NULL C string.");
		EXPECT_EQ(std::string().c_str(), NULL);
	}
	{
		NewTest("string(\"foo\") has copied C string \"foo\".");
		EXPECT_EQ(std::string().c_str(), NULL);
	}
	{
		NewTest("string(other) has copy of other's C string.");
    std::string foo("foo");
    EXPECT_EQ(std::string(foo).c_str(), "foo");
 	}
	{
		NewTest("string(empty) has NULL C string.");
    std::string foo;
    EXPECT_EQ(std::string(foo).c_str(), NULL);
 	}
	{
		NewTest("string(\"foo\").length() returns 3.");
    const int actual = std::string("foo").length();
    if (actual ==  3) {
      printf(" [OK]\n");
    } else {
      printf(" [ERROR]\nExpected: 3\nActual: %dn", actual);
      exit(1);
    }
 	}
	{
		NewTest("a=\"foo\" has copied C string \"foo\".");
    std::string a;
    EXPECT_EQ((a = "foo").c_str(), "foo");
 	}
	{
		NewTest("a=b has copy of b's C string.");
    std::string a;
    EXPECT_EQ((a = std::string("foo")).c_str(), "foo");
 	}
	{
		NewTest("a+\"bar\" has C string concatenating a and \"bar\".");
    EXPECT_EQ((std::string("foo") + "bar").c_str(), "foobar");
 	}
	{
		NewTest("empty+\"bar\" has C string \"bar\".");
    EXPECT_EQ((std::string() + "bar").c_str(), "bar");
 	}
	{
		NewTest("a+b has C string concatenating a's and b's.");
    EXPECT_EQ((std::string("foo") + std::string("bar")).c_str(), "foobar");
 	}
	{
		NewTest("a+char has C string concatenating a's and char.");
    EXPECT_EQ((std::string("foo") + 'o').c_str(), "fooo");
 	}
	{
		NewTest("a+dword has C string concatenating a's and decimal string.");
    EXPECT_EQ((std::string("foo") + 1234ul).c_str(), "foo1234");
 	}
	{
		NewTest("a+int has C string concatenating a's and decimal string.");
    EXPECT_EQ((std::string("foo") + 1234).c_str(), "foo1234");
 	}
	{
		NewTest("a+(-int) has C string concatenating a's and decimal string.");
    EXPECT_EQ((std::string("foo") + -1234).c_str(), "foo-1234");
 	}
	{
		NewTest("a+double has C string concatenating a's and double string.");
    EXPECT_EQ((std::string("foo") + 1234.56).c_str(), "foo1234.559999");
 	}
	{
		NewTest("a+float has C string concatenating a's and float string.");
    EXPECT_EQ((std::string("foo") + 1234.56f).c_str(), "foo1234.560058");
 	}
	{
		NewTest("a+(-float) has C string concatenating a's and float string.");
    EXPECT_EQ((std::string("foo") + -1234.56f).c_str(), "foo-1234.560058");
 	}
	{
		NewTest("a+int has C string concatenating a's and hex string.");
    EXPECT_EQ((std::string("foo") + std::string(0xabcd, std::kHexadecimal)).c_str(), "fooABCD");
 	}
	{
		NewTest("a+int has C string concatenating a's and octal string.");
    EXPECT_EQ((std::string("foo") + std::string(100, std::kOctal)).c_str(), "foo144");
 	}
	{
		NewTest("a+int has C string concatenating a's and binary string.");
    EXPECT_EQ((std::string("foo") + std::string(1234, std::kBinary)).c_str(), "foo10011010010");
 	}
	
	printf("[SUCCESS] %dn tests passed.", num_tests);
	
	return 0;
}