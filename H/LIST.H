#ifndef __LIST_INCLUDED__
#define __LIST_INCLUDED__

#ifdef __cplusplus
  extern "C" {
#endif

#define kListEnd -1

typedef void * HList;

HList *NewList();
#pragma aux NewList "*" modify [eax ebx ecx edx esi edi ebp]\
						value [ebx];

int DeleteList(HList list);
#pragma aux DeleteList "*"	parm [eax]\
							modify [eax ebx ecx edx esi edi ebp]\
							value [eax];

int AddElement(HList list, void *element, int at_index);
#pragma aux AddElement "*"	parm [eax] [ebx] [ecx]\
							modify [eax ebx ecx edx esi edi ebp]\
							value [eax];

int DeleteElement(HList list, void *element);
#pragma aux DeleteElement "*"	parm [eax] [ebx]\
								modify [eax ebx ecx edx esi edi ebp]\
								value [eax];

void *GetNextElement(HList list);
#pragma aux GetNextElement "*"	parm [eax]\
								modify [eax ebx ecx edx esi edi ebp]\
								value [ebx];

void ResetListPtr(HList list);
#pragma aux ResetListPtr "*"	parm [eax]\
								modify [eax ebx ecx edx esi edi ebp];

#ifdef __cplusplus
	};
#endif

#endif