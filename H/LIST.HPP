#ifndef __LIST_HPP_INCLUDED__
#define __LIST_HPP_INCLUDED__

#include "list.h"

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

#endif