;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  [tDR], 1998                                    Copyright the DarkRising
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³                                      Coded by:              Nitro!
;³  VBE 1.00-3.0 Driver 1.00b           Support & BugFixed by: Teknik, B52
;³
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  DATE         REVISION           AUTHOR & COMMENTS
;³  ÄÄÄÄÄÄÄÄ     ÄÄÄÄÄÄÄÄÄÄÄÄÄ      ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  13-11-98     Version 1.00b      Nitro! : First Version
;³  17-04-99     Continue           Nitro!
;³  14-05-99     Lineal, Banked     Nitro!
;³               sin emulmodes
;³  15-05-99     Emulacion de los
;³               modos 16 sin 5:6:5 Nitro!
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Estructura de informacion VESA
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
VESAInfo        struc
        ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        ;³ Estructura del estandar VESA v1.0
        ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        VESASignature   db 'VBE2'       ; Firma del estandar VESA
        VESAVersion     dw ?            ; Version de VESA
        OEMNamePtr      dd ?            ; Puntero al nombre OEM
        CapabFlags      dd ?            ; Banderas de capacidades
        ModeListPtr     dd ?            ; Puntero a la lista de modos
        TotalVidMemory  dw ?            ; Memoria de video en bloques de 64k
        ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        ;³ Estandar VESA v2.0
        ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        OEMSoftVersion  dw ?            ; Version del software VESA
        VendorNamePtr   dd ?            ; Puntero al nombre del vendedor
        ProductNamePtr  dd ?            ; Puntero al nombre del producto
        ProductRevPtr   dd ?            ; Puntero a la cadena de revision
                                        ; del producto
                        db 222 dup (?)  ; Reservado
                        db 256 dup (?)  ; Reservado para OEM
VESAInfo        ends
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Estructura de informacion de modos VESA
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
VESAModeInfo    struc
        ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        ;³ Estructura del estandar VESA v1.0
        ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        ModeAttrib      dw ?            ; Atributos del modo de video
        WinAAttrib      db ?            ; Atributos de la ventana A
        WinBAttrib      db ?            ; Atributos de la ventana B
        WinGran         dw ?            ; Granularidad de las ventanas en kb
        WinSize         dw ?            ; Tama¤o de las ventanas en kb
        StartSegA       dw ?            ; Segmento de inicio de la ven. A
        StartSegB       dw ?            ; Segmento de inicio de la ven. B
        WinPosPtr       dd ?            ; Puntero a la funcion de cambio
                                        ; de posicion.
        ByteScanLine    dw ?            ; Bytes por scanline
        ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        ;³ Parte opcional del estandar VESA v1.0 y v1.1 (Necesaria para OEM)
        ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        XSize           dw ?            ; Tama¤o X del modo (pixels)
        YSize           dw ?            ; Tama¤o Y del modo (pixels)
        XChar           db ?            ; Tama¤o X de un caracter (pixels)
        YChar           db ?            ; Tama¤o Y de un caracter (pixels)
        NumMemPlanes    db ?            ; Numero de planos de memoria
        NumBitPixel     db ?            ; Numero de bits por pixel
        NumBanks        db ?            ; Numero de bancos
        MemModelType    db ?            ; Tipo de modelo de memoria
        SizeOfBank      db ?            ; Tama¤o del banco en kb
        NumPages        db ?            ; Numero de paginas de imagen
                        db 0            ; Reservado
        ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        ;³ Estandar VESA v1.2
        ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        RedMaskSize     db ?            ; Tama¤o de la mascara de rojo
        RedFieldPos     db ?            ; Posicion del campo de rojo
        GreenMaskSize   db ?            ; Tama¤o de la mascara de verde
        GreenFieldPos   db ?            ; Posicion del campo de verde
        BlueMaskSize    db ?            ; Tama¤o de la mascara de azul
        BlueFieldPos    db ?            ; Posicion del campo de azul
        ReservMaskSize  db ?            ; Reservado (tama¤o de la mascara)
        ReservFieldPos  db ?            ; Reservado (posicion del campo)
        DirectColorInfo db ?            ; Informacion del modo DirectColor
        ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        ;³ Estandar VESA v2.0
        ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        PhysAdress      dd ?            ; Direccion fisica de la memoria
                                        ; de video lineal
        OffscreenPtr    dd ?            ; Direccion de comienzo de la memoria
                                        ; que esta fuera de pantalla
        OffscreenSize   dw ?            ; Tama¤o de la memoria fuera de
                                        ; pantalla
                        db 206 dup (?)  ; Reservado
VESAModeInfo    ends

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Datos del driver
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.data?
BaseMemorySelector      dw      ?
BaseMemoryBuffer        dd      ?
BaseMemorySegment       dw      ?
TotalVideoMemory        dd      ?
VBEVersion              dw      ?
BaseMemorySelector2     dw      ?
BaseMemoryBuffer2       dd      ?
BaseMemorySegment2      dw      ?
.data
    DRVBE_text1     db '     ş VBE Driver 1.25 initialized Ok!',13,10,0
    DRVBE_text2     db '     ş VBE Driver 1.25 uninstalled Ok!',13,10,0
    DRVBE_text3     db '          ş VESA Version %bn'
                    dd offset VBEVersion+1
                    db '.%bn'
                    dd offset VBEVersion
                    db 13,10
                    db '          ş Video memory in board %dn'
                    dd offset TotalVideoMemory
                    db ' Kb.',13,10
                    db '          ş OEM Name: %s'
    DRVBE_text5     dd ?
                    db 13,10
    EnableV200      db 0,'         ş Vendor Name: %s'
    DRVBE_text6     dd ?
                    db 13,10
                    db '          ş Product Name: %s'
    DRVBE_text7     dd ?
                    db 13,10
                    db '          ş Product Revision: %s'
    DRVBE_text8     dd ?
                    db 13,10, 0
    DRVBE_text4     db '          ş VBE Protected Mode Extensions available',13,10,0

