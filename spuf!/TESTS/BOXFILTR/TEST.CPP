#include "tdl.h"
#include "string.h"

void CheckIntegralmage(const int *expected, const SLI *actual_sli) {
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

void CheckIntegralmage32(const int *expected, const SLI *actual_sli) {
	const int *actual = actual_sli->SLIIntegralImage;
	const int len = actual_sli->SLIXSize * actual_sli->SLIYSize;
	bool are_equal = true;
	for (int i = 0; i < len; ++i) {
		if (expected[i*4] != actual[i*4] || expected[i*4+1] != actual[i*4+1] || expected[i*4+2] != actual[i*4+2]) {
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
			printf("(%dn %dn %dn) ", expected[i*4], expected[i*4+1], expected[i*4+2]);
		}
		printf("\nActual: ");
		for (i = 0; i < len; ++i) {
			printf("(%dn %dn %dn) ", actual[i*4], actual[i*4+1], actual[i*4+2]);
		}
		exit(1);
	}
}

int num_tests = 0;

void NewTest(const char *name) {
	++num_tests;
	printf("Test %dn: ", num_tests);
	printf(name);
	printf(".");
}

void ReferenceScaledBoxIntegral_(SLI *src, int kernel_width, int kernel_height, SLI *dst, DWORD divider) {
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
      dst_pixels[y * dst->SLIPitch + x] = static_cast<BYTE>(sum / divider);
    }
  }
}

void ReferenceScaledBoxIntegral(SLI *src, int kernel_width, int kernel_height, SLI *dst) {
  ReferenceScaledBoxIntegral_(src, kernel_width, kernel_height, dst, 1);
}

void ReferenceScaledBoxIntegral32_(SLI *src, int kernel_width, int kernel_height, SLI *dst, DWORD divider) {
  BYTE *dst_pixels = (BYTE *)GetCurrentFramePtr(dst);
  BYTE *src_pixels = (BYTE *)GetCurrentFramePtr(src);
  for (int y = 0; y < dst->SLIYSize; ++y) {
    for (int x = 0; x < dst->SLIXSize; ++x) {
      for (int c = 0; c < 3; ++c) {
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
            sum += src_pixels[src_y * src->SLIPitch + src_x * 4 + c];
          }
        }
        dst_pixels[y * dst->SLIPitch + x * 4 + c] = static_cast<BYTE>(sum / divider);
      }
    }
  }
}

void ReferenceScaledBoxIntegral32(SLI *src, int kernel_width, int kernel_height, SLI *dst) {
  ReferenceScaledBoxIntegral32_(src, kernel_width, kernel_height, dst, 1);
}

void ReferenceBoxFilter(SLI *src, int kernel_width, int kernel_height, SLI *dst) {
  ReferenceScaledBoxIntegral_(src, kernel_width, kernel_height, dst, kernel_width * kernel_height);
}

