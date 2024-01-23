#include "tdl.h"
#include "string.h"

int num_tests = 0;

void NewTest(const char *name) {
	++num_tests;
	printf("Test %dn: ", num_tests);
	printf(name);
	printf(".");
}

void CheckExpectedSLI(SLI *result, SLI *expected, int max_error = 0) {
  BYTE *result_pixels = (BYTE *)GetCurrentFramePtr(result);
  BYTE *expected_pixels = (BYTE *)GetCurrentFramePtr(expected);
  if (result->SLIYSize != expected->SLIYSize) {
    printf(" [ERROR]\nActual and expected SLI heights do not match.\n");
    exit(3);
  }
  if (result->SLIXSize != expected->SLIXSize) {
    printf(" [ERROR]\nActual and expected SLI widths do not match.\n");
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
    printf(" [ERROR]\nActual and expectated SLI heights do not match.\n");
    exit(3);
  }
  if (result->SLIXSize != expected->SLIXSize) {
    printf(" [ERROR]\nActual and expectated SLI widths do not match.\n");
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

SLI *CreateTestSourceSLI() {
		SLI *source = CreateSLI(2, 2, 32, 1);
    BYTE *p = (BYTE *)GetCurrentFramePtr(source);
    *reinterpret_cast<DWORD *>(&p[0]) = 0x123456;
    *reinterpret_cast<DWORD *>(&p[4]) = 0x789987;
    *reinterpret_cast<DWORD *>(&p[source->SLIPitch]) = 0x654321;
    *reinterpret_cast<DWORD *>(&p[source->SLIPitch + 4]) = 0x000000;
    return source;
}

SLI *CreateTestDestSLI() {
		SLI *source = CreateSLI(2, 2, 32, 1);
    BYTE *p = (BYTE *)GetCurrentFramePtr(source);
    *reinterpret_cast<DWORD *>(&p[0]) = 0x523Af2;
    *reinterpret_cast<DWORD *>(&p[4]) = 0xc9d2e5;
    *reinterpret_cast<DWORD *>(&p[source->SLIPitch]) = 0x3a4532;
    *reinterpret_cast<DWORD *>(&p[source->SLIPitch + 4]) = 0x7e2351;
    return source;
}

void ReferenceBlitWithConstantAlpha(SLI *source, SLI *dest, DWORD alpha) {
  BYTE *source_ptr = (BYTE *)GetCurrentFramePtr(source);
  BYTE *dest_ptr = (BYTE *)GetCurrentFramePtr(dest);
  for (int y = 0; y < dest->SLIYSize; ++y) {
    for (int x = 0; x < dest->SLIXSize; ++x) {
      DWORD sr = source_ptr[y * source->SLIPitch + x * 4];
      DWORD sg = source_ptr[y * source->SLIPitch + x * 4 + 1];
      DWORD sb = source_ptr[y * source->SLIPitch + x * 4 + 2];
      DWORD dr = dest_ptr[y * dest->SLIPitch + x * 4];
      DWORD dg = dest_ptr[y * dest->SLIPitch + x * 4 + 1];
      DWORD db = dest_ptr[y * dest->SLIPitch + x * 4 + 2];
      dest_ptr[y * dest->SLIPitch + x * 4] = static_cast<BYTE>(((sr * (alpha & 0xff)) + (dr * (255 - (alpha & 0xff)))) / 255);
      dest_ptr[y * dest->SLIPitch + x * 4 + 1] = static_cast<BYTE>(((sg * ((alpha >> 8) & 0xff)) + (dg * (255 - ((alpha >> 8) & 0xff)))) / 255);
      dest_ptr[y * dest->SLIPitch + x * 4 + 2] = static_cast<BYTE>(((sb * ((alpha >> 16) & 0xff)) + (db * (255 - ((alpha >> 16) & 0xff)))) / 255);
      dest_ptr[y * dest->SLIPitch + x * 4 + 3] = 0;
    }
  }
}

void ReferenceBlitWithAlphaMap(SLI *source, SLI *dest, SLI *alpha) {
  BYTE *source_ptr = (BYTE *)GetCurrentFramePtr(source);
  BYTE *dest_ptr = (BYTE *)GetCurrentFramePtr(dest);
  BYTE *alpha_ptr = (BYTE *)GetCurrentFramePtr(alpha);
  for (int y = 0; y < dest->SLIYSize; ++y) {
    for (int x = 0; x < dest->SLIXSize; ++x) {
      DWORD r = source_ptr[y * source->SLIPitch + x * 4];
      DWORD g = source_ptr[y * source->SLIPitch + x * 4 + 1];
      DWORD b = source_ptr[y * source->SLIPitch + x * 4 + 2];
      DWORD a = alpha_ptr[y * alpha->SLIPitch + x];
      dest_ptr[y * dest->SLIPitch + x * 4] = static_cast<BYTE>((r * a) / 255);
      dest_ptr[y * dest->SLIPitch + x * 4 + 1] = static_cast<BYTE>((g * a) / 255);
      dest_ptr[y * dest->SLIPitch + x * 4 + 2] = static_cast<BYTE>((b * a) / 255);
      dest_ptr[y * dest->SLIPitch + x * 4 + 3] = 0;
    }
  }
}

int main() {
	NewTest("Blit 32 bpp -> 32 bpp");
	{
    SLI *source = CreateTestSourceSLI();
		SLI *dest = CreateTestDestSLI();
		Blit(dest, source);

    CheckExpectedSLI32(dest, source);

		DestroySLI(source);
		DestroySLI(dest);
		printf(" [OK]\n");
	}

	NewTest("Blit 32 bpp -> 32 bpp with alpha=0.5");
	{
    const DWORD channel_alpha = 127;
    const DWORD alpha = channel_alpha | (channel_alpha << 8) | (channel_alpha << 16);

    SLI *source = CreateTestSourceSLI();
		SLI *dest = CreateTestDestSLI();
    SetAlpha(source, reinterpret_cast<void *>(alpha));
    SetBlitType(source, SLIBlitAlpha);
		Blit(dest, source);

    SLI *expected_dest = CreateTestDestSLI();
    ReferenceBlitWithConstantAlpha(source, expected_dest, alpha);
    CheckExpectedSLI32(dest, expected_dest, /*max_error=*/1);

		DestroySLI(source);
		DestroySLI(dest);
		DestroySLI(expected_dest);
		printf(" [OK]\n");
	}

	printf("[SUCCESS] %dn tests passed.", num_tests);

	return 0;
}