SetStart_           dd  ?
SetStartProtected   dd  ?
SetBank_            dd  ?

.code
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      GetModeInfo:    Obtiene informacion de un modo VESA
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Entrada:        EAX : Modo del que se quiere obtener informacion
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³      Salida:         Estructura ModeInfobl rellenado
;³                      Carry cuando hay error (EAX = SGL_ERROR)
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetModeInfo proc

;   Rellena la estructura de informacion del modo
        mov     cx,ax
        mov     ax,BaseMemorySegment
        mov     RealESSegment,ax
        mov     ax,04f01h
        xor     edi,edi
        push    10h
        call    RealInterrupt

;   Comprobamos que la funcion ha sido soportada
        cmp     ax,004fh
        ;breakp  "Fucion 4f01 devuelve:", eax
        jne     Modenotgood

;   Comprobamos si el modo es un modo valido
        mov     esi, BaseMemoryBuffer
        mov     bx, [VESAModeInfo PTR esi.ModeAttrib]
        test    bx, 0000001b
        jz      Modenotgood

;   Reparamos la antigua definicion de modos en las versiones 1.1
        cmp     [VESAModeInfo PTR esi.MemModelType], 4 ; Packed mode
        jne     notoldbios11

        mov     bl, [VESAModeInfo PTR esi.NumBitPixel]
        cmp     bl, 8
        jbe     notoldbios11

        mov     [VESAModeInfo PTR esi.MemModelType], 6 ; RGB mode

        cmp     bl, 15
        jne     skipvideo15
        mov     [VESAModeInfo PTR esi.RedMaskSize], 5
        mov     [VESAModeInfo PTR esi.RedFieldPos], 10
        mov     [VESAModeInfo PTR esi.GreenMaskSize], 5
        mov     [VESAModeInfo PTR esi.GreenFieldPos], 5
        mov     [VESAModeInfo PTR esi.BlueMaskSize], 5
        mov     [VESAModeInfo PTR esi.BlueFieldPos], 0
        mov     [VESAModeInfo PTR esi.ReservMaskSize], 1
        mov     [VESAModeInfo PTR esi.ReservFieldPos], 15
skipvideo15:
        cmp     bl, 16
        jne     skipvideo16
        mov     [VESAModeInfo PTR esi.RedMaskSize], 5
        mov     [VESAModeInfo PTR esi.RedFieldPos], 11
        mov     [VESAModeInfo PTR esi.GreenMaskSize], 5
        mov     [VESAModeInfo PTR esi.GreenFieldPos], 5
        mov     [VESAModeInfo PTR esi.BlueMaskSize], 5
        mov     [VESAModeInfo PTR esi.BlueFieldPos], 0
        mov     [VESAModeInfo PTR esi.ReservMaskSize], 0
        mov     [VESAModeInfo PTR esi.ReservFieldPos], 0
skipvideo16:
        cmp     bl, 24
        jne     skipvideo24
        mov     [VESAModeInfo PTR esi.RedMaskSize], 8
        mov     [VESAModeInfo PTR esi.RedFieldPos], 16
        mov     [VESAModeInfo PTR esi.GreenMaskSize], 8
        mov     [VESAModeInfo PTR esi.GreenFieldPos], 8
        mov     [VESAModeInfo PTR esi.BlueMaskSize], 8
        mov     [VESAModeInfo PTR esi.BlueFieldPos], 0
        mov     [VESAModeInfo PTR esi.ReservMaskSize], 0
        mov     [VESAModeInfo PTR esi.ReservFieldPos], 0
skipvideo24:
notoldbios11:

;   Convertimos los modos de 32k de color de las version 1.2+ en modos 15 bits
        cmp     bl, 16
        jne     not32kconvert
        cmp     [VESAModeInfo PTR esi.ReservMaskSize], 1
        jne     not32kconvert
        mov     [VESAModeInfo PTR esi.NumBitPixel], 15
not32kconvert:
;   El modo es correcto ;)
        mov     eax, SGL_OK
        clc
        ret

Modenotgood:
;   El modo no es correcto
        mov     eax, SGL_ERROR
        stc
        ret
        endp
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

SGLAllocBase    proc
        mov     ax, 100h
        mov     bx, 1024/16     ; Pedimos espacio de sobras 8)
        int     31h
        jc      SGLALLOCBASE_ErrorExit
        mov     BaseMemorySegment, ax
        mov     BaseMemorySelector, dx
        and     eax,0ffffh
        shl     eax,4
        mov     BaseMemoryBuffer,eax    ; Puntero cercano al buffer
                                        ; en la memoria base.
        mov     ax, 100h
        mov     bx, 1024/16     ; Pedimos espacio de sobras 8)
        int     31h
        jc      SGLALLOCBASE_ErrorExit
        mov     BaseMemorySegment2, ax
        mov     BaseMemorySelector2, dx
        and     eax,0ffffh
        shl     eax,4
        mov     BaseMemoryBuffer2,eax    ; Puntero cercano al buffer
                                        ; en la memoria base.
        mov     eax, SGL_OK
        clc
        ret
SGLALLOCBASE_ErrorExit:
        mov     eax, SGL_NOMEM
        stc
        ret
        endp
SGLFreeBase     proc
        mov     ax, 101h
        mov     dx, BaseMemorySelector
        int     31h
        mov     ax, 101h
        mov     dx, BaseMemorySelector2
        int     31h
        ret
        endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Inicializacion del driver
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VBE_Init     proc

;   Ponemos la variables a sus valores iniciales para posibles reinicializaciones
;   de la new!SGL
            mov     EnableV200, 0
            mov     SetStart_, offset SetStart_Real
            mov     SetBank_, offset SetBank_Real
