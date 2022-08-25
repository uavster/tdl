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
		index_ = nodes_[index_].next;
		return *this;
	}
	base_list_iterator operator++(int) {
		base_list_iterator it(&nodes_, index_);
		index_ = nodes_[index_].next;
		return it;
	}
	bool operator==(const base_list_iterator &it) const {
		return index_ == it.index_;
	}
	bool operator!=(const base_list_iterator &it) const {
		return index_ != it.index_;
	}

public:
	base_list_iterator(const vector<list_node<T> > *nodes, size_t index) : nodes_(*nodes), index_(index) {}
	const vector<list_node<T> > &nodes_;
	size_t index_;
};

template<class T> class list_iterator : public base_list_iterator<T> {
public:	
	friend class list<T>;
	
	T &operator*() const {
		return nodes_[index_].value;
	}
	T *operator->() const {
		return &nodes_[index_].value;
	}

protected:
	list_iterator(const vector<list_node<T> > *nodes, size_t index) : base_list_iterator<T>(nodes, index) {}
};

template<class T> class const_list_iterator : public base_list_iterator<T> {
public:
	friend class list<T>;

	const_list_iterator(const list_iterator<T> &it) : base_list_iterator<T>(it) {}

	const T &operator*() const {
		return nodes_[index_].value;
	}
	const T *operator->() const {
		return &nodes_[index_].value;
	}
	
protected:
	const_list_iterator(const vector<list_node<T> > *nodes, size_t index) : base_list_iterator<T>(nodes, index) {}
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
	
	void push_back(const T &value) {
		nodes_.push_back(value);
		if (tail_ != list_kTerminalNode) {
			nodes_[tail_].next = nodes_.size() - 1;
		}
		nodes_.back().prev = tail_;
		nodes_.back().next = list_kTerminalNode;
		tail_ = nodes_.size() - 1;
		if (head_ == list_kTerminalNode) {
			head_ = tail_;
		}
	}
	
	typedef list_iterator<T> iterator;
	
	iterator begin() const { return iterator(&nodes_, head_); }
	iterator end() const { return iterator(&nodes_, list_kTerminalNode); }

	typedef const_list_iterator<T> const_iterator;
	
	const_iterator cbegin() const { return const_iterator(begin()); }
	const_iterator cend() const { return const_iterator(end()); }
	
private:
	size_t head_;
	size_t tail_;
	size_t size_;
	vector<list_node<T> > nodes_;
};

#undef list_kTerminalNode

}	// namespace std

#endif