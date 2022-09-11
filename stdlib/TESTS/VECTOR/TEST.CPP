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

void CheckSize(const vector<int> &actual, const int expected_size) {
	if (actual.size() == expected_size) {
		printf(" [OK]\n");
	} else {
		printf(" [ERROR]\nExpected size: %dn\n", expected_size);
		printf("Actual size:   %dn ; ", actual.size());
		PrintIntVector(actual);
		exit(1);
	}
}

void CheckResult(const int actual, const int expected) {
	if (actual == expected) {
		printf(" [OK]\n");
	} else {
		printf(" [ERROR]\nExpected: %dn\nActual: %dn\n", expected, actual);
		exit(1);
	}
}

void CheckIteratorsEqual(const vector<int>::const_iterator &it1, const vector<int>::const_iterator &it2) {
	if (it1 == it2) {
		printf(" [OK]\n");
	} else {
		printf(" [ERROR]\nExpected: == return true\nActual: == returns false\n");
		exit(1);
	}
}

#define EXPECT_EQ(actual, expected) { \
	CheckResult(actual, expected, sizeof(expected) / sizeof(int)); \
}

#define EXPECT_1EQ(actual, expected) { \
	CheckResult(actual, expected); \
}

#define EXPECT_IT_EQ(actual, expected) { \
	CheckIteratorsEqual(actual, expected); \
}

#define EXPECT_SIZE(actual, expected_size) { \
	CheckSize(actual, expected_size); \
}

#define EXPECT_EMPTY(actual) { \
	EXPECT_SIZE(actual, 0); \
}

