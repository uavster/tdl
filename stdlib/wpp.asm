 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; File:
;;    /xskernel/include/lang/watcom/arch/i386/watcom.s
;;
;; Description:
;;    WATCOM C/C++ Runtime Library Definition
;;
;; Author(s):
;;    Sadovnikov Vladimir
;;
;;
;; Copyright(s):
;;    (C) SyBase Inc.
;;    (C) Open Watcom Project
;;    (C) SadKo (Sadovnikov And Company)
;;    (C) XSystem Kernel Team
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Modified by B52 / tDR for compatibility with TASM, WPP386 and TDL.

.386p
.model flat

.data

STACK_FRAME struc
prev_frame_ptr          dd ?
current_try_catch_node  dd ?  ; Points to __wcpp_4_fs_handler_rtn__ by default.
possibly_catch_info     dd ?
try_catch_state         dd ?
ends

; This structure must not exceed 52 bytes longs.
TRY_CATCH_LIST_NODE struc
next_node_ptr           dd ?  ; Pointer to next node, or 0 if none.
state                   dd ?  ; Try-catch state when _setjmp_ was called.
fork_addr               dd ?  ; Code address after call to _setjmp_.
exception_ptr           dd ?  ; Pointer to the exception thrown in this try-catch, or 0 if none.
ends

default_exception_handler_message db 13,10,"Uncaught exception!",13,10,"$"

.code

public __wcpp_4_dtor_array_store__
__wcpp_4_dtor_array_store__:
        retn

public __wcpp_4_undef_vfun__
__wcpp_4_undef_vfun__:
        retn

public ___wcpp_4_data_init_fs_root_
___wcpp_4_data_init_fs_root_:
        retn

public ____wcpp_4_data_undefined_member_data_
____wcpp_4_data_undefined_member_data_:
        retn

public __wcpp_4_undefed_cdtor__
__wcpp_4_undefed_cdtor__:
        retn

; Register Destruction Function
public __wcpp_4_pure_error__
__wcpp_4_pure_error__:
        retn

public ___wcpp_4_data_module_dtor_ref_
___wcpp_4_data_module_dtor_ref_:
        retn

public __wcpp_4_fs_handler_
__wcpp_4_fs_handler_:
        retn

public __wcpp_4_fs_handler_rtn__
__wcpp_4_fs_handler_rtn__ TRY_CATCH_LIST_NODE<0, 0, 0, 0>

public _setjmp_
_setjmp_:
        ; eax=pointer to stack space with at least 52 bytes. We use it to store the linked list node.
        push ebx ecx

        ; __wint_thread_data points to new node, and node.next points at previous node.
        mov ebx,__wint_thread_data
        mov ecx,[STACK_FRAME ptr ebx.current_try_catch_node]
        mov [TRY_CATCH_LIST_NODE ptr eax.next_node_ptr],ecx
        mov [STACK_FRAME ptr ebx.current_try_catch_node],eax

        ; Set the node's try-catch state.
        mov ecx,[STACK_FRAME ptr ebx.try_catch_state]
        mov [TRY_CATCH_LIST_NODE ptr eax.state],ecx

        ; Set the node's fork address.
        mov ecx,[esp+4*2]   ; EDX=Pointer to instruction after CALL.
        mov [TRY_CATCH_LIST_NODE ptr eax.fork_addr],ecx

        ; Clear exception pointer.
        mov [TRY_CATCH_LIST_NODE ptr eax.exception_ptr],0

        ; Return != 1 to enter try block.
        xor eax,eax

        pop ecx ebx
        retn

public __argc
__argc:
        retn

global _exit_: near

default_exception_handler:
        mov ah,9
        mov edx,offset default_exception_handler_message
        int 21h
        mov al,0ffh
        call _exit_

