;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Coordinates Transform for SPUF! System
;       by Ignacio Mellado Bataller ( a.k.a. B52 / the DarkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code
        INCLUDE sgl.inc
        INCLUDE coords.inc                
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initialises fast coordinate conversion for typical modes which can be
; calculated as: Y SHL S1 + Y SHL S2 + ...
;
; INPUT -> VideoX = X size of screen buffer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FastCoordInit   proc
        ; VideoX/2
        mov     eax,VideoX
        shr     eax,1
        mov     HalfVideoX,eax
        ; VideoY/2
        mov     eax,VideoY
        shr     eax,1
        mov     HalfVideoY,eax
        ; Fixup for 'TransCoords'
        mov     eax,VideoX
        cmp     eax,256
        jz      convert256
        cmp     eax,320
        jz      convert320
        cmp     eax,640
        jz      convert640
        cmp     eax,800
        jz      convert800
        cmp     eax,1280
        jz      convert1280
        cmp     eax,1600
        jz      convert1600

        ; if the mode is not typical, we will simply multiply with FMUL
        ; (faster than FIMUL)
        mov     VideoXFloat,eax
        fild    VideoXFloat
        fstp    VideoXFloat
        mov     make_it_linear,offset rare_resolution
        ret
        ; otherwise...
        convert256:
        mov     make_it_linear,offset resolution_256
        ret
        convert320:
        mov     make_it_linear,offset resolution_320
        ret
        convert640:
        mov     make_it_linear,offset resolution_640
        ret
        convert800:
        mov     make_it_linear,offset resolution_800
        ret
        convert1280:
        mov     make_it_linear,offset resolution_1280
        ret
        convert1600:
        mov     make_it_linear,offset resolution_1600
        ret
FastCoordInit   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Transforms the given screen coordinates to a linear pointer into video
; memory
;
; INPUT  -> EAX = X coordinate
;           EBX = Y coordinate
;           ECX = Reference system for coordinates transform
;
;               The number indicates the value of ECX and where the reference
;               system is centered:
;
;                           1ÄÄÄÄÄÄ8ÄÄÄÄÄÄ7
;                           ³             ³
;               SCREEN ->   2      0      6
;                           ³             ³
;                           3ÄÄÄÄÄÄ4ÄÄÄÄÄÄ5
;
; OUTPUT -> EAX = linear pointer into video memory
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
TransCoords     proc
        jmp     RefSystems[ecx*4]
        rs0:
                ; the system is screen-centered
                add     eax,HalfVideoX
                add     ebx,HalfVideoY
                jmp     make_it_linear
        rs1:
                jmp     make_it_linear
        rs2:
                add     ebx,HalfVideoY
                jmp     make_it_linear
        rs3:
                add     ebx,VideoY
                jmp     make_it_linear
        rs4:
                add     eax,HalfVideoX
                add     ebx,VideoY
                jmp     make_it_linear
        rs5:
                add     eax,VideoX
                add     ebx,VideoY
                jmp     make_it_linear
        rs6:
                add     eax,VideoX
                add     ebx,HalfVideoY
                jmp     make_it_linear
        rs7:
                add     eax,VideoX
                jmp     make_it_linear
        rs8:
                add     eax,HalfVideoX
                jmp     make_it_linear
        resolution_256:
                shl     ebx,8
                add     ebx,eax
                ret
        resolution_320:
                mov     ecx,ebx
                shl     ebx,8
                shl     ecx,6
                add     ebx,ecx
                add     ebx,eax
                ret
        resolution_640:
                mov     ecx,ebx
                shl     ebx,9
                shl     ecx,7
                add     ebx,ecx
                add     ebx,eax
                ret
        resolution_800:
                mov     ecx,ebx
                mov     edx,ebx
                shl     ebx,9
                shl     ecx,8
                shl     edx,5
                add     ebx,ecx
                add     ebx,edx
                add     ebx,eax
                ret
        resolution_1280:
                mov     ecx,ebx
                shl     ebx,10
                shl     ecx,8
                add     ebx,ecx
                add     ebx,eax
                ret
        resolution_1600:
                mov     ecx,ebx
                mov     edx,ebx
                shl     ebx,10
                shl     ecx,9
                shl     edx,6
                add     ebx,ecx
                add     ebx,edx
                add     ebx,eax
                ret
        rare_resolution:
                mov     trash,ebx
                fild    trash
                fmul    VideoXFloat
                fistp   trash
                mov     ebx,trash
                add     ebx,eax
                ret
TransCoords     endp

.data
RefSystems      dd offset rs0,offset rs1,offset rs2,offset rs3,offset rs4
                dd offset rs5,offset rs6,offset rs7,offset rs8
make_it_linear  dd offset resolution_320
HalfVideoX      dd 160
HalfVideoY      dd 100
VideoXFloat     dd ?
trash           dd ?

end
