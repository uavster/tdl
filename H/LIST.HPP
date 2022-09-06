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

	base_list_iterator(const base_list_iterator<T> &other) : nodes_(other.nodes_), index_(other.index_) {}

	base_list_iterator &operator++() {
		index_ = (*nodes_)[index_].next;
		return *this;
	}
	base_list_iterator operator++(int) {
		base_list_iterator it(*this);
		index_ = (*nodes_)[index_].next;
		return it;
	}
	base_list_iterator &operator--() {
		index_ = (*nodes_)[index_].prev;
		return *this;
	}
	base_list_iterator operator--(int) {
		base_list_iterator it(*this);
		index_ = (*nodes_)[index_].prev;
		return it;
	}	
	bool operator==(const base_list_iterator &it) const {
		return index_ == it.index_;
	}
	bool operator!=(const base_list_iterator &it) const {
		return index_ != it.index_;
	}
	base_list_iterator &operator=(const base_list_iterator &other) {
		nodes_ = other.nodes_;
		index_ = other.index_;
		return *this;
	}

protected:
	base_list_iterator(const vector<list_node<T> > *nodes, size_t index) : nodes_(nodes), index_(index) {}
	const vector<list_node<T> > *nodes_;
	size_t index_;
};

template<class T> class list_iterator : public base_list_iterator<T> {
public:	
	friend class list<T>;
	
	list_iterator(const base_list_iterator<T> &it) : base_list_iterator<T>(it) {}
	
	T &operator*() const {
		return (*nodes_)[index_].value;
	}
	T *operator->() const {
		return &(*nodes_)[index_].value;
	}
	list_iterator &operator=(const list_iterator &other) {
		base_list_iterator::operator=(other);
		return *this;
	}

protected:
	list_iterator(const vector<list_node<T> > *nodes, size_t index) : base_list_iterator<T>(nodes, index) {}
};

template<class T> class const_list_iterator : public base_list_iterator<T> {
public:
	friend class list<T>;

	const_list_iterator(const base_list_iterator<T> &it) : base_list_iterator<T>(it) {}
	const_list_iterator(const list_iterator<T> &it) : base_list_iterator<T>(it) {}

	const T &operator*() const {
		return (*nodes_)[index_].value;
	}
	const T *operator->() const {
		return &(*nodes_)[index_].value;
	}
	const_list_iterator operator=(const const_list_iterator &other) {
		base_list_iterator::operator=(other);
		return *this;
	}
	
protected:
	const_list_iterator(const vector<list_node<T> > *nodes, size_t index) : base_list_iterator<T>(nodes, index) {}
};

template<class T> class base_reverse_list_iterator : public base_list_iterator<T> {
public:
	friend class list<T>;

	base_reverse_list_iterator(const base_reverse_list_iterator<T> &other) : base_list_iterator<T>(other) {}
	base_reverse_list_iterator(const base_list_iterator<T> &other) : base_list_iterator<T>(other) {}

	base_reverse_list_iterator &operator++() {
		index_ = (*nodes_)[index_].prev;
		return *this;
	}
	base_reverse_list_iterator operator++(int) {
		base_reverse_list_iterator it(*this);
		index_ = (*nodes_)[index_].prev;
		return it;
	}
	base_reverse_list_iterator &operator--() {
		index_ = (*nodes_)[index_].next;
		return *this;
	}
	base_reverse_list_iterator operator--(int) {
		base_reverse_list_iterator it(*this);
		index_ = (*nodes_)[index_].next;
		return it;
	}	
	base_reverse_list_iterator &operator=(const base_reverse_list_iterator &other) {
		base_list_iterator::operator=(other);
		return *this;
	}
	
protected:
	base_reverse_list_iterator(const vector<list_node<T> > *nodes, size_t index) : base_list_iterator<T>(nodes, index) {}
};

template<class T> class reverse_list_iterator : public base_reverse_list_iterator<T> {
public:	
	friend class list<T>;
	
	reverse_list_iterator(const base_reverse_list_iterator<T> &it) : base_reverse_list_iterator<T>(it) {}
	
	T &operator*() const {
		return (*nodes_)[index_].value;
	}
	T *operator->() const {
		return &(*nodes_)[index_].value;
	}
	reverse_list_iterator &operator=(const reverse_list_iterator &other) {
		base_reverse_list_iterator::operator=(other);
		return *this;
	}

protected:
	reverse_list_iterator(const vector<list_node<T> > *nodes, size_t index) : base_reverse_list_iterator<T>(nodes, index) {}
};

template<class T> class const_reverse_list_iterator : public base_reverse_list_iterator<T> {
public:
	friend class list<T>;

	const_reverse_list_iterator(const base_reverse_list_iterator<T> &it) : base_reverse_list_iterator<T>(it) {}
	const_reverse_list_iterator(const reverse_list_iterator<T> &it) : base_reverse_list_iterator<T>(it) {}

	const T &operator*() const {
		return (*nodes_)[index_].value;
	}
	const T *operator->() const {
		return &(*nodes_)[index_].value;
	}
	const_reverse_list_iterator &operator=(const const_reverse_list_iterator &other) {
		base_reverse_list_iterator::operator=(other);
		return *this;
	}
	
protected:
	const_reverse_list_iterator(const vector<list_node<T> > *nodes, size_t index) : base_reverse_list_iterator<T>(nodes, index) {}
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
template<class T> class list {
public:
	list() : head_(list_kTerminalNode), tail_(list_kTerminalNode), size_(0) {}
	list(size_t count, const T &value = T()) : head_(list_kTerminalNode), tail_(list_kTerminalNode), size_(0) {
		nodes_.resize(count, list_node<T>(value));
		vector<list_node<T> >::iterator it = nodes_.begin();
		for (size_t i = 0; i < nodes_.size(); ++i, ++it) {
			it->prev = i - 1;	// Assumes list_kTerminalNode == -1.
			it->next = i + 1;
		}
		nodes_.rbegin()->next = list_kTerminalNode;
	}
	
	size_t size() const { return size_; }
	bool empty() const { return size_ == 0; }
	
	T &front() const { return nodes_[head_].value; }
	T &back() const { return nodes_[tail_].value; }
	
	typedef list_iterator<T> iterator;
	
	iterator begin() const { return iterator(&nodes_, head_); }
	iterator end() const { return iterator(&nodes_, list_kTerminalNode); }

	typedef const_list_iterator<T> const_iterator;
	
	const_iterator cbegin() const { return const_iterator(begin()); }
	const_iterator cend() const { return const_iterator(end()); }

	typedef reverse_list_iterator<T> reverse_iterator;
	
	reverse_iterator rbegin() const { return reverse_iterator(&nodes_, tail_); }
	reverse_iterator rend() const { return reverse_iterator(&nodes_, list_kTerminalNode); }

	typedef const_reverse_list_iterator<T> const_reverse_iterator;

	const_reverse_iterator crbegin() const { return const_reverse_iterator(rbegin()); }
	const_reverse_iterator crend() const { return const_reverse_iterator(rend()); }

	iterator insert(iterator position, const T &value) {
		nodes_.push_back(value);
		size_t new_index = nodes_.size() - 1;
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
			tail_ = new_index;
		}
		nodes_[new_index].prev = new_prev;
		nodes_[new_index].next = position.index_;		
		++size_;
		return iterator(&nodes_, new_index);
	}
	
	void erase(iterator position) {
		if (position.index_ == list_kTerminalNode) {
			return;
		}
		size_t prev_index = nodes_[position.index_].prev;
		size_t next_index = nodes_[position.index_].next;
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
		--size_;
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