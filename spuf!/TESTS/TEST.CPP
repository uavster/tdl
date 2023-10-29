#include "tdl.h"
#include "string.h"

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
		printf(" [ERROR]\nExpected: ");
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
		printf(" [ERROR] CreateIntegralImage failed with error %dn.\n", error_code);
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

void ReferenceBoxFilter(SLI *src, int kernel_width, int kernel_height, SLI *dst) {
  BYTE *dst_pixels = (BYTE *)GetCurrentFramePtr(dst);
  BYTE *src_pixels = (BYTE *)GetCurrentFramePtr(src);
  for (int y = 0; y < dst->SLIYSize; ++y) {
    for (int x = 0; x < dst->SLIXSize; ++x) {
      DWORD sum = 0;
      for (int v = 0; v < kernel_height; ++v) {
        int src_y = y - kernel_height / 2 + v;
        if (src_y < 0 || src_y >= src->SLIYSize) {
          continue;
        }
        for (int u = 0; u < kernel_width; ++u) {
          int src_x = x - kernel_width / 2 + u;
          if (src_x < 0 || src_x >= src->SLIXSize) {
            continue;
          }
          sum += src_pixels[src_y * src->SLIPitch + src_x];
        }
      }
      dst_pixels[y * dst->SLIPitch + x] = static_cast<BYTE>(sum);
    }
  }
}

void CheckBoxFilter(SLI *result, SLI *expected) {
  BYTE *result_pixels = (BYTE *)GetCurrentFramePtr(result);
  BYTE *expected_pixels = (BYTE *)GetCurrentFramePtr(expected);
  if (result->SLIYSize != expected->SLIYSize) {
    printf(" [ERROR]\nResult and expectation SLI heights do not match.\n");
    exit(3);
  }
  if (result->SLIXSize != expected->SLIXSize) {
    printf(" [ERROR]\nResult and expectation SLI widths do not match.\n");
    exit(4);
  }

  bool are_equal = true;
  for (int y = 0; y < result->SLIYSize && are_equal; ++y) {
    for (int x = 0; x < result->SLIXSize; ++x) {
      if (result_pixels[y * result->SLIPitch + x] != expected_pixels[y * expected->SLIPitch + x]) {
        are_equal = false;
        break;
      }
    }
  }
  if (!are_equal) {
    printf(" [ERROR]\nActual (left) vs expected (right):\n");

    const int element_width = 4;
    const int spaces_between_matrices = element_width * 2;

    for (int y = 0; y < result->SLIYSize; ++y) {
      // Actual row.
      for (int x = 0; x < result->SLIXSize; ++x) {
        DWORD value = static_cast<DWORD>(result_pixels[y * result->SLIPitch + x]);
        char tmp[4];
        sprintf(tmp, "%dn", value);
        int num_spaces = element_width - strlen(tmp);
        bool pixels_match = result_pixels[y * result->SLIPitch + x] == expected_pixels[y * expected->SLIPitch + x];
        if (!pixels_match) {
          --num_spaces;
        }
        for (int i = 0; i < num_spaces; ++i) {
          printf(" ");
        }
        if (!pixels_match) {
          printf("*");
        }
        printf(tmp);
      }

      for (int i = 0; i < spaces_between_matrices; ++i) {
        printf(" ");
      }

      // Expected row.
      for (x = 0; x < result->SLIXSize; ++x) {
        DWORD value = static_cast<DWORD>(expected_pixels[y * expected->SLIPitch + x]);
        char tmp[4];
        sprintf(tmp, "%dn", value);
        const int num_spaces = element_width - strlen(tmp);
        for (int i = 0; i < num_spaces; ++i) {
          printf(" ");
        }
        printf(tmp);
      }

      printf("\n");
    }
    exit(5);
  }
}

int main() {
	NewTest("CreateIntegralImage does nothing with zero width and height SLI");
	{
		SLI *sli = CreateSLI(0, 0, 8, 1);
		CheckCreateIntegralImage(sli);
		DestroySLI(sli);
		printf(" [OK]\n");
	}

	NewTest("CreateIntegralImage does nothing with zero height SLI");
	{
		SLI *sli = CreateSLI(2, 0, 8, 1);
		CheckCreateIntegralImage(sli);
		DestroySLI(sli);
		printf(" [OK]\n");
	}

	NewTest("CreateIntegralImage does nothing with zero width SLI");
	{
		SLI *sli = CreateSLI(0, 2, 8, 1);
		CheckCreateIntegralImage(sli);
		DestroySLI(sli);
		printf(" [OK]\n");
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

  NewTest("BoxFilter works with 5x5 kernel on 6x6 constant image");
  {
    SLI *input_sli = CreateSLI(8, 8, 8, 1);
    SLI *output_sli = CreateSLI(8, 8, 8, 1);
    SLI *expected_sli = CreateSLI(8, 8, 8, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(input_sli);
    for (int y = 0; y < input_sli->SLIYSize; ++y) {
      for (int x = 0; x < input_sli->SLIXSize; ++x) {
        pixels[y * input_sli->SLIPitch + x] = x+2+y+3;
      }
    }
		CheckCreateIntegralImage(input_sli);

    ReferenceBoxFilter(input_sli, 5, 5, expected_sli);
    BoxFilter(input_sli, 5, 5, output_sli);

    CheckBoxFilter(output_sli, expected_sli);
  }

	printf("[SUCCESS] %dn tests passed.", num_tests);

	return 0;
}