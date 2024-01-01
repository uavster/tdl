;�����������������������������������������������������������������������������
; Box filter
;
; The filter has arbitrary kernel size and constant cost. This is achieved 
; computing the integral image first, and the filter with four reads per pixel.
;�����������������������������������������������������������������������������

.386p
.model flat
jumps
.code

include stderror.inc
include assert.inc
include alloc.inc
include sli.inc
include boxfiltr.inc

;�����������������������������������������������������������������������������
; Creates a table in multiplication_table, where each element is index * multiplier
;
; Input:  EDX = Multiplier
;�����������������������������������������������������������������������������
_CreateMultiplicationTable proc
  xor   ecx,ecx
  xor   eax,eax
  create_multiplication_table:
      mov   [ecx*4+multiplication_table],eax
      add   eax,edx
  inc   cl
  jnz   create_multiplication_table
  ret
endp

;�����������������������������������������������������������������������������
; Sets up the integral image creation common to all SLI formats
;
; Input:  ESI -> Input SLI
;         EBX = Multiplier
; Output:
;   CF = 0 if success
;     ESI -> Input SLI
;     EDX = Multiplier
;   CF = 1 if error
;�����������������������������������������������������������������������������
_SetUpIntegralImage proc
	cmp		[SLI ptr esi.SLIYSize],0
	jz		skip_integral_image_creation
	cmp		[SLI ptr esi.SLIXSize],0
	jz		skip_integral_image_creation

	cmp		[SLI ptr esi.SLIIntegralImage],0
	jz		no_integral_image_buffer
  ; If the integral image has the requested multiplier, leave.
  cmp   ebx,[SLI ptr esi.SLIIntegralImageMultiplier]
  je    skip_integral_image_creation
  ; Otherwise, compute integral image with new multiplier.
  mov   edx,ebx   ; Multiplier is in EDX from here on.
  jmp   got_integral_image_buffer
  no_integral_image_buffer:
			; Allocate a buffer in the SLI for the integral image.
			mov		ecx,[SLI ptr esi.SLIXSize]
			imul	ecx,[SLI ptr esi.SLIYSize]
			imul  ecx,[SLI ptr esi.SLIColorBits]
      shl   ecx,2
			push	esi ebx
			call	malloc
			pop		edx esi   ; Multiplier is in EDX from here on.
			ErrorCode	MALLOC_ERROR
			mov		[SLI ptr esi.SLIIntegralImage],ebx
	got_integral_image_buffer:
  ; Update multiplier.
  mov   [SLI ptr esi.SLIIntegralImageMultiplier],edx
  clc
  ret

  skip_integral_image_creation:
  stc
  ret
endp

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
_CreateIntegralImage8	proc
	; Only 8 bpp supported.
	mov		esi,eax
	mov		eax,[SLI ptr esi.SLIColorBits]
	AssertDword	eax,_eq,1

  call  _SetUpIntegralImage
  jc    integral_image_done
  ; ESI -> input SLI, EDX = Multiplier

  call  _CreateMultiplicationTable

	push	ebp

	mov		eax,esi
	call	GetCurrentFramePtr
	mov		ebp,eax
	mov		edx,[SLI ptr esi.SLIYSize]
	xor		eax,eax
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
			add		eax,[multiplication_table+4*ebx]
			mov		[edi+ecx*4],eax
	inc		ecx
	jnz		create_integral_image_x_loop_0

	; Lines after first.
	mov		edx,[SLI ptr esi.SLIYSize]
	dec		edx
	jz		integral_image_done_pop

  mov		ecx,[SLI ptr esi.SLIXSize]
  neg		ecx
  lea		eax,[ecx*4]
  mov		dword ptr top_cell_offset-4,eax
  sub		eax,4
  mov		dword ptr top_left_cell_offset-4,eax
	create_integral_image_y_loop:			
			mov		ecx,[SLI ptr esi.SLIXSize]
			add		ebp,ecx
			lea		edi,[edi+ecx*4]
			neg		ecx
			; Set first element in the row as top element + first row pixel.
      xor   ebx,ebx
			mov		eax,[edi+ecx*8]
			mov		bl,ds:[ebp+ecx]
			add		eax,[multiplication_table+4*ebx]
			mov		[edi+ecx*4],eax
			inc		ecx
			jz		create_integral_image_x_loop_done
			create_integral_image_x_loop:
					; Each element is previous element + top element - top_left element + current pixel.
					sub		eax,[edi+ecx*4-12345678h]
					top_left_cell_offset:
					add		eax,[edi+ecx*4-12345678h]
					top_cell_offset:
          xor   ebx,ebx
					mov		bl,ds:[ebp+ecx]
					add		eax,[multiplication_table+4*ebx]
					mov		[edi+ecx*4],eax
			inc		ecx
			jnz		create_integral_image_x_loop
			create_integral_image_x_loop_done:
	dec		edx
	jnz		create_integral_image_y_loop
	
	integral_image_done_pop:
	pop		ebp
	
	integral_image_done:
	ret
_CreateIntegralImage8	endp

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
_CreateIntegralImage32	proc
	; Only 32 bpp supported.
	mov		esi,eax
	mov		eax,[SLI ptr esi.SLIColorBits]
	AssertDword	eax,_eq,4

  call  _SetUpIntegralImage
  jc    integral_image_done
  ; ESI -> input SLI, EDX = Multiplier
  
  call  _CreateMultiplicationTable

	push	ebp

	mov		eax,esi
	call	GetCurrentFramePtr
	mov		ebp,eax
	mov		edx,[SLI ptr esi.SLIYSize]
	xor		eax,eax
	mov		edi,[SLI ptr esi.SLIIntegralImage]
		
	; First line.
	mov		ecx,[SLI ptr esi.SLIXSize]
  shl   ecx,2
	; ebp -> source image, edi -> integral image, edx = height, ecx = width
	lea		ebp,[ebp+ecx]
	lea		edi,[edi+ecx*4]
	neg		ecx
	xor		ebx,ebx
	xor		eax,eax ; r
  xor   edx,edx ; g
  push  esi
  xor   esi,esi ; b
	create_integral_image_x_loop_0_32:
      ; Red
			mov		bl,ds:[ebp+ecx]
			add		eax,[multiplication_table+4*ebx]
			mov		[edi+ecx*4],eax
      ; Green
			mov		bl,ds:[ebp+ecx+1]
			add		edx,[multiplication_table+4*ebx]
			mov		[edi+ecx*4+4],edx
      ; Blue
			mov		bl,ds:[ebp+ecx+2]
			add		esi,[multiplication_table+4*ebx]
			mov		[edi+ecx*4+8],esi
	add		ecx,4
	jnz		create_integral_image_x_loop_0_32
  pop   esi

	; Lines after first.
	mov		edx,[SLI ptr esi.SLIYSize]
	dec		edx
	jz		integral_image_done_pop32

  mov		eax,[SLI ptr esi.SLIXSize]
  inc   eax
  shl   eax,4
  neg   eax  
  mov		dword ptr top_left_cell_offset_r-4,eax
  add   eax,4
  mov		dword ptr top_left_cell_offset_g-4,eax
  add   eax,4
  mov		dword ptr top_left_cell_offset_b-4,eax
  add   eax,8
  mov		dword ptr top_cell_offset_r-4,eax
  add   eax,4
  mov		dword ptr top_cell_offset_g-4,eax
  add   eax,4
  mov		dword ptr top_cell_offset_b-4,eax
	create_integral_image_y_loop32:			
			mov		ecx,[SLI ptr esi.SLIXSize]
      shl   ecx,2
			lea		ebp,[ebp+ecx]
			lea		edi,[edi+ecx*4]
			neg		ecx
			; Set first element in the row as top element + first row pixel.
      xor   ebx,ebx
      ; Red
			mov		eax,[edi+ecx*8]
			mov		bl,ds:[ebp+ecx]
			add		eax,[multiplication_table+4*ebx]
			mov		[edi+ecx*4],eax
      ; Green
			mov		eax,[edi+ecx*8+4]
			mov		bl,ds:[ebp+ecx+1]
			add		eax,[multiplication_table+4*ebx]
			mov		[edi+ecx*4+4],eax
      ; Blue
			mov		eax,[edi+ecx*8+8]
			mov		bl,ds:[ebp+ecx+2]
			add		eax,[multiplication_table+4*ebx]
			mov		[edi+ecx*4+8],eax

			add		ecx,4
			jz		create_integral_image_x_loop_done32
			create_integral_image_x_loop32:
					; Each element is previous element + top element - top_left element + current pixel.
          ; Red
					mov		eax,[edi+ecx*4-16]
					sub		eax,[edi+ecx*4-12345678h]
					top_left_cell_offset_r:
					add		eax,[edi+ecx*4-12345678h]
					top_cell_offset_r:
          xor   ebx,ebx
					mov		bl,ds:[ebp+ecx]
					add		eax,[multiplication_table+4*ebx]
					mov		[edi+ecx*4],eax
          ; Green
					mov		eax,[edi+ecx*4-16+4]
					sub		eax,[edi+ecx*4-12345678h]
					top_left_cell_offset_g:
					add		eax,[edi+ecx*4-12345678h]
					top_cell_offset_g:
          xor   ebx,ebx
					mov		bl,ds:[ebp+ecx+1]
					add		eax,[multiplication_table+4*ebx]
					mov		[edi+ecx*4+4],eax
          ; Blue
					mov		eax,[edi+ecx*4-16+8]
					sub		eax,[edi+ecx*4-12345678h]
					top_left_cell_offset_b:
					add		eax,[edi+ecx*4-12345678h]
					top_cell_offset_b:
          xor   ebx,ebx
					mov		bl,ds:[ebp+ecx+2]
					add		eax,[multiplication_table+4*ebx]
					mov		[edi+ecx*4+8],eax
			add		ecx,4
			jnz		create_integral_image_x_loop32
			create_integral_image_x_loop_done32:
	dec		edx
	jnz		create_integral_image_y_loop32
	
	integral_image_done_pop32:
	pop		ebp
	ret
