; 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;  SpanBuffering                                             Coded by Nitro!
;                                                                   16-7-98
;
; 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
SCREENX         EQU     320
SCREENY         EQU     400


CarryOutput equ 1

.386p
.model flat
.stack 100h
.data

    MaxSpan =   100 ; 100 spans per line

    span    struc
       Next dd  ?
       Back dd  ?
       texp dd  ?
       lmap dd  ?
         tp dd  ?
         x1 dd  ?
         x2 dd  ?
         iz dd  ?
         u1 dd  ?
         v1 dd  ?
         u2 dd  ?
         v2 dd  ?
        diz dd  ?
        du1 dd  ?
        dv1 dd  ?
        du2 dd  ?
        dv2 dd  ?
    ends
pepe    span    {x1=110, x2=SCREENX-1, iz=0.0000001, u1=0.0, v1=0.0, diz=0.0, du1=65536.0, dv1=5536.0, texp=offset texture, tp=3}
void    span    {x1=0, x2=SCREENX-1, iz=0.0000000, diz=0.0,texp=0, tp=1}
cte_65536       dd     65536.0
cte_65536_orig  dd     8536.0
angulo          dd     0.0
uincr           dd     0.0
vincr           dd     0.0
grado           dd     0.017453292
movimiento      dd     255.12345
ctemov          dd     -1.0
cteorig         dd     -100.0
cleanmode       db     0
.code
        include utils.inc
        include sgl.inc
        include littable.inc
        include filesys.inc
        include sbuflib.inc
        includelib ttl.lib
        includelib sbuflib.lib
        extrn   insertSpan:near

        assume  cs:@code, ds:@data, es:@data
start:
        InitDPMI
        call    InitSGL
        jc      ErrorInit

        mov     edx, offset Filename
        mov     al, 0
        call    ttl_open
        or      eax,eax
        jz      Error01
        mov     handle, ax        

        mov     ah,42h
        mov     al,0
        mov     bx,handle
        xor     ecx, ecx
        mov     edx,32;2336;16+768

        int     21h
        jc      Error01        

        mov     ah,3fh
        mov     bx,handle
        mov     ecx,768
        mov     edx,offset pal1
        int     21h
        jc      Error01

        mov     ah,3fh
        mov     bx,handle
        mov     ecx,256*256
        mov     edx,offset texture
        int     21h
        jc      Error01

        call    ttl_Close
        jc      Error01


        mov     esi, offset pal1
        mov     ecx, 768
buclepal2:
        mov     al, [esi]
        shr     al, 2
        mov     [esi], al
        inc     esi
        loop    buclepal2

        mov     esi, offset pal1
        mov     edi, offset litmap
        mov     eax, 3
        call    CreateLitTable


        mov     eax, SCREENX
        mov     ebx, SCREENY
        mov     ecx, 16
        call    SetVideoMode
        jc      errorset

        mov     eax, SCREENY
        call    CreateSBuffer
        jc      ErrorSbuffer
        mov     MySbuffer, eax

        cli
mainbucle:

       mov     eax, MySbuffer
       call    InitSbuffer

       cmp    cleanmode, 0
       jne    dontclean1

       mov      ecx, SCREENY
voidspan:
       push     ecx
        mov     eax, MySbuffer
        mov     ebx, offset void
        dec     ecx
        call    InsertSpan
       pop      ecx
       loop     voidspan

       jmp      dontclean2
dontclean1:
      call    GetAvailPage
      mov     edi, eax
      mov     ecx, (SCREENX)*SCREENY*2/4
      mov     eax, (0001100011100011b shl 16) + 0001100011100011b
      rep     stosd
