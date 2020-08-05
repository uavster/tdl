.386p
.model flat
.stack 200h
.code
        INCLUDE utils.inc
        INCLUDE polyint.inc
        INCLUDE newsgl.inc
start:
        InitDPMI

        mov     eax,offset pc1
        mov     ebx,3
        call    FindInterPoly
        ErrorExit "Error calculating polynome!"
        mov     poly,eax
        
        mov     eax,640
        mov     ebx,480
        mov     ecx,8
        call    SetVideoMode
        ErrorExit "Can't init video mode"

        call    GetAvailPage
        mov     edi,eax
        eval_points:
                mov     ebx,poly
                mov     eax,point
                push    edi
                call    EvalPoly
                pop     edi 
                mov     trash,eax
                fld     trash
                fldf    60.0
                fdivp
                fistp   trash

                fldf    479.0
                fild    trash
                fsubp
                fldf    640.0
                fmulp
                fiadd   x_coord
                fistp   trash

                mov     eax,trash
                fld     point
                fistp   trash
                cmp     trash,3
                jz      algo
                cmp     trash,10
                jz      algo
                cmp     trash,14
                jz      algo
                mov     byte ptr [edi+eax],0fh
                jmp     nada

                algo:
                mov     dword ptr [edi+eax],030303h
                mov     dword ptr [edi+eax+640],030303h
                mov     dword ptr [edi+eax+640*2],030303h
                mov     dword ptr [edi+eax+640*3],030303h

                nada:
                fldf    11.0
                fldf    640.0
                fdivp
                fadd    point
                fstp    point
        inc     x_coord
        cmp     x_coord,640
        jnz     eval_points

        call    ShowPage

        xor     ah,ah
        int     16h

        mov     eax,3
        call    UnSetVideoMode

        Exit

.data
x_coord dd 0
point   dd 3.0

cadena  db 13,10,"Valor: %d-n"
        dd offset trash
        db 0
trash   dd ?


c1      CONDITION <0,400.0>
c3      CONDITION <1,150.0>

c2      CONDITION <0,1000.0>
c4      CONDITION <1,1111.0>
c5      CONDITION <2,2222.0>

c6      CONDITION <0,255.0>
c7      CONDITION <1,333.0>

pc1     POINTCONDITION <3.0,2,offset c1>
pc2     POINTCONDITION <10.0,3,offset c2>
pc3     POINTCONDITION <14.0,2,offset c6>

.data?
poly    dd ?

end start
