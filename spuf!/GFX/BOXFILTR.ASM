;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Box filter
;
; The filter has arbitrary kernel size and constant cost. This is achieved 
; computing the integral image first, and the filter with four reads per pixel.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
jumps
.code

include stderror.inc
include assert.inc
include alloc.inc
include sli.inc
include boxfiltr.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Computes the integral image of a SLI
;
; It allocates a buffer for the integral image and stores it in the SLI, if it
; had not been allocated already.
;
; Input:	EAX -> Input SLI
; Output:	CF = 0, if ok
;				EAX = 0 (NO_ERROR)
;			CF = 1, if error
; 				EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CreateIntegralImage	proc
	; Only 8 bpp supported.
	mov		esi,eax
	mov		eax,[SLI ptr esi.SLIColorBits]
	AssertDword	eax,_eq,1

	cmp		[SLI ptr esi.SLIYSize],0
	jz		integral_image_done
	cmp		[SLI ptr esi.SLIXSize],0
	jz		integral_image_done

	cmp		[SLI ptr esi.SLIIntegralImage],0
	jnz		got_integral_image_buffer
			; Allocate a buffer in the SLI for the integral image
			mov		eax,[SLI ptr esi.SLIXSize]
			xor		edx,edx
			imul	[SLI ptr esi.SLIYSize]
			shl		eax,2
			mov		ecx,eax
			push	esi
			call	malloc
			pop		esi
			ErrorCode	MALLOC_ERROR
			mov		[SLI ptr esi.SLIIntegralImage],ebx
	got_integral_image_buffer:

	push	ebp
	
	mov		eax,esi
	call	GetCurrentFramePtr
	mov		ebp,eax
	mov		edx,[SLI ptr esi.SLIYSize]
	xor		eax,eax
	xor		ebx,ebx
	mov		edi,[SLI ptr esi.SLIIntegralImage]
		
	; First line.
	mov		ecx,[SLI ptr esi.SLIXSize]
	; ebp -> source image, edi -> integral image, edx = height, ecx = width
	add		ebp,ecx
	lea		edi,[edi+ecx*4]
	neg		ecx
	xor		eax,eax
	xor		ebx,ebx
	create_integral_image_x_loop_0:
			mov		bl,ds:[ebp+ecx]
			add		eax,ebx
			mov		[edi+ecx*4],eax
	inc		ecx
	jnz		create_integral_image_x_loop_0

	; Lines after first.
	mov		edx,[SLI ptr esi.SLIYSize]
	dec		edx
	jz		integral_image_done_pop
	xor		ebx,ebx
	create_integral_image_y_loop:			
			mov		ecx,[SLI ptr esi.SLIXSize]
			add		ebp,ecx
			lea		edi,[edi+ecx*4]
			neg		ecx
			lea		eax,[ecx*4]
			mov		dword ptr top_cell_offset-4,eax
			sub		eax,4
			mov		dword ptr top_left_cell_offset-4,eax
			; Set first element in the row as top element + first row pixel.
			xor		eax,eax
			mov		bl,[edi+ecx*8]
			add		eax,ebx
			mov		bl,ds:[ebp+ecx]
			add		eax,ebx
			mov		[edi+ecx*4],eax
			inc		ecx
			jz		create_integral_image_x_loop_done
			create_integral_image_x_loop:
					; Each element is previous element + top element - top_left element + current pixel.
					mov		bl,[edi+ecx*4-12345678h]
					top_left_cell_offset:
					sub		eax,ebx
					mov		bl,[edi+ecx*4-12345678h]
					top_cell_offset:
					add		eax,ebx
					mov		bl,ds:[ebp+ecx]
					add		eax,ebx
					mov		[edi+ecx*4],eax
			inc		ecx
			jnz		create_integral_image_x_loop
			create_integral_image_x_loop_done:
	dec		edx
	jnz		create_integral_image_y_loop
	
	integral_image_done_pop:
	pop		ebp
	
	integral_image_done:
	xor		eax,eax
	clc
	ret
CreateIntegralImage	endp

BoxFilter	proc
	ret
BoxFilter	endp

end