int main() {
	{
		NewTest("Emtpy constructor creates empty vector.");
		EXPECT_EMPTY(vector<int>());
	}
	{
		NewTest("One-argument constructor sets vector size.");
		EXPECT_SIZE(vector<int>(3), 3);
	}
	{
		NewTest("Two-argument constructor initializes element values.");
		vector<int> v(3, 52);
		const int expected[] = {52, 52, 52};
		EXPECT_EQ(v, expected);
	}
	{
		NewTest("size() returns number of elements.");
		EXPECT_1EQ(vector<int>(3, 0).size(), 3);
	}
	{
		NewTest("push_back() adds one element after end.");
		vector<int> v(3, 52);
		v.push_back(42);
		const int expected[] = {52, 52, 52, 42};
		EXPECT_EQ(v, expected);
	}
	{
		NewTest("pop_back() removes last element.");
		vector<int> v(3, 52);
		v.pop_back();
		const int expected[] = {52, 52};
		EXPECT_EQ(v, expected);
	}
	{
		NewTest("clear() erases all elements.");
		vector<int> v(3, 52);
		v.clear();
		EXPECT_EMPTY(v);
	}
	{
		NewTest("size() returns number of elements.");
		EXPECT_1EQ(vector<int>(3, 0).size(), 3);
	}
	{
		NewTest("indexing returns value.");
		vector<int> v;
		v.push_back(52);
		v.push_back(53);
		EXPECT_1EQ(v[1], 53);
	}	
	{
		NewTest("resize() to larger size increases size.");
		vector<int> v;
		v.resize(3);
		EXPECT_SIZE(v, 3);
	}	
	{
		NewTest("resize() to same size conserves size.");
		vector<int> v(3);
		v.resize(3);
		EXPECT_SIZE(v, 3);
	}	
	{
		NewTest("resize() to smaller size reduces size.");
		vector<int> v(3);
		v.resize(1);
		EXPECT_SIZE(v, 1);
	}	
	{
		NewTest("resize() to larger size with value sets value of new elements.");
		vector<int> v(1, 52);
		v.resize(3, 53);
		const int expected[] = { 52, 53, 53 };
		EXPECT_EQ(v, expected);
	}	
	{
		NewTest("reserve() does not change size if larger.");
		vector<int> v;
		v.reserve(3);
		EXPECT_EMPTY(v);
	}	
	{
		NewTest("reserve() does not change size if smaller.");
		vector<int> v(3);
		v.reserve(1);
		EXPECT_SIZE(v, 3);
	}	
	{
		NewTest("front() returns first element.");
		vector<int> v;
		v.push_back(52);
		v.push_back(53);
		EXPECT_1EQ(v.front(), 52);
	}	
	{
		NewTest("back() returns last element.");
		vector<int> v;
		v.push_back(52);
		v.push_back(53);
		EXPECT_1EQ(v.back(), 53);
	}	
	{
		NewTest("iterator: dereferencing returns value.");
		vector<int> v(1, 52);
		EXPECT_1EQ(*v.begin(), 52);
	}
	{
		NewTest("iterator: assignment makes iterators equal.");
		vector<int> v(1, 52);
		vector<int>::iterator it = v.begin();
		EXPECT_IT_EQ(it, v.begin());
	}
	{
		NewTest("iterator: increment passed last element equals end().");
		vector<int> v(1, 52);
		EXPECT_IT_EQ(++v.begin(), v.end());
	}
	{
		NewTest("iterator: decrement passed first element equals rend().");
		vector<int> v(1, 52);
		EXPECT_IT_EQ(--v.begin(), v.rend());
	}
	{
		NewTest("iterator: --end() equals rbegin().");
		vector<int> v(1, 52);
		EXPECT_IT_EQ(--v.end(), v.rbegin());
	}
	{
		NewTest("iterator: arrow operator returns structure members.");
		struct Structure {
			int a;
			char b;
		};
		Structure element = { 52, 53 };
		vector<Structure> s(2, element);
		vector<int> actual;
		for (vector<Structure>::iterator it = s.begin(); it != s.end(); ++it) {
			actual.push_back(it->a);
			actual.push_back(it->b);
		}	
		const int expected[] = {52, 53, 52, 53};
		EXPECT_EQ(actual, expected);
	}
	{
		NewTest("iterator: positive indexing returns value.");
		EXPECT_1EQ(vector<int>(1, 52).begin()[0], 52);
	}
	{
		NewTest("iterator: negative indexing returns value.");
		EXPECT_1EQ(vector<int>(1, 52).end()[-1], 52);
	}
	{
		NewTest("iterator: adding int gives correct new iterator.");
		vector<int> v;
		v.push_back(52);
		v.push_back(53);
		v.push_back(54);
		EXPECT_1EQ(*(v.begin() + 2), 54);
	}
	{
		NewTest("iterator: subtracting int gives correct new iterator.");
		vector<int> v;
		v.push_back(52);
		v.push_back(53);
		v.push_back(54);
		EXPECT_1EQ(*(v.end() - 3), 52);
	}
	{
		NewTest("iterator: deferencing allows mutation.");
		vector<int> s(1, 52);
		++*s.begin();
		EXPECT_1EQ(s.front(), 53);
	}
	{
		NewTest("iterator: arrow operator allows mutation.");
		struct Structure {
			int a;
			char b;
		};
		Structure element = { 52, 53 };
		vector<Structure> s(1, element);
		++s.begin()->a;
		++s.begin()->b;
		vector<int> actual;
		for (vector<Structure>::iterator it = s.begin(); it != s.end(); ++it) {
			actual.push_back(it->a);
			actual.push_back(it->b);
		}	
		const int expected[] = {53, 54};
		EXPECT_EQ(actual, expected);
	}
	{
		NewTest("const_iterator: dereferencing returns value.");
		vector<int> v(1, 52);
		EXPECT_1EQ(*v.cbegin(), 52);
	}
	{
		NewTest("const_iterator: assignment makes iterators equal.");
		vector<int> v(1, 52);
		vector<int>::const_iterator it = v.cbegin();
		EXPECT_IT_EQ(it, v.cbegin());
	}
	{
		NewTest("const_iterator: increment passed last element equals cend().");
		vector<int> v(1, 52);
		EXPECT_IT_EQ(++v.cbegin(), v.cend());
	}
	{
		NewTest("const_iterator: decrement passed first element equals crend().");
		vector<int> v(1, 52);
		EXPECT_IT_EQ(--v.cbegin(), v.crend());
	}
	{
		NewTest("const_iterator: --end() equals rbegin().");
		vector<int> v(1, 52);
		EXPECT_IT_EQ(--v.cend(), v.crbegin());
	}
	{
		NewTest("const_iterator: arrow operator returns structure members.");
		struct Structure {
			int a;
			char b;
		};
		Structure element = { 52, 53 };
		vector<Structure> s(2, element);
		vector<int> actual;
		for (vector<Structure>::const_iterator it = s.cbegin(); it != s.cend(); ++it) {
			actual.push_back(it->a);
			actual.push_back(it->b);
		}	
		const int expected[] = {52, 53, 52, 53};
		EXPECT_EQ(actual, expected);
	}
	{
		NewTest("const_iterator: positive indexing returns value.");
		EXPECT_1EQ(vector<int>(1, 52).cbegin()[0], 52);
	}
	{
		NewTest("const_iterator: negative indexing returns value.");
		EXPECT_1EQ(vector<int>(1, 52).cend()[-1], 52);
	}
	{
		NewTest("const_iterator: adding int gives correct new iterator.");
		vector<int> v;
		v.push_back(52);
		v.push_back(53);
		v.push_back(54);
		EXPECT_1EQ(*(v.cbegin() + 2), 54);
	}
	{
		NewTest("const_iterator: subtracting int gives correct new iterator.");
		vector<int> v;
		v.push_back(52);
		v.push_back(53);
		v.push_back(54);
		EXPECT_1EQ(*(v.cend() - 3), 52);
	}
	{
		NewTest("reverse_iterator: dereferencing returns value.");
		vector<int> v(1, 52);
		EXPECT_1EQ(*v.rbegin(), 52);
	}
	{
		NewTest("reverse_iterator: assignment makes iterators equal.");
		vector<int> v(1, 52);
		vector<int>::reverse_iterator it = v.rbegin();
		EXPECT_IT_EQ(it, v.rbegin());
	}
	{
		NewTest("reverse_iterator: increment passed last element equals rend().");
		vector<int> v(1, 52);
		EXPECT_IT_EQ(++v.rbegin(), v.rend());
	}
	{
		NewTest("reverse_iterator: decrement passed first element equals end().");
		vector<int> v(1, 52);
		EXPECT_IT_EQ(--v.rbegin(), v.end());
	}
	{
		NewTest("reverse_iterator: --rend() equals begin().");
		vector<int> v(1, 52);
		EXPECT_IT_EQ(--v.rend(), v.begin());
	}
	{
		NewTest("reverse_iterator: arrow operator returns structure members.");
		struct Structure {
			int a;
			char b;
		};
		Structure element = { 52, 53 };
		vector<Structure> s(2, element);
		vector<int> actual;
		for (vector<Structure>::reverse_iterator it = s.rbegin(); it != s.rend(); ++it) {
			actual.push_back(it->a);
			actual.push_back(it->b);
		}	
		const int expected[] = {52, 53, 52, 53};
		EXPECT_EQ(actual, expected);
	}
	{
		NewTest("reverse_iterator: positive indexing returns value.");
		EXPECT_1EQ(vector<int>(1, 52).rbegin()[0], 52);
	}
	{
		NewTest("reverse_iterator: negative indexing returns value.");
		EXPECT_1EQ(vector<int>(1, 52).rend()[-1], 52);
	}
	{
		NewTest("reverse_iterator: subtracting int gives correct new iterator.");
		vector<int> v;
		v.push_back(52);
		v.push_back(53);
		v.push_back(54);
		EXPECT_1EQ(*(v.rend() - 2), 53);
	}
	{
		NewTest("reverse_iterator: iteration reverses element order.");
		vector<int> v;
		v.push_back(1);
		v.push_back(2);
		v.push_back(3);
		vector<int> actual;
		for (vector<int>::reverse_iterator it = v.rbegin(); it != v.rend(); ++it) {
			actual.push_back(*it);
		}	
		const int expected[] = {3, 2, 1};
		EXPECT_EQ(actual, expected);
	}
	{
		NewTest("const_reverse_iterator: dereferencing returns value.");
		vector<int> v(1, 52);
		EXPECT_1EQ(*v.crbegin(), 52);
	}
	{
		NewTest("const_reverse_iterator: assignment makes iterators equal.");
		vector<int> v(1, 52);
		vector<int>::const_reverse_iterator it = v.crbegin();
		EXPECT_IT_EQ(it, v.crbegin());
	}
	{
		NewTest("const_reverse_iterator: inc passed last elem equals crend().");
		vector<int> v(1, 52);
		EXPECT_IT_EQ(++v.crbegin(), v.crend());
	}
	{
		NewTest("const_reverse_iterator: dec passed first elem equals cend().");
		vector<int> v(1, 52);
		EXPECT_IT_EQ(--v.crbegin(), v.cend());
	}
	{
		NewTest("const_reverse_iterator: --crend() equals cbegin().");
		vector<int> v(1, 52);
		EXPECT_IT_EQ(--v.crend(), v.cbegin());
	}
	{
		NewTest("const_reverse_iterator: arrow operator returns structure members.");
		struct Structure {
			int a;
			char b;
		};
		Structure element = { 52, 53 };
		vector<Structure> s(2, element);
		vector<int> actual;
		for (vector<Structure>::const_reverse_iterator it = s.crbegin(); it != s.crend(); ++it) {
			actual.push_back(it->a);
			actual.push_back(it->b);
		}	
		const int expected[] = {52, 53, 52, 53};
		EXPECT_EQ(actual, expected);
	}
	{
		NewTest("const_reverse_iterator: positive indexing returns value.");
		EXPECT_1EQ(vector<int>(1, 52).crbegin()[0], 52);
	}
	{
		NewTest("const_reverse_iterator: negative indexing returns value.");
		EXPECT_1EQ(vector<int>(1, 52).crend()[-1], 52);
	}
	{
		NewTest("const_reverse_iterator: adding int gives correct new iterator.");
		vector<int> v;
		v.push_back(52);
		v.push_back(53);
		v.push_back(54);
		EXPECT_1EQ(*(v.crbegin() + 2), 52);
	}
	{
		NewTest("const_reverse_iterator: subtract int gives correct new iterator.");
		vector<int> v;
		v.push_back(52);
		v.push_back(53);
		v.push_back(54);
		EXPECT_1EQ(*(v.crend() - 2), 53);
	}
	{
		NewTest("const_reverse_iterator: iteration reverses element order.");
		vector<int> v;
		v.push_back(1);
		v.push_back(2);
		v.push_back(3);
		vector<int> actual;
		for (vector<int>::const_reverse_iterator it = v.crbegin(); it != v.crend(); ++it) {
			actual.push_back(*it);
		}	
		const int expected[] = {3, 2, 1};
		EXPECT_EQ(actual, expected);
	}
	{
		NewTest("insert one element at the start.");
		vector<int> v;
		v.push_back(2);
		v.push_back(3);
		v.insert(v.begin(), 1);
		const int expected[] = {1, 2, 3};
		EXPECT_EQ(v, expected);
	}
	{
		NewTest("insert one element mid-vector.");
		vector<int> v;
		v.push_back(1);
		v.push_back(3);
		v.insert(v.begin() + 1, 2);
		const int expected[] = {1, 2, 3};
		EXPECT_EQ(v, expected);
	}
	{
		NewTest("insert one element at the end.");
		vector<int> v;
		v.push_back(1);
		v.push_back(2);
		v.insert(v.end(), 3);
		const int expected[] = {1, 2, 3};
		EXPECT_EQ(v, expected);
	}
	{
		NewTest("insert multiple elements.");
		vector<int> v;
		v.push_back(1);
		v.push_back(3);
		v.insert(v.begin() + 1, 3, 2);
		const int expected[] = {1, 2, 2, 2, 3};
		EXPECT_EQ(v, expected);
	}
	{
		NewTest("erase multiple elements.");
		vector<int> v;
		v.push_back(1);
		v.push_back(2);
		v.push_back(3);
		v.push_back(4);
		v.push_back(5);
		v.erase(v.begin() + 1, v.end() - 1);
		const int expected[] = {1, 5};
		EXPECT_EQ(v, expected);
	}
	{
		NewTest("erase all elements.");
		vector<int> v;
		v.push_back(1);
		v.push_back(2);
		v.push_back(3);
		v.push_back(4);
		v.push_back(5);
		v.erase(v.begin(), v.end());
		EXPECT_EMPTY(v);
	}
	
	printf("[SUCCESS] %dn tests passed.", num_tests);
	
	return 0;
}