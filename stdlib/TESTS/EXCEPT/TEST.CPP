#include "except.hpp"
#include "stdio.h"
#include "debug.h"

int num_tests = 0;

class Test {
public:
  Test(const char *name) {
    ++num_tests;
    printf("Test %dn: ", num_tests);
    printf(name);
  }

  virtual ~Test() {
    // Test was ok if program was not interrupted.
    printf(" [OK]\n");
  }
};

#define NewTest(name) const Test test = Test(name);

void CheckResultEqual(const void *actual, const void *expected) {
  if (expected == NULL) {
    if (actual != NULL) {
		  printf(" [ERROR]\nExpected: NULL");
      printf("\nActual:   != NULL");
      printf("\n");
  		exit(1);
    }
    return;
  }
  const char *expected_str = static_cast<const char *>(expected);
  const char *actual_str = static_cast<const char *>(actual);
	for (size_t i = 0; expected_str[i] == actual_str[i] && expected_str[i] != '\0'; ++i) {}	
	if (expected_str[i] != actual_str[i]) {
		printf(" [ERROR]\nExpected: ");
		printf(expected_str);
		printf("\nActual:   ");
		printf(actual_str);
		printf("\n");
		exit(1);
	}
}

void CheckResultNotEqual(const void *actual, const void *expected) {
  if (expected == NULL) {
    if (actual == NULL) {
		  printf(" [ERROR]\nExpected: != NULL");
      printf("\nActual:   NULL");
      printf("\n");
  		exit(1);
    }
    return;
  }
  const char *expected_str = static_cast<const char *>(expected);
  const char *actual_str = static_cast<const char *>(actual);
	for (size_t i = 0; expected_str[i] == actual_str[i] && expected_str[i] != '\0'; ++i) {}	
	if (expected_str[i] == actual_str[i]) {
		printf(" [ERROR]\nExpected: != ");
		printf(expected_str);
		printf("\nActual:   ");
		printf(actual_str);
		printf("\n");
		exit(1);
	}
}


#define EXPECT_EQ(actual, expected) { \
	CheckResultEqual(actual, expected); \
}

#define EXPECT_NE(actual, expected) { \
	CheckResultNotEqual(actual, expected); \
}

const static char exception_in_func_msg[] = "Exception thrown in function call";

void ThrowException() {
  throw Exception(exception_in_func_msg);
}

void ThrowExceptionCatchAndRethrow() {
  try {
    throw Exception(exception_in_func_msg);
  } catch(...) {
    throw GetLastException();
  }
}