;   alojamos un buffer en la memoria base

            call    SGLAllocBase
            jc      DRIVER_VBE_ErrorExit2

;   si hay un driver de VESA 2.00+ pedimos la informacion extra
            mov     eax, BaseMemoryBuffer2
            mov     dword ptr [eax], '2EBV'

;   pedimos a la BIOS k rellene el buffer
            mov     ax, BaseMemorySegment2
            mov     RealESSegment, ax
            mov     ax, 04f00h
            xor     edi, edi
            push    10h
            call    RealInterrupt

;   miramos si almenos existe un driver VESA
            cmp     ax, 004fh
            jne     DRIVER_VBE_ErrorExit

            mov     eax, BaseMemoryBuffer2
            cmp     dword ptr [eax], 'ASEV'
            jne     DRIVER_VBE_ErrorExit


;   Obtenemos la version VESA
            mov     esi, BaseMemoryBuffer2
            mov     ax, [VESAInfo PTR esi.VESAVersion]
            mov     VBEVersion, ax

;   Corregimos el BUG de algunas BIOS antiguas que retornaban mal la version

            cmp     VBEVersion, 200h
            jne     thereisnobug
            cmp     [VESAInfo PTR esi.VendorNamePtr], 0
            jne     thereisnobug
            mov     VBEVersion, 102h
            mov     [VESAInfo PTR esi.VESAVersion], 102h
thereisnobug:

;   Convertimos los punteros lejanos en punteros near

            mov     eax, [VESAInfo PTR esi.OEMNamePtr]
            call    RealAddress
            mov     [VESAInfo PTR esi.OEMNamePtr], eax
            mov     DRVBE_text5, eax

            mov     eax, [VESAInfo PTR esi.ModeListPtr]
            call    RealAddress
            mov     [VESAInfo PTR esi.ModeListPtr], eax


            cmp     VBEVersion, 200h        ; estos campos solo pertenecen
            jb      VBEINI001               ; a las versiones >= 2.00

            mov     EnableV200, ' '         ; Imprimimos informacion
                                            ; extra de versiones >= 2.00

            mov     eax, [VESAInfo PTR esi.VendorNamePtr]
            call    RealAddress
            mov     [VESAInfo PTR esi.VendorNamePtr], eax
            mov     DRVBE_text6, eax

            mov     eax, [VESAInfo PTR esi.ProductNamePtr]
            call    RealAddress
            mov     [VESAInfo PTR esi.ProductNamePtr], eax
            mov     DRVBE_text7, eax

            mov     eax, [VESAInfo PTR esi.ProductRevPtr]
            call    RealAddress
            mov     [VESAInfo PTR esi.ProductRevPtr], eax
            mov     DRVBE_text8, eax
VBEINI001:

;   Calculamos la memoria total

            movzx   eax, [VESAInfo PTR esi.TotalVidMemory]
            shl     eax, 6
            mov     TotalVideoMemory, eax

            iprint   DRVBE_text1
            iprint   DRVBE_text3

;   Miramos si existe el interfaz de modo protegido
            mov     ax, 4f0ah
            xor     bx, bx
            push    10h
            call    RealInterrupt
            cmp     ax, 004fh
            jne     Noprotectedmode
            mov     ax, RealESSegment
            shl     eax, 16
            mov     ax, di
            call    RealAddress
            xor     ebx, ebx
            mov     bx, [eax+2]
            add     ebx, eax
            mov     [SetStartProtected], ebx
            xor     ebx, ebx
            mov     bx, [eax]
            add     ebx, eax
            mov     [SetBank_], ebx

            mov     eax, offset SetStart_Protected
            mov     [SetStart_], eax

            iprint   DRVBE_text4

Noprotectedmode:

;   A¤adimos los modos VESA disponibles a la lista general de modos

            mov     ebx, BaseMemoryBuffer2
            mov     ecx, 0cafeh
            mov     edi, [VESAInfo PTR ebx.ModeListPtr]
            mov     ebx, BaseMemoryBuffer
insertVESAModes:
            xor     eax, eax
            mov     ax, [edi]
            ;breakp  "Encontrado modo:", eax
            add     edi, 2
            cmp     ax, 0ffffh
            je      insertVESAModesEnd
            push    edi eax ebx
            call    GetModeInfo
            pop     ebx eax edi
            jc      insertVESAModes

            mov     word ptr ModeTemp.DriverData[0], ax

            mov     ModeTemp.driver, DR_VBE
            movzx   ecx, [VESAModeInfo PTR ebx.XSize]
            ;breakp  "              X:", ecx
            mov     ModeTemp.Xresolution, ecx
            movzx   ecx, [VESAModeInfo PTR ebx.YSize]
            ;breakp  "              Y:", ecx
            mov     ModeTemp.Yresolution, ecx
            movzx   ecx, [VESAModeInfo PTR ebx.NumBitPixel]
            ;breakp  "              C:", ecx
            mov     ModeTemp.ColorBits, ecx
            mov     ModeTemp.ModeType, 0

            add     ecx, 7
            shr     ecx, 3
            mov     ModeTemp.BytesPerPixel, ecx

            push    ebx ; Salvamos el puntero a la informacion VESA
            push    eax ; Salvamos el numero del modo actual
            push    edi

            movzx   ecx, [VESAModeInfo PTR ebx.XSize]
            ;breakp  <13,10,"Tama¤o X:">, ecx
            movzx   eax, [VESAModeInfo PTR ebx.YSize]
            ;breakp  <13,10,"Tama¤o Y:">, eax
            movzx   ebx, [VESAModeInfo PTR ebx.NumBitPixel]
            ;breakp  <13,10,"ColorBits:">, ebx
            call    CalcSizeDD
            mov     ModeTemp.DDSize, eax



            pop     edi
            pop     eax
            pop     ebx

            cmp     [VESAModeInfo PTR ebx.NumBitPixel], 16
            jne     DontMakeColorConversion

