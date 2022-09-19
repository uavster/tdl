#ifndef __LIST_HPP_INCLUDED__
#define __LIST_HPP_INCLUDED__

#include "list.h"
#include "vector.hpp"

// A wrapper around the legacy linked list assembly implementation.
// Each node of the list has a pointer to the element. 
// All elements are owned by the inserter. Iteration is limited
// to one at a time; the iteration state is kept by the list.
template<class T> class PointerList {
public:
	PointerList() {
		list_ = NewList();
	}
	
	~PointerList() {
		DeleteList(list_);
	}

	enum Position { kStart = 0, kEnd = -1 };
	
	bool Insert(T *element, int at_index = kEnd) {
		return AddElement(list_, element, at_index) == 0;
	}
	
	bool Erase(T *element) {
		return DeleteElement(list_, element) == 0;
	}
	
	void Restart() {
		ResetListPtr(list_);
	}
	
	T *Next() {
		return static_cast<T *>(GetNextElement(list_));
	}
	
private:
	HList list_;
};

namespace std {

#ifdef list_kTerminalNode
#error "list_kTerminalNode is already defined elsewhere."
#endif
#define list_kTerminalNode static_cast<size_t>(-1)

template<class T> class list_node {
public:
	size_t prev;
	size_t next;
	// Value is stored in line for memory compactness.
	T value;
	
	list_node() : prev(list_kTerminalNode), next(list_kTerminalNode), value() {}
	list_node(const T &v) : prev(list_kTerminalNode), next(list_kTerminalNode), value(v) {}
};

template<class T> class base_list_iterator {
public:
	friend class list<T>;

	base_list_iterator() {}
	base_list_iterator(const base_list_iterator<T> &other) : list_(other.list_), index_(other.index_) {}

	base_list_iterator &operator++() {
		if (index_ != list_kTerminalNode) {
			index_ = list_->nodes_[index_].next;
		} else {
			index_ = list_->head_;
		}
		return *this;
	}
	base_list_iterator operator++(int) {
		base_list_iterator it(*this);
		++(*this);
		return it;
	}
	base_list_iterator &operator--() {
		if (index_ != list_kTerminalNode) {
			index_ = list_->nodes_[index_].prev;
		} else {
			index_ = list_->tail_;
		}
		return *this;
	}
	base_list_iterator operator--(int) {
		base_list_iterator it(*this);
		--(*this);
		return it;
	}	
	bool operator==(const base_list_iterator &it) const {
		return index_ == it.index_;
	}
	bool operator!=(const base_list_iterator &it) const {
		return !(*this == it);
	}
	base_list_iterator &operator=(const base_list_iterator &other) {
		list_ = other.list_;
		index_ = other.index_;
		return *this;
	}

protected:
	base_list_iterator(const list<T> *list, size_t index) : list_(list), index_(index) {}
	const list<T> *list_;
	size_t index_;
};

template<class T> class list_iterator : public base_list_iterator<T> {
public:	
	friend class list<T>;
	
	list_iterator() : base_list_iterator<T>() {}
	list_iterator(const base_list_iterator<T> &it) : base_list_iterator<T>(it) {}
	
	T &operator*() const {
		return list_->nodes_[index_].value;
	}
	T *operator->() const {
		return &*(*this);
	}
	list_iterator &operator=(const list_iterator &other) {
		base_list_iterator::operator=(other);
		return *this;
	}

protected:
	list_iterator(const list<T> *list, size_t index) : base_list_iterator<T>(list, index) {}
};

template<class T> class const_list_iterator : public base_list_iterator<T> {
public:
	friend class list<T>;

	const_list_iterator() : base_list_iterator<T>() {}
	const_list_iterator(const base_list_iterator<T> &it) : base_list_iterator<T>(it) {}
	const_list_iterator(const list_iterator<T> &it) : base_list_iterator<T>(it) {}

	const T &operator*() const {
		return list_->nodes_[index_].value;
	}
	const T *operator->() const {
		return &*(*this);
	}
	const_list_iterator operator=(const const_list_iterator &other) {
		base_list_iterator::operator=(other);
		return *this;
	}
	
protected:
	const_list_iterator(const list<T> *list, size_t index) : base_list_iterator<T>(list, index) {}
};

template<class T> class base_reverse_list_iterator : public base_list_iterator<T> {
public:
	friend class list<T>;

	base_reverse_list_iterator() : base_list_iterator<T>() {}
	base_reverse_list_iterator(const base_reverse_list_iterator<T> &other) : base_list_iterator<T>(other) {}
	base_reverse_list_iterator(const base_list_iterator<T> &other) : base_list_iterator<T>(other) {}

	base_reverse_list_iterator &operator++() {
		base_list_iterator::operator--();
		return *this;
	}
	base_reverse_list_iterator operator++(int) {
		return base_list_iterator::operator--(0);
	}
	base_reverse_list_iterator &operator--() {
		base_list_iterator::operator++();
		return *this;
	}
	base_reverse_list_iterator operator--(int) {
		return base_list_iterator::operator++(0);
	}	
	base_reverse_list_iterator &operator=(const base_reverse_list_iterator &other) {
		base_list_iterator::operator=(other);
		return *this;
	}
	
protected:
	base_reverse_list_iterator(const list<T> *list, size_t index) : base_list_iterator<T>(list, index) {}
};

template<class T> class reverse_list_iterator : public base_reverse_list_iterator<T> {
public:	
	friend class list<T>;
	
	reverse_list_iterator() : base_reverse_list_iterator<T>() {}
	reverse_list_iterator(const base_reverse_list_iterator<T> &it) : base_reverse_list_iterator<T>(it) {}
	
	T &operator*() const {
		return list_->nodes_[index_].value;
	}
	T *operator->() const {
		return &*(*this);
	}
	reverse_list_iterator &operator=(const reverse_list_iterator &other) {
		base_reverse_list_iterator::operator=(other);
		return *this;
	}

protected:
	reverse_list_iterator(const list<T> *list, size_t index) : base_reverse_list_iterator<T>(list, index) {}
};

template<class T> class const_reverse_list_iterator : public base_reverse_list_iterator<T> {
public:
	friend class list<T>;

	const_reverse_list_iterator() : base_reverse_list_iterator<T>() {}
	const_reverse_list_iterator(const base_reverse_list_iterator<T> &it) : base_reverse_list_iterator<T>(it) {}
	const_reverse_list_iterator(const reverse_list_iterator<T> &it) : base_reverse_list_iterator<T>(it) {}

	const T &operator*() const {
		return list_->nodes_[index_].value;
	}
	const T *operator->() const {
		return &*(*this);
	}
	const_reverse_list_iterator &operator=(const const_reverse_list_iterator &other) {
		base_reverse_list_iterator::operator=(other);
		return *this;
	}
	
protected:
	const_reverse_list_iterator(const list<T> *list, size_t index) : base_reverse_list_iterator<T>(list, index) {}
};

// STL-style list that owns the elements and allows for multiple iterators.
// It uses a vector as node store as opposed to allocating each node
// individually. This is meant to minimize the allocation time and memory
// overhead that would dominate in lists with small elements, and favor 
// efficient cache use if elements are not reordered.

// For simplicity, the nodes of inserted elements are always appended to the
// back of the store, and the space left by an erasure is never reused. 
// This has an extra memory cost, but could also favor cache efficiency of
// iteration after erasing or inserting at the back by keeping node addresses
// monotonically increasing. Copying the list can be used to compact the layout
// (and make nodes sequential) in memory again, which may be worth it if it
// has to be iterated many times.
// 
// Iterators keep a reference to the list and the node index in the 
// store so that they are always valid. There could be a performance penalty
// when iterating, compared to pointing directly at the node, but that would
// not prevent iterator invalidation, and would violate the STL invalidation
// rules.
// 
// An important difference with the standard is that those functions erasing
// elements do not call their destructors, so callers have to do it explicitly
// before erasing. This is a limitation imposed by Watcom 11, as it does not
// compile if the destructor is called on a native type, unlike modern compilers,
// where that is a no op. That would prevent lists from being used for native 
// types, so we do not call the destructor.
template<class T> class list {
	friend class base_list_iterator<T>;
	friend class list_iterator<T>;
	friend class const_list_iterator<T>;
	friend class reverse_list_iterator<T>;
	friend class const_reverse_list_iterator<T>;
public:
	list() : head_(list_kTerminalNode), tail_(list_kTerminalNode), size_(0) {}
	list(size_t count, const T &value = T()) : head_(list_kTerminalNode), tail_(list_kTerminalNode), size_(0) {
		resize(count, value);
	}
	
	void resize(size_t count, const T &value = T()) {
		size_t old_size = nodes_.size();
		if (count == old_size) {
			return;
		}
		size_ = count;
		if (count > old_size) {
			nodes_.resize(size_, list_node<T>(value));
			if (head_ == list_kTerminalNode) {
				head_ = 0;
			}
			if (tail_ != list_kTerminalNode) {
				nodes_[tail_].next = old_size;
			}
			nodes_[old_size].prev = tail_;
			nodes_[old_size].next = old_size + 1;
			for (size_t i = old_size + 1; i < nodes_.size(); ++i) {
				nodes_[i].prev = i - 1;		// Assumes list_kTerminalNode == -1.
				nodes_[i].next = i + 1;
			}
			nodes_[nodes_.size() - 1].next = list_kTerminalNode;
			tail_ = nodes_.size() - 1;
		} else {
			list<T>::const_iterator it = crbegin();
			while (count-- > 0) { ++it; }				
			tail_ = it.index_;
			nodes_[tail_].next = list_kTerminalNode;
		}
	}
	
	size_t size() const { return size_; }
	bool empty() const { return size_ == 0; }
	
	T &front() const { return nodes_[head_].value; }
	T &back() const { return nodes_[tail_].value; }
	
	typedef list_iterator<T> iterator;
	
	iterator begin() const { return iterator(this, head_); }
	iterator end() const { return iterator(this, list_kTerminalNode); }

	typedef const_list_iterator<T> const_iterator;
	
	const_iterator cbegin() const { return const_iterator(begin()); }
	const_iterator cend() const { return const_iterator(end()); }

	typedef reverse_list_iterator<T> reverse_iterator;
	
	reverse_iterator rbegin() const { return reverse_iterator(this, tail_); }
	reverse_iterator rend() const { return reverse_iterator(this, list_kTerminalNode); }

	typedef const_reverse_list_iterator<T> const_reverse_iterator;

	const_reverse_iterator crbegin() const { return const_reverse_iterator(rbegin()); }
	const_reverse_iterator crend() const { return const_reverse_iterator(rend()); }

	iterator insert(iterator position, size_t count, const T &value) {
		if (count == 0) {
			return position;
		}
		nodes_.insert(nodes_.end(), count, value);
		size_t new_index = nodes_.size() - count;
		size_t new_prev;
		if (position.index_ != list_kTerminalNode) {
			// The list is not empty, and not inserting at end.
			new_prev = nodes_[position.index_].prev;
			nodes_[position.index_].prev = new_index;
			if (new_prev != list_kTerminalNode) {
				nodes_[new_prev].next = new_index;
			} else {
				// Inserting at front.
				head_ = new_index;
			}
		} else {
			new_prev = tail_;
			if (new_prev != list_kTerminalNode) {
				// The list is empty.
				nodes_[tail_].next = new_index;
			} else {
				// Inserting at end.
				head_ = new_index;
			}
			tail_ = new_index + count - 1;
		}
		nodes_[new_index].prev = new_prev;
		nodes_[new_index].next = new_index + 1;
		for (size_t i = new_index + 1; i < new_index + count; ++i) {
			nodes_[i].prev = i - 1;
			nodes_[i].next = i + 1;
		}
		nodes_[new_index + count - 1].next = position.index_;
		size_ += count;
		return iterator(this, new_index);
	}
	
	iterator insert(iterator position, const T &value) {
		return insert(position, 1, value);
	}
	
	iterator erase(iterator first, iterator last) {
		if (first == end() || first == last) {
			return last;
		}
		for (list<T>::iterator it = first; it != last; ++it) {
			// Unlike on modern compilers, Watcom 11 fails compiling the destructor call if T is a native type.
			// it->~T();
			--size_;
		}
		size_t prev_index = nodes_[first.index_].prev;
		size_t next_index = last.index_;
		if (prev_index != list_kTerminalNode) {
			nodes_[prev_index].next = next_index;
		} else {
			head_ = next_index;
		}
		if (next_index != list_kTerminalNode) {
			nodes_[next_index].prev = prev_index;
		} else {
			tail_ = prev_index;
		}
		return last;
	}
	
	iterator erase(iterator position) {
		list<T>::iterator last(position);
		return erase(position, ++last);
	}
	
	void push_front(const T &value) {
		insert(begin(), value);
	}	
	void pop_front() {
		erase(begin());
	}
	
	void push_back(const T &value) {
		insert(end(), value);
	}
	void pop_back() {
		erase(rbegin());
	}
	
	void clear() {
		head_ = list_kTerminalNode;
		tail_ = list_kTerminalNode;
		size_ = 0;
		nodes_.clear();
	}
	
	void sort() {
		// STL sort must be stable (preserver existing order of equivalent elements).
		// We use buble sort to respect that and for simplicity.
		bool swapped_any;
		do {
			swapped_any = false;
			for (iterator it = begin(); it != rbegin();) {
				iterator next_it = it;
				++next_it;
				if (*next_it < *it) {
					swap_consecutive_nodes(it, next_it);
					swapped_any = true;
				} else {
					++it;
				}
			}
		} while(swapped_any);
	}

protected:
	void swap_consecutive_nodes(iterator first, iterator second) {
		list_node<T> &node1 = nodes_[first.index_];
		list_node<T> &node2 = nodes_[second.index_];
		// node1.prev <-> node2
		if (node1.prev == list_kTerminalNode) {
			head_ = second.index_;
		} else {
			nodes_[node1.prev].next = second.index_;
		}
		node2.prev = node1.prev;
		// node1 <-> node2.next
		node1.next = node2.next;
		if (node2.next == list_kTerminalNode) {
			tail_ = first.index_;
		} else {
			nodes_[node2.next].prev = first.index_;
		}
		// node2 <-> node1
		node2.next = first.index_;
		node1.prev = second.index_;
	}
	
private:
	size_t head_;
	size_t tail_;
	size_t size_;
	vector<list_node<T> > nodes_;
};

#undef list_kTerminalNode

}	// namespace std

#endif