dontclean2:

       fldz
       fst     [pepe.u1]
       fstp    [pepe.v1]
       fld     angulo 
       fadd    grado
       fst     angulo
       fsincos
       fld     st
       fmul    cte_65536_orig
       fadd    cte_65536_orig
       fadd    cte_65536_orig
       fstp    cte_65536
       fmul    cte_65536
       fst     [pepe.du1]
       fst     [vincr]
       fmul    movimiento
       fadd    [pepe.u1]
       fadd    [pepe.v1]
       fsub    [pepe.dv1]
       fadd    [pepe.du1]
       fadd    [pepe.du1]
       fadd    [uincr]

       fstp    [pepe.u1]
       fmul    cte_65536
       fst     [pepe.dv1]
       fst     [uincr]
       fmul    movimiento
       fadd    [pepe.v1]
       fadd    [pepe.u1]
       fsub    [pepe.du1]
       fadd    [pepe.dv1]
       fadd    [vincr]
       
       fstp    [pepe.v1]

       mov      ecx, SCREENY
buclespan:
       push     ecx


        mov     eax, MySbuffer
        mov     ebx, offset pepe
        dec     ecx
        call    InsertSpan

       fld     [pepe.v1]
       fsub    [pepe.du1]
       fstp    [pepe.v1]
       fld     [pepe.u1]
       fadd    [pepe.dv1]
       fstp    [pepe.u1]

       pop      ecx
       loop     buclespan


       mov     edi, MySbuffer
       mov     ebp, offset Polytest
;       call    FastTexturedTriangle

       mov     edi, MySbuffer
       mov     ebp, offset Polytest3
   ;    call    FastTexturedTriangle

       mov     edi, MySbuffer
       mov     ebp, offset Polytest2
   ;    call    FastTexturedTriangle

       mov     edi, MySbuffer
       mov     esi, offset Polytest4
       call    TexTriangleFM

       mov     edi, MySbuffer
       mov     esi, offset Polytest5
       call    TexTriangleFM

      call    GetAvailPage
      mov     edi, eax

      mov     eax, MySbuffer
      mov     ecx, SCREENX
      call    RenderSpanBuffer

      call    ShowPage


        ;mov     ah, 1
        ;int     16h
        ;jz      mainbucle
        ;xor     ah, ah
        ;int     16h
        in      al, 60h

        cmp     al,1eh
;        'a'
        jne     tecla3

        fld     dword ptr [point13+4]
        fld1
        faddp
        fstp    dword ptr [point13+4]

tecla3:

        cmp     al, 10h;'q'
        jne     tecla4

        fld     dword ptr [point13+4]
        fld1
        fsubp
        fstp    dword ptr [point13+4]

tecla4:

        cmp     al, 19h;'p'
        jne     tecla1

        fld     dword ptr [point13]
        fld1
        faddp
        fstp    dword ptr [point13]

tecla1:

        cmp     al, 18h; 'o'
        jne     tecla2

        fld     dword ptr [point13]
        fld1
        fsubp
        fstp    dword ptr [point13]

tecla2:


        cmp     al, 21h;'f'
        jne     tecla5

        fld     dword ptr [point15+4]
        fld1
        faddp
        fstp    dword ptr [point15+4]

tecla5:

        cmp     al, 13h;'r'
        jne     tecla6

        fld     dword ptr [point15+4]
        fld1
        fsubp
        fstp    dword ptr [point15+4]

tecla6:

        cmp     al, 15h;'y'
        jne     tecla7

        fld     dword ptr [point15]
        fld1
        faddp
        fstp    dword ptr [point15]

tecla7:

        cmp     al, 14h;'t'
        jne     tecla8

        fld     dword ptr [point15]
        fld1
        fsubp
        fstp    dword ptr [point15]

tecla8:

        cmp     al, 30h;'b'
        jne     tecla9

        fld     dword ptr [point14+4]
        fld1
        faddp
        fstp    dword ptr [point14+4]

tecla9:

        cmp     al, 22h;'g'
        jne     tecla10

        fld     dword ptr [point14+4]
        fld1
        fsubp
        fstp    dword ptr [point14+4]

tecla10:

        cmp     al, 24h;'j'
        jne     tecla11

        fld     dword ptr [point14]
        fld1
        faddp
        fstp    dword ptr [point14]

tecla11:

        cmp     al, 23h;'h'
        jne     tecla12

        fld     dword ptr [point14]
        fld1
        fsubp
        fstp    dword ptr [point14]

tecla12:
        cmp     al, 2
        jne     tecla13

        dec      [pepe.x1]

