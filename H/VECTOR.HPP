#ifndef VECTOR_HPP_INCLUDED_
#define VECTOR_HPP_INCLUDED_

#include "stddef.h"
#include "stdio.h"
#include "alloc.h"
#include "except.hpp"
#include "memcpy.h"

namespace std {

template<class T> class random_access_iterator {
public:	
	random_access_iterator() {}

	T *operator->() const {
		return p_;
	}
	T &operator*() const {
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
	int operator-(const random_access_iterator<T> it) const {
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

template<class T> class random_access_reverse_iterator : public random_access_iterator<T> {
public:
	random_access_reverse_iterator() : random_access_iterator<T>() {}

	random_access_reverse_iterator<T> operator++(int) {
		return random_access_iterator<T>::operator--(0);
	}
	random_access_reverse_iterator<T> &operator++() {
		random_access_iterator<T>::operator--();
		return *this;
	}
	random_access_reverse_iterator<T> operator--(int) {
		return random_access_iterator<T>::operator++(0);
	}
	random_access_reverse_iterator<T> &operator--() {
		random_access_iterator<T>::operator++();
		return *this;
	}
	random_access_reverse_iterator<T> &operator+=(size_t n) {
		random_access_iterator<T>::operator-=(n);
		return *this;
	}
	random_access_reverse_iterator<T> &operator-=(size_t n) {
		random_access_iterator<T>::operator+=(n);
		return *this;		
	}
	random_access_reverse_iterator<T> &operator+=(int n) {
		random_access_iterator<T>::operator-=(n);
		return *this;
	}
	random_access_reverse_iterator<T> &operator-=(int n) {
		random_access_iterator<T>::operator+=(n);
		return *this;
	}
	bool operator<(const random_access_reverse_iterator<T> it) const {
		return random_access_iterator<T>::operator>(it);
	}
	bool operator<=(const random_access_reverse_iterator<T> it) const {
		return random_access_iterator<T>::operator>=(it);
	}
	bool operator>(const random_access_reverse_iterator<T> it) const {
		return random_access_iterator<T>::operator<(it);
	}
	bool operator>=(const random_access_reverse_iterator<T> it) const {
		return random_access_iterator<T>::operator<=(it);
	}
	int operator-(const random_access_reverse_iterator<T> it) const {
		return static_cast<random_access_iterator>(it) - static_cast<random_access_iterator>(*this);
	}
	T &operator[](size_t i) const {
		return *((*this) + i);
	}
	T &operator[](int i) const {
		return random_access_iterator<T>::operator[](-i);
	}
protected:
	random_access_reverse_iterator(T *p) : random_access_iterator<T>(p) {}
private:
	random_access_reverse_iterator(random_access_iterator<T> it) : random_access_iterator(&*it) {}
};

template<class T> class vector {
public:
	vector() : capacity_(0), size_(0), data_(NULL) {}
	vector(const size_t num_elems) : capacity_(0), size_(num_elems), data_(NULL) {
		reserve(num_elems);
	}
	vector(const size_t num_elems, const T &value) : capacity_(0), size_(num_elems), data_(NULL) {
		reserve(num_elems);
		for (size_t i = 0; i < num_elems; ++i) {
			data_[i] = value;
		}
	}
	virtual ~vector() { if (data_ != NULL) { free(data_); data_ = NULL; } }
	
	void clear() { size_ = 0; }
	
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
	inline size_t capacity() const { return capacity_; }
	inline bool empty() const { return size_ == 0; }
	inline T *data() const { return data_; }
	inline T &operator[](size_t i) const { return data_[i]; }
	inline T &front() const { return *data_; }
	inline T &back() const { return data_[size_ - 1]; }
	
	typedef random_access_iterator<T> iterator;
	class const_iterator : public random_access_iterator<const T> {
	public:
		const_iterator() : random_access_iterator<const T>() {}
		const_iterator(iterator it) : random_access_iterator<const T>(&*it) {}
		const_iterator(const random_access_iterator<const T> &it) : random_access_iterator<const T>(it) {}
	};

	inline const_iterator cbegin() const { return const_iterator(data_); }
	inline const_iterator cend() const { return const_iterator(&data_[size_]); }
	
	inline iterator begin() const { return iterator(data_); }
	inline iterator end() const { return iterator(&data_[size_]); }
	
	typedef random_access_reverse_iterator<T> reverse_iterator;
	class const_reverse_iterator : public random_access_reverse_iterator<const T> {
	public:
		const_reverse_iterator() : random_access_reverse_iterator<const T>() {}
		const_reverse_iterator(reverse_iterator it) : random_access_reverse_iterator<const T>(&*it) {}
		const_reverse_iterator(const random_access_reverse_iterator<const T> &it) : random_access_reverse_iterator<const T>(it) {}
	};

	inline const_reverse_iterator crbegin() const { return const_reverse_iterator(&data_[size_ - 1]); }
	inline const_reverse_iterator crend() const { return const_reverse_iterator(data_ - 1); }
	inline reverse_iterator rbegin() const { return reverse_iterator(&data_[size_ - 1]); }
	inline reverse_iterator rend() const { return reverse_iterator(data_ - 1); }

	iterator erase(iterator first, iterator last) {
		if (last <= first) { return last; }
		size_t num_elems_to_move = end() - last;
		if (num_elems_to_move > 0) {
			memcpy(&*first, &*last, num_elems_to_move * sizeof(T));
		}
		size_ -= (last - first);
		return first;
	}
	
	iterator insert(iterator pos, size_t count, const T &value) {
		if (count == 0) {
			return pos;
		}
		// Save the insertion index, as pos will be invalidated by the next reserve().
		int insertion_index = pos - begin();
		size_t num_elems_to_move = end() - pos;
		reserve(size_ + count);
		if (num_elems_to_move) {
			T *src = &*(end() - 1);
			T *dst = src + count;
			T *dst_end = dst - num_elems_to_move;
			for (; dst != dst_end; --src, --dst) {
				*dst = *src;
			}
		}
		size_ += count;
		iterator it = begin() + insertion_index;
		while(count--) {
			*it = value;
			++it;
		}
		return begin() + insertion_index;
	}
	
	iterator insert(iterator pos, const T &value) {
		return insert(pos, 1, value);
	}
	
	void resize(size_t count, T value = T()) {
		if (count == size_) {
			return;
		}
		if (count < size_) {
			size_ = count;
			return;
		}
		insert(end(), count - size_, value);
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
			printf("Unable to reserve vector capacity.");
			exit(1);
		}
	}
	
private:
	size_t capacity_;
	size_t size_;
	T *data_;
};

}	// std

#endif	// VECTOR_HPP_INCLUDED_