;�����������������������������������������������������������������������������
; Computes the integral image of an 8 bpp SLI
;
; It allocates a buffer for the integral image and stores it in the SLI, if it
; had not been allocated already.
;
; Input:	EAX -> Input SLI
;         EBX = Multiplier
; Asserts: 
;   Input SLI is 8 bpp
;�����������������������������������������������������������������������������
global CreateIntegralImage: NEAR

;�����������������������������������������������������������������������������
; Computes the integral image of an 32 bpp SLI
;
; It allocates a buffer for the integral image and stores it in the SLI, if it
; had not been allocated already.
;
; Input:	EAX -> Input SLI
;         EBX = Multiplier
; Asserts: 
;   Input SLI is 32 bpp
;�����������������������������������������������������������������������������
global CreateIntegralImage32: NEAR

;�����������������������������������������������������������������������������
; For each pixel, computes the integral in a neighborhood and scales it with
; a divider
;
; The integral image must have been generated first for the SLI contents
; with CreateIntegralImage. The time complexity does not depend on the kernel
; size, only on the image dimensions. 
;
; Input and output SLIs must be the same size.
;
; Input:	EAX -> Input SLI (CreateIntegralImage must have been called first)
;			EBX = Kernel width (rounded up to odd number)
;     ECX = Kernel height (rounded up to odd number)
;     EDX = log2 of divider; the result for each pixel is divided by this value
;			EDI -> Output SLI
; Throws: 
;   Input SLI does not have an integral image
;�����������������������������������������������������������������������������
global ScaledBoxIntegral: NEAR

;�����������������������������������������������������������������������������
; Applies a box filter of the given size on the SLI contents
;
; Input and output SLIs must be the same size.
;
; The time complexity does not depend on the kernel size, only on the image
; dimensions. 
;
; There's no need to create the integral image before calling this function.
; It will be created internally if needed.
;
; Input:	EAX -> Input SLI
;			EBX = Kernel width (rounded up to odd number)
;     ECX = Kernel height (rounded up to odd number)
;			EDI -> Output SLI
;�����������������������������������������������������������������������������
global BoxFilter: NEAR