int main() {
	{
		NewTest("ExceptionWithoutContext has correct description.");
		EXPECT_EQ(ExceptionBase().Description(), "Unknown exception");
	}
	{
		NewTest("MallocException has correct description.");
		EXPECT_EQ(MallocException().Description(), "Unable to allocate memory");
	}
	{
		NewTest("Exception has correct description.");
		EXPECT_EQ(Exception("foo").Description(), "foo");
	}

  // Exception support in Watcom 11 C++ compiler is enabled by our library hooks.
  // The only catch is that we can't reliably set the exception as a parameter in the catch block,
  // which needs to call GetLastException() instead.
  // Test different try-catch cases.

	{
		NewTest("GetLastExceptionPtr returns NULL if no previous throw.");
		EXPECT_EQ(GetLastExceptionPtr(), NULL);
	}

	{
		NewTest("Catch block gets exception thrown in try block.");
    const char exception_msg[] = "test exception";
    const ExceptionBase *actual = NULL;
    try {
      throw Exception(exception_msg);
    } catch(...) {
      actual = GetLastExceptionPtr();
    }
    EXPECT_NE(actual, NULL);
		EXPECT_EQ(actual->Description(), exception_msg);
	}

	{
		NewTest("GetLastException throws if no previous throw.");
    const ExceptionBase *actual = NULL;
    try {
      GetLastException();
    } catch(...) {
      actual = GetLastExceptionPtr();
    }
    EXPECT_NE(actual, NULL);
		EXPECT_EQ(actual->Description(), NoExceptionThrown().Description());
	}

	{
		NewTest("GetLastException returns exception if previous throw.");
    const ExceptionBase *actual = NULL;
    const char exception_msg[] = "test exception";
    try {
      throw Exception(exception_msg);
    } catch(...) {
      actual = &GetLastException();
    }
    EXPECT_NE(actual, NULL);
		EXPECT_EQ(actual->Description(), exception_msg);
	}

  {
		NewTest("GetLastException returns right exception after two try-catch.");
    const ExceptionBase *actual = NULL;
    const char exception1_msg[] = "first exception";
    const char exception2_msg[] = "second exception";
    try {
      throw Exception(exception1_msg);
    } catch(...) {
      actual = &GetLastException();
    }
    try {
      throw Exception(exception2_msg);
    } catch(...) {
      actual = &GetLastException();
    }
    EXPECT_NE(actual, NULL);
		EXPECT_EQ(actual->Description(), exception2_msg);
	}

  {
		NewTest("Catch block gets exception after try-catch at same level.");
    const ExceptionBase *actual = NULL;
    const Exception decoy_exception("decoy exception");
    const char exception_msg[] = "true exception";
    try {
    } catch(...) {
      actual = &decoy_exception;
    }
    try {
      throw Exception(exception_msg);
    } catch(...) {
      actual = &GetLastException();
    }
    EXPECT_NE(actual, NULL);
		EXPECT_EQ(actual->Description(), exception_msg);
	}

  {
		NewTest("Catch block gets exception before try-catch at same level.");
    const ExceptionBase *actual = NULL;
    const Exception decoy_exception("decoy exception");
    const char exception_msg[] = "true exception";
    try {
      throw Exception(exception_msg);
    } catch(...) {
      actual = &GetLastException();
    }
    try {
    } catch(...) {
      actual = &decoy_exception;
    }
    EXPECT_NE(actual, NULL);
		EXPECT_EQ(actual->Description(), exception_msg);
	}

/*
  // This case is unsupported because the compiler does not generate any call at the end of a try block for us to 
  // locally unwind the try-catch; therefore, the throw will target the inner try-catch instead of the containing one.
  {
		NewTest("GetLastExceptionPtr returns NULL when throw is after try-catch.");
    const ExceptionBase *actual = NULL;
    const char exception_msg[] = "test exception";
    try {
      try {
      } catch(...) {
      }
      throw Exception(exception_msg);
    } catch(...) {      
    }
    EXPECT_EQ(actual, NULL);
	}
*/

	{
		NewTest("GetLastExceptionPtr returns NULL after catch block.");
    try {
      throw Exception("test exception");
    } catch(...) {
    }
    EXPECT_EQ(GetLastExceptionPtr(), NULL);
	}

	{
		NewTest("Try calling function that throws; catch block gets exception.");
    const ExceptionBase *actual = NULL;
    try {
      ThrowException();
    } catch(...) {
      actual = GetLastExceptionPtr();
    }
    EXPECT_NE(actual, NULL);
    EXPECT_EQ(actual->Description(), exception_in_func_msg);
  }

	{
		NewTest("Try calling function that rethrows; catch block gets exception.");
    const ExceptionBase *actual = NULL;
    try {
      ThrowExceptionCatchAndRethrow();
    } catch(...) {
      actual = GetLastExceptionPtr();
    }
    EXPECT_NE(actual, NULL);
    EXPECT_EQ(actual->Description(), exception_in_func_msg);
  }

	{
		NewTest("Outer catch block gets exception re-thrown at inner catch block.");
    const char exception_msg[] = "test exception";
    const ExceptionBase *actual = NULL;
    try {
      try {
        throw Exception("something else");
      } catch(...) {
        throw Exception(exception_msg);
      }
    } catch(...) {
      actual = GetLastExceptionPtr();
    }
    EXPECT_NE(actual, NULL);
		EXPECT_EQ(actual->Description(), exception_msg);
	}

	printf("[SUCCESS] %dn tests passed.", num_tests);
	
	return 0;
}