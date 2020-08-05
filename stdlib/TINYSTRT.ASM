.386
.387
.model flat,prolog
locals
smart
jumps
IDEAL


STACK 10000h

DATASEG

CODESEG

extrn main_: proc

public __do_exit_with_msg__
public _cstart_
public __CHP
public _fltused_
public __8087
_fltused_:
__8087:
_cstart_:

__CHP:
  ret

start:
  jmp cmain
  db 'WATCOM'
cmain:
;  mov [__psp],es
  sti
  cld
  push ds
  pop es

  finit
  push 1F7Fh
  fldcw [word ptr esp]
  add esp,4

  call main_

__do_exit_with_msg__:
  mov ax,4c00h
  int 21h

end start