_CreateIntegralImage32	endp

;�����������������������������������������������������������������������������
; Computes the integral image of a SLI
;
; Supports 8 bpp and 32 bpp SLIs. It allocates a buffer for the integral image 
; and stores it in the SLI, if it had not been allocated already.
;
; Input:	EAX -> Input SLI
;         EBX = Multiplier
; Asserts: 
;   Input SLI is 8 bpp
;�����������������������������������������������������������������������������
CreateIntegralImage proc
  cmp [SLI ptr eax.SLIColorBits],1
  jne cii_not_8bpp
    call _CreateIntegralImage8
    ret
  cii_not_8bpp:
  cmp [SLI ptr eax.SLIColorBits],4
  jne cii_not_32bpp
    call _CreateIntegralImage32
    ret
  cii_not_32bpp:
  AssertDword 0, _eq, 1
CreateIntegralImage endp

output_width      equ 0
output_height     equ 1
output_pitch      equ 2
output_frame_ptr  equ 3
half_kernel_height_plus_one_by_output_pitch   equ 4
half_kernel_height_by_input_width equ 5
output_height_by_output_pitch equ 6
output_height_minus_half_kernel_height_minus_one_by_output_pitch equ 7
half_kernel_height_by_two_plus_one_by_input_width equ 8
input_height_minus_one_by_input_width equ 9
input_height_minus_half_kernel_height_by_two_minus_two_by_input_width equ 10
minus_half_width_minus_one equ 11
half_kernel_width_plus_one_by_two_minus_output_width equ 12
num_variables     equ 13

get macro reg, var_offset
mov   reg, ss:[ebp+4*var_offset]
endm

set macro var_offset, reg
mov   ss:[ebp+4*var_offset], reg
endm

add_ macro reg, var_offset
add   reg, ss:[ebp+4*var_offset]
endm

sub_ macro reg, var_offset
sub   reg, ss:[ebp+4*var_offset]
endm

imul_ macro reg, var_offset
imul  reg, ss:[ebp+4*var_offset]
endm

;�����������������������������������������������������������������������������
; Initializes the stack variables for the scaled box integral functions
;
; Input:	
;			EBX = Half kernel width
;     ECX = Half kernel height
;     ESI -> Input SLI
;			EDI -> Output SLI
;     EBP -> Stack frame
;�����������������������������������������������������������������������������
_InitScaledBoxIntegralVariables  proc
  mov   eax,[SLI ptr edi.SLIXSize]
  set   output_width,eax
  mov   eax,[SLI ptr edi.SLIYSize]
  set   output_height,eax
  mov   eax,[SLI ptr edi.SLIPitch]
  set   output_pitch,eax
  mov   eax,edi
  call  GetCurrentFramePtr
  set   output_frame_ptr,eax
  mov   eax,ecx
  inc   eax
  imul  eax,[SLI ptr edi.SLIPitch]
  set   half_kernel_height_plus_one_by_output_pitch,eax
  mov   eax,ecx
  imul  eax,[SLI ptr esi.SLIXSize]
  set   half_kernel_height_by_input_width,eax
  shl   eax,1
  add   eax,[SLI ptr esi.SLIXSize]
  set   half_kernel_height_by_two_plus_one_by_input_width,eax
  mov   eax,[SLI ptr edi.SLIYSize]
  imul  eax,[SLI ptr edi.SLIPitch]
  set   output_height_by_output_pitch,eax
  sub_  eax,half_kernel_height_plus_one_by_output_pitch
  set   output_height_minus_half_kernel_height_minus_one_by_output_pitch,eax
  mov   eax,[SLI ptr esi.SLIYSize]
  dec   eax
  imul  eax,[SLI ptr esi.SLIXSize]
  set   input_height_minus_one_by_input_width,eax
  lea   eax,[ecx*2+2]
  sub   eax,[SLI ptr esi.SLIYSize]
  neg   eax
  imul  eax,[SLI ptr esi.SLIXSize]
  set   input_height_minus_half_kernel_height_by_two_minus_two_by_input_width,eax
  mov   eax,ebx
  inc   eax
  neg   eax
  set   minus_half_width_minus_one,eax   
  lea   eax,[ebx*2+2]  
  sub_  eax,output_width
  set   half_kernel_width_plus_one_by_two_minus_output_width,eax
  ret
