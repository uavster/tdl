/* ==== ArtNouveaU Tiny Library ~ tinymath.h =============================

   WATCOM C/C++ Standard Libraries replacement for tiny code.
   Copyright (C) 1997 by the gang at ArtNouveaU, All Rights Reserved.

        author           : <G>SZ ~ ArtNouveaU
        file creation    : 24 October 1997
        file description : intrinsics for math functions

        revision history :
            (24/10/97) the beginning
            (26/10/97) added sincos intrinsic
            (30/10/97) added acos and asin intrinsics
            (31/10/97) added ceil and floor ones
            (01/11/97) added hypot, cosh, sinh, acosh, asinh atanh ones
            (02/11/97) added tanh intrinsic

        references       :
            Submissive/Cubic math intrinsics, 1997.

            WATCOM C/C++ v11.0 Math Library, 1997.

        notes            : pow returns nan with non-positive argument

  ======================================================================== */

#ifndef _TINYMATH_H_INCLUDED
#define _TINYMATH_H_INCLUDED

  #ifdef __cplusplus
    extern "C" {
  #endif


  //static char math_id[] = "$Id: tinymath.h, v1.0 1997/10/24 <G>SZ Exp $";

  extern void    finit(void);
  extern double  acos(double __x);       /* atan(sqrt(1 - sqr(x)) / x) */
  extern double  asin(double __x);
  extern double  atan(double __x);
  extern double  atan2(double __y, double __x);
  extern double  ceil(double __x);
  extern double  cos(double __x);
  extern double  exp(double __x);
  extern double  exp2(double __x);
  extern double  exp10(double __x);
  extern double  fabs(double __x);
  extern double  floor(double __x);
  extern double  fmod(double __x, double __y);
  extern double  hypot(double __x, double __y);
  extern double  log(double __x);
  extern double  log2(double __x);
  extern double  log10(double __x);
  extern double  pow(double __x, double __y);
  extern double  sin(double __x);
  extern void    sincos(float __x, float *__sin, float *__cos);
  extern double  sqr(double __x);
  extern double  sqrt(double __x);
  extern double  tan(double __x);
  extern double  acosh(double __x);      /* logn(sqrt(sqr(x) - 1) + x) */
  extern double  asinh(double __x);      /* logn(sqrt(sqr(x) + 1) + x) */
  extern double  atanh(double __x);   /* -logn((1 - x) / (1 + x)) * .5 */
  extern double  cosh(double __x);       /* (1 / exp(x) + exp(x)) * .5 */
  extern double  sinh(double __x);       /* (exp(x) - 1 / exp(x)) * .5 */
  extern double  tanh(double __x);   /* -(1 - exp(2x)) / (1 + exp(2x)) */

  #pragma aux    finit modify [8087] = "finit"
  #pragma aux    acos parm [8087] value [8087] modify [8087 eax] = "sub esp, 4" "fst dword ptr [esp]" "fmul st, st" "fld1" "fsubrp st(1), st" "fsqrt" "fdiv dword ptr [esp]" "fld1" "fpatan" "mov eax, [esp]" "cmp eax, 0x80000000" "jbe _acos_exit" "fldpi" "faddp st(1), st" "_acos_exit:" "pop eax"
  #pragma aux    asin parm [8087] value [8087] modify [8087 eax] = "sub esp, 4" "fst dword ptr [esp]" "mov eax, [esp]" "test eax, eax" "je _asin_zero" "fmul st, st" "fld1" "fsubrp st(1), st" "fsqrt" "fdiv dword ptr [esp]" "fld1" "fpatan" "fchs" "mov eax, 0x3F000000" "push eax" "fld dword ptr [esp]" "pop eax" "fldpi" "fmulp st(1), st" "mov eax, [esp]" "cmp eax, 0x80000000" "jbe _asin_exit" "fchs" "_asin_exit:" "faddp st(1), st" "_asin_zero:" "pop eax"
  #pragma aux    atan parm [8087] value [8087] modify [8087] = "fld1" "fpatan"
  #pragma aux    atan2 parm [8087] [8087] value [8087] modify [8087] = "fxch" "fpatan"
  #pragma aux    ceil parm [8087] value [8087] modify [8087 eax] = "fchs" "fld1" "fld st(1)" "fprem" "sub esp, 4" "fst dword ptr [esp]" "fxch st(2)" "mov eax, [esp]" "cmp eax, 0x80000000"  "jbe _ceil_exit" "fsub st, st(1)" "_ceil_exit:" "fsub st, st(2)"  "fstp st(1)" "fstp st(1)" "fchs" "pop eax"
  #pragma aux    cos parm [8087] value [8087] modify [8087] = "fcos"
  #pragma aux    exp parm [8087] value [8087] modify [8087] = "fldl2e" "fmulp st(1), st" "fld1" "fld st(1)" "fprem" "f2xm1" "faddp st(1), st" "fscale" "fxch" "fstp st"
  #pragma aux    exp2 parm [8087] value [8087] modify [8087] = "fld1" "fld st(1)" "fprem" "f2xm1" "faddp st(1), st" "fscale" "fxch" "fstp st"
  #pragma aux    exp10 parm [8087] value [8087] modify [8087] = "fldl2t" "fmulp st(1), st" "fld1" "fld st(1)" "fprem" "f2xm1" "faddp st(1), st" "fscale" "fxch" "fstp st"
  #pragma aux    fabs parm [8087] value [8087] modify [8087] = "fabs"
  #pragma aux    floor parm [8087] value [8087] modify [8087 eax] = "fld1" "fld st(1)" "fprem" "sub esp, 4" "fst dword ptr [esp]" "fxch st(2)" "mov eax, [esp]" "cmp eax, 0x80000000"  "jbe _ceil_exit" "fsub st, st(1)" "_ceil_exit:" "fsub st, st(2)"  "fstp st(1)" "fstp st(1)" "pop eax"
  #pragma aux    fmod parm [8087] [8087] value [8087] modify [8087] = "fprem" "fxch" "fstp st"
  #pragma aux    hypot parm [8087] [8087] value [8087] modify [8087] = "fmul st, st" "fxch" "fmul st, st" "faddp st(1), st" "fsqrt"
  #pragma aux    log parm [8087] value [8087] modify [8087] = "fldln2" "fxch" "fyl2x"
  #pragma aux    log2 parm [8087] value [8087] modify [8087] = "fld1" "fxch" "fyl2x"
  #pragma aux    log10 parm [8087] value [8087] modify [8087] = "fldlg2" "fxch" "fyl2x"
  #pragma aux    pow parm [8087] [8087] value [8087] modify [8087] = "fyl2x" "fld1" "fld st(1)" "fprem" "f2xm1" "faddp st(1), st" "fscale" "fxch" "fstp st"
  #pragma aux    sin parm [8087] value [8087] modify [8087] = "fsin"
  #pragma aux    sincos parm [8087] [eax] [edx] modify [8087] = "fsincos" "fstp dword ptr [edx]" "fstp dword ptr [eax]"
  #pragma aux    sqr parm [8087] value [8087] modify [8087] = "fmul st, st"
  #pragma aux    sqrt parm [8087] value [8087] modify [8087] = "fsqrt"
  #pragma aux    tan parm [8087] value [8087] modify [8087] = "fptan" "fstp st"
  #pragma aux    acosh parm [8087] value [8087] modify [8087] = "fld st" "fmul st, st" "fld1" "fsubp st(1), st" "fsqrt" "faddp st(1), st" "fldln2" "fxch" "fyl2x"
  #pragma aux    asinh parm [8087] value [8087] modify [8087] = "fld st" "fmul st, st" "fld1" "faddp st(1), st" "fsqrt" "faddp st(1), st" "fldln2" "fxch" "fyl2x"
  #pragma aux    atanh parm [8087] value [8087] modify [8087 eax] = "fld1" "fsub st, st(1)" "fld1" "faddp st(2), st" "fdivrp st(1), st" "fldln2" "fxch" "fyl2x" "mov eax, 0xBF000000" "push eax" "fld dword ptr [esp]" "fmulp st(1), st" "pop eax"
  #pragma aux    cosh parm [8087] value [8087] modify [8087 eax] = "fldl2e" "fmulp st(1), st" "fld1" "fld st(1)" "fprem" "f2xm1" "faddp st(1), st" "fscale" "fxch" "fstp st" "fld1" "fdiv st, st(1)" "faddp st(1), st" "mov eax, 0x3F000000" "push eax" "fld dword ptr [esp]" "fmulp st(1), st" "pop eax"
  #pragma aux    sinh parm [8087] value [8087] modify [8087 eax] = "fldl2e" "fmulp st(1), st" "fld1" "fld st(1)" "fprem" "f2xm1" "faddp st(1), st" "fscale" "fxch" "fstp st" "fld1" "fdiv st, st(1)" "fsubp st(1), st" "mov eax, 0x3F000000" "push eax" "fld dword ptr [esp]" "fmulp st(1), st" "pop eax"
  #pragma aux    tanh parm [8087] value [8087] modify [8087 eax] = "fld st" "mov eax, 0x40000000" "push eax" "fld dword ptr [esp]" "fmul st, st(1)" "fldl2e" "fmulp st(1), st" "fld1" "fld st(1)" "fprem" "f2xm1" "faddp st(1), st" "fscale" "fxch" "fstp st" "fld1" "fsub st, st(1)" "fchs" "fld1" "faddp st(2), st" "fdivrp st(1), st" "pop eax"


  #ifndef M_PI
    #define M_PI 3.14159265358979323846
  #endif


  #ifdef __cplusplus
    };
  #endif

#endif