;   Comprobamos que los bits estan normalmente sino pasamos el modo
;   como emulado para hacer la conversion
            xor     eax, eax
            mov     al, [VESAModeInfo PTR ebx.RedMaskSize]
            ;breakp  <13,10,"RedMaskSize:">, eax
            mov     al, [VESAModeInfo PTR ebx.RedFieldPos]
            ;breakp  <13,10,"RedFieldPos:">, eax
            mov     al, [VESAModeInfo PTR ebx.GreenMaskSize]
            ;breakp  <13,10,"GreenMaskSize:">, eax
            mov     al, [VESAModeInfo PTR ebx.GreenFieldPos]
            ;breakp  <13,10,"GreenFieldPos:">, eax
            mov     al, [VESAModeInfo PTR ebx.BlueMaskSize]
            ;breakp  <13,10,"BlueMaskSize:">, eax
            mov     al, [VESAModeInfo PTR ebx.BlueFieldPos]
            ;breakp  <13,10,"BlueFieldPos:">, eax

            cmp     [VESAModeInfo PTR ebx.RedMaskSize], 5
            jne     MakeColorConversion
            cmp     [VESAModeInfo PTR ebx.RedFieldPos], 11
            jne     MakeColorConversion
            cmp     [VESAModeInfo PTR ebx.GreenMaskSize], 6
            jne     MakeColorConversion
            cmp     [VESAModeInfo PTR ebx.GreenFieldPos], 5
            jne     MakeColorConversion
            cmp     [VESAModeInfo PTR ebx.BlueMaskSize], 5
            jne     MakeColorConversion
            cmp     [VESAModeInfo PTR ebx.BlueFieldPos], 0
            jne     MakeColorConversion
            jmp     DontMakeColorConversion

MakeColorConversion:
            mov     eax, dword ptr [VESAModeInfo PTR ebx.RedMaskSize]
            mov     dword ptr ModeTemp.DriverData[32-6], eax
            mov     ax, word ptr [VESAModeInfo PTR ebx.BlueMaskSize]
            mov     word ptr ModeTemp.DriverData[32-2], ax

            mov     ModeTemp.ModeType, MT_Emulated
            movzx   ecx, [VESAModeInfo PTR ebx.XSize]
            mov     ModeTemp.RealX, ecx
            movzx   ecx, [VESAModeInfo PTR ebx.YSize]
            mov     ModeTemp.RealY, ecx
            movzx   ecx, [VESAModeInfo PTR ebx.NumBitPixel]
            mov     ModeTemp.RealC, ecx
            mov     ModeTemp.EmulType, ET_Color
            mov     ecx, ModeTemp.BytesPerPixel
            mov     ModeTemp.RealBPP, ecx


DontMakeColorConversion:

            mov     cx, [VESAModeInfo PTR ebx.ModeAttrib]
            test    cx, 10000000b

            jnz     LinearModeavail

;   Modo banked de solo una pagina

            mov     ModeTemp.Npages, 1  ; 1 pagina
            mov     byte ptr ModeTemp.DriverData[2], 1 ; banked mode
            mov     cx, [VESAModeInfo PTR ebx.WinGran]
            mov     word ptr ModeTemp.DriverData[3], cx ; Granularidad bancos
            mov     cx, [VESAModeInfo PTR ebx.WinSize]
            mov     word ptr ModeTemp.DriverData[5], cx ; tama¤o de bancos


;   Miramos si la ventana A es valida para escritura
            mov     al, [VESAModeInfo PTR ebx.WinAattrib]
            test    al, 1
            jz      WinANotValid
            test    al, 100b
            jz      WinANotValid

            movzx   eax, [VESAModeInfo PTR ebx.StartSegA]
            shl     eax, 4
            mov     dword ptr ModeTemp.DriverData[7], eax ; segmento de escritura
            mov     byte ptr ModeTemp.DriverData[11],  0; ventana de escritura
            jmp     FoundValidWindow
WinANotValid:
;   Miramos si la ventana B es valida para escritura
            mov     al, [VESAModeInfo PTR ebx.WinBattrib]
            test    al, 1
            jz      insertVESAModes     ; Is not a valid mode
            test    al, 100b
            jz      insertVESAModes     ; Is not a valid mode

            movzx   eax, [VESAModeInfo PTR ebx.StartSegB]
            shl     eax, 4
            mov     dword ptr ModeTemp.DriverData[7], eax ; segmento de escritura
            mov     byte ptr ModeTemp.DriverData[11],  1; ventana de escritura

FoundValidWindow:

            mov     esi, offset ModeTemp
            push    edi ebx
            call    AddMode
            pop     ebx edi
            jc      DRIVER_VBE_ErrorExit
            jmp     insertVESAModes

LinearModeavail:
    ; Calcularemos el numero de paginas a mano debido a que determinadas
    ; tarjetas devuelven un numero erroneo
;            mov     cl, [VESAModeInfo PTR ebx.NumPages]
;            inc     cl
;            mov     ModeTemp.Npages, cl

            mov     eax, TotalVideoMemory
            shl     eax, 10
            mov     ecx, ModeTemp.DDSize
            shl     ecx, 2
            div     ecx
            mov     ModeTemp.Npages, al


            mov     byte ptr ModeTemp.DriverData[2], 2 ; linear mode

            mov     ecx, [VESAModeInfo PTR ebx.PhysAdress]
            mov     dword ptr ModeTemp.DriverData[3], ecx ; linearframebuffer
            mov     ecx, TotalVideoMemory
            shl     ecx, 10
            mov     dword ptr ModeTemp.DriverData[7], ecx ; Memoria SVGA
            mov     esi, offset ModeTemp
            push    edi ebx
            call    AddMode
            pop     ebx edi
            jc      DRIVER_VBE_ErrorExit
            jmp     insertVESAModes

