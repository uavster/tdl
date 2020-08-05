;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Common 3D routines
;       by Ignacio Mellado Bataller (a.k.a. B52 / the DarkRising)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code
        INCLUDE 3d.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Normalizes a 3D vector
;
; INPUT : EAX -> 3D vector
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
NormalizeVector proc
comment ¤
fld [eax.x]
;fldf 1000.0
;fmulp
fistp trash
pushad
print  deb_normal
popad
;mov eax,trash
fld [eax.y]
;fldf 1000.0
;fmulp
fistp trash
pushad
print  deb_normal
popad
;mov ebx,trash
fld [eax.z]
;fldf 1000.0
;fmulp
fistp trash
pushad
print  deb_normal
xor ah,ah
int 16h
popad
;mov ecx,trash
¤
        ; Normalize vector
        fld     [eax.x]
        fmul    [eax.x]
        fld     [eax.y]
        fmul    [eax.y]
        faddp
        fld     [eax.z]
        fmul    [eax.z]
        faddp
        fsqrt
        fld     [eax.x]
        fld     st(1)
        fdivp
        fstp    [eax.x]
        fld     [eax.y]
        fld     st(1)
        fdivp
        fstp    [eax.y]
        fld     [eax.z]
        fld     st(1)
        fdivp
        fstp    [eax.z]
        fstp    trash
        ret
NormalizeVector endp

.data?
trash   dd ?

end
