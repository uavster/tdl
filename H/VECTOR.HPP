#ifndef VECTOR_HPP_INCLUDED_
#define VECTOR_HPP_INCLUDED_

#include "stddef.h"
#include "alloc.h"
#include "except.hpp"
#include "memcpy.h"

namespace std {

template<class T> class random_access_iterator {
public:
	T *operator->() {
		return p_;
	}
	T &operator*() {
		return *p_;
	}
	random_access_iterator<T> operator++(int) {
		random_access_iterator<T> self = *this;
		++p_;
		return self;
	}
	random_access_iterator<T> &operator++() {
		++p_;
		return *this;
	}
	random_access_iterator<T> operator--(int) {
		random_access_iterator<T> self = *this;
		--p_;
		return self;
	}
	random_access_iterator<T> &operator--() {
		--p_;
		return *this;
	}
	random_access_iterator<T> &operator+=(size_t n) {
		p_ += n;
		return *this;
	}
	random_access_iterator<T> &operator-=(size_t n) {
		p_ -= n;
		return *this;
	}
	random_access_iterator<T> &operator+=(int n) {
		p_ += n;
		return *this;
	}
	random_access_iterator<T> &operator-=(int n) {
		p_ -= n;
		return *this;
	}
	bool operator==(const random_access_iterator<T> it) const {
		return p_ == it.p_;
	}
	bool operator!=(const random_access_iterator<T> it) const {
		return p_ != it.p_;
	}
	bool operator<(const random_access_iterator<T> it) const {
		return p_ < it.p_;
	}
	bool operator<=(const random_access_iterator<T> it) const {
		return p_ <= it.p_;
	}
	bool operator>(const random_access_iterator<T> it) const {
		return p_ > it.p_;
	}
	bool operator>=(const random_access_iterator<T> it) const {
		return p_ >= it.p_;
	}
	size_t operator-(const random_access_iterator<T> it) const {
		return p_ - it.p_;
	}
	T &operator[](size_t i) const {
		return *(p_ + i);
	}
	T &operator[](int i) const {
		return *(p_ + i);
	}
protected:
	random_access_iterator(T *p) : p_(p) {}
private:
	T *p_;
};

template<class T> T operator+(const T it, const size_t n) {
	T cit = it;
	cit += n;
	return cit;
}
template<class T> T operator+(const size_t n, const T it) {
	return it + n;
}
template<class T> T operator+(const T it, const int n) {
	T cit = it;
	cit += n;
	return cit;
}
template<class T> T operator+(const int n, const T it) {
	return it + n;
}
template<class T> T operator-(const T it, const int n) {
	T cit = it;
	cit -= n;
	return cit;
}
template<class T> T operator-(const T it, const size_t n) {
	T cit = it;
	cit -= n;
	return cit;
}

template<class T> class vector {
public:
	vector() : capacity_(0), size_(0), data_(NULL) {}
	vector(const size_t num_elems) : size_(num_elems), data_(NULL) {
		reserve(num_elems);
	}
	vector(const size_t num_elems, const T &value) : size_(num_elems), data_(NULL) {
		reserve(num_elems);
		for (size_t i = 0; i < num_elems; ++i) {
			data_[i] = value;
		}
	}
	virtual ~vector() { if (data_ != NULL) { free(data_); data_ = NULL; } }
	
	void clear() {
		size_ = 0;
		if (data_ != NULL) { free(data_); data_ = NULL; }
	}
	void reserve(size_t capacity) {
		if (capacity <= capacity_) {
			return;
		}
		if (data_ == NULL) {
			data_ = static_cast<T *>(malloc(capacity * sizeof(T)));
			check_data();
		} else {
			data_ = static_cast<T *>(realloc(data_, capacity * sizeof(T)));
			check_data();
		}
		capacity_ = capacity;
	}

	void push_back(const T &value) {
		++size_;
		if (size_ > capacity_) {
			reserve(size_ + capacity_increase());
		}
		data_[size_ - 1] = value;
	}
	void pop_back() {
		--size_;
		if (size_ < capacity_ / 2 + capacity_increase()) {
			reserve(size_ + capacity_increase());
		}
	}
	inline size_t size() const { return size_; }
	inline T *data() const { return data_; }
	inline T &operator[](size_t i) const { return data_[i]; }
	inline T &front() const { return *data_; }
	inline T &back() const { return data_[size_ - 1]; }
	
	typedef random_access_iterator<T>	iterator;
	class const_iterator : public random_access_iterator<const T> {
	public:
		const_iterator(iterator it) : random_access_iterator<const T>(&*it) {}
	};

	inline const_iterator cbegin() const { return const_iterator(data_); }
	inline const_iterator cend() const { return const_iterator(&data_[size_]); }
	
	inline iterator begin() const { return iterator(data_); }
	inline iterator end() const { return iterator(&data_[size_]); }

	iterator erase(iterator first, iterator last) {
		if (last <= first) { return last; }
		size_t num_elems_to_move = end() - last;
		if (num_elems_to_move > 0) {
			memcpy(&*first, &*last, num_elems_to_move * sizeof(T));
		}
		size_ -= (last - first);
		return first;
	}
	
protected:
	size_t capacity_increase() const {
		size_t cap_increase = size_ >> 2;
		if (cap_increase < 8) {
			cap_increase = 8;
		}
		return cap_increase;
	}
	void check_data() {
		if (data_ == NULL) {
			throw Exception("Not enough memory.");
		}
	}
	
private:
	size_t capacity_;
	size_t size_;
	T *data_;
};

}	// std

#endif	// VECTOR_HPP_INCLUDED_