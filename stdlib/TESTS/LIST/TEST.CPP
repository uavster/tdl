#include "tdl.h"
#include "list.hpp"

using namespace std;

int num_tests = 0;

void NewTest(const char *name) {
	++num_tests;
	printf("Test %dn: ", num_tests);
	printf(name);
}

void PrintIntList(const list<int> &l) {
	for (list<int>::const_iterator it = l.cbegin(); it != l.cend(); ++it) {
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

void CheckResult(const list<int> &actual, const int *expected, size_t expected_len) {
	bool are_equal = expected_len == actual.size();
	if (are_equal) {
		list<int>::const_iterator it = actual.cbegin();
		for (size_t i = 0; i < actual.size(); ++i, ++it) {
			if (expected[i] != *it) {
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
		PrintIntList(actual);
		exit(1);
	}
}

void CheckSize(const list<int> &actual, const int expected_size) {
	if (actual.size() == expected_size) {
		printf(" [OK]\n");
	} else {
		printf(" [ERROR]\nExpected size: %dn\n", expected_size);
		printf("Actual size:   %dn ; ", actual.size());
		PrintIntList(actual);
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

void CheckIteratorsEqual(const list<int>::const_iterator &it1, const list<int>::const_iterator &it2) {
	if (it1 == it2) {
		printf(" [OK]\n");
	} else {
		printf(" [ERROR]\nExpected: == returns true\nActual: == returns false\n");
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
		NewTest("Emtpy constructor creates empty list.");
		EXPECT_EMPTY(list<int>());
	}
	{
		NewTest("One-argument constructor sets list size.");
		EXPECT_SIZE(list<int>(3), 3);
	}
	{
		NewTest("Two-argument constructor initializes element values.");
		list<int> l(3, 52);
		const int expected[] = {52, 52, 52};
		EXPECT_EQ(l, expected);
	}
	{
		NewTest("size() returns number of elements.");
		EXPECT_1EQ(list<int>(3, 0).size(), 3);
	}
	{
		NewTest("push_back() adds one element after end.");
		list<int> l(3, 52);
		l.push_back(42);
		const int expected[] = {52, 52, 52, 42};
		EXPECT_EQ(l, expected);
	}
	{
		NewTest("pop_back() removes last element.");
		list<int> l(3, 52);
		l.pop_back();
		const int expected[] = {52, 52};
		EXPECT_EQ(l, expected);
	}
	{
		NewTest("clear() erases all elements.");
		list<int> l(3, 52);
		l.clear();
		EXPECT_EMPTY(l);
	}
	{
		NewTest("resize() to larger size increases size.");
		list<int> l;
		l.resize(3);
		EXPECT_SIZE(l, 3);
	}	
	{
		NewTest("resize() to same size conserves size.");
		list<int> l(3, 52);
		l.resize(3);
		const int expected[] = { 52, 52, 52 };
		EXPECT_EQ(l, expected);
	}	
	{
		NewTest("resize() to smaller size reduces size.");
		list<int> l(3, 52);
		l.resize(1);
		const int expected[] = { 52 };
		EXPECT_EQ(l, expected);
	}	
	{
		NewTest("resize() to larger size with value sets value of new elements.");
		list<int> l(1, 52);
		l.resize(3, 53);
		const int expected[] = { 52, 53, 53 };
		EXPECT_EQ(l, expected);
	}	
	{
		NewTest("front() returns first element.");
		list<int> l;
		l.push_back(52);
		l.push_back(53);
		EXPECT_1EQ(l.front(), 52);
	}	
	{
		NewTest("back() returns last element.");
		list<int> l;
		l.push_back(52);
		l.push_back(53);
		EXPECT_1EQ(l.back(), 53);
	}	
	{
		NewTest("iterator: default constructor can be called.");
		list<int>::iterator it;
		printf(" [OK]\n");
	}
	{
		NewTest("iterator: dereferencing returns value.");
		list<int> l(1, 52);
		EXPECT_1EQ(*l.begin(), 52);
	}
	{
		NewTest("iterator: assignment makes iterators equal.");
		list<int> l(1, 52);
		list<int>::iterator it = l.begin();
		EXPECT_IT_EQ(it, l.begin());
	}
	{
		NewTest("iterator: increment passed last element equals end().");
		list<int> l(1, 52);
		EXPECT_IT_EQ(++l.begin(), l.end());
	}
	{
		NewTest("iterator: decrement passed first element equals rend().");
		list<int> l(1, 52);
		EXPECT_IT_EQ(--l.begin(), l.rend());
	}
	{
		NewTest("iterator: --end() equals rbegin().");
		list<int> l(1, 52);
		EXPECT_IT_EQ(--l.end(), l.rbegin());
	}
	{
		NewTest("iterator: arrow operator returns structure members.");
		struct Structure {
			int a;
			char b;
			bool operator<(const Structure &s) { return a < s.a; }
		};
		Structure element = { 52, 53 };
		list<Structure> l(2, element);
		list<int> actual;
		for (list<Structure>::iterator it = l.begin(); it != l.end(); ++it) {
			actual.push_back(it->a);
			actual.push_back(it->b);
		}	
		const int expected[] = {52, 53, 52, 53};
		EXPECT_EQ(actual, expected);
	}
	{
		NewTest("iterator: deferencing allows mutation.");
		list<int> l(1, 52);
		++*l.begin();
		EXPECT_1EQ(l.front(), 53);
	}
	{
		// NewTest("iterator: arrow operator allows mutation.");
		struct Structure {
			int a;
			char b;
			bool operator<(const Structure &s) { return a < s.a; }
		};
		Structure element = { 52, 53 };
		list<Structure> s(1, element);
		++s.begin()->a;
		++s.begin()->b;
		list<int> actual;
		for (list<Structure>::iterator it = s.begin(); it != s.end(); ++it) {
			actual.push_back(it->a);
			actual.push_back(it->b);
		}	
		const int expected[] = {53, 54};
		EXPECT_EQ(actual, expected);
	}
	{
		NewTest("const_iterator: default constructor can be called.");
		list<int>::const_iterator it;
	}
	{
		NewTest("const_iterator: dereferencing returns value.");
		list<int> l(1, 52);
		EXPECT_1EQ(*l.cbegin(), 52);
	}
	{
		NewTest("const_iterator: assignment makes iterators equal.");
		list<int> l(1, 52);
		list<int>::const_iterator it = l.cbegin();
		EXPECT_IT_EQ(it, l.cbegin());
	}
	{
		NewTest("const_iterator: increment passed last element equals cend().");
		list<int> l(1, 52);
		EXPECT_IT_EQ(++l.cbegin(), l.cend());
	}
	{
		NewTest("const_iterator: decrement passed first element equals crend().");
		list<int> l(1, 52);
		EXPECT_IT_EQ(--l.cbegin(), l.crend());
	}
	{
		NewTest("const_iterator: --end() equals rbegin().");
		list<int> l(1, 52);
		EXPECT_IT_EQ(--l.cend(), l.crbegin());
	}
	{
		NewTest("const_iterator: arrow operator returns structure members.");
		struct Structure {
			int a;
			char b;
			bool operator<(const Structure &s) { return a < s.a; }
		};
		Structure element = { 52, 53 };
		list<Structure> s(2, element);
		list<int> actual;
		for (list<Structure>::const_iterator it = s.cbegin(); it != s.cend(); ++it) {
			actual.push_back(it->a);
			actual.push_back(it->b);
		}	
		const int expected[] = {52, 53, 52, 53};
		EXPECT_EQ(actual, expected);
	}
	{
		NewTest("reverse_iterator: default constructor can be called.");
		list<int>::reverse_iterator it;
	}
	{
		NewTest("reverse_iterator: dereferencing returns value.");
		list<int> l(1, 52);
		EXPECT_1EQ(*l.rbegin(), 52);
	}
	{
		NewTest("reverse_iterator: assignment makes iterators equal.");
		list<int> l(1, 52);
		list<int>::reverse_iterator it = l.rbegin();
		EXPECT_IT_EQ(it, l.rbegin());
	}
	{
		NewTest("reverse_iterator: increment passed last element equals rend().");
		list<int> l(1, 52);
		EXPECT_IT_EQ(++l.rbegin(), l.rend());
	}
	{
		NewTest("reverse_iterator: decrement passed first element equals end().");
		list<int> l(1, 52);
		EXPECT_IT_EQ(--l.rbegin(), l.end());
	}
	{
		NewTest("reverse_iterator: --rend() equals begin().");
		list<int> l(1, 52);
		EXPECT_IT_EQ(--l.rend(), l.begin());
	}
	{
		NewTest("reverse_iterator: arrow operator returns structure members.");
		struct Structure {
			int a;
			char b;
			bool operator<(const Structure &s) { return a < s.a; }
		};
		Structure element = { 52, 53 };
		list<Structure> s(2, element);
		list<int> actual;
		for (list<Structure>::reverse_iterator it = s.rbegin(); it != s.rend(); ++it) {
			actual.push_back(it->a);
			actual.push_back(it->b);
		}	
		const int expected[] = {52, 53, 52, 53};
		EXPECT_EQ(actual, expected);
	}
	{
		NewTest("reverse_iterator: iteration reverses element order.");
		list<int> l;
		l.push_back(1);
		l.push_back(2);
		l.push_back(3);
		list<int> actual;
		for (list<int>::reverse_iterator it = l.rbegin(); it != l.rend(); ++it) {
			actual.push_back(*it);
		}	
		const int expected[] = {3, 2, 1};
		EXPECT_EQ(actual, expected);
	}
	{
		NewTest("const_reverse_iterator: default constructor can be called.");
		list<int>::const_reverse_iterator it;
		printf(" [OK]\n");
	}
	{
		NewTest("const_reverse_iterator: dereferencing returns value.");
		list<int> l(1, 52);
		EXPECT_1EQ(*l.crbegin(), 52);
	}
	{
		NewTest("const_reverse_iterator: assignment makes iterators equal.");
		list<int> l(1, 52);
		list<int>::const_reverse_iterator it = l.crbegin();
		EXPECT_IT_EQ(it, l.crbegin());
	}
	{
		NewTest("const_reverse_iterator: inc passed last elem equals crend().");
		list<int> l(1, 52);
		EXPECT_IT_EQ(++l.crbegin(), l.crend());
	}
	{
		NewTest("const_reverse_iterator: dec passed first elem equals cend().");
		list<int> l(1, 52);
		EXPECT_IT_EQ(--l.crbegin(), l.cend());
	}
	{
		NewTest("const_reverse_iterator: --crend() equals cbegin().");
		list<int> l(1, 52);
		EXPECT_IT_EQ(--l.crend(), l.cbegin());
	}
	{
		NewTest("const_reverse_iterator: arrow operator returns structure members.");
		struct Structure {
			int a;
			char b;
			bool operator<(const Structure &s) { return a < s.a; }
		};
		Structure element = { 52, 53 };
		list<Structure> s(2, element);
		list<int> actual;
		for (list<Structure>::const_reverse_iterator it = s.crbegin(); it != s.crend(); ++it) {
			actual.push_back(it->a);
			actual.push_back(it->b);
		}	
		const int expected[] = {52, 53, 52, 53};
		EXPECT_EQ(actual, expected);
	}
	{
		NewTest("const_reverse_iterator: iteration reverses element order.");
		list<int> l;
		l.push_back(1);
		l.push_back(2);
		l.push_back(3);
		list<int> actual;
		for (list<int>::const_reverse_iterator it = l.crbegin(); it != l.crend(); ++it) {
			actual.push_back(*it);
		}	
		const int expected[] = {3, 2, 1};
		EXPECT_EQ(actual, expected);
	}
	{
		NewTest("insert one element at the start.");
		list<int> l;
		l.push_back(2);
		l.push_back(3);
		l.insert(l.begin(), 1);
		const int expected[] = {1, 2, 3};
		EXPECT_EQ(l, expected);
	}
	{
		NewTest("insert one element mid-list.");
		list<int> l;
		l.push_back(1);
		l.push_back(3);
		l.insert(++l.begin(), 2);
		const int expected[] = {1, 2, 3};
		EXPECT_EQ(l, expected);
	}
	{
		NewTest("insert one element at the end.");
		list<int> l;
		l.push_back(1);
		l.push_back(2);
		l.insert(l.end(), 3);
		const int expected[] = {1, 2, 3};
		EXPECT_EQ(l, expected);
	}
	{
		NewTest("insert multiple elements mid list.");
		list<int> l;
		l.push_back(1);
		l.push_back(3);
		l.insert(++l.begin(), 3, 2);
		const int expected[] = {1, 2, 2, 2, 3};
		EXPECT_EQ(l, expected);
	}
	{
		NewTest("insert multiple elements at end.");
		list<int> l;
		l.push_back(1);
		l.push_back(3);
		l.insert(l.end(), 3, 2);
		const int expected[] = {1, 3, 2, 2, 2};
		EXPECT_EQ(l, expected);
	}
	{
		NewTest("rbegin() valid after inserting multiple elements at end.");
		list<int> l;
		l.push_back(1);
		l.push_back(3);
		l.insert(l.end(), 3, 2);
		list<int> rl;
		for (list<int>::const_reverse_iterator it = l.crbegin(); it != l.crend(); ++it) {
			rl.push_back(*it);
		}
		const int expected[] = {2, 2, 2, 3, 1};
		EXPECT_EQ(rl, expected);
	}
	{
		NewTest("insert multiple elements at start.");
		list<int> l;
		l.push_back(1);
		l.push_back(3);
		l.insert(l.begin(), 3, 2);
		const int expected[] = {2, 2, 2, 1, 3};
		EXPECT_EQ(l, expected);
	}
	{
		NewTest("erase multiple elements.");
		list<int> l;
		l.push_back(1);
		l.push_back(2);
		l.push_back(3);
		l.push_back(4);
		l.push_back(5);
		l.erase(++l.begin(), --l.end());
		const int expected[] = {1, 5};
		EXPECT_EQ(l, expected);
	}
	{
		NewTest("erase all elements.");
		list<int> l;
		l.push_back(1);
		l.push_back(2);
		l.push_back(3);
		l.push_back(4);
		l.push_back(5);
		l.erase(l.begin(), l.end());
		EXPECT_EMPTY(l);
	}
	
	printf("[SUCCESS] %dn tests passed.", num_tests);
	
	return 0;
}