insertVESAModesEnd:
            mov     eax, SGL_OK
            clc
            ret
DRIVER_VBE_ErrorExit:
            mov     eax, SGL_ERROR
            stc
            ret
DRIVER_VBE_ErrorExit2:
            stc
            ret
            endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Desinicializacion del driver
;³	Input: AL = 0 for verbose, 1 for silent
;³	Output: EAX = SGL_OK, CF = 0
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VBE_UnInit   proc
            ;   Liberamos la memoria base alojada
			push	eax
            mov     ax, 101h
            mov     dx, BaseMemorySelector
            int     31h
			pop		eax
            jc      VBE_UnInit_ExitError

			or		al,al
			jnz		drvbe_uninit_silent
            ;   Texto de salida
            eprint  DRVBE_text2
			drvbe_uninit_silent:

            mov     eax, SGL_OK
            clc
            ret
VBE_UnInit_ExitError:
            mov     eax, SGL_NOMEM
            stc
            ret
            endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Inicializacion del modo de video
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.data?
BankedBytesPerLine  dd  ?
.code
DRIVER_VBE_SetBankedMode    proc

            mov     DVBEActivePage, 0
            mov     ecx, dword ptr [ActualMode.DriverData][7]
            mov     DVBEAvailPagePtrBase, ecx

            ; Calculamos el numero de bancos por ventana
            xor     eax, eax
            mov     ax, word ptr [ActualMode.DriverData][5]
            ;breakp  "el tama¤o del banco es ", eax
            shl     eax, 8
            mov     VBE_Banked_WinSizedd, eax
            xor     ebx, ebx
            mov     bx, word ptr [ActualMode.DriverData][3]
            ;breakp  "La granularidad es ", ebx
            shl     ebx, 8
            div     ebx
            mov     VBE_Banked_NBanks, eax
            ;breakp  "Numero de bancos ", eax

            ; Obtenemos la ventana que utilizaremos
            mov     al, byte ptr [ActualMode.DriverData][11]
            mov     VBE_Banked_BankWindow, al

            ; Alojamos la memoria necesaria para el modo
            mov     ecx, [ActualMode.DDSize]
            shl     ecx, 2
            add     ecx, 8
            call    malloc

            or      ebx, ebx
            jz      DRIVER_VBE_SetBankedMode_error
            mov     OriginalMemBuffer, ebx
            add     ebx, 7
            and     ebx, not 111b
            mov     DVBEAvailPagePtr, ebx

            shr     ecx, 2      ; Borramos el buffer alojado
            mov     edi, ebx
            xor     eax, eax
            rep     stosd

            mov     bx, word ptr [ActualMode.DriverData][0]
            mov     ax, 4f02h
            int     10h

            cmp     ax, 004fh
            jne     DRIVER_VBE_SetBankedMode_error

            mov     eax, [ActualMode.XResolution]
            imul    eax, [ActualMode.BytesPerPixel]
            mov     BankedBytesPerLine, eax

            mov     ecx, [ActualMode.XResolution]
            mov     ax, 4f06h  ; ponemos el ancho del modo al indicado
            mov     bl, 0      ; para corregir un error en las trident
            int     10h        ; si nos deja claro XD
            cmp     ax, 004fh
            jne     DRIVER_VBE_SkipSetLength
            movzx   ecx, cx
            movzx   ebx, bx
            ;breakp  "Ancho de video", ecx
            ;breakp  "Bytes per line", ebx
            mov     BankedBytesPerLine, ebx
DRIVER_VBE_SkipSetLength:
            clc
            mov     eax, SGL_OK
            ret
DRIVER_VBE_SetBankedMode_error:
            stc
            mov     eax, SGL_ERROR
            ret
            endp

DRIVER_VBE_SetSinglePageLinearMode  proc
            mov     DVBEActivePage, 0
            mov     ecx, dword ptr [ActualMode.DriverData][3]
            mov     esi, dword ptr [ActualMode.DriverData][7]
            call    MapMemory
            jc      DRIVER_VBE_SetSinglePageLinearMode_error
            mov     DVBEAvailPagePtrBase, ecx

            mov     ecx, [ActualMode.DDSize]
            shl     ecx, 2
            add     ecx, 8
            call    malloc

            or      ebx, ebx
            jz      DRIVER_VBE_SetSinglePageLinearMode_error
            mov     OriginalMemBuffer, ebx
            add     ebx, 7
            and     ebx, not 111b
            mov     DVBEAvailPagePtr, ebx


            shr     ecx, 2      ; Borramos el buffer alojado
            mov     edi, ebx
            xor     eax, eax
            rep     stosd

            mov     bx, word ptr [ActualMode.DriverData][0]
            or      bx, 1 shl 14
            mov     ax, 4f02h
            int     10h

            cmp     ax, 004fh
            jne     DRIVER_VBE_SetSinglePageLinearMode_error

            clc
            mov     eax, SGL_OK
            ret
DRIVER_VBE_SetSinglePageLinearMode_error:
            stc
            mov     eax, SGL_ERROR
            ret
            endp
.data?
    ModeSettings    dd  ?
