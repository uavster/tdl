;�����������������������������������������������������������������������������
; Computes the integral image of a SLI
;
; It allocates a buffer for the integral image and stores it in the SLI, if it
; had not been allocated already.
;
; Input:	EAX -> Input SLI
; Throws: 
;   Input SLI is not 8bpp
;�����������������������������������������������������������������������������
global CreateIntegralImage: NEAR

;�����������������������������������������������������������������������������
; Applies a box filter of the given size on the SLI contents
;
; The integral image must have been generated first for the SLI contents
; with CreateIntegralImage. The time complexity only depends on the image 
; dimensions, and it does not depend on the filter size.
;
; Input and output SLIs must be the same size.
;
; Input:	EAX -> Input SLI (CreateIntegralImage must have been called first)
;			EBX = Kernel width (rounded up to odd number)
;     ECX = Kernel height (rounded up to odd number)
;			EDI -> Output SLI
; Throws: 
;   Input SLI does not have an integral image
;�����������������������������������������������������������������������������
global BoxFilter: NEAR