public __wcpp_4_throw__
__wcpp_4_throw__:
        ; Store pointer to exception in ecx.
        mov ecx,eax

        ; If the fork address is the default one, setjmp has not been run for this stack frame, and we should try that of the outer try-catch.
        stack_unwinding_loop:
            ; Update eax to point to the stack frame of the outer try-catch.
            mov eax,__wint_thread_data
            
            ; If the node's fork address is 0, there's no try-catch enclosing the throw.
            mov ebx,[STACK_FRAME ptr eax.current_try_catch_node]
            mov edx,[TRY_CATCH_LIST_NODE ptr ebx.fork_addr]
            test edx,edx
            je no_try_catch

            ; The exception has been thrown from a try-catch. 
            
            ; The search for a handling catch block depends on whether it was thrown from a try block or a catch block.
            ; Throwing increases the try-catch's state in the stack frame; therefore, if the recorded state in the current node plus one 
            ; matches the stack frame's, the throw statement is in a try block; otherwise, it's in a catch block.
            mov edx,[TRY_CATCH_LIST_NODE ptr ebx.state]
            inc edx
            cmp [STACK_FRAME ptr eax.try_catch_state],edx
            je exception_handler_found    ; Exception thrown from a try block.

            ; Exception thrown from a catch block.
            mov ebx,[TRY_CATCH_LIST_NODE ptr ebx.next_node_ptr]
            test ebx,ebx
            jz no_try_catch   ; No more outer try-catchs in this stack frame: unwind it.

            ; The stack frame's try-block is now the containing one.
            mov [STACK_FRAME ptr eax.current_try_catch_node],ebx
            ; Run the catch block of the containing try-catch.
            jmp exception_handler_found

            no_try_catch:
            ; The stack frame cannot catch the exception: unwind it.
            mov ebp,[ebp]
            ; No more stack frames: call the default exception handler.
            test ebp,ebp
            jz default_exception_handler
            
            ; Set the new inner stack frame in __wint_thread_data
            mov eax,[STACK_FRAME ptr eax.prev_frame_ptr]
            mov __wint_thread_data,eax

            ; Since an exception was thrown, increase the new stack frame's try-catch state.
            ; This must be done to know whether the exception was thrown from the try block or the catch block of the new stack frame.
            inc [STACK_FRAME ptr eax.try_catch_state]

            ; The stack space containing the exception data stays alive until esp is restored.
        jmp stack_unwinding_loop

        exception_handler_found:
        ; ebx=pointer to node with the catch block handling the exception.        
        ; Store exception pointer in node.
        mov [TRY_CATCH_LIST_NODE ptr ebx.exception_ptr],ecx
        ; Overwrite return address with try-catch fork point.
        mov eax,[TRY_CATCH_LIST_NODE ptr ebx.fork_addr]
        test eax,eax
        jz default_exception_handler
        mov ss:[esp],eax
        ; Simulate setjmp returning 1 to enter catch block.
        mov eax,1
        retn

public GetLastExceptionPtr
GetLastExceptionPtr proc
        mov eax,__wint_thread_data
        mov eax,[STACK_FRAME ptr eax.current_try_catch_node]
        mov eax,[TRY_CATCH_LIST_NODE ptr eax.exception_ptr]
        retn
  endp

public __wcpp_4_catch_done__
__wcpp_4_catch_done__:
        ; The try-catch is now the containing one.
        mov eax,__wint_thread_data
        mov ebx,[STACK_FRAME ptr eax.current_try_catch_node]
        mov ebx,[TRY_CATCH_LIST_NODE ptr ebx.next_node_ptr]
        mov [STACK_FRAME ptr eax.current_try_catch_node],ebx
        retn

public __compiled_under_generic
__compiled_under_generic:
        retn
		
public __wcpp_4_destruct_all__
__wcpp_4_destruct_all__:
        retn

public __wcpp_4_lcl_register__
__wcpp_4_lcl_register__:
		retn

public __wcpp_4_ctor_array_storage_gm__
__wcpp_4_ctor_array_storage_gm__:
		retn

public __wcpp_4_undefined_member_function__
__wcpp_4_undefined_member_function__:
		retn

public __wcpp_4_destruct__
__wcpp_4_destruct__:
		retn

base_stack_frame STACK_FRAME<0,0,0,0>

public __wint_thread_data
__wint_thread_data dd offset base_stack_frame

public __wcpp_4_ctor_array__
align 16
__wcpp_4_ctor_array__:
		retn

public __wcpp_4_dtor_array__
align 16
__wcpp_4_dtor_array__:
		retn

end