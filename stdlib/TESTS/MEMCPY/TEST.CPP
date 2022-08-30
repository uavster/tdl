#include "tdl.h"

#define kTestBufferSize	32

void CheckResult(const BYTE *expected, const BYTE *actual, DWORD len) {
	bool wrote_offbuffer = false;
	int offbuffer_index = 0;
	for (int i = len; i < kTestBufferSize + 1; ++i) {
		if (actual[i] != 0xff) {
			wrote_offbuffer = true;
			offbuffer_index = i;
			break;
		}
	}
	if (wrote_offbuffer) {
		printf("[ERROR]\nToo many bytes were copied in the output buffer, starting at index %dn.", offbuffer_index);
		exit(2);
	}
	
	bool are_equal = true;
	for (i = 0; i < len; ++i) {
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

int num_tests = 0;
BYTE test_output[kTestBufferSize + 1];

void NewTest(const char *name) {
	++num_tests;
	printf("Test %dn: ", num_tests);
	printf(name);
	printf(".");
	memset(test_output, 0xff, kTestBufferSize + 1);
}

void amemcpyTest(const char *name, const BYTE *expected_buffer, const DWORD len) {
	NewTest(name);
	amemcpy(test_output, expected_buffer, len);
	CheckResult(expected_buffer, test_output, len);
}

void memcpyTest(const char *name, const BYTE *expected_buffer, const DWORD len) {
	NewTest(name);
	memcpy(test_output, expected_buffer, len);
	CheckResult(expected_buffer, test_output, len);
}

int main() {
	// Our malloc guarantees 4-byte alignment of the buffer.
	BYTE *expected_buffer = (BYTE *)malloc(kTestBufferSize);
	for (int i = 0; i < kTestBufferSize; ++i) { expected_buffer[i] = i + 1; }

	amemcpyTest("amemcpy() multiple dwords", expected_buffer, kTestBufferSize);
	amemcpyTest("amemcpy() multiple dwords, word", expected_buffer, kTestBufferSize - 2);
	amemcpyTest("amemcpy() multiple dwords, byte", expected_buffer, kTestBufferSize - 3);
	amemcpyTest("amemcpy() multiple dwords, word, byte", expected_buffer, kTestBufferSize - 1);
	
	amemcpyTest("amemcpy() byte, multiple dwords", expected_buffer + 3, kTestBufferSize - 3);
	amemcpyTest("amemcpy() byte, multiple dwords, word", expected_buffer + 3, kTestBufferSize - 1);
	amemcpyTest("amemcpy() byte, multiple dwords, byte", expected_buffer + 3, kTestBufferSize - 2);
	amemcpyTest("amemcpy() byte, multiple dwords, word, byte", expected_buffer + 3, kTestBufferSize - 4);
	
	amemcpyTest("amemcpy() word, multiple dwords", expected_buffer + 2, kTestBufferSize - 2);
	amemcpyTest("amemcpy() word, multiple dwords, word", expected_buffer + 2, kTestBufferSize - 4);
	amemcpyTest("amemcpy() word, multiple dwords, byte", expected_buffer + 2, kTestBufferSize - 5);
	amemcpyTest("amemcpy() word, multiple dwords, word, byte", expected_buffer + 2, kTestBufferSize - 3);
	
	amemcpyTest("amemcpy() byte, word, multiple dwords", expected_buffer + 1, kTestBufferSize - 1);
	amemcpyTest("amemcpy() byte, word, multiple dwords, word", expected_buffer + 1, kTestBufferSize - 3);
	amemcpyTest("amemcpy() byte, word, multiple dwords, byte", expected_buffer + 1, kTestBufferSize - 4);
	amemcpyTest("amemcpy() byte, word, multiple dwords, word, byte", expected_buffer + 1, kTestBufferSize - 2);
	
	amemcpyTest("amemcpy() dword", expected_buffer, 4);
	amemcpyTest("amemcpy() word", expected_buffer, 2);

	amemcpyTest("amemcpy() word", expected_buffer + 2, 2);
	amemcpyTest("amemcpy() word, byte", expected_buffer, 3);
	amemcpyTest("amemcpy() word, word", expected_buffer + 2, 4);
	amemcpyTest("amemcpy() word, word, byte", expected_buffer + 2, 5);
	amemcpyTest("amemcpy() word, dword", expected_buffer + 2, 6);
	
	amemcpyTest("amemcpy() byte, byte", expected_buffer + 1, 2);
	amemcpyTest("amemcpy() byte, word", expected_buffer + 1, 3);
	amemcpyTest("amemcpy() byte, word, byte", expected_buffer + 1, 4);
	amemcpyTest("amemcpy() byte, word, word", expected_buffer + 1, 5);
	amemcpyTest("amemcpy() byte, word, word, byte", expected_buffer + 1, 6);
	
	amemcpyTest("amemcpy() byte-aligned byte", expected_buffer + 1, 1);
	amemcpyTest("amemcpy() word-aligned byte", expected_buffer + 2, 1);
	amemcpyTest("amemcpy() dword-aligned byte", expected_buffer, 1);

	amemcpyTest("amemcpy() nothing", expected_buffer, 0);
	
	memcpyTest("memcpy() multiple dwords", expected_buffer, kTestBufferSize);
	memcpyTest("memcpy() multiple dwords, word", expected_buffer, kTestBufferSize - 2);
	memcpyTest("memcpy() multiple dwords, byte", expected_buffer, kTestBufferSize - 3);
	memcpyTest("memcpy() multiple dwords, word, byte", expected_buffer, kTestBufferSize - 1);
	
	memcpyTest("memcpy() byte, multiple dwords", expected_buffer + 3, kTestBufferSize - 3);
	memcpyTest("memcpy() byte, multiple dwords, word", expected_buffer + 3, kTestBufferSize - 1);
	memcpyTest("memcpy() byte, multiple dwords, byte", expected_buffer + 3, kTestBufferSize - 2);
	memcpyTest("memcpy() byte, multiple dwords, word, byte", expected_buffer + 3, kTestBufferSize - 4);
	
	memcpyTest("memcpy() word, multiple dwords", expected_buffer + 2, kTestBufferSize - 2);
	memcpyTest("memcpy() word, multiple dwords, word", expected_buffer + 2, kTestBufferSize - 4);
	memcpyTest("memcpy() word, multiple dwords, byte", expected_buffer + 2, kTestBufferSize - 5);
	memcpyTest("memcpy() word, multiple dwords, word, byte", expected_buffer + 2, kTestBufferSize - 3);
	
	memcpyTest("memcpy() byte, word, multiple dwords", expected_buffer + 1, kTestBufferSize - 1);
	memcpyTest("memcpy() byte, word, multiple dwords, word", expected_buffer + 1, kTestBufferSize - 3);
	memcpyTest("memcpy() byte, word, multiple dwords, byte", expected_buffer + 1, kTestBufferSize - 4);
	memcpyTest("memcpy() byte, word, multiple dwords, word, byte", expected_buffer + 1, kTestBufferSize - 2);
	
	memcpyTest("memcpy() dword", expected_buffer, 4);
	memcpyTest("memcpy() word", expected_buffer, 2);

	memcpyTest("memcpy() word", expected_buffer + 2, 2);
	memcpyTest("memcpy() word, byte", expected_buffer, 3);
	memcpyTest("memcpy() word, word", expected_buffer + 2, 4);
	memcpyTest("memcpy() word, word, byte", expected_buffer + 2, 5);
	memcpyTest("memcpy() word, dword", expected_buffer + 2, 6);
	
	memcpyTest("memcpy() byte, byte", expected_buffer + 1, 2);
	memcpyTest("memcpy() byte, word", expected_buffer + 1, 3);
	memcpyTest("memcpy() byte, word, byte", expected_buffer + 1, 4);
	memcpyTest("memcpy() byte, word, word", expected_buffer + 1, 5);
	memcpyTest("memcpy() byte, word, word, byte", expected_buffer + 1, 6);
	
	memcpyTest("memcpy() byte-aligned byte", expected_buffer + 1, 1);
	memcpyTest("memcpy() word-aligned byte", expected_buffer + 2, 1);
	memcpyTest("memcpy() dword-aligned byte", expected_buffer, 1);

	memcpyTest("memcpy() nothing", expected_buffer, 0);	

	printf("[SUCCESS] %dn tests passed.", num_tests);

	free(expected_buffer);
	return 0;
}