.code
DRIVER_VBE_SetVideoMode   proc
            mov     ModeSettings, ecx
            test    [ActualMode.ModeType], MT_Emulated
            jnz     DVBE_Emulatedmode


            cmp     byte ptr [ActualMode.DriverData][2], 1
            je      DVBE_SVM_SetBankedMode


            test    ModeSettings, SGL_MemoryBuffer
            jnz     DVBE_SVM_CreateLinearBuffered
            cmp     [TMODE ptr esi.NPages], 1
            je      DVBE_SVM_CreateLinearBuffered

    ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ;³  Inicializacion del modo lineal multipagina
    ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

            mov     DVBEActivePage, 0
            mov     ecx, dword ptr [ActualMode.DriverData][3]
            mov     esi, dword ptr [ActualMode.DriverData][7]
            call    MapMemory
            jc      DVBE_SVM_ErrorExit
            mov     DVBEAvailPagePtrBase, ecx
            mov     DVBEAvailPagePtr, ecx

            mov     UnSetVideoMode_, offset DRIVER_VBE_UnSetVideoMode_LinearMultiPage
            mov     ShowPage_, offset DRIVER_VBE_ShowPage_LinearMultiPage
            mov     GetAvailPage_, offset DRIVER_VBE_GetAvailPage_LinearMultiPage
            mov     WaitRetrace_, offset DRIVER_VBE_WaitRetrace
            mov     GetMemoryPtr_, offset DRIVER_VBE_GetMemoryPtr_Linear

            mov     bx, word ptr [ActualMode.DriverData][0]
            or      bx, 1 shl 14
            mov     ax, 4f02h
            int     10h

            cmp     ax, 004fh
            jne     DVBE_SVM_ErrorExit


            xor     eax, eax
            xor     ebx, ebx
            xor     ecx, ecx
            xor     edx, edx
            call    SetStart

            jmp     DVBE_SVM_OKExit

DVBE_SVM_CreateLinearBuffered:

    ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ;³  Inicializacion del modo lineal de una pagina
    ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
            call    DRIVER_VBE_SetSinglePageLinearMode
            jc      DVBE_SVM_ErrorExit


            mov     UnSetVideoMode_, offset DRIVER_VBE_UnSetVideoMode_LinearSinglePage
            mov     ShowPage_, offset DRIVER_VBE_ShowPage_LinearSinglePage
            mov     GetAvailPage_, offset DRIVER_VBE_GetAvailPage_LinearSinglePage
            mov     WaitRetrace_, offset DRIVER_VBE_WaitRetrace
            mov     GetMemoryPtr_, offset DRIVER_VBE_GetMemoryPtr_Linear

            jmp     DVBE_SVM_OKExit

DVBE_SVM_SetBankedMode:

    ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ;³  Inicializacion del modo banked
    ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
            call    DRIVER_VBE_SetBankedMode
            jc      DVBE_SVM_ErrorExit

            mov     UnSetVideoMode_, offset DRIVER_VBE_UnSetVideoMode_Banked
            mov     ShowPage_, offset DRIVER_VBE_ShowPage_Banked
            mov     GetAvailPage_, offset DRIVER_VBE_GetAvailPage_Banked
            mov     WaitRetrace_, offset DRIVER_VBE_WaitRetrace
            mov     GetMemoryPtr_, offset DRIVER_VBE_GetMemoryPtr_Banked

            jmp     DVBE_SVM_OKExit

DVBE_SVM_OKExit:
            mov     eax, SGL_OK
            clc
            ret
DVBE_Emulatedmode:
            cmp     [ActualMode.EmulType], ET_Color
            je      DVBE_EmulateOnlyColor


            jmp     DVBE_SVM_ErrorExit
DVBE_EmulateOnlyColor:
            mov     eax, [ActualMode.ColorBits]
            cmp     eax, [ActualMode.RealC]
            je      DVBE_EmulateSwapRGBBits

            jmp     DVBE_SVM_ErrorExit
DVBE_EmulateSwapRGBBits:
            cmp     [ActualMode.RealC], 16
            je      DVBE_EmulateSwap16RGBBits
            jmp     DVBE_SVM_ErrorExit

DVBE_EmulateSwap16RGBBits:
            cmp     byte ptr [ActualMode.DriverData][2], 1
            je      DVBE_EmulateSwapRGBBits_banked
            call    DRIVER_VBE_SetSinglePageLinearMode
            jc      DVBE_SVM_ErrorExit

            mov     UnSetVideoMode_, offset DRIVER_VBE_UnSetVideoMode_LinearSinglePage
            mov     ShowPage_, offset DRIVER_VBE_ShowPage_LinearSinglePageSwapRGB
            mov     GetAvailPage_, offset DRIVER_VBE_GetAvailPage_LinearSinglePage
            mov     WaitRetrace_, offset DRIVER_VBE_WaitRetrace
            mov     GetMemoryPtr_, offset DRIVER_VBE_GetMemoryPtr_Banked

            jmp     DVBE_SVM_OKExit
DVBE_EmulateSwapRGBBits_banked:
            call    DRIVER_VBE_SetBankedMode
            jc      DVBE_SVM_ErrorExit

            mov     UnSetVideoMode_, offset DRIVER_VBE_UnSetVideoMode_Banked
            mov     ShowPage_, offset DRIVER_VBE_ShowPage_BankedSwapRGB
            mov     GetAvailPage_, offset DRIVER_VBE_GetAvailPage_Banked
            mov     WaitRetrace_, offset DRIVER_VBE_WaitRetrace
            mov     GetMemoryPtr_, offset DRIVER_VBE_GetMemoryPtr_Banked

            jmp     DVBE_SVM_OKExit
DVBE_SVM_ErrorExit:
            mov     eax, SGL_ERROR
            stc
            ret
            endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Rutinas de cambio de bancos
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.data?
VBE_Banked_BankWindow db ?
.code
SetBank         proc
        mov     ax, 4f05h
        xor     bh, bh
        mov     bl, VBE_Banked_BankWindow
        jmp     [SetBank_]
        endp