void CheckExpectedSLI(SLI *result, SLI *expected, int max_error = 0) {
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
      int error = static_cast<int>(result_pixels[y * result->SLIPitch + x]) - static_cast<int>(expected_pixels[y * expected->SLIPitch + x]);
      if (error > max_error || error < -max_error) {
        are_equal = false;
        break;
      }
    }
  }
  if (are_equal) {
		printf("[OK]\n");
  } else {
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

void CheckExpectedSLI32(SLI *result, SLI *expected, int max_error = 0) {
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
      int error = static_cast<int>(result_pixels[y * result->SLIPitch + x * 4]) - static_cast<int>(expected_pixels[y * expected->SLIPitch + x * 4]);
      if (error > max_error || error < -max_error) {
        are_equal = false;
        break;
      }
      error = static_cast<int>(result_pixels[y * result->SLIPitch + x * 4 + 1]) - static_cast<int>(expected_pixels[y * expected->SLIPitch + x * 4 + 1]);
      if (error > max_error || error < -max_error) {
        are_equal = false;
        break;
      }
      error = static_cast<int>(result_pixels[y * result->SLIPitch + x * 4 + 2]) - static_cast<int>(expected_pixels[y * expected->SLIPitch + x * 4 + 2]);
      if (error > max_error || error < -max_error) {
        are_equal = false;
        break;
      }
    }
  }
  if (are_equal) {
		printf("[OK]\n");
  } else {
    printf(" [ERROR]\nActual:\n");

    const int element_width = 4;
    const int spaces_between_matrices = element_width * 2;

    for (int y = 0; y < result->SLIYSize; ++y) {
      // Actual row.
      for (int x = 0; x < result->SLIXSize; ++x) {
        printf("(");
        for (int c = 0; c < 3; ++c) {
          const DWORD value = static_cast<DWORD>(result_pixels[y * result->SLIPitch + x * 4 + c]);
          char tmp[4];
          sprintf(tmp, "%dn", value);
          int num_spaces = element_width - strlen(tmp);
          bool pixels_match = result_pixels[y * result->SLIPitch + x * 4 + c] == expected_pixels[y * expected->SLIPitch + x * 4 + c];
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
        printf(") ");
      }
      printf("\n");
    }

    printf("\nExpected:\n");

    for (y = 0; y < result->SLIYSize; ++y) {
      // Expected row.
      for (int x = 0; x < result->SLIXSize; ++x) {
        printf("(");
        for (int c = 0; c < 3; ++c) {
          DWORD value = static_cast<DWORD>(expected_pixels[y * expected->SLIPitch + x * 4 + c]);
          char tmp[4];
          sprintf(tmp, "%dn", value);
          const int num_spaces = element_width - strlen(tmp);
          for (int i = 0; i < num_spaces; ++i) {
            printf(" ");
          }
          printf(tmp);
        }
        printf(") ");
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
		CreateIntegralImage(sli, 1);
		DestroySLI(sli);
		printf(" [OK]\n");
	}

	NewTest("CreateIntegralImage does nothing with zero height SLI");
	{
		SLI *sli = CreateSLI(2, 0, 8, 1);
		CreateIntegralImage(sli, 1);
		DestroySLI(sli);
		printf(" [OK]\n");
	}

	NewTest("CreateIntegralImage does nothing with zero width SLI");
	{
		SLI *sli = CreateSLI(0, 2, 8, 1);
		CreateIntegralImage(sli, 1);
		DestroySLI(sli);
		printf(" [OK]\n");
	}

	NewTest("CreateIntegralImage works with 1x1 SLI");
	{
		SLI *sli = CreateSLI(1, 1, 8, 1);
		((BYTE *)GetCurrentFramePtr(sli))[0] = 1;
		CreateIntegralImage(sli, 1);
		const int expected[] = { 1 };
		CheckIntegralmage(expected, sli);
		DestroySLI(sli);
	}

	NewTest("CreateIntegralImage works with 3x1 SLI");
	{
		SLI *sli = CreateSLI(3, 1, 8, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(sli);
		pixels[0] = 1;
		pixels[1] = 2;
		pixels[2] = 3;
		CreateIntegralImage(sli, 1);
		const int expected[] = { 1, 3, 6 };
		CheckIntegralmage(expected, sli);
		DestroySLI(sli);
	}

	NewTest("CreateIntegralImage works with 1x3 SLI");
	{
		SLI *sli = CreateSLI(1, 3, 8, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(sli);
		pixels[0] = 1;
		pixels[1] = 2;
		pixels[2] = 3;
		CreateIntegralImage(sli, 1);
		const int expected[] = { 1, 3, 6 };
		CheckIntegralmage(expected, sli);
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
		CreateIntegralImage(sli, 1);
		const int expected[] = { 	1, 3, 6, 
									5, 12, 21,
									12, 27, 45
								};
		CheckIntegralmage(expected, sli);
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
		CreateIntegralImage(sli, 1);
		const int expected[] = { 	1, 3, 6, 
									5, 12, 21,
									12, 27, 45,
									22, 48, 78
								};
		CheckIntegralmage(expected, sli);
		DestroySLI(sli);
	}

	NewTest("CreateIntegralImage works with 4x3 SLI and premultipler of 256");
	{
		SLI *sli = CreateSLI(4, 3, 8, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(sli);
    for (int y = 0; y < sli->SLIYSize; ++y) {
      for (int x = 0; x < sli->SLIXSize; ++x) {
        pixels[y * sli->SLIPitch + x] = x+2+y+3;
      }
    }

    int expected[4 * 3];
    {
      for (int y = 0; y < sli->SLIYSize; ++y) {
        for (int x = 0; x < sli->SLIXSize; ++x) {
          expected[y * 4 + x] = 0;
          for (int j = 0; j <= y; ++j) {
            for (int i = 0; i <= x; ++i) {
              expected[y * 4 + x] += 256 * pixels[j * sli->SLIPitch + i];
            }
          }
        }
      }
    }
		
		CreateIntegralImage(sli, 256);
		CheckIntegralmage(expected, sli);
		DestroySLI(sli);
	}

	NewTest("CreateIntegralImage works with 3x4 SLI with multiplier of 23");
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
		CreateIntegralImage(sli, 23);
		const int expected[] = { 	1*23, 3*23, 6*23, 
									5*23, 12*23, 21*23,
									12*23, 27*23, 45*23,
									22*23, 48*23, 78*23
								};
		CheckIntegralmage(expected, sli);
		DestroySLI(sli);
	}

  NewTest("ScaledBoxIntegral works with 5x5 kernel on 8x8 SLI");
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
		CreateIntegralImage(input_sli, 1);

    ReferenceScaledBoxIntegral(input_sli, 5, 5, expected_sli);
    ScaledBoxIntegral(input_sli, 5, 5, 0, output_sli);

    CheckExpectedSLI(output_sli, expected_sli);

		DestroySLI(expected_sli);
		DestroySLI(output_sli);
		DestroySLI(input_sli);
  }

  NewTest("BoxFilter works with 5x5 kernel on 8x8 SLI");
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

    ReferenceBoxFilter(input_sli, 5, 5, expected_sli);
    BoxFilter(input_sli, 5, 5, output_sli);

    CheckExpectedSLI(output_sli, expected_sli, /*max_error=*/1);

		DestroySLI(expected_sli);
		DestroySLI(output_sli);
		DestroySLI(input_sli);
  }

  NewTest("BoxFilter works with 1x1 kernel on 4x3 SLI");
  {
    const int image_width = 4;
    const int image_height = 3;
    const int kernel_width = 1;
    const int kernel_height = 1;

    SLI *input_sli = CreateSLI(image_width, image_height, 8, 1);
    SLI *output_sli = CreateSLI(image_width, image_height, 8, 1);

    SLI *expected_sli = CreateSLI(image_width, image_height, 8, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(input_sli);
    for (int y = 0; y < input_sli->SLIYSize; ++y) {
      for (int x = 0; x < input_sli->SLIXSize; ++x) {
        pixels[y * input_sli->SLIPitch + x] = x+2+y+3;
      }
    }

    ReferenceBoxFilter(input_sli, kernel_width, kernel_height, expected_sli);
    BoxFilter(input_sli, kernel_width, kernel_height, output_sli);

    CheckExpectedSLI(output_sli, expected_sli, /*max_error=*/1);

		DestroySLI(expected_sli);
		DestroySLI(output_sli);
		DestroySLI(input_sli);
  }

	NewTest("CreateIntegralImage does nothing with zero width and height SLI");
	{
		SLI *sli = CreateSLI(0, 0, 32, 1);
		CreateIntegralImage(sli, 1);
		DestroySLI(sli);
		printf(" [OK]\n");
	}

	NewTest("CreateIntegralImage does nothing with zero height SLI");
	{
		SLI *sli = CreateSLI(2, 0, 32, 1);
		CreateIntegralImage(sli, 1);
		DestroySLI(sli);
		printf(" [OK]\n");
	}

	NewTest("CreateIntegralImage does nothing with zero width SLI");
	{
		SLI *sli = CreateSLI(0, 2, 32, 1);
		CreateIntegralImage(sli, 1);
		DestroySLI(sli);
		printf(" [OK]\n");
	}

	NewTest("CreateIntegralImage works with 1x1 SLI");
	{
		SLI *sli = CreateSLI(1, 1, 32, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(sli);
		pixels[0] = 1;
		pixels[1] = 2;
		pixels[2] = 3;
		pixels[3] = 0xff;
		CreateIntegralImage(sli, 1);
		const int expected[] = { 1, 2, 3 };
		CheckIntegralmage32(expected, sli);
		DestroySLI(sli);
	}  

	NewTest("CreateIntegralImage works with 3x1 SLI");
	{
		SLI *sli = CreateSLI(3, 1, 32, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(sli);
		pixels[0] = 1;
		pixels[1] = 2;
		pixels[2] = 3;
		pixels[3] = 0xff;
		pixels[4] = 4;
		pixels[5] = 5;
		pixels[6] = 6;
		pixels[7] = 0xff;
		pixels[8] = 7;
		pixels[9] = 8;
		pixels[10] = 9;
		pixels[11] = 0xff;
		CreateIntegralImage(sli, 1);
		const int expected[] = { 1, 2, 3, 0xff, 5, 7, 9, 2*0xff, 12, 15, 18, 3*0xff };
		CheckIntegralmage32(expected, sli);
		DestroySLI(sli);
	}

	NewTest("CreateIntegralImage works with 1x3 SLI");
	{
		SLI *sli = CreateSLI(1, 3, 32, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(sli);
		pixels[0] = 1;
		pixels[1] = 2;
		pixels[2] = 3;
		pixels[3] = 0xff;
		pixels[4] = 4;
		pixels[5] = 5;
		pixels[6] = 6;
		pixels[7] = 0xff;
		pixels[8] = 7;
		pixels[9] = 8;
		pixels[10] = 9;
		pixels[11] = 0xff;
		CreateIntegralImage(sli, 1);
		const int expected[] = { 1, 2, 3, 0xff, 5, 7, 9, 2*0xff, 12, 15, 18, 3*0xff };
		CheckIntegralmage32(expected, sli);
		DestroySLI(sli);
	}

	NewTest("CreateIntegralImage works with 3x3 SLI");
	{
		SLI *sli = CreateSLI(3, 3, 32, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(sli);
    int j = 0;
    for (int y = 0; y < sli->SLIYSize; ++y) {
      for (int x = 0; x < sli->SLIYSize; ++x) {
        pixels[y * sli->SLIPitch + x * 4] = ++j;
        pixels[y * sli->SLIPitch + x * 4 + 1] = ++j;
        pixels[y * sli->SLIPitch + x * 4 + 2] = ++j;
        pixels[y * sli->SLIPitch + x * 4 + 3] = 0xff;
      }
    }
		CreateIntegralImage(sli, 1);
		const int expected[] = { 	
      /*p00=*/1, 2, 3, 0xff, /*p01=*/5, 7, 9, 0xff*2, /*p02=*/12, 15, 18, 0xff*3, 
      /*p10=*/11, 13, 15, 0xff*2, /*p11=*/28, 32, 36, 0xff*3, /*p12=*/51, 57, 63, 0xff*4, 
      /*p20=*/30, 33, 36, 0xff*3, /*p21=*/69, 75, 81, 0xff*4, /*p22=*/117, 126, 135, 0xff*5, 
		};
		CheckIntegralmage32(expected, sli);
		DestroySLI(sli);
	}

	NewTest("CreateIntegralImage works with 4x3 SLI and premultipler of 256");
	{
		SLI *sli = CreateSLI(4, 3, 32, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(sli);
    for (int y = 0; y < sli->SLIYSize; ++y) {
      for (int x = 0; x < sli->SLIXSize; ++x) {
        pixels[y * sli->SLIPitch + x * 3] = x+y+5;
        pixels[y * sli->SLIPitch + x * 3 + 1] = y-x+3;
        pixels[y * sli->SLIPitch + x * 3 + 2] = x*2+y;
        pixels[y * sli->SLIPitch + x * 3 + 3] = 0xff;
      }
    }

    int expected[4 * 3 * 4];
    {
      for (int y = 0; y < sli->SLIYSize; ++y) {
        for (int x = 0; x < sli->SLIXSize; ++x) {
          expected[(y * 4 + x) * 4] = 0;
          expected[(y * 4 + x) * 4 + 1] = 0;
          expected[(y * 4 + x) * 4 + 2] = 0;
          for (int j = 0; j <= y; ++j) {
            for (int i = 0; i <= x; ++i) {
              expected[(y * 4 + x) * 4] += 256 * pixels[j * sli->SLIPitch + i * 4];
              expected[(y * 4 + x) * 4 + 1] += 256 * pixels[j * sli->SLIPitch + i * 4 + 1];
              expected[(y * 4 + x) * 4 + 2] += 256 * pixels[j * sli->SLIPitch + i * 4 + 2];
            }
          }
        }
      }
    }
		
		CreateIntegralImage(sli, 256);
		CheckIntegralmage32(expected, sli);
		DestroySLI(sli);
	}

	NewTest("CreateIntegralImage works with 3x4 SLI with multiplier of 23");
	{
		SLI *sli = CreateSLI(3, 4, 32, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(sli);
    for (int y = 0; y < sli->SLIYSize; ++y) {
      for (int x = 0; x < sli->SLIXSize; ++x) {
        pixels[y * sli->SLIPitch + x * 3] = x+y+5;
        pixels[y * sli->SLIPitch + x * 3 + 1] = y-x+3;
        pixels[y * sli->SLIPitch + x * 3 + 2] = 255-x*2+y;
        pixels[y * sli->SLIPitch + x * 3 + 3] = 0xff;
      }
    }

    int expected[3 * 4 * 4];
    {
      for (int y = 0; y < sli->SLIYSize; ++y) {
        for (int x = 0; x < sli->SLIXSize; ++x) {
          expected[(y * sli->SLIXSize + x) * 4] = 0;
          expected[(y * sli->SLIXSize + x) * 4 + 1] = 0;
          expected[(y * sli->SLIXSize + x) * 4 + 2] = 0;
          for (int j = 0; j <= y; ++j) {
            for (int i = 0; i <= x; ++i) {
              expected[(y * sli->SLIXSize + x) * 4] += 23 * pixels[j * sli->SLIPitch + i * 4];
              expected[(y * sli->SLIXSize + x) * 4 + 1] += 23 * pixels[j * sli->SLIPitch + i * 4 + 1];
              expected[(y * sli->SLIXSize + x) * 4 + 2] += 23 * pixels[j * sli->SLIPitch + i * 4 + 2];
            }
          }
        }
      }
    }
		
		CreateIntegralImage(sli, 23);
		CheckIntegralmage32(expected, sli);
		DestroySLI(sli);
	}

  NewTest("ScaledBoxIntegral works with 3x3 kernel on 5x5 SLI");
  {
    SLI *input_sli = CreateSLI(5, 5, 32, 1);
    SLI *output_sli = CreateSLI(5, 5, 32, 1);
    SLI *expected_sli = CreateSLI(5, 5, 32, 1);
		BYTE *pixels = (BYTE *)GetCurrentFramePtr(input_sli);
    for (int y = 0; y < input_sli->SLIYSize; ++y) {
      for (int x = 0; x < input_sli->SLIXSize; ++x) {
        pixels[y * input_sli->SLIPitch + x * 3] = x+y+5;
        pixels[y * input_sli->SLIPitch + x * 3 + 1] = y-x+3;
        pixels[y * input_sli->SLIPitch + x * 3 + 2] = 255-x*2+y;
        pixels[y * input_sli->SLIPitch + x * 3 + 3] = 0xff;
      }
    }
		CreateIntegralImage(input_sli, 1);

    ReferenceScaledBoxIntegral32(input_sli, 3, 3, expected_sli);
    ScaledBoxIntegral(input_sli, 3, 3, 0, output_sli);

    CheckExpectedSLI32(output_sli, expected_sli);

		DestroySLI(expected_sli);
		DestroySLI(output_sli);
		DestroySLI(input_sli);
  }  

	printf("[SUCCESS] %dn tests passed.", num_tests);

	return 0;
}