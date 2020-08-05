;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Polynomial interpolation routines
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / the DarkRising)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code

        INCLUDE polyint.inc
        INCLUDE alloc.inc
        INCLUDE utils.inc
        INCLUDE stderror.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Finds the coeficients for the minimum order interpolator polynome with
; the given conditions
;
; INPUT  : EAX -> POINTCONDITION array
;          EBX = Number of POINTCONDITIONS
;
; OUTPUT : CF = 0 if ok
;               EAX -> POLYNOME structure
;          CF = 1 if error
;               EAX = NULL
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FindInterPoly   proc
        ; -------Find the space we need to build interpolation scheme---------
        mov     pc_array,eax
        mov     num_pcs,ebx
        mov     total_space,0
        parse_pointconditions:

                mov     edx,[eax.NumConditions]
                mov     esi,[eax.Conditions]
                xor     ebp,ebp
                find_highest_order:
                        cmp     [esi.Order],ebp
                        jbe     below_order
                                mov     ebp,[esi.Order]
                        below_order:
                        add     esi,size CONDITION
                dec     edx
                jnz     find_highest_order
                inc     ebp
                mov     [eax.NumEntries],ebp
                add     total_space,ebp

                add     eax,size POINTCONDITION
        dec     ebx
        jnz     parse_pointconditions

        ;---------------------------Allocate space-----------------------------
        ; Space for polynome buffer
        mov     ecx,size COEFICIENT
        imul    ecx,total_space
        add     ecx,size POLYNOME-size CoefData
        call    malloc
        ErrorCode 0
        mov     eax,total_space
        mov     [ebx.NumCoefs],eax
        mov     poly_buffer,ebx

        ; Space for scheme buffer
        mov     ebx,total_space
        mov     ecx,total_space
        find_scheme_space:
                add     ecx,ebx
        dec     ebx
        jnz     find_scheme_space
        shl     ecx,2
        call    malloc
        ErrorCode 0
        mov     scheme_buffer,ebx

        ;-------------------Build interpolation scheme------------------------
        mov     esi,pc_array
        mov     ecx,num_pcs
        mov     edi,scheme_buffer
        walk_pointconditions:
                mov     edx,[esi.NumEntries]
                mov     ebx,[esi.XPoint]
                mov     ebp,[esi.Conditions]
                mov     eax,ds:[ebp.Value]      ; f(x0)
                mov     ebp,total_space
                walk_conditions:
                        mov     [edi],ebx
                        mov     ds:[edi+ebp*4],eax
                        add     edi,4
                dec     edx
                jnz     walk_conditions
                add     esi,size POINTCONDITION
        loop    walk_pointconditions

        mov     esi,scheme_buffer
        mov     ebp,total_space
        lea     esi,[esi+ebp*4]
        dec     ebp
        xor     edx,edx
        xor     edi,edi
        inc     edi
        find_increments:
                mov     ecx,ebp
                xor     ebx,ebx
                find_increment_line:
                        fld     dword ptr [esi+edx*4+4]
                        fsub    dword ptr [esi+edx*4]
                        fst     temp
                        cmp     temp,0
                        jz      search_data

                        ; If the difference between the two previous values
                        ; is not 0, then divide it by the difference between
                        ; the points the come from
                                mov     eax,ebx
                                sub     eax,total_space
                                add     eax,edi
                                fld     dword ptr [esi+eax*4]
                                mov     eax,ebx
                                sub     eax,total_space
                                fsub    dword ptr [esi+eax*4]
                                fdivp
                                jmp     end_calc

                        ; If previous values are the same one, we look for
                        ; the needed data into the given conditions
                        search_data:
                                mov     eax,ebx
                                sub     eax,total_space
                                mov     eax,[esi+eax*4]
                                push    ecx esi
                                mov     ecx,num_pcs
                                mov     esi,pc_array
                                search_our_point:
                                        cmp     [esi.XPoint],eax
                                        jz      found_our_point
                                        add     esi,size POINTCONDITION
                                dec     ecx
                                jnz     search_our_point
                                pop     esi ecx
                                xor     eax,eax
                                stc
                                ret

                                found_our_point:
                                mov     ecx,[esi.NumConditions]
                                mov     esi,[esi.Conditions]
                                search_our_cond:
                                        cmp     [esi.Order],edi
                                        jz      found_our_cond
                                        add     esi,size CONDITION
                                dec     ecx
                                jnz     search_our_cond
                                pop     esi ecx
                                fld1
                                faddp
                                jmp     end_calc
                                found_our_cond:
                                fadd    [esi.Value]
                                pop     esi ecx

                        end_calc:
                        lea     eax,[ebp+edx]                        
                        fstp    dword ptr ds:[esi+eax*4+4]
                        inc     edx
                        inc     ebx
                dec     ecx
                jnz     find_increment_line
                inc     edx
                inc     edi
        dec     ebp
        jnz     find_increments

        ;-------------Take the polynome coefficients from the scheme----------
        mov     esi,scheme_buffer
        mov     ecx,total_space
        lea     esi,[esi+ecx*4]
        mov     edi,poly_buffer
        take_first_coef:
                mov     eax,[esi]
                mov     [edi.CoefData.CoefValue],eax
                lea     esi,[esi+ecx*4]
                add     edi,size COEFICIENT
        dec     ecx
        jnz     take_first_coef

        ;--------------Take the points related to coeficients-----------------
        mov     esi,pc_array
        mov     ecx,num_pcs
        mov     edi,poly_buffer
        fld1
        fstp    [edi.CoefData.PointValue]
        add     edi,size COEFICIENT
        take_points:
                mov     edx,[esi.NumEntries]
                mov     eax,[esi.XPoint]
                cmp     ecx,1
                jnz     assign_points
                        dec     edx
                assign_points:
                        mov     [edi.CoefData.PointValue],eax
                        add     edi,size COEFICIENT
                dec     edx
                jnz     assign_points
                add     esi,size POINTCONDITION
        dec     ecx
        jnz     take_points

        ;--------------------------Free scheme buffer--------------------------
        mov     ebx,scheme_buffer
        call    free
        ErrorCode 0