SetBank_Real    proc
        int     10h
        ret
        endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Rutinas de cambio de inicio de pantalla
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetStart proc
        mov     eax, 4f07h
        jmp     [SetStart_]
        endp

SetStart_Real    proc
        int     10h
        ret
        endp

SetStart_Protected   proc
        push    ebx
        mov     ebx, [ActualMode.BytesPerPixel]
        imul    edx, ebx
        imul    edx, [ActualMode.XResolution]
        imul    ecx, ebx
        add     edx, ecx
        shr     edx, 2
        movzx   ecx, dx
        shr     edx, 16
        mov     eax, 4f07h
        pop     ebx
        ;breakp  "ecx: ", ecx
        ;breakp  "edx: ", edx
        ;breakp  "ebx: ", ebx
        ;breakp  "eax: ", eax
        jmp     dword ptr [SetStartProtected]
        endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Rutinas de conversion de bits de color
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

;   esi, Source
;   edi, Destiny
;   ecx, Number of pixels
;   ebp, tabla a la conversion de bits

LMBlit16to16 proc
        lea esi, [esi+ecx*2]
        lea edi, [edi+ecx*2]
        neg ecx
LMBlit16to16lab:
        mov     ax,[esi+ecx*2]

        mov     edx, eax
        and     edx, 11111b
        mov     cl, 5
        sub     cl, [ebp+4]
        shr     edx, cl
        mov     cl, [ebp+5]
        shl     edx, cl

        shr     eax, 5
        mov     ebx, eax
        and     ebx, 111111b
        mov     cl, 6
        sub     cl, [ebp+2]
        shr     ebx, cl
        mov     cl, [ebp+3]
        shl     ebx, cl

        or      edx, ebx

        shr     eax, 6
        mov     ebx, eax
        and     ebx, 11111b
        mov     cl, 5
        sub     cl, [ebp+0]
        shr     ebx, cl
        mov     cl, [ebp+1]
        shl     ebx, cl

        or      edx, ebx

        mov     [edi+ecx*2], dx
        inc     ecx
        jnz     LMBlit16to16lab
        ret
        endp



;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Rutinas para los modos lineales con mas de una pagina
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.data?
DVBEActivePage  dd  ?
DVBEAvailPagePtr dd ?
DVBEAvailPagePtrBase dd ?
.code
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  ShowPage: Finaliza la pagina actual
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VBE_ShowPage_LinearMultiPage proc
        xor     ebx, ebx
        or      eax, eax
        jz      DVBESP_LMP001
        mov     ebx, 80h
DVBESP_LMP001:
        mov     eax, DVBEActivePage
        imul    eax, [ActualMode.YResolution]
        push    eax
        mov     eax, DVBEActivePage
        inc     eax
        cmp     al, [ActualMode.NPages]
        jne     DVBESP_LMP002
        xor     eax, eax
DVBESP_LMP002:
        mov     DVBEActivePage, eax
        imul    eax,[ActualMode.DDSize]
        shl     eax, 2
        add     eax, DVBEAvailPagePtrBase
        mov     DVBEAvailPagePtr, eax
        pop     edx
        xor     ecx, ecx
        jmp     SetStart
        endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Obtiene la pagina actual
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VBE_GetAvailPage_LinearMultiPage proc
        mov     eax, DVBEAvailPagePtr
        clc
        ret
        endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Finaliza el modo lineal de mas de una pagina
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VBE_UnsetVideoMode_LinearMultiPage   proc
        mov     eax, SGL_OK
        clc
        ret
        endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Rutinas para los modos lineales con una pagina
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  ShowPage: Finaliza la pagina actual
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VBE_ShowPage_LinearSinglePage proc
        xor     ebx, ebx
        or      eax, eax
        jz      DVBESP_LSP001
        mov     ebx, 80h
DVBESP_LSP001:
        xor     edx, edx
        xor     ecx, ecx
        call    SetStart
        mov     esi, DVBEAvailPagePtr
        mov     edi, DVBEAvailPagePtrBase
        mov     ecx, [ActualMode.DDSize]
        ;shr     ecx, 1
        ;jmp     Fast2QCopy
        rep     movsd
        ret
        endp

DRIVER_VBE_ShowPage_LinearSinglePageSwapRGB proc
        xor     ebx, ebx
        or      eax, eax
        jz      DVBESP_LSPSRGB001
        mov     ebx, 80h
DVBESP_LSPSRGB001:
        xor     edx, edx
        xor     ecx, ecx
        call    SetStart
        mov     esi, DVBEAvailPagePtr
        mov     edi, DVBEAvailPagePtrBase
        mov     ecx, [ActualMode.DDSize]
        shl     ecx, 1
        mov     ebp, offset ActualMode.DriverData[32-6]
        jmp     LMBlit16to16
        endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Obtiene la pagina actual
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VBE_GetAvailPage_LinearSinglePage proc
        mov     eax, DVBEAvailPagePtr
        clc
        ret
        endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Finaliza el modo lineal de mas de una pagina
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VBE_UnsetVideoMode_LinearSinglePage   proc
        mov     ebx, OriginalMemBuffer
        call    free
        mov     eax, SGL_OK
        clc
        ret
        endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Rutinas para los modos banked
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  ShowPage: Finaliza la pagina actual
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
saferep macro instr
        local skipthisrep
        or  ecx, ecx
        jz  skipthisrep
        rep instr
    skipthisrep:
        endm

.data?
VBE_Banked_WinSizeDD    dd  ?
VBE_Banked_NBanks       dd  ?
VBE_Banked_BytesPerLine dd  ?
VBE_Banked_CopiedX      dd  ?
VBE_Banked_CopiedPitch  dd  ?
VBE_Banked_WinSizeDDCurrent dd ?
.code
DRIVER_VBE_ShowPage_Banked proc
        xor     ebx, ebx
        or      eax, eax
        jz      DVBESP_B001
        mov     ebx, 80h
