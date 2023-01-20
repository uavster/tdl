#include "tdl.h"

void CheckResult(const int *expected, const SLI *actual_sli) {
	const int *actual = actual_sli->SLIIntegralImage;
	const int len = actual_sli->SLIXSize * actual_sli->SLIYSize;
	bool are_equal = true;
	for (int i = 0; i < len; ++i) {
		if (expected[i] != actual[i]) {
			are_equal = false;
			break;
		}
	}	
	
	printf(" ");
	if (are_equal) {
		printf("[OK]\n");
	} else {
		printf("[ERROR]\nExpected: ");
		for (i = 0; i < len; ++i) {
			printf("%dn ", expected[i]);
		}
		printf("\nActual: ");
		for (i = 0; i < len; ++i) {
			printf("%dn ", actual[i]);
		}
		exit(1);
	}
}

void CheckCreateIntegralImage(SLI *sli) {
	int error_code = CreateIntegralImage(sli);
	if (error_code) {
		printf("[ERROR] CreateIntegralImage failed with error %dn.\n", error_code);
		exit(2);
	}
}

int num_tests = 0;

void NewTest(const char *name) {
	++num_tests;
	printf("Test %dn: ", num_tests);
	printf(name);
	printf(".");
}

int main() {
	NewTest("CreateIntegralImage does nothing with zero with and height SLI");
	{
		SLI *sli = CreateSLI(0, 0, 8, 1);
		CheckCreateIntegralImage(sli);
		DestroySLI(sli);
		printf("\n");
	}

	NewTest("CreateIntegralImage does nothing with zero height SLI");
	{
		SLI *sli = CreateSLI(2, 0, 8, 1);
		CheckCreateIntegralImage(sli);
		DestroySLI(sli);
		printf("\n");
	}

	NewTest("CreateIntegralImage does nothing with zero width SLI");
	{
		SLI *sli = CreateSLI(0, 2, 8, 1);
		CheckCreateIntegralImage(sli);
		DestroySLI(sli);
		printf("\n");
	}

	NewTest("CreateIntegralImage works with 1x1 SLI");
	{
		SLI *sli = CreateSLI(1, 1, 8, 1);
		((BYTE *)GetCurrentFramePtr(sli))[0] = 1;
		CheckCreateIntegralImage(sli);
		const int expected[] = { 1 };
		CheckResult(expected, sli);
		DestroySLI(sli);
	}

	NewTest("CreateIntegralImage works with 3x1 SLI");
	{
		SLI *sli = CreateSLI(3, 1, 8, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(sli);
		pixels[0] = 1;
		pixels[1] = 2;
		pixels[2] = 3;
		CheckCreateIntegralImage(sli);
		const int expected[] = { 1, 3, 6 };
		CheckResult(expected, sli);
		DestroySLI(sli);
	}

	NewTest("CreateIntegralImage works with 1x3 SLI");
	{
		SLI *sli = CreateSLI(1, 3, 8, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(sli);
		pixels[0] = 1;
		pixels[1] = 2;
		pixels[2] = 3;
		CheckCreateIntegralImage(sli);
		const int expected[] = { 1, 3, 6 };
		CheckResult(expected, sli);
		DestroySLI(sli);
	}

	NewTest("CreateIntegralImage works with 3x3 SLI");
	{
		SLI *sli = CreateSLI(3, 3, 8, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(sli);
		pixels[0] = 1;
		pixels[1] = 2;
		pixels[2] = 3;
		pixels[3] = 4;
		pixels[4] = 5;
		pixels[5] = 6;
		pixels[6] = 7;
		pixels[7] = 8;
		pixels[8] = 9;
		CheckCreateIntegralImage(sli);
		const int expected[] = { 	1, 3, 6, 
									5, 12, 21,
									12, 27, 45
								};
		CheckResult(expected, sli);
		DestroySLI(sli);
	}

	NewTest("CreateIntegralImage works with 3x4 SLI");
	{
		SLI *sli = CreateSLI(3, 4, 8, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(sli);
		pixels[0] = 1;
		pixels[1] = 2;
		pixels[2] = 3;
		pixels[3] = 4;
		pixels[4] = 5;
		pixels[5] = 6;
		pixels[6] = 7;
		pixels[7] = 8;
		pixels[8] = 9;
		pixels[9] = 10;
		pixels[10] = 11;
		pixels[11] = 12;
		CheckCreateIntegralImage(sli);
		const int expected[] = { 	1, 3, 6, 
									5, 12, 21,
									12, 27, 45,
									22, 48, 78
								};
		CheckResult(expected, sli);
		DestroySLI(sli);
	}
	
	printf("[SUCCESS] %dn tests passed.", num_tests);

	return 0;
}