;------DEBUGGING routine--------------------
if POLYDEBUG
        LPrintS "Resultados de interpolaci¢n polin¢mica (datos redondeados)"
        LPrintS "Arbol de coeficientes: "
        mov     esi,scheme_buffer
        mov     ecx,total_space
        fi1:
                fld     dword ptr [esi]
                push    esi ecx
                fistp   trash
                print   cadena
                pop     ecx esi
                add     esi,4
        dec     ecx
        jnz     fi1

        mov     ebp,total_space
        fi2:
                push    ebp esi
                print   cr
                pop     esi ebp
                mov     ecx,ebp
                fi3:
                        fld     dword ptr [esi]
                        push    ecx esi ebp
                        fistp   trash
                        print   cadena
                        pop     ebp esi ecx
                        add     esi,4
                dec     ecx
                jnz     fi3
        dec     ebp
        jnz     fi2

        print   cr
        print   cr
        LPrintS "Coeficientes del polinomio interpolador: "
        mov     esi,poly_buffer
        mov     ecx,[esi.NumCoefs]
        print_coefs:
                fld     dword ptr [esi.CoefData.CoefValue]
                fistp   trash
                push    esi ecx
                print   cadena
                pop     ecx esi
                add     esi,size COEFICIENT
        loop    print_coefs

        print   cr
        print   cr
        LPrintS "Valores multiplicadores de cada t‚rmino: "
        mov     esi,poly_buffer
        mov     ecx,[esi.NumCoefs]
        print_points:
                fld     dword ptr [esi.CoefData.PointValue]
                fistp   trash
                push    esi ecx
                print   cadena
                pop     ecx esi
                add     esi,size COEFICIENT
        loop    print_points

endif
;------------------------------------------

        ;--------------------------Return parameters---------------------------
        mov     eax,poly_buffer
        clc
        ret

FindInterPoly   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Evaluates an interpolator polynome at a given point
;
; INPUT : EAX = Point (float)
;         EBX -> POLYNOME structure
;
; OUTPUT : EAX = Polynome value (float)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
EvalPoly        proc
        mov     EvalPoint,eax
        fld1
        fstp    Accumulator
        fld     [ebx.CoefData.CoefValue]        ; First coeficient
        mov     ecx,[ebx.NumCoefs]
        dec     ecx
        add_coefs:
                add     ebx,size COEFICIENT
                fld     EvalPoint
                fsub    [ebx.CoefData.PointValue]
                fmul    Accumulator
                fst     Accumulator
                fmul    [ebx.CoefData.CoefValue]
                faddp
        dec     ecx
        jnz     add_coefs
        fstp    EvalPoint
        mov     eax,EvalPoint
        ret
EvalPoly        endp

if POLYDEBUG
.data
cadena  db " %d-n"
        dd offset trash
        db 0
trash   dd ?
cr      db 13,10,0
endif

.data?
EvalPoint       dd ?
Accumulator     dd ?

temp            dd ?
pc_array        dd ?
num_pcs         dd ?
total_space     dd ?
poly_buffer     dd ?
scheme_buffer   dd ?

end
