;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Bresenham routine to draw lines on a SLI
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.386p
.model flat
.code

        INCLUDE sli.inc
        INCLUDE gfx.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Clips a point within X coordinates
;
; INPUT  : EAX = x
;          EBX = y
;
; OUTPUT : EAX = New X
;          EBX = New Y
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ClipX   proc
        xor     ebp,ebp
        ; Need to find what will be the new 'x' (0 or SLIXSize-1 ?)
        test    eax,eax
        js      x_signed
                mov     ebp,size_x
                dec     ebp
        x_signed:
        ; Y = Y + ( NewX - X ) * y_increment
        mov     trash,ebp       
        sub     trash,eax
        fild    trash
        fmul    y_increment
        fistp   trash
        add     ebx,trash       
        mov     eax,ebp         ; X = NewX
        ret
ClipX   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Clips a point within Y coordinates
;
; INPUT  : EAX = x
;          EBX = y
;
; OUTPUT : EAX = New X
;          EBX = New Y
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ClipY   proc
        xor     ebp,ebp
        ; Need to find what will be the new 'y' (0 or SLIYSize-1 ?)
        test    ebx,ebx
        js      y_signed
                mov     ebp,size_y
                dec     ebp
        y_signed:
        ; X = X + ( NewY - Y ) * x_incrment
        mov     trash,ebp       
        sub     trash,ebx
        fild    trash
        fmul    x_increment
        fistp   trash
        add     eax,trash       
        mov     ebx,ebp         ; Y = NewY
        ret
