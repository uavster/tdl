#include "tdl.h"
#include "vector.hpp"

using namespace std;

int num_tests = 0;

void NewTest(const char *name) {
	++num_tests;
	printf("Test %dn: ", num_tests);
	printf(name);
}

void PrintIntVector(const vector<int> &v) {
	for (vector<int>::const_iterator it = v.cbegin(); it != v.cend(); it++) {
		printf("%dn ", *it);
	}
	printf("\n");
}

void PrintIntArray(const int *arr, size_t len) {
	for (size_t i = 0; i < len; ++i) {
		printf("%dn ", arr[i]);
	}
	printf("\n");
}

void CheckResult(const vector<int> &actual, const int *expected, size_t expected_len) {
	bool are_equal = expected_len == actual.size();
	if (are_equal) {
		for (size_t i = 0; i < actual.size(); ++i) {
			if (expected[i] != actual[i]) {
				are_equal = false;
				break;
			}
		}	
	}
	
	if (are_equal) {
		printf(" [OK]\n");
	} else {
		printf(" [ERROR]\nExpected: ");
		PrintIntArray(expected, expected_len);
		printf("Actual:   ");
		PrintIntVector(actual);
		exit(1);
	}
}

#define EXPECT_EQ(actual, expected) { \
	CheckResult(actual, expected, sizeof(expected) / sizeof(int)); \
}

int main() {
	vector<int> v(6, 52);
	{
		NewTest("vector<int>(6, 52)");
		const int expected[] = {52, 52, 52, 52, 52, 52};
		EXPECT_EQ(v, expected);
	}
	{
		NewTest("push_back(42)");
		v.push_back(42);
		const int expected[] = {52, 52, 52, 52, 52, 52, 42};
		EXPECT_EQ(v, expected);
	}
	
	// printf("v[0] = %dn\n", v[0]);
	// printf("v[v.size() - 1] = %dn\n", v[v.size() - 1]);
	
	// v.pop_back();
	// PrintVectorInt(v);

	// struct S {
		// int a;
		// char b;
	// };
	// S elem = { 52, 53 };
	// vector<S> s(4, elem);
	// for (vector<S>::const_iterator it2 = s.cbegin(); it2 != s.cend(); it2++) {
		// printf("{%dn,%dn} ", it2->a, it2->b);
	// }	
	// printf("\n");
	
	// v.clear();
	// v.push_back(1);
	// v.push_back(2);
	// v.push_back(3);
	// PrintVectorInt(v);
	
	// vector<int>::iterator bit = v.end();
	// --bit;
	// for (size_t i = 0; i < v.size(); ++i) {
		// printf("%dn ", *(bit--));
	// }
	// printf("\n");
	
	// v.clear();
	// PrintVectorInt(v);
	
	// v.push_back(52);
	// *v.begin() = 42;
	// printf("%dn\n", *v.cbegin());
	
	// v.push_back(7);
	// printf("%dn %dn\n", v.front(), v.back());
	
	// v.push_back(8);
	// v.erase(v.begin(), ++v.begin());
	// PrintVectorInt(v);	

	// v.push_back(9);
	// v.push_back(10);
	// v.push_back(11);
	// PrintVectorInt(v);
	// printf("%dn %dn\n", v.begin()[2], v.end()[-2]);

	// PrintVectorInt(v, v.begin() + 2);
	
	// for (vector<int>::const_reverse_iterator rit = v.crbegin(); rit != v.crend(); ++rit) {
		// printf("%dn ", *rit);
	// }
	// printf("\n");
	
	// printf("%dn %dn\n", v.rbegin()[1], v.rend()[-2]);
	
	// v.insert(v.begin() + 2, 8, 52);
	// PrintVectorInt(v);
	
	// v.resize(5);
	// PrintVectorInt(v);
	
	// v.resize(20);
	// PrintVectorInt(v);
	
	// *v.rbegin() = 13;
	// PrintVectorInt(v);
	
	// printf("[SUCCESS] %dn tests passed.", num_tests);
	
	printf("[SUCCESS] %dn tests passed.", num_tests);
	
	return 0;
}