tecla13:
        cmp     al, 3
        jne     tecla14

        inc      [pepe.x1]

tecla14:
        cmp     al, 4
        jne     tecla15

        dec      [pepe.x2]

tecla15:
        cmp     al, 5
        jne     tecla16

        inc      [pepe.x2]

tecla16:
        cmp     al,0fh 
        jne     tecla17

        mov     cleanmode, 1

tecla17:
        cmp     al,2ch 
        jne     tecla18

        mov     cleanmode, 0

tecla18:

        cmp     al, 9
        jne     tecla19

        fld     ctemov
        fadd    movimiento
        fstp    movimiento

tecla19:

        cmp     al, 10
        jne     tecla20

        fld     movimiento
        fsub    ctemov
        fstp    movimiento

tecla20:

        cmp     al, 7
        jne     tecla21

        fld     cteorig
        fadd    cte_65536_orig
        fstp    cte_65536_orig

tecla21:

        cmp     al, 8
        jne     tecla22

        fld     cte_65536_orig
        fsub    cteorig
        fstp    cte_65536_orig

tecla22:

        cmp     al, 1

        jne     mainbucle
        sti
        mov     ax, 3
        call    UnSetVideoMode
exitlabel:
        exit
errorinit:
        print   texto1
        jmp     exitlabel
errorset:
        print   texto3
        jmp     exitlabel
ErrorSbuffer:
        print   texto2
        jmp     exitlabel

texto1  db ' Error in InitSGL',13,10,0
texto2  db ' Error creating Span-Buffer',13,10,0
texto3  db ' Error in SetVideoMode: Mode is not valid!',13,10,0

    Error01:
        print   texterror
        mov     ah, 4ch
        int     21h



texterror   db  'Error al cargar el archivo',0
filename    db  'trez.raw',0
handle      dw  0

MySbuffer   dd  0

    polytest    dd  offset texture
                dd  offset point1
                dd  offset point13
                dd  offset point15


    point1      dd  0.0
                dd  0.0
                dd  128.0
                dd  128.0
                dd  421.0

    point2      dd  319.0
                dd  0.0
                dd  255.0
                dd  255.0
                dd  421.0
                
    point3      dd  0.0
                dd  399.0
                dd  255.0
                dd  0.0
                dd  421.0

    polytest2   dd  offset texture
                dd  offset point4
                dd  offset point5
                dd  offset point6


    point4      dd  319.0
                dd  0.0
                dd  0.0
                dd  0.0
                dd  1.0

    point5      dd  0.0
                dd  399.0
                dd  255.0
                dd  255.0
                dd  1.0
                
    point6      dd  319.0
                dd  399.0
                dd  255.0
                dd  0.0
                dd  1.0

    polytest3   dd  offset texture
                dd  offset point7
                dd  offset point8
                dd  offset point9

    polytest4   dd  offset texture
                dd  offset point14
                dd  offset point11
                dd  offset point15

    polytest5   dd  offset texture
                dd  offset point13
                dd  offset point14
                dd  offset point15


    point7      dd  1.0
                dd  50.0
                dd  0.0
                dd  0.0
                dd  22341.0

    point8      dd  15.0
                dd  340.0
                dd  255.0
                dd  255.0
                dd  23441.0
                
    point9      dd  317.0
                dd  80.0
                dd  255.0
                dd  0.0
                dd  23241.0


    point13     dd  10.0
                dd  10.0
                dd  5.0
                dd  5.0
                dd  0.4

    point14     dd  200.0
                dd  10.0
                dd  255.0
                dd  5.0
                dd  0.4
                
    point15     dd  10.0
                dd  200.0
                dd  5.0
                dd  255.0
                dd  0.4

    point10     dd  200.0
                dd  10.0
                dd  255.0
                dd  5.0
                dd  0.4

    point11     dd  200.0
                dd  200.0
                dd  255.0
                dd  255.0
                dd  0.4
                
    point12     dd  10.0
                dd  200.0
                dd  5.0
                dd  255.0
                dd  0.4
.data?
align       16
texture     db 256*256 dup (?)
litmap      db 256*32*2 dup (?)
pal1        db 768 dup (?)

end start