ClipY   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Draws a 32 bit clipped line on a SLI
;
; INPUT : EAX = x0
;         EBX = y0
;         ECX = x1
;         EDX = y1
;         ESI = color in B:G:R:0 format
;         EDI -> destination SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Line    proc

        ; ---------------------Move clip zone to origin-----------------------
        sub     eax,[edi.SLIClip.SLRR1.SLPX]
        sub     ecx,[edi.SLIClip.SLRR1.SLPX]
        sub     ebx,[edi.SLIClip.SLRR1.SLPY]
        sub     edx,[edi.SLIClip.SLRR1.SLPY]

        mov     ebp,[edi.SLIClip.SLRR2.SLPX]
        sub     ebp,[edi.SLIClip.SLRR1.SLPX]
        mov     size_x,ebp
        mov     ebp,[edi.SLIClip.SLRR2.SLPY]
        sub     ebp,[edi.SLIClip.SLRR1.SLPY]
        mov     size_y,ebp

        ; ----------------Test if line won't be drawn anyway------------------
        cmp     eax,size_x
        jb      xs_are_ok
        cmp     ecx,size_x
        jb      xs_are_ok
        push    eax ecx         ; Test if EAX & ECX are the same sign
        sar     eax,31
        sar     ecx,31
        xor     eax,ecx
        pop     ecx eax
        jz      dont_draw_line

        xs_are_ok:
        cmp     ebx,size_y
        jb      ys_are_ok
        cmp     edx,size_y
        jb      ys_are_ok
        push    ebx edx         ; Test if EBX & EDX are the same sign
        sar     ebx,31
        sar     edx,31
        xor     ebx,edx
        pop     edx ebx
        jz      dont_draw_line
        ys_are_ok:

        ; ---------Calculate 'y' unit increment as (y1-y0)/(x1-x0)------------
        mov     y_increment,edx
        sub     y_increment,ebx
        fild    y_increment
        mov     y_increment,ecx
        sub     y_increment,eax
        fidiv   y_increment
        fstp    y_increment
        ; Calculate 'x' unit increment as 1/y_increment
        fld1
        fdiv    y_increment
        fstp    x_increment

        ; -----------------------Do clipping----------------------------------
        cmp     eax,size_x      ; Is x1 into screen 'x' range?
        jb      x1_nc
                ; x1 needs to be clipped
                call    ClipX
        x1_nc:
        cmp     ecx,size_x      ; Is x2 into screen 'x' range?
        jb      x2_nc
                ; x2 needs to be clipped
                push    eax ebx
                mov     eax,ecx
                mov     ebx,edx
                call    ClipX
                mov     ecx,eax
                mov     edx,ebx
                pop     ebx eax
        x2_nc:
        cmp     ebx,size_y      ; Is y1 into screen 'y' range?
        jb      y1_nc
                ; y1 needs to be clipped
                call    ClipY
        y1_nc:
        cmp     edx,size_y      ; Is y1 into screen 'y' range?
        jb      y2_nc
                ; y2 needs to be clipped
                push    eax ebx
                mov     eax,ecx
                mov     ebx,edx
                call    ClipY
                mov     ecx,eax
                mov     edx,ebx
                pop     ebx eax
        y2_nc:
        ; If after clipping there are points still outside screen, don't draw
        cmp     eax,size_x
        jae     dont_draw_line
        cmp     ecx,size_x
        jae     dont_draw_line
        cmp     ebx,size_y
        jae     dont_draw_line
        cmp     edx,size_y
        jae     dont_draw_line

        ; ---------------Move it all to clip zone again-----------------------
        add     eax,[edi.SLIClip.SLRR1.SLPX]
        add     ecx,[edi.SLIClip.SLRR1.SLPX]
        add     ebx,[edi.SLIClip.SLRR1.SLPY]
        add     edx,[edi.SLIClip.SLRR1.SLPY]

        ; -----------Force the line to be drawn top to bottom-----------------
        cmp     ebx,edx
        jb      short xy_ok
                xchg    eax,ecx
                xchg    ebx,edx
        xy_ok:

        ; -----------------Calculate initial offset into SLI------------------
        mov     dest_pointer,ebx
        fild    dest_pointer
        fimul   [edi.SLIXSize]
        mov     dest_pointer,eax
        fiadd   dest_pointer
        fistp   dest_pointer
        shl     dest_pointer,2  ; it's 32 bits

        ; ---------------------Calculate 'x' & 'y' variations-----------------
        mov     x1,ecx
        mov     y1,edx
        sub     ecx,eax
        jns     short x_ok_3
                neg     ecx
        x_ok_3:
        sub     edx,ebx
        jns     short y_ok_3
                neg     edx
        y_ok_3:

        mov     ebp,ecx
        or      ebp,edx
        jz      dont_draw_line

        ; ----------Modify increments depending on 'x' & 'y' variations-------
        mov     ebp,[edi.SLIXSize]
        shl     ebp,2
        cmp     edx,ecx 
        jbe     short below_1
                xchg    edx,ecx
                ; Real-time code modification to speed up drawing
                cmp     eax,x1
                jb x_ok_1
                        mov     inc1,-4             ; ADD ESI,-4
                        mov     inc2,ebp            ; ADD ESI,SLIXSize
                        jmp     short cont_init   
                x_ok_1:
                        mov     inc1,4              ; ADD ESI,4
                        mov     inc2,ebp            ; ADD ESI,SLIXSize
                        jmp     short cont_init
        below_1:
                cmp     eax,x1
                jb      short x_ok_2
                        mov     inc2,-4             ; ADD ESI,-4
                        mov     inc1,ebp            ; ADD ESI,SLIXSize
                        jmp     short cont_init
                x_ok_2:
                        mov     inc2,4              ; ADD ESI,4
                        mov     inc1,ebp            ; ADD ESI,SLIXSize
                        jmp     short cont_init     ; load prefetch queue!
        cont_init:

        ; -------------------Initialize Bresenham variables-------------------
        sal     edx,1
        mov     ebx,edx
        sub     edx,ecx
        mov     ebp,ecx
        sal     ebp,1
        inc     ecx
        ; Initialize destination pointer
        mov     eax,esi
        mov     esi,[edi.SLIFramePtr]
        add     esi,dest_pointer

        ;---------------------------Do main loop------------------------------
        line_loop:
                mov     [esi],eax
                test    edx,edx
                js      short negative
                        sub     edx,ebp
                        db      81h,0c6h        ; ADD ESI,INC1
                        inc1    dd ?
                negative:
                        add     edx,ebx
                        db      81h,0c6h        ; ADD ESI,INC2
                        inc2    dd ?
        dec     ecx
        jnz     short line_loop
        dont_draw_line:
        ret

Line    endp

.data?
y_increment     dd ?
x_increment     dd ?
dest_pointer    dd ?
size_x          dd ?
size_y          dd ?
trash           dd ?
x1              dd ?
y1              dd ?

end