_InitScaledBoxIntegralVariables endp

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
; Asserts: 
;   Input SLI does not have an integral image
;�����������������������������������������������������������������������������
_ScaledBoxIntegral8	proc
  ; The input must have an integral image.
  AssertDword [eax.SLIIntegralImage], _ne, 0

  ; ebx = Half kernel width (rounded up to odd number).
  ; ecx = Half kernel height (rounded up to odd number).
  shr   ebx,1
  shr   ecx,1
  ; edi -> output SLI
  ; esi -> input SLI
  mov   esi,eax

  ; Update right shift opcodes with log2(divider).
  mov   byte ptr ds:[divider_top_left-1],dl
  mov   byte ptr ds:[divider_top_center-1],dl
  mov   byte ptr ds:[divider_top_right-1],dl
  mov   byte ptr ds:[divider_center_left-1],dl
  mov   byte ptr ds:[divider_center_center-1],dl
  mov   byte ptr ds:[divider_center_right-1],dl
  mov   byte ptr ds:[divider_bottom_left-1],dl
  mov   byte ptr ds:[divider_bottom_center-1],dl
  mov   byte ptr ds:[divider_bottom_right-1],dl

  ; Make space for stack variables.
  push  ebp
  sub   esp,num_variables*4
  mov   ebp,esp

  call  _InitScaledBoxIntegralVariables

  ; ---- Modify code for pointers of top band ----

  ; Self-modify the top-left corner address of the destination image.
  ; The row loop counter is: [-(half_kernel_height + 1) * output_image_pitch * sizeof(uint8_t):output_image_pitch * sizeof(uint8_t):0)
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint8_t):sizeof(uint8_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint8_t) * (half_kernel_width + 1 + output_image_pitch * (half_kernel_height + 1))
  get   edx,half_kernel_height_plus_one_by_output_pitch
  add   edx,ebx
  inc   edx
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_top_left-4],edx

  ; Self-modify the top-left corner address of the integral image.
  ; The point at (j, i) gets the integral in [(0, 0), (half_kernel_height + j, half_kernel_width + i)]
  ; The row loop counter is: [0:input_image_width * sizeof(uint32_t):half_kernel_height * input_image_width * sizeof(uint32_t))
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint32_t):sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset = integral_image.data + sizeof(uint32_t) * ((half_kernel_width + 1) + half_kernel_width + input_image_width * half_kernel_height)
  get   edx,half_kernel_height_by_input_width
  add   edx,ebx
  add   edx,ebx
  inc   edx
  shl   edx,2
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_top_left-4],edx

  ; Self-modify the top-center address of the destination image.
  ; The row loop counter is: [-(half_kernel_height + 1) * output_image_pitch * sizeof(uint8_t):output_image_pitch * sizeof(uint8_t):0)
  ; The column loop counter is: [sizeof(uint8_t)*(-output_image_width + 2*(half_kernel_width + 1)):sizeof(uint8_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint8_t) * (output_image_width - (half_kernel_width + 1) + (half_kernel_height + 1) * output_image_pitch)
  get   edx,half_kernel_height_plus_one_by_output_pitch
  add   edx,[SLI ptr edi.SLIXSize]
  sub   edx,ebx
  dec   edx
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_top_center-4],edx

  ; Self-modify the top-center corner addresses of the integral image.
  ; The point at (j, i) gets the integral in [(0, i - half_kernel_width), (half_kernel_height + j, i + half_kernel_width)]
  ; The row loop counter is: [0:input_image_width * sizeof(uint32_t):half_kernel_height * input_image_width * sizeof(uint32_t))
  ; The column loop counter is: [sizeof(uint8_t)*(-output_image_width + 2*(half_kernel_width + 1)):sizeof(uint8_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_l = integral_image.data + sizeof(uint32_t) * (output_image_width - 2*(half_kernel_width + 1) + half_kernel_height * integral_image_width)
  ; integral_image_offset_r = integral_image.data + sizeof(uint32_t) * (output_image_width - 1 + half_kernel_height * integral_image_width)
	mov		eax,[SLI ptr esi.SLIIntegralImage]
  get   edx,half_kernel_height_by_input_width
  add   edx,[SLI ptr edi.SLIXSize]
  push  edx
  dec   edx
  shl   edx,2
  add   edx,eax
  mov   dword ptr ds:[integral_image_top_center_r-4],edx
  pop   edx
  sub   edx,ebx
  sub   edx,ebx
  sub   edx,2
  shl   edx,2
  add   edx,eax
  mov   dword ptr ds:[integral_image_top_center_l-4],edx

  ; Self-modify the top-right corner address of the destination image.
  ; The row loop counter is: [-(half_kernel_height + 1) * output_image_pitch * sizeof(uint8_t):output_image_pitch * sizeof(uint8_t):0)
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint8_t):sizeof(uint8_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint8_t) * (output_image_width + (half_kernel_height + 1) * output_image_pitch)
  get   edx,half_kernel_height_plus_one_by_output_pitch
  add   edx,[SLI ptr edi.SLIXSize]
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_top_right-4],edx

  ; Self-modify the top-right corner address of the integral image.
  ; The point at (j, i) gets the integral in [(0, input_image_width - half_kernel_width + i), (half_kernel_height + j, input_image_width)]
  ; The row loop counter is: [0:input_image_width * sizeof(uint32_t):half_kernel_height * input_image_width * sizeof(uint32_t)]
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint32_t):sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_l = integral_image.data + sizeof(uint32_t) * (integral_image_width - 1 - half_kernel_width + integral_image_width * half_kernel_height)
  ; The right offset is not incremented by the column loop, so:
  ; integral_image_offset_r = integral_image.data + sizeof(uint32_t) * (integral_image_width - 1 + integral_image_width * half_kernel_height)
	mov		eax,[SLI ptr esi.SLIIntegralImage]
  get   edx,half_kernel_height_by_input_width
  add   edx,[SLI ptr esi.SLIXSize]
  dec   edx
  push  edx
  shl   edx,2
  add   edx,eax
  mov   dword ptr ds:[integral_image_top_right_r-4],edx
  pop   edx
  sub   edx,ebx
  shl   edx,2
  add   edx,eax
  mov   dword ptr ds:[integral_image_top_right_l-4],edx

  ; ---- Modify code for pointers of central band ----

  ; Self-modify the center-left side address of the destination image.
  ; The row loop counter is: [(-output_image_height + 2*(half_kernel_height + 1)) * output_image_pitch * sizeof(uint8_t):output_image_pitch * sizeof(uint8_t):0)
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint8_t):sizeof(uint8_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint8_t) * (half_kernel_width + 1 + output_image_pitch * (output_image_height - half_kernel_height - 1))
  get   edx,output_height_minus_half_kernel_height_minus_one_by_output_pitch
  add   edx,ebx
  inc   edx
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_center_left-4],edx

  ; Self-modify the center-left side address of the integral image.
  ; The point at (j, i) gets the integral in [(j - half_kernel_height, 0), (j + half_kernel_height, i + half_kernel_width)]
  ; The row loop counter is: [0:input_image_width * sizeof(uint32_t):(output_image_height - 2*hald_kernel_height) * input_image_width * sizeof(uint32_t))
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint32_t):sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_t = integral_image.data + sizeof(uint32_t) * ((half_kernel_width + 1) + half_kernel_width)
  ; integral_image_offset_b = integral_image.data + sizeof(uint32_t) * ((half_kernel_width + 1) + half_kernel_width + input_image_width * (2*half_kernel_height + 1))
  lea   edx,[ebx*2 + 1]
  shl   edx,2
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_center_left_t-4],edx
  lea   edx,[ebx*2 + 1]
  add_  edx,half_kernel_height_by_two_plus_one_by_input_width
  shl   edx,2
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_center_left_b-4],edx
  
  ; Self-modify the center-center address of the destination image.
  ; The row loop counter is: [(-output_image_height + 2*(half_kernel_height + 1)) * output_image_pitch * sizeof(uint32_t):output_image_pitch * sizeof(uint32_t):0)
  ; The column loop counter is: [sizeof(uint8_t)*(-output_image_width + 2*(half_kernel_width + 1)):sizeof(uint8_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint8_t) * (output_image_width - (half_kernel_width + 1) + output_image_pitch * (output_image_height - half_kernel_height - 1))
  get   edx,output_height_minus_half_kernel_height_minus_one_by_output_pitch
  add   edx,[SLI ptr edi.SLIXSize]
  sub   edx,ebx
  dec   edx
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_center_center-4],edx

  ; Self-modify the center-center corner addresses of the integral image.
  ; The point at (j, i) gets the integral in [(j - half_kernel_height, i - half_kernel_width), (j + half_kernel_height, i + half_kernel_width)]
  ; The row loop counter is: [0:input_image_width * sizeof(uint32_t):(output_image_height - 2*hald_kernel_height) * input_image_width * sizeof(uint32_t))
  ; The column loop counter is: [sizeof(uint32_t)*(-output_image_width + 2*(half_kernel_width + 1)):sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_tl = integral_image.data + sizeof(uint32_t) * (output_image_width - 2*(half_kernel_width + 1))
  ; integral_image_offset_tr = integral_image.data + sizeof(uint32_t) * (output_image_width - 1)
  ; integral_image_offset_bl = integral_image.data + sizeof(uint32_t) * (output_image_width - 2*(half_kernel_width + 1) + input_image_width * (2*half_kernel_height + 1)
  ; integral_image_offset_br = integral_image.data + sizeof(uint32_t) * (output_image_width - 1 + input_image_width * (2*half_kernel_height + 1)
	mov		eax,[SLI ptr esi.SLIIntegralImage]
  mov   edx,[SLI ptr edi.SLIXSize]
  sub   edx,ebx
  sub   edx,ebx
  sub   edx,2
  shl   edx,2
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_center_tl-4],edx
  mov   edx,[SLI ptr edi.SLIXSize]
  dec   edx
  shl   edx,2
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_center_tr-4],edx
  get   edx,half_kernel_height_by_two_plus_one_by_input_width
  sub   edx,ebx
  sub   edx,ebx
  sub   edx,2
  add   edx,[SLI ptr edi.SLIXSize]
  shl   edx,2
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_center_bl-4],edx
  get   edx,half_kernel_height_by_two_plus_one_by_input_width
  add   edx,[SLI ptr edi.SLIXSize]
  dec   edx
  shl   edx,2
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_center_br-4],edx

  ; Self-modify the center-right address of the destination image.
  ; The row loop counter is: [(-output_image_height + 2*(half_kernel_height + 1)) * output_image_pitch * sizeof(uint32_t):output_image_pitch * sizeof(uint32_t):0)
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint8_t):sizeof(uint8_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint8_t) * (output_image_width + output_image_pitch * (output_image_height - half_kernel_height - 1))
  get   edx,output_height_minus_half_kernel_height_minus_one_by_output_pitch
  add   edx,[SLI ptr edi.SLIXSize]
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_center_right-4],edx

  ; Self-modify the center-right corner addresses of the integral image.
  ; The point at (j, i) gets the integral in [(j - half_kernel_height, i - half_kernel_width), (j + half_kernel_height, input_image_width)]
  ; The row loop counter is: [0:input_image_width * sizeof(uint32_t):(output_image_height - 2*hald_kernel_height) * input_image_width * sizeof(uint32_t))
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint32_t):sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_tl = integral_image.data + sizeof(uint32_t) * (integral_image_width - (half_kernel_width + 1))
  ; integral_image_offset_bl = integral_image.data + sizeof(uint32_t) * (integral_image_width - (half_kernel_width + 1) + integral_image_width * (2*half_kernel_height + 1)
  ; The right offsets are not incremented in the column loop, so:
  ; integral_image_offset_tr = integral_image.data + sizeof(uint32_t) * (integral_image_width - 1)
  ; integral_image_offset_br = integral_image.data + sizeof(uint32_t) * (integral_image_width - 1 + integral_image_width * (2*half_kernel_height + 1))
	mov		eax,[SLI ptr esi.SLIIntegralImage]
  mov   edx,[SLI ptr esi.SLIXSize]
  sub   edx,ebx
  dec   edx
  shl   edx,2
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_right_tl-4],edx
  mov   edx,[SLI ptr edi.SLIXSize]
  dec   edx
  shl   edx,2
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_right_tr-4],edx
  get   edx,half_kernel_height_by_two_plus_one_by_input_width
  add   edx,[SLI ptr esi.SLIXSize]
  sub   edx,ebx
  dec   edx
  shl   edx,2
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_right_bl-4],edx
  get   edx,half_kernel_height_by_two_plus_one_by_input_width
  add   edx,[SLI ptr esi.SLIXSize]
  dec   edx
  shl   edx,2
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_right_br-4],edx

  ; ---- Modify code for pointers of bottom band ----

  ; Self-modify the bottom-left side address of the destination image.
  ; The row loop counter is: [-(half_kernel_height + 1)  * output_image_pitch * sizeof(uint8_t):output_image_pitch * sizeof(uint8_t):0)
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint8_t):sizeof(uint8_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint8_t) * (half_kernel_width + 1 + output_image_pitch * output_image_height)
  get   edx,output_height_by_output_pitch
  add   edx,ebx
  inc   edx
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_bottom_left-4],edx

  ; Self-modify the bottom-left side address of the integral image.
  ; The point at (j, i) gets the integral in [(j - half_kernel_height, 0), (integral_image_height - 1, i + half_kernel_width)]
  ; The row loop counter is: [0:input_image_width * sizeof(uint32_t):(half_kernel_height + 1) * input_image_width * sizeof(uint32_t))
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint32_t):sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_tr = integral_image.data + sizeof(uint32_t) * ((half_kernel_width + 1) + half_kernel_width + input_image_width * (integral_image_height - 1 - (2*half_kernel_height + 1))
  ; The right offsets are not incremented in the row loop, so:
  ; integral_image_offset_br = integral_image.data + sizeof(uint32_t) * ((half_kernel_width + 1) + half_kernel_width + input_image_width * (integral_image_height - 1)
  mov   eax,[SLI ptr esi.SLIIntegralImage]
  get   edx,input_height_minus_half_kernel_height_by_two_minus_two_by_input_width
  add   edx,ebx
  add   edx,ebx
  inc   edx
  shl   edx,2
  add   edx,eax
  mov   dword ptr ds:[integral_image_bottom_left_tr-4],edx
  get   edx,input_height_minus_one_by_input_width
  add   edx,ebx
  add   edx,ebx
  inc   edx
  shl   edx,2
  add   edx,eax
  mov   dword ptr ds:[integral_image_bottom_left_br-4],edx

  ; Self-modify the bottom-center address of the destination image.
  ; The row loop counter is: [-(half_kernel_height + 1) * output_image_pitch * sizeof(uint8_t):output_image_pitch * sizeof(uint8_t):0)
  ; The column loop counter is: [sizeof(uint8_t)*(-output_image_width + 2*(half_kernel_width + 1)):sizeof(uint8_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint8_t) * (output_image_width - (half_kernel_width + 1) + output_image_pitch * output_image_height)
  get   edx,output_height_by_output_pitch
  add   edx,[SLI ptr edi.SLIXSize]
  sub   edx,ebx
  dec   edx
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_bottom_center-4],edx

  ; Self-modify the bottom-center corner addresses of the integral image.
  ; The point at (j, i) gets the integral in [(j - half_kernel_height, i - half_kernel_width), (integral_image_height - 1, i + half_kernel_width)]
  ; The row loop counter is: [0:input_image_width * sizeof(uint32_t):(half_kernel_height + 1) * input_image_width * sizeof(uint32_t))
  ; The column loop counter is: [sizeof(uint32_t)*(-output_image_width + 2*(half_kernel_width + 1)):sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_tl = integral_image.data + sizeof(uint32_t) * (output_image_width - 2*(half_kernel_width + 1) + input_image_width * (integral_image_height - 1 - (2*half_kernel_height + 1))))
  ; integral_image_offset_tr = integral_image.data + sizeof(uint32_t) * (output_image_width - 1 + input_image_width * (integral_image_height - 1 - (2*half_kernel_height + 1))))
  ; The bottom offsets are not incremented in the row loop, so:
  ; integral_image_offset_bl = integral_image.data + sizeof(uint32_t) * (output_image_width - 2*(half_kernel_width + 1) + input_image_width * (integral_image_height - 1)
  ; integral_image_offset_br = integral_image.data + sizeof(uint32_t) * (output_image_width - 1 + input_image_width * (integral_image_height - 1)
  get   edx,input_height_minus_half_kernel_height_by_two_minus_two_by_input_width
  add   edx,[SLI ptr edi.SLIXSize]
  push  edx
  lea   eax,[ebx*2 + 2]
  sub   edx,eax
  shl   edx,2
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_center_tl-4],edx
  pop   edx
  dec   edx
  shl   edx,2
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_center_tr-4],edx
  get   edx,input_height_minus_one_by_input_width
  add   edx,[SLI ptr edi.SLIXSize]
  push  edx
  lea   eax,[2*ebx + 2]
  sub   edx,eax
  shl   edx,2
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_center_bl-4],edx
  pop   edx
  dec   edx
  shl   edx,2
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_center_br-4],edx

  ; Self-modify the bottom-right address of the destination image.
  ; The row loop counter is: [-(half_kernel_height + 1) * output_image_pitch * sizeof(uint8_t):output_image_pitch * sizeof(uint8_t):0)
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint8_t):sizeof(uint8_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint8_t) * (output_image_width + output_image_pitch * output_image_height)
  get   edx,output_height_by_output_pitch
  add   edx,[SLI ptr edi.SLIXSize]
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_bottom_right-4],edx

  ; Self-modify the bottom-right corner addresses of the integral image.
  ; The point at (j, i) gets the integral in [(j - half_kernel_height, i - half_kernel_width), (input_image_height - 1, input_image_width - 1)]
  ; The row loop counter is: [0:input_image_width * sizeof(uint32_t):(half_kernel_height + 1) * input_image_width * sizeof(uint32_t))
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint32_t):sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_tl = integral_image.data + sizeof(uint32_t) * (output_image_width - (half_kernel_width + 1) + input_image_width * (integral_image_height - 1 - (2*half_kernel_height + 1)))
  ; The top right offset is not incremented in the column loop, so:
  ; integral_image_offset_tr = integral_image.data + sizeof(uint32_t) * (output_image_width - 1 + input_image_width * (integral_image_height - 1 - (2*half_kernel_height + 1)))
  ; The bottom left offset is not incremented in the row loop, so:
  ; integral_image_offset_bl = integral_image.data + sizeof(uint32_t) * (output_image_width - (half_kernel_width + 1) + input_image_width * (integral_image_height - 1))
  ; The bottom right offset is not incremented in the row or column loops, so:
  ; integral_image_offset_br = integral_image.data + sizeof(uint32_t) * (output_image_width - 1 + input_image_width * (integral_image_height - 1))
  get   edx,input_height_minus_half_kernel_height_by_two_minus_two_by_input_width
  add   edx,[SLI ptr edi.SLIXSize]
  dec   edx
  push  edx
  sub   edx,ebx
  shl   edx,2
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_right_tl-4],edx
  pop   edx
  shl   edx,2
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_right_tr-4],edx
  get   edx,input_height_minus_one_by_input_width
  add   edx,[SLI ptr edi.SLIXSize]
  dec   edx
  push  edx
  sub   edx,ebx
  shl   edx,2
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_right_bl-4],edx
  pop   edx
  shl   edx,2
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_right_br-4],edx

  ; ---- Iterate over the three bands ----

  ; TODO: deal with image smaller than kernel in any dimension.

  ; Filter top pixels up to half the kernel height.
  ; edi: output image row offset
  get   edi,half_kernel_height_plus_one_by_output_pitch
  neg   edi
  ; ebx: integral image row offset
  xor   ebx,ebx
  filter_top_pixels:        
        ; edx: column offset
        get   edx,minus_half_width_minus_one
        filter_top_left_pixels:
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_top_left:
              shr   eax,5
              divider_top_left:
              mov   [edi+edx+12345678h],al
              destination_top_left:
        inc   edx
        jnz   filter_top_left_pixels

        get   edx,half_kernel_width_plus_one_by_two_minus_output_width
        filter_top_central_pixels:
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_top_center_r:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_top_center_l:
              shr   eax,5
              divider_top_center:
              mov   [edi+edx+12345678h],al
              destination_top_center:
        inc   edx
        jnz   filter_top_central_pixels

        ; edx: column offset
        get   edx,minus_half_width_minus_one
        mov   ecx,[ebx+12345678h]
        integral_image_top_right_r:
        filter_top_right_pixels:
              mov   eax,ecx
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_top_right_l:
              shr   eax,5
              divider_top_right:
              mov   [edi+edx+12345678h],al
              destination_top_right:
        inc   edx
        jnz   filter_top_right_pixels

  mov   eax,[SLI ptr esi.SLIXSize]
  lea   ebx,[ebx+eax*4]
  add_  edi,output_pitch
  jnz   filter_top_pixels

  ; Filter central pixels below half the kernel height and above half the kernel height before the image bottom.
  ; edi: output image row offset
  get   edi,half_kernel_height_plus_one_by_output_pitch
  sub_  edi,output_height_minus_half_kernel_height_minus_one_by_output_pitch
  ; ebx: integral image row offset
  xor   ebx,ebx
  filter_center_pixels:        
        ; edx: column offset
        get   edx,minus_half_width_minus_one
        filter_center_left_pixels:
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_center_left_b:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_left_t:
              shr   eax,5
              divider_center_left:
              mov   [edi+edx+12345678h],al
              destination_center_left:
        inc   edx
        jnz   filter_center_left_pixels

        get   edx,half_kernel_width_plus_one_by_two_minus_output_width
        filter_center_central_pixels:
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_br:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_tr:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_bl:
              add   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_tl:
              shr   eax,5
              divider_center_center:
              mov   [edi+edx+12345678h],al
              destination_center_center:
        inc   edx
        jnz   filter_center_central_pixels

        ; edx: column offset
        get   edx,minus_half_width_minus_one
        mov   ecx,[ebx+12345678h]
        integral_image_center_right_br:
        sub   ecx,[ebx+12345678h]
        integral_image_center_right_tr:
        filter_center_right_pixels:
              mov   eax,ecx
              add   eax,[ebx+edx*4+12345678h]
              integral_image_center_right_tl:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_right_bl:
              shr   eax,5
              divider_center_right:
              mov   [edi+edx+12345678h],al
              destination_center_right:
        inc   edx
        jnz   filter_center_right_pixels
  
  mov   eax,[SLI ptr esi.SLIXSize]
  lea   ebx,[ebx+eax*4]
  add_  edi,output_pitch
  jnz   filter_center_pixels

  ; Filter bottom pixels, up to half kernel height above the bottom of the image.
  ; edi: output image row offset
  get   edi,half_kernel_height_plus_one_by_output_pitch
  neg   edi
  ; ebx: integral image row offset
  xor   ebx,ebx
  filter_bottom_pixels:        
        ; edx: column offset
        get   edx,minus_half_width_minus_one
        filter_bottom_left_pixels:
              mov   eax,[edx*4+12345678h]
              integral_image_bottom_left_br:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_left_tr:
              shr   eax,5
              divider_bottom_left:
              mov   [edi+edx+12345678h],al
              destination_bottom_left:
        inc   edx
        jnz   filter_bottom_left_pixels

        get   edx,half_kernel_width_plus_one_by_two_minus_output_width
        filter_bottom_central_pixels:
              mov   eax,[edx*4+12345678h]
              integral_image_bottom_center_br:
              sub   eax,[edx*4+12345678h]
              integral_image_bottom_center_bl:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_center_tr:
              add   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_center_tl:
              shr   eax,5
              divider_bottom_center:
              mov   [edi+edx+12345678h],al
              destination_bottom_center:
        inc   edx
        jnz   filter_bottom_central_pixels

        ; edx: column offset
        get   edx,minus_half_width_minus_one
        mov   ecx,ds:[12345678h]
        integral_image_bottom_right_br:
        sub   ecx,[ebx+12345678h]
        integral_image_bottom_right_tr:
        filter_bottom_right_pixels:
              mov   eax,ecx
              add   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_right_tl:
              sub   eax,[edx*4+12345678h]
              integral_image_bottom_right_bl:
              shr   eax,5
              divider_bottom_right:
              mov   [edi+edx+12345678h],al
              destination_bottom_right:
        inc   edx
        jnz   filter_bottom_right_pixels

  mov   eax,[SLI ptr esi.SLIXSize]
  lea   ebx,[ebx+eax*4]
  add_  edi,output_pitch
  jnz   filter_bottom_pixels

  ; Destroy stack frame.
  add   esp,num_variables*4
  pop   ebp

	ret
