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
__wcpp_4_fs_handler_rtn__:
        retn
		
public _setjmp_
_setjmp_:
        retn

public __argc
__argc:
        retn

public __wcpp_4_throw__
__wcpp_4_throw__:
        retn

public __wcpp_4_catch_done__
__wcpp_4_catch_done__:
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

public __wint_thread_data
__wint_thread_data:
		retn

public __wcpp_4_ctor_array__
align 16
__wcpp_4_ctor_array__:
		retn

public __wcpp_4_dtor_array__
align 16
__wcpp_4_dtor_array__:
		retn

end