DVBESP_B001:
        xor     edx, edx
        xor     ecx, ecx
        call    SetStart

        mov     eax, [ActualMode.XResolution]
        imul    eax, [ActualMode.BytesPerPixel]
        mov     VBE_Banked_BytesPerLine, eax

        mov     VBE_Banked_CopiedX, eax
        mov     ebx, BankedBytesPerLine
        sub     ebx, eax
        mov     VBE_Banked_CopiedPitch, ebx

        mov     esi, DVBEAvailPagePtr
        mov     ecx, [ActualMode.DDSize]
        ;breakp  "el tama¤o del modo es", ecx
        xor     edx, edx
DVBESP_B002:
        mov     eax, VBE_Banked_WinSizeDD
        mov     VBE_Banked_WinSizeDDCurrent, eax
        or      ecx, ecx
        jz      DVBESP_B003
        cmp     ecx, eax
        jae     DVBESP_B002bis
        mov     VBE_Banked_WinSizeDDCurrent, ecx
DVBESP_B002bis:
        push    edx ecx
        call    Setbank

        mov     edi, DVBEAvailPagePtrBase

        mov     ecx, VBE_Banked_CopiedX
        or      ecx, ecx
        jne     DVBESP_LABEL001

        mov     edx, ecx
        shr     ecx, 2
        ;saferep movsd

        and     edx, 11b
        mov     ecx, edx
        ;saferep movsb
DVBESP_LABEL001:

        mov     ecx, VBE_Banked_CopiedPitch
        or      ecx, ecx
        jne     DVBESP_LABEL002
        add     edi, ecx

DVBESP_LABEL002:

        mov     eax, VBE_Banked_WinSizeDDCurrent
        shl     eax, 2
        sub     eax, VBE_Banked_CopiedX
        sub     eax, VBE_Banked_CopiedPitch
        idiv    BankedBytesPerLine
        or      eax, eax
        jz      DVBESP_LABEL003bis
DVBESP_LABEL003:
        mov     ebx, edi
        mov     ecx, VBE_Banked_BytesPerLine
        shr     ecx, 2
        ;saferep movsd
        mov     ecx, VBE_Banked_BytesPerLine
        and     ecx, 11b
        ;saferep movsb
        mov     edi, ebx
        add     edi, BankedBytesPerLine
        dec     eax
        jnz     DVBESP_LABEL003
DVBESP_LABEL003bis:

        mov     ecx, VBE_Banked_BytesPerLine
        cmp     ecx, edx
        jb      DVBESP_LABEL004
        mov     ecx, edx
DVBESP_LABEL004:
        mov     eax, VBE_Banked_BytesPerLine
        sub     eax, ecx
        mov     VBE_Banked_CopiedX, eax
        sub     edx, ecx

        mov     eax, BankedBytesPerLine
        sub     eax, VBE_Banked_BytesPerLine
        sub     eax, edx
        mov     VBE_Banked_CopiedPitch, eax

        mov     ebx, ecx
        shr     ecx, 2
        ;saferep movsd
        mov     ecx, ebx
        ;saferep movsb
DVBESP_LABEL005:

        add     edi, edx
        pop     ecx edx
        add     edx, VBE_Banked_NBanks
        sub     ecx, VBE_Banked_WinSizeDDCurrent
        jmp     DVBESP_B002
DVBESP_B003:

        ret
        endp

DRIVER_VBE_ShowPage_BankedSwapRGB   proc
        xor     ebx, ebx
        or      eax, eax
        jz      DVBESP_BSRGB001
        mov     ebx, 80h
DVBESP_BSRGB001:
        xor     edx, edx
        xor     ecx, ecx
        call    SetStart

        mov     esi, DVBEAvailPagePtr
        mov     ecx, [ActualMode.DDSize]
        xor     edx, edx
DVBESP_BSRGB002:
        cmp     ecx, VBE_Banked_WinSizeDD
        jbe     DVBESP_BSRGB003
        push    edx ecx
        call    Setbank
        mov     ecx, VBE_Banked_WinSizeDD
        mov     edi, DVBEAvailPagePtrBase

        shl     ecx, 1
        mov     ebp, offset ActualMode.DriverData[32-6]
        call    LMBlit16to16

        pop     ecx edx
        add     edx, VBE_Banked_NBanks
        sub     ecx, VBE_Banked_WinSizeDD
        jmp     DVBESP_BSRGB002
DVBESP_BSRGB003:
        call    Setbank
        mov     edi, DVBEAvailPagePtrBase
        shl     ecx, 1
        mov     ebp, offset ActualMode.DriverData[32-6]
        jmp     LMBlit16to16

        ;ret
        endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Obtiene la pagina actual
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VBE_GetAvailPage_Banked proc
        mov     eax, DVBEAvailPagePtr
        clc
        ret
        endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Finaliza el modo banked
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VBE_UnsetVideoMode_Banked   proc
        mov     ebx, OriginalMemBuffer
        call    free
        mov     eax, SGL_OK
        clc
        ret
        endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Espera al retrazo
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VBE_WaitRetrace  proc
        mov     ax, 4f07h   ; obtenemos el inicio de pantalla
        mov     bx, 1
        int     10h
        mov     ebx, 80h    ; ponemos el inicio de pantalla esperando el retr.
        movzx   edx, dx
        movzx   ecx, cx
        jmp     SetStart
        endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Obtiene el puntero de acceso directo a memoria
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VBE_GetMemoryPtr_Linear  proc
        mov     eax, DVBEAvailPagePtrBase
        clc
        ret
        endp
DRIVER_VBE_GetMemoryPtr_Banked  proc
        stc
        ret
        endp