_ScaledBoxIntegral8	endp

;�����������������������������������������������������������������������������
; For each pixel, computes the integral in a neighborhood and scales it with
; a divider
;
; The integral image must have been generated first for the SLI contents
; with CreateIntegralImage32. The time complexity does not depend on the kernel
; size, only on the image dimensions. 
;
; Input and output SLIs must be the same size.
;
; Input:	EAX -> Input SLI (CreateIntegralImage32 must have been called first)
;			EBX = Kernel width (rounded up to odd number)
;     ECX = Kernel height (rounded up to odd number)
;     EDX = log2 of divider; the result for each pixel is divided by this value
;			EDI -> Output SLI
; Asserts: 
;   Input SLI does not have an integral image
;�����������������������������������������������������������������������������
_ScaledBoxIntegral32	proc
  ; The input must have an integral image.
  AssertDword [eax.SLIIntegralImage], _ne, 0

  ; ebx = Half kernel width (rounded up to odd number).
  ; ecx = Half kernel height (rounded up to odd number).
  shr   ebx,1
  shr   ecx,1
  ; edi -> output SLI
  ; esi -> input SLI
  mov   esi,eax

  ; Update right shift opcodes with log2(divider).
  mov   byte ptr ds:[divider_top_left_r-1],dl
  mov   byte ptr ds:[divider_top_center_r-1],dl
  mov   byte ptr ds:[divider_top_right_r-1],dl
  mov   byte ptr ds:[divider_top_left_g-1],dl
  mov   byte ptr ds:[divider_top_center_g-1],dl
  mov   byte ptr ds:[divider_top_right_g-1],dl
  mov   byte ptr ds:[divider_top_left_b-1],dl
  mov   byte ptr ds:[divider_top_center_b-1],dl
  mov   byte ptr ds:[divider_top_right_b-1],dl

  mov   byte ptr ds:[divider_center_left_r-1],dl
  mov   byte ptr ds:[divider_center_left_g-1],dl
  mov   byte ptr ds:[divider_center_left_b-1],dl
  mov   byte ptr ds:[divider_center_center_r-1],dl
  mov   byte ptr ds:[divider_center_center_g-1],dl
  mov   byte ptr ds:[divider_center_center_b-1],dl
  mov   byte ptr ds:[divider_center_right_r-1],dl
  mov   byte ptr ds:[divider_center_right_g-1],dl
  mov   byte ptr ds:[divider_center_right_b-1],dl

  mov   byte ptr ds:[divider_bottom_left_r-1],dl
  mov   byte ptr ds:[divider_bottom_left_g-1],dl
  mov   byte ptr ds:[divider_bottom_left_b-1],dl
  mov   byte ptr ds:[divider_bottom_center_r-1],dl
  mov   byte ptr ds:[divider_bottom_center_g-1],dl
  mov   byte ptr ds:[divider_bottom_center_b-1],dl
  mov   byte ptr ds:[divider_bottom_right_r-1],dl
  mov   byte ptr ds:[divider_bottom_right_g-1],dl
  mov   byte ptr ds:[divider_bottom_right_b-1],dl

  ; Make space for stack variables.
  push  ebp
  sub   esp,num_variables*4
  mov   ebp,esp

  call  _InitScaledBoxIntegralVariables

  ; ---- Modify code for pointers of top band ----

  ; Self-modify the top-left corner address of the destination image.
  ; The row loop counter is: [-(half_kernel_height + 1) * output_image_pitch * sizeof(uint32_t):output_image_pitch * sizeof(uint32_t):0)
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint32_t):sizeof(uint32_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint32_t) * (half_kernel_width + 1) + output_image_pitch * (half_kernel_height + 1)
  get   edx,half_kernel_height_plus_one_by_output_pitch
  lea   edx,[edx+ebx*4+4]
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_top_left32-4],edx

  ; Self-modify the top-left corner address of the integral image.
  ; The point at (j, i) gets the integral in [(0, 0), (half_kernel_height + j, half_kernel_width + i)]
  ; The row loop counter is: [0:input_image_width * 4 * sizeof(uint32_t):half_kernel_height * input_image_width * 4 * sizeof(uint32_t))
  ; The column loop counter is: [-(half_kernel_width + 1) * 4 * sizeof(uint32_t):4 * sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset = integral_image.data + 4 * sizeof(uint32_t) * ((half_kernel_width + 1) + half_kernel_width + input_image_width * half_kernel_height)
  get   edx,half_kernel_height_by_input_width
  add   edx,ebx
  add   edx,ebx
  inc   edx
  shl   edx,4
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_top_left_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_top_left_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_top_left_b-4],edx

  ; Self-modify the top-center address of the destination image.
  ; The row loop counter is: [-(half_kernel_height + 1) * output_image_pitch * sizeof(uint32_t):output_image_pitch * sizeof(uint32_t):0)
  ; The column loop counter is: [sizeof(uint32_t)*(-output_image_width + 2*(half_kernel_width + 1)):sizeof(uint32_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint32_t) * (output_image_width - (half_kernel_width + 1)) + (half_kernel_height + 1) * output_image_pitch
  mov   edx,[SLI ptr edi.SLIXSize]
  sub   edx,ebx
  dec   edx
  shl   edx,2
  add_  edx,half_kernel_height_plus_one_by_output_pitch
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_top_center32-4],edx

  ; Self-modify the top-center addresses of the integral image.
  ; The point at (j, i) gets the integral in [(0, i - half_kernel_width), (half_kernel_height + j, i + half_kernel_width)]
  ; The row loop counter is: [0:input_image_width * 4 * sizeof(uint32_t):half_kernel_height * input_image_width * 4 * sizeof(uint32_t))
  ; The column loop counter is: [4 * sizeof(uint32_t)*(-output_image_width + 2*(half_kernel_width + 1)):4 * sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_l = integral_image.data + 4 * sizeof(uint32_t) * (output_image_width - 2*(half_kernel_width + 1) + half_kernel_height * integral_image_width)
  ; integral_image_offset_r = integral_image.data + 4 * sizeof(uint32_t) * (output_image_width - 1 + half_kernel_height * integral_image_width)
	mov		eax,[SLI ptr esi.SLIIntegralImage]
  get   edx,half_kernel_height_by_input_width
  add   edx,[SLI ptr edi.SLIXSize]
  push  edx
  dec   edx
  shl   edx,4
  add   edx,eax
  mov   dword ptr ds:[integral_image_top_center_r_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_top_center_r_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_top_center_r_b-4],edx
  pop   edx
  sub   edx,ebx
  sub   edx,ebx
  sub   edx,2
  shl   edx,4
  add   edx,eax
  mov   dword ptr ds:[integral_image_top_center_l_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_top_center_l_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_top_center_l_b-4],edx

  ; Self-modify the top-right corner address of the destination image.
  ; The row loop counter is: [-(half_kernel_height + 1) * output_image_pitch * sizeof(uint32_t):output_image_pitch * sizeof(uint32_t):0)
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint32_t):sizeof(uint32_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint32_t) * output_image_width + (half_kernel_height + 1) * output_image_pitch
  mov   edx,[SLI ptr edi.SLIXSize]
  shl   edx,2
  add_  edx,half_kernel_height_plus_one_by_output_pitch
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_top_right32-4],edx

  ; Self-modify the top-right corner address of the integral image.
  ; The point at (j, i) gets the integral in [(0, input_image_width - half_kernel_width + i), (half_kernel_height + j, input_image_width)]
  ; The row loop counter is: [0:input_image_width * 4 * sizeof(uint32_t):half_kernel_height * input_image_width * 4 * sizeof(uint32_t)]
  ; The column loop counter is: [-(half_kernel_width + 1) * 4 * sizeof(uint32_t):4 * sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_l = integral_image.data + 4 * sizeof(uint32_t) * (integral_image_width - 1 - half_kernel_width + integral_image_width * half_kernel_height)
  ; The right offset is not incremented by the column loop, so:
  ; integral_image_offset_r = integral_image.data + 4 * sizeof(uint32_t) * (integral_image_width - 1 + integral_image_width * half_kernel_height)
	mov		eax,[SLI ptr esi.SLIIntegralImage]
  get   edx,half_kernel_height_by_input_width
  add   edx,[SLI ptr esi.SLIXSize]
  dec   edx
  push  edx
  shl   edx,4
  add   edx,eax
  mov   dword ptr ds:[integral_image_top_right_r_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_top_right_r_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_top_right_r_b-4],edx
  pop   edx
  sub   edx,ebx
  shl   edx,4
  add   edx,eax
  mov   dword ptr ds:[integral_image_top_right_l_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_top_right_l_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_top_right_l_b-4],edx

  ; ---- Modify code for pointers of central band ----

  ; Self-modify the center-left side address of the destination image.
  ; The row loop counter is: [(-output_image_height + 2*(half_kernel_height + 1)) * output_image_pitch * sizeof(uint32_t):output_image_pitch * sizeof(uint32_t):0)
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint32_t):sizeof(uint32_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint32_t) * (half_kernel_width + 1) + output_image_pitch * (output_image_height - half_kernel_height - 1)
  lea   edx,[ebx*4+4]
  add_  edx,output_height_minus_half_kernel_height_minus_one_by_output_pitch
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_center_left32-4],edx

  ; Self-modify the center-left side address of the integral image.
  ; The point at (j, i) gets the integral in [(j - half_kernel_height, 0), (j + half_kernel_height, i + half_kernel_width)]
  ; The row loop counter is: [0:input_image_width * 4 * sizeof(uint32_t):(output_image_height - 2*hald_kernel_height) * input_image_width * 4 * sizeof(uint32_t))
  ; The column loop counter is: [-(half_kernel_width + 1) * 4 * sizeof(uint32_t):4 * sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_t = integral_image.data + 4 * sizeof(uint32_t) * ((half_kernel_width + 1) + half_kernel_width)
  ; integral_image_offset_b = integral_image.data + 4 * sizeof(uint32_t) * ((half_kernel_width + 1) + half_kernel_width + input_image_width * (2*half_kernel_height + 1))
  lea   edx,[ebx*2 + 1]
  shl   edx,4
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_center_left_t_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_left_t_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_left_t_b-4],edx
  lea   edx,[ebx*2 + 1]
  add_  edx,half_kernel_height_by_two_plus_one_by_input_width
  shl   edx,4
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_center_left_b_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_left_b_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_left_b_b-4],edx
  
  ; Self-modify the center-center address of the destination image.
  ; The row loop counter is: [(-output_image_height + 2*(half_kernel_height + 1)) * output_image_pitch * sizeof(uint32_t):output_image_pitch * sizeof(uint32_t):0)
  ; The column loop counter is: [sizeof(uint32_t)*(-output_image_width + 2*(half_kernel_width + 1)):sizeof(uint32_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint32_t) * (output_image_width - (half_kernel_width + 1)) + output_image_pitch * (output_image_height - half_kernel_height - 1)
  mov   edx,[SLI ptr edi.SLIXSize]
  sub   edx,ebx
  dec   edx
  shl   edx,2
  add_  edx,output_height_minus_half_kernel_height_minus_one_by_output_pitch
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_center_center32-4],edx

  ; Self-modify the center-center corner addresses of the integral image.
  ; The point at (j, i) gets the integral in [(j - half_kernel_height, i - half_kernel_width), (j + half_kernel_height, i + half_kernel_width)]
  ; The row loop counter is: [0:input_image_width * 4 * sizeof(uint32_t):(output_image_height - 2*hald_kernel_height) * input_image_width * 4 * sizeof(uint32_t))
  ; The column loop counter is: [4 * sizeof(uint32_t)*(-output_image_width + 2*(half_kernel_width + 1)):4 * sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_tl = integral_image.data + 4 * sizeof(uint32_t) * (output_image_width - 2*(half_kernel_width + 1))
  ; integral_image_offset_tr = integral_image.data + 4 * sizeof(uint32_t) * (output_image_width - 1)
  ; integral_image_offset_bl = integral_image.data + 4 * sizeof(uint32_t) * (output_image_width - 2*(half_kernel_width + 1) + input_image_width * (2*half_kernel_height + 1)
  ; integral_image_offset_br = integral_image.data + 4 * sizeof(uint32_t) * (output_image_width - 1 + input_image_width * (2*half_kernel_height + 1)
	mov		eax,[SLI ptr esi.SLIIntegralImage]
  mov   edx,[SLI ptr edi.SLIXSize]
  sub   edx,ebx
  sub   edx,ebx
  sub   edx,2
  shl   edx,4
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_center_tl_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_center_tl_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_center_tl_b-4],edx
  mov   edx,[SLI ptr edi.SLIXSize]
  dec   edx
  shl   edx,4
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_center_tr_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_center_tr_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_center_tr_b-4],edx
  get   edx,half_kernel_height_by_two_plus_one_by_input_width
  sub   edx,ebx
  sub   edx,ebx
  sub   edx,2
  add   edx,[SLI ptr edi.SLIXSize]
  shl   edx,4
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_center_bl_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_center_bl_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_center_bl_b-4],edx
  get   edx,half_kernel_height_by_two_plus_one_by_input_width
  add   edx,[SLI ptr edi.SLIXSize]
  dec   edx
  shl   edx,4
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_center_br_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_center_br_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_center_br_b-4],edx

  ; Self-modify the center-right address of the destination image.
  ; The row loop counter is: [(-output_image_height + 2*(half_kernel_height + 1)) * output_image_pitch * sizeof(uint32_t):output_image_pitch * sizeof(uint32_t):0)
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint32_t):sizeof(uint8_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint32_t) * output_image_width + output_image_pitch * (output_image_height - half_kernel_height - 1)
  mov   edx,[SLI ptr edi.SLIXSize]
  shl   edx,2
  add_  edx,output_height_minus_half_kernel_height_minus_one_by_output_pitch
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_center_right32-4],edx

  ; Self-modify the center-right corner addresses of the integral image.
  ; The point at (j, i) gets the integral in [(j - half_kernel_height, i - half_kernel_width), (j + half_kernel_height, input_image_width)]
  ; The row loop counter is: [0:input_image_width * 4 * sizeof(uint32_t):(output_image_height - 2*hald_kernel_height) * input_image_width * 4 * sizeof(uint32_t))
  ; The column loop counter is: [-(half_kernel_width + 1) * 4 * sizeof(uint32_t):4 * sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_tl = integral_image.data + 4 * sizeof(uint32_t) * (integral_image_width - (half_kernel_width + 1))
  ; integral_image_offset_bl = integral_image.data + 4 * sizeof(uint32_t) * (integral_image_width - (half_kernel_width + 1) + integral_image_width * (2*half_kernel_height + 1)
  ; The right offsets are not incremented in the column loop, so:
  ; integral_image_offset_tr = integral_image.data + 4 * sizeof(uint32_t) * (integral_image_width - 1)
  ; integral_image_offset_br = integral_image.data + 4 * sizeof(uint32_t) * (integral_image_width - 1 + integral_image_width * (2*half_kernel_height + 1))
	mov		eax,[SLI ptr esi.SLIIntegralImage]
  mov   edx,[SLI ptr esi.SLIXSize]
  sub   edx,ebx
  dec   edx
  shl   edx,4
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_right_tl_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_right_tl_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_right_tl_b-4],edx
  mov   edx,[SLI ptr edi.SLIXSize]
  dec   edx
  shl   edx,4
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_right_tr_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_right_tr_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_right_tr_b-4],edx
  get   edx,half_kernel_height_by_two_plus_one_by_input_width
  add   edx,[SLI ptr esi.SLIXSize]
  sub   edx,ebx
  dec   edx
  shl   edx,4
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_right_bl_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_right_bl_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_right_bl_b-4],edx
  get   edx,half_kernel_height_by_two_plus_one_by_input_width
  add   edx,[SLI ptr esi.SLIXSize]
  dec   edx
  shl   edx,4
  add   edx,eax
  mov   dword ptr ds:[integral_image_center_right_br_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_right_br_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_center_right_br_b-4],edx

  ; ---- Modify code for pointers of bottom band ----

  ; Self-modify the bottom-left side address of the destination image.
  ; The row loop counter is: [-(half_kernel_height + 1)  * output_image_pitch * sizeof(uint32_t):output_image_pitch * sizeof(uint32_t):0)
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint32_t):sizeof(uint32_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint32_t) * (half_kernel_width + 1) + output_image_pitch * output_image_height
  mov   edx,ebx
  inc   edx
  shl   edx,2
  add_  edx,output_height_by_output_pitch
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_bottom_left32-4],edx

  ; Self-modify the bottom-left side address of the integral image.
  ; The point at (j, i) gets the integral in [(j - half_kernel_height, 0), (integral_image_height - 1, i + half_kernel_width)]
  ; The row loop counter is: [0:input_image_width * 4 * sizeof(uint32_t):(half_kernel_height + 1) * input_image_width * 4 * sizeof(uint32_t))
  ; The column loop counter is: [-(half_kernel_width + 1) * 4 * sizeof(uint32_t):4 * sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_tr = integral_image.data + 4 * sizeof(uint32_t) * ((half_kernel_width + 1) + half_kernel_width + input_image_width * (integral_image_height - 1 - (2*half_kernel_height + 1))
  ; The right offsets are not incremented in the row loop, so:
  ; integral_image_offset_br = integral_image.data + 4 * sizeof(uint32_t) * ((half_kernel_width + 1) + half_kernel_width + input_image_width * (integral_image_height - 1)
  mov   eax,[SLI ptr esi.SLIIntegralImage]
  get   edx,input_height_minus_half_kernel_height_by_two_minus_two_by_input_width
  add   edx,ebx
  add   edx,ebx
  inc   edx
  shl   edx,4
  add   edx,eax
  mov   dword ptr ds:[integral_image_bottom_left_tr_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_left_tr_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_left_tr_b-4],edx
  get   edx,input_height_minus_one_by_input_width
  add   edx,ebx
  add   edx,ebx
  inc   edx
  shl   edx,4
  add   edx,eax
  mov   dword ptr ds:[integral_image_bottom_left_br_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_left_br_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_left_br_b-4],edx

  ; Self-modify the bottom-center address of the destination image.
  ; The row loop counter is: [-(half_kernel_height + 1) * output_image_pitch * sizeof(uint32_t):output_image_pitch * sizeof(uint32_t):0)
  ; The column loop counter is: [sizeof(uint32_t)*(-output_image_width + 2*(half_kernel_width + 1)):sizeof(uint32_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint32_t) * (output_image_width - (half_kernel_width + 1)) + output_image_pitch * output_image_height
  mov   edx,[SLI ptr edi.SLIXSize]
  sub   edx,ebx
  dec   edx
  shl   edx,2
  add_  edx,output_height_by_output_pitch
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_bottom_center32-4],edx

  ; Self-modify the bottom-center corner addresses of the integral image.
  ; The point at (j, i) gets the integral in [(j - half_kernel_height, i - half_kernel_width), (integral_image_height - 1, i + half_kernel_width)]
  ; The row loop counter is: [0:input_image_width * 4 * sizeof(uint32_t):(half_kernel_height + 1) * input_image_width * 4 * sizeof(uint32_t))
  ; The column loop counter is: [4 * sizeof(uint32_t)*(-output_image_width + 2*(half_kernel_width + 1)):4 * sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_tl = integral_image.data + 4 * sizeof(uint32_t) * (output_image_width - 2*(half_kernel_width + 1) + input_image_width * (integral_image_height - 1 - (2*half_kernel_height + 1))))
  ; integral_image_offset_tr = integral_image.data + 4 * sizeof(uint32_t) * (output_image_width - 1 + input_image_width * (integral_image_height - 1 - (2*half_kernel_height + 1))))
  ; The bottom offsets are not incremented in the row loop, so:
  ; integral_image_offset_bl = integral_image.data + 4 * sizeof(uint32_t) * (output_image_width - 2*(half_kernel_width + 1) + input_image_width * (integral_image_height - 1)
  ; integral_image_offset_br = integral_image.data + 4 * sizeof(uint32_t) * (output_image_width - 1 + input_image_width * (integral_image_height - 1)
  get   edx,input_height_minus_half_kernel_height_by_two_minus_two_by_input_width
  add   edx,[SLI ptr edi.SLIXSize]
  push  edx
  lea   eax,[ebx*2 + 2]
  sub   edx,eax
  shl   edx,4
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_center_tl_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_center_tl_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_center_tl_b-4],edx
  pop   edx
  dec   edx
  shl   edx,4
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_center_tr_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_center_tr_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_center_tr_b-4],edx
  get   edx,input_height_minus_one_by_input_width
  add   edx,[SLI ptr edi.SLIXSize]
  push  edx
  lea   eax,[2*ebx + 2]
  sub   edx,eax
  shl   edx,4
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_center_bl_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_center_bl_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_center_bl_b-4],edx
  pop   edx
  dec   edx
  shl   edx,4
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_center_br_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_center_br_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_center_br_b-4],edx

  ; Self-modify the bottom-right address of the destination image.
  ; The row loop counter is: [-(half_kernel_height + 1) * output_image_pitch * sizeof(uint32_t):output_image_pitch * sizeof(uint32_t):0)
  ; The column loop counter is: [-(half_kernel_width + 1) * sizeof(uint32_t):sizeof(uint32_t):0)
  ; So, the input image offset must be:
  ; input_image_offset = output_image.data + sizeof(uint32_t) * output_image_width + output_image_pitch * output_image_height
  mov   edx,[SLI ptr edi.SLIXSize]
  shl   edx,2
  add_  edx,output_height_by_output_pitch
  add_  edx,output_frame_ptr
  mov   dword ptr ds:[destination_bottom_right32-4],edx

  ; Self-modify the bottom-right corner addresses of the integral image.
  ; The point at (j, i) gets the integral in [(j - half_kernel_height, i - half_kernel_width), (input_image_height - 1, input_image_width - 1)]
  ; The row loop counter is: [0:input_image_width * 4 * sizeof(uint32_t):(half_kernel_height + 1) * input_image_width * 4 * sizeof(uint32_t))
  ; The column loop counter is: [-(half_kernel_width + 1) * 4 * sizeof(uint32_t):4 * sizeof(uint32_t):0)
  ; So, the integral image offset must be:
  ; integral_image_offset_tl = integral_image.data + 4 * sizeof(uint32_t) * (output_image_width - (half_kernel_width + 1) + input_image_width * (integral_image_height - 1 - (2*half_kernel_height + 1)))
  ; The top right offset is not incremented in the column loop, so:
  ; integral_image_offset_tr = integral_image.data + 4 * sizeof(uint32_t) * (output_image_width - 1 + input_image_width * (integral_image_height - 1 - (2*half_kernel_height + 1)))
  ; The bottom left offset is not incremented in the row loop, so:
  ; integral_image_offset_bl = integral_image.data + 4 * sizeof(uint32_t) * (output_image_width - (half_kernel_width + 1) + input_image_width * (integral_image_height - 1))
  ; The bottom right offset is not incremented in the row or column loops, so:
  ; integral_image_offset_br = integral_image.data + 4 * sizeof(uint32_t) * (output_image_width - 1 + input_image_width * (integral_image_height - 1))
  get   edx,input_height_minus_half_kernel_height_by_two_minus_two_by_input_width
  add   edx,[SLI ptr edi.SLIXSize]
  dec   edx
  push  edx
  sub   edx,ebx
  shl   edx,4
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_right_tl_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_right_tl_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_right_tl_b-4],edx
  pop   edx
  shl   edx,4
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_right_tr_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_right_tr_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_right_tr_b-4],edx
  get   edx,input_height_minus_one_by_input_width
  add   edx,[SLI ptr edi.SLIXSize]
  dec   edx
  push  edx
  sub   edx,ebx
  shl   edx,4
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_right_bl_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_right_bl_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_right_bl_b-4],edx
  pop   edx
  shl   edx,4
  add   edx,[SLI ptr esi.SLIIntegralImage]
  mov   dword ptr ds:[integral_image_bottom_right_br_r-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_right_br_g-4],edx
  add   edx,4
  mov   dword ptr ds:[integral_image_bottom_right_br_b-4],edx

  ; ---- Iterate over the three bands ----

  ; TODO: deal with image smaller than kernel in any dimension.

  ; Filter top pixels up to half the kernel height.
  ; edi: output image row offset
  get   edi,half_kernel_height_plus_one_by_output_pitch
  neg   edi
  ; ebx: integral image row offset
  xor   ebx,ebx
  filter_top_pixels32:        
        ; edx: column offset
        get   edx,minus_half_width_minus_one
        shl   edx,2
        filter_top_left_pixels32:
              ; Red
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_top_left_r:
              shr   eax,5
              divider_top_left_r:
              mov   ecx,eax
              ror   ecx,8

              ; Green
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_top_left_g:
              shr   eax,5
              divider_top_left_g:
              mov   cl,al
              ror   ecx,8

              ; Blue
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_top_left_b:
              shr   eax,5
              divider_top_left_b:
              mov   cl,al
              ror   ecx,8

              ; Alpha
              mov   cl,0ffh
              ror   ecx,8

              mov   [edi+edx+12345678h],ecx
              destination_top_left32:
        add   edx,4
        jnz   filter_top_left_pixels32

        get   edx,half_kernel_width_plus_one_by_two_minus_output_width
        shl   edx,2
        filter_top_central_pixels32:
              ; Red
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_top_center_r_r:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_top_center_l_r:
              shr   eax,5
              divider_top_center_r:
              mov   ecx,eax
              ror   ecx,8

              ; Green
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_top_center_r_g:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_top_center_l_g:
              shr   eax,5
              divider_top_center_g:
              mov   cl,al
              ror   ecx,8

              ; Blue
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_top_center_r_b:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_top_center_l_b:
              shr   eax,5
              divider_top_center_b:
              mov   cl,al
              ror   ecx,8

              ; Alpha
              mov   cl,0ffh
              ror   ecx,8

              mov   [edi+edx+12345678h],ecx
              destination_top_center32:
        add   edx,4
        jnz   filter_top_central_pixels32

        ; edx: column offset
        get   edx,minus_half_width_minus_one
        shl   edx,2
        filter_top_right_pixels32:
              ; Red
              mov   eax,[ebx+12345678h]
              integral_image_top_right_r_r:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_top_right_l_r:
              shr   eax,5
              divider_top_right_r:
              mov   ecx,eax
              ror   ecx,8

              ; Green
              mov   eax,[ebx+12345678h]
              integral_image_top_right_r_g:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_top_right_l_g:
              shr   eax,5
              divider_top_right_g:
              mov   cl,al
              ror   ecx,8

              ; Blue
              mov   eax,[ebx+12345678h]
              integral_image_top_right_r_b:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_top_right_l_b:
              shr   eax,5
              divider_top_right_b:
              mov   cl,al
              ror   ecx,8

              ; Alpha
              mov   cl,0ffh
              ror   ecx,8

              mov   [edi+edx+12345678h],ecx
              destination_top_right32:
        add   edx,4
        jnz   filter_top_right_pixels32

  mov   eax,[SLI ptr esi.SLIXSize]
  shl   eax,4
  lea   ebx,[ebx+eax]
  add_  edi,output_pitch
  jnz   filter_top_pixels32

  ; Filter central pixels below half the kernel height and above half the kernel height before the image bottom.
  ; edi: output image row offset
  get   edi,half_kernel_height_plus_one_by_output_pitch
  sub_  edi,output_height_minus_half_kernel_height_minus_one_by_output_pitch
  ; ebx: integral image row offset
  xor   ebx,ebx
  filter_center_pixels32:        
        ; edx: column offset
        get   edx,minus_half_width_minus_one
        shl   edx,2
        filter_center_left_pixels32:
              ; Red
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_center_left_b_r:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_left_t_r:
              shr   eax,5
              divider_center_left_r:
              mov   ecx,eax
              ror   ecx,8

              ; Green
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_center_left_b_g:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_left_t_g:
              shr   eax,5
              divider_center_left_g:
              mov   cl,al
              ror   ecx,8

              ; Blue
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_center_left_b_b:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_left_t_b:
              shr   eax,5
              divider_center_left_b:
              mov   cl,al
              ror   ecx,8

              ; Alpha
              mov   cl,0ffh
              ror   ecx,8

              mov   [edi+edx+12345678h],ecx
              destination_center_left32:
        add   edx,4
        jnz   filter_center_left_pixels32

        get   edx,half_kernel_width_plus_one_by_two_minus_output_width
        shl   edx,2
        filter_center_central_pixels32:
              ; Red
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_br_r:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_tr_r:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_bl_r:
              add   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_tl_r:
              shr   eax,5
              divider_center_center_r:
              mov   ecx,eax
              ror   ecx,8

              ; Green
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_br_g:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_tr_g:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_bl_g:
              add   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_tl_g:
              shr   eax,5
              divider_center_center_g:
              mov   cl,al
              ror   ecx,8

              ; Blue
              mov   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_br_b:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_tr_b:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_bl_b:
              add   eax,[ebx+edx*4+12345678h]
              integral_image_center_center_tl_b:
              shr   eax,5
              divider_center_center_b:
              mov   cl,al
              ror   ecx,8

              ; Alpha
              mov   cl,0ffh
              ror   ecx,8

              mov   [edi+edx+12345678h],ecx
              destination_center_center32:
        add   edx,4
        jnz   filter_center_central_pixels32

        ; edx: column offset
        get   edx,minus_half_width_minus_one
        shl   edx,2
        filter_center_right_pixels32:
              ; Red
              mov   eax,[ebx+12345678h]
              integral_image_center_right_br_r:
              sub   eax,[ebx+12345678h]
              integral_image_center_right_tr_r:
              add   eax,[ebx+edx*4+12345678h]
              integral_image_center_right_tl_r:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_right_bl_r:
              shr   eax,5
              divider_center_right_r:
              mov   ecx,eax
              ror   ecx,8

              ; Green
              mov   eax,[ebx+12345678h]
              integral_image_center_right_br_g:
              sub   eax,[ebx+12345678h]
              integral_image_center_right_tr_g:
              add   eax,[ebx+edx*4+12345678h]
              integral_image_center_right_tl_g:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_right_bl_g:
              shr   eax,5
              divider_center_right_g:
              mov   cl,al
              ror   ecx,8

              ; Blue
              mov   eax,[ebx+12345678h]
              integral_image_center_right_br_b:
              sub   eax,[ebx+12345678h]
              integral_image_center_right_tr_b:
              add   eax,[ebx+edx*4+12345678h]
              integral_image_center_right_tl_b:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_center_right_bl_b:
              shr   eax,5
              divider_center_right_b:
              mov   cl,al
              ror   ecx,8

              ; Alpha
              mov   cl,0ffh
              ror   ecx,8

              mov   [edi+edx+12345678h],ecx
              destination_center_right32:
        add   edx,4
        jnz   filter_center_right_pixels32
  
  mov   eax,[SLI ptr esi.SLIXSize]
  shl   eax,4
  lea   ebx,[ebx+eax]
  add_  edi,output_pitch
  jnz   filter_center_pixels32

  ; Filter bottom pixels, up to half kernel height above the bottom of the image.
  ; edi: output image row offset
  get   edi,half_kernel_height_plus_one_by_output_pitch
  neg   edi
  ; ebx: integral image row offset
  xor   ebx,ebx
  filter_bottom_pixels32:
        ; edx: column offset
        get   edx,minus_half_width_minus_one
        shl   edx,2
        filter_bottom_left_pixels32:
              ; Red
              mov   eax,[edx*4+12345678h]
              integral_image_bottom_left_br_r:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_left_tr_r:
              shr   eax,5
              divider_bottom_left_r:
              mov   ecx,eax
              ror   ecx,8

              ; Green
              mov   eax,[edx*4+12345678h]
              integral_image_bottom_left_br_g:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_left_tr_g:
              shr   eax,5
              divider_bottom_left_g:
              mov   cl,al
              ror   ecx,8

              ; Blue
              mov   eax,[edx*4+12345678h]
              integral_image_bottom_left_br_b:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_left_tr_b:
              shr   eax,5
              divider_bottom_left_b:
              mov   cl,al
              ror   ecx,8

              ; Alpha
              mov   cl,0ffh
              ror   ecx,8

              mov   [edi+edx+12345678h],ecx
              destination_bottom_left32:
        inc   edx
        jnz   filter_bottom_left_pixels32

        get   edx,half_kernel_width_plus_one_by_two_minus_output_width
        shl   edx,2
        filter_bottom_central_pixels32:
              ; Red
              mov   eax,[edx*4+12345678h]
              integral_image_bottom_center_br_r:
              sub   eax,[edx*4+12345678h]
              integral_image_bottom_center_bl_r:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_center_tr_r:
              add   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_center_tl_r:
              shr   eax,5
              divider_bottom_center_r:
              mov   ecx,eax
              ror   ecx,8

              ; Green
              mov   eax,[edx*4+12345678h]
              integral_image_bottom_center_br_g:
              sub   eax,[edx*4+12345678h]
              integral_image_bottom_center_bl_g:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_center_tr_g:
              add   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_center_tl_g:
              shr   eax,5
              divider_bottom_center_g:
              mov   cl,al
              ror   ecx,8

              ; Blue
              mov   eax,[edx*4+12345678h]
              integral_image_bottom_center_br_b:
              sub   eax,[edx*4+12345678h]
              integral_image_bottom_center_bl_b:
              sub   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_center_tr_b:
              add   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_center_tl_b:
              shr   eax,5
              divider_bottom_center_b:
              mov   cl,al
              ror   ecx,8

              ; Alpha
              mov   cl,0ffh
              ror   ecx,8

              mov   [edi+edx+12345678h],ecx
              destination_bottom_center32:
        inc   edx
        jnz   filter_bottom_central_pixels32

        ; edx: column offset
        get   edx,minus_half_width_minus_one
        shl   edx,2
        filter_bottom_right_pixels32:
              ; Red
              mov   eax,ds:[12345678h]
              integral_image_bottom_right_br_r:
              sub   eax,[ebx+12345678h]
              integral_image_bottom_right_tr_r:
              add   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_right_tl_r:
              sub   eax,[edx*4+12345678h]
              integral_image_bottom_right_bl_r:
              shr   eax,5
              divider_bottom_right_r:
              mov   ecx,eax
              ror   ecx,8

              ; Green
              mov   eax,ds:[12345678h]
              integral_image_bottom_right_br_g:
              sub   eax,[ebx+12345678h]
              integral_image_bottom_right_tr_g:
              add   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_right_tl_g:
              sub   eax,[edx*4+12345678h]
              integral_image_bottom_right_bl_g:
              shr   eax,5
              divider_bottom_right_g:
              mov   cl,al
              ror   ecx,8

              ; Blue
              mov   eax,ds:[12345678h]
              integral_image_bottom_right_br_b:
              sub   eax,[ebx+12345678h]
              integral_image_bottom_right_tr_b:
              add   eax,[ebx+edx*4+12345678h]
              integral_image_bottom_right_tl_b:
              sub   eax,[edx*4+12345678h]
              integral_image_bottom_right_bl_b:
              shr   eax,5
              divider_bottom_right_b:
              mov   cl,al
              ror   ecx,8

              ; Alpha
              mov   cl,0ffh
              ror   ecx,8

              mov   [edi+edx+12345678h],ecx
              destination_bottom_right32:
        add   edx,4
        jnz   filter_bottom_right_pixels32

  mov   eax,[SLI ptr esi.SLIXSize]
  shl   eax,4
  lea   ebx,[ebx+eax]
  add_  edi,output_pitch
  jnz   filter_bottom_pixels32

  ; Destroy stack frame.
  add   esp,num_variables*4
  pop   ebp

	ret
