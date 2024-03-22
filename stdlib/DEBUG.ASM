; --------------
; Writes the bytecodes around the call to this function to a file.
; Assumes a near call and ds having the same base address as cs.
; 
; Input:
; eax -> number of bytes before the call site
; ebx -> number of bytes after the call site
; edx -> file path
;
; Output:
; cf = 0 if success
;   eax = 0
; cf = 1 if error
;   eax = error code
; --------------

jumps
.386p
.model flat

.data
byte_formatter  db "%b02hn"
byte_value_ptr  dd ?
                db " ",0

.code

include filesys.inc
include utils.inc
include stderror.inc

public DumpCodeToFile

DumpCodeToFile proc
  ; Create file.
  push eax ebx
  call ttl_create
  mov ecx,eax   ; ecx = file handle
  pop ebx eax
  ErrorCode FILE_OPEN_ERROR

  ; Get call site offset from stack.  
  mov esi,ss:[esp]
  sub esi,eax   ; esi -> input buffer
  xchg ebx,ecx  ; ebx = file handle
  add ecx,eax   ; ecx = number of bytes to write
  sub esp,4
  mov edi,esp   ; edi -> temp variable
  write_bytes:
    mov byte_value_ptr,esi
    push esi ecx edi ebx
    mov esi,offset byte_formatter
    call FormatString
    pop ebx edx
    push edx ebx 
    mov ecx,3
    call ttl_write    
    pop ebx edi ecx esi
    jc write_error
    inc esi
  dec ecx
  jnz write_bytes

  add esp,4
  call ttl_close
  xor eax,eax
  clc
  ret

  write_error:
  add esp,4
  call ttl_close
  mov eax,FILE_WRITE_ERROR
  stc
  ret
endp

end