_ScaledBoxIntegral32	endp

;�����������������������������������������������������������������������������
; For each pixel, computes the integral in a neighborhood and scales it with
; a divider
;
; It supports 8 bpp and 32 bpp SLIs. The integral image must have been generated 
; first for the SLI contents with CreateIntegralImage. The time complexity does 
; not depend on the kernel size, only on the image dimensions. 
;
; Input and output SLIs must be the same size.
;
; Input:	EAX -> Input SLI (CreateIntegralImage must have been called first)
;			EBX = Kernel width (rounded up to odd number)
;     ECX = Kernel height (rounded up to odd number)
;     EDX = log2 of divider; the result for each pixel is divided by this value
;			EDI -> Output SLI
; Asserts: 
;   Input SLI does not have an integral image
;�����������������������������������������������������������������������������
ScaledBoxIntegral	proc
  cmp [SLI ptr eax.SLIColorBits],1
  jne sbi_not_8bpp
    call _ScaledBoxIntegral8
    ret
  sbi_not_8bpp:
  cmp [SLI ptr eax.SLIColorBits],4
  jne sbi_not_32bpp
    call _ScaledBoxIntegral32
    ret
  sbi_not_32bpp:
  AssertDword 0, _eq, 1
ScaledBoxIntegral	endp

;�����������������������������������������������������������������������������
; Applies a box filter of the given size on the SLI contents
;
; It supports 8 bpp and 32 bpp SLIs. Input and output SLIs must be the same
; size and type.
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
BoxFilter	proc
  ; The normalizing factor 1/kernel_area is turned into Y/D, where D is a power of 2.
  ; The highest value of the pre-multiplied integral image is W*H*255*D/K, which must be <= 2^32-1 (where W:image width, H:image height, K:kernel area).
  ; Therefore D <= 2^(floor(log2(K*((2^32-1)/(W*H*255))))).
  ; The highest possible D gives us the maximum accuracy for Y/D in integer math, so D = 2^(floor(log2(K*((2^32-1)/(W*H*255))))).
  push  ebp
  mov   esi,eax
  push  eax edi ecx ebx
  mov   ebx,[SLI ptr esi.SLIXSize]
  imul  ebx,[SLI ptr esi.SLIYSize]
  mov   eax,-1
  xor   edx,edx
  div   ebx
  pop   ebx
  push  ebx
  imul  ebx,ecx
  mov   ebp,ebx   ; EBP = K
  imul  eax,ebx
  mov   ebx,255
  xor   edx,edx
  div   ebx
  bsr   ecx,eax   ; Takes 3 cycles per scanned bit position!
  push  ecx
  ; Now, Y, the multiplier is D/K.
  mov   eax,1
  shl   eax,cl
  xor   edx,edx
  div   ebp
  ; Pre-multiply the integral image by Y.
  mov   ebx,eax
  mov   eax,esi
  call  CreateIntegralImage
  pop   edx       ; EDX = log2(D)
  pop   ebx ecx edi eax 
  call  ScaledBoxIntegral
  pop   ebp
  ret
BoxFilter endp

.data?
multiplication_table    dd 256 dup(?)

end