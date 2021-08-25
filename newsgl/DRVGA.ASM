;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  [tDR], 1998                                    Copyright the DarkRising
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³                                      Coded by:              Nitro!
;³  VGA Driver 1.00b                    Support & BugFixed by: Teknik, B52
;³
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  DATE         REVISION           AUTHOR & COMMENTS
;³  ÄÄÄÄÄÄÄÄ     ÄÄÄÄÄÄÄÄÄÄÄÄÄ      ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  08-11-98     Version 1.00b      Nitro! : First Version
;³  13-11-98     Version 1.00b      Finished
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Datos del driver
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.data?
ModeSize2Q          dd  ?
OriginalMemBuffer   dd  ?
MemBuffer           dd  ?   ; aligned to qword for MMX blts
.data
    DRVGA_text1     db '     ş VGA Driver 1.00b initialized Ok!',13,10,0
    DRVGA_text2     db '     ş VGA Driver 1.00b uninstalled Ok!',13,10,0
.code
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Macros generales
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
outport macro port, value
        mov     al, value
        mov     dx, port
        out     dx, al
        endm
outp    macro port, value, value2
        mov     ax, value +(value2 shl 8)
        mov     dx, port
        out     dx, ax
        endm
inp     macro   port
        mov     dx, port
        in      al, dx
        endm

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Inicializacion del driver
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VGA_Init     proc
;   De momento damos por supuesto k hay VGA (ya lo har‚!)

;   A¤adimos el modo 13h 320x200 8bits
            mov     ModeTemp.Driver, DR_VGA
            mov     ModeTemp.Xresolution, 320
            mov     ModeTemp.Yresolution, 200
            mov     ModeTemp.ColorBits, 8
            mov     ModeTemp.BytesPerPixel, 1
            mov     ModeTemp.Npages, 1
            mov     ModeTemp.Modetype, 0
            mov     ModeTemp.DDSize, 64000/4
            mov     esi, offset ModeTemp
            call    AddMode
            jc      DRIVER_VGA_ErrorExit

;   A¤adimos el modo 256x256 8bits
            mov     ModeTemp.Driver, DR_VGA
            mov     ModeTemp.Xresolution, 256
            mov     ModeTemp.Yresolution, 256
            mov     ModeTemp.ColorBits, 8
            mov     ModeTemp.BytesPerPixel, 1
            mov     ModeTemp.Npages, 1
            mov     ModeTemp.Modetype, 0
            mov     ModeTemp.DDSize, LARGE 65536/4
            mov     esi, offset ModeTemp
            call    AddMode
            jc      DRIVER_VGA_ErrorExit

            iprint   DRVGA_text1

            mov     eax, SGL_OK
            clc
            ret
DRIVER_VGA_ErrorExit:
            mov     eax, SGL_ERROR
            stc
            ret
            endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Desinicializacion del driver
;³	Input: AL = 0 for verbose, 1 for silent
;³	Output: EAX = SGL_OK, CF = 0
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VGA_UnInit   proc
			or		al,al
			jnz		drvga_uninit_silent
            eprint   DRVGA_text2
			drvga_uninit_silent:
            mov     eax, SGL_OK
            clc
            ret
            endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Inicializa un modo de video VGA
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VGA_SetVideoMode     proc
            test    [ActualMode.ModeType], MT_Emulated
            jnz     DVGA_Emulatedmode
            cmp     [ActualMode.Xresolution], 256
            je      Set256mode
            mov     ecx, 64008
            call    malloc
            or      ebx, ebx
            jz      DVGA_SETErrorExit

            shr     ecx, 2      ; Borramos el buffer alojado
            mov     edi, ebx
            xor     eax, eax
            rep     stosd

            mov     OriginalMemBuffer, ebx
            add     ebx, 7
            and     ebx, not 111b
            mov     MemBuffer, ebx
            mov     ModeSize2Q, 64000/8
            mov     ax, 13h
            int     10h
            mov     UnSetVideoMode_, offset DRIVER_VGA_UnSetVideoMode
            mov     ShowPage_, offset DRIVER_VGA_ShowPage
            mov     GetAvailPage_, offset DRIVER_VGA_GetAvailPage
            mov     WaitRetrace_, offset DRIVER_VGA_WaitRetrace
            mov     GetMemoryPtr_, offset DRIVER_VGA_GetMemoryPtr
            jmp     DVGA_SVM_OKExit
Set256mode:
            mov     ecx, LARGE 256*256+8
            call    malloc
            or      ebx, ebx
            jz      DVGA_SETErrorExit

            shr     ecx, 2      ; Borramos el buffer alojado
            mov     edi, ebx
            xor     eax, eax
            rep     stosd

            mov     OriginalMemBuffer, ebx
            add     ebx, 7
            and     ebx, not 111b
            mov     MemBuffer, ebx
            mov     ModeSize2Q, 8192 ;LARGE 256*256/8

            mov     ax, 13h
            int     10h
            outport 3d4h, 11h
            inp     3d5h
            and     al, 7fh
            mov     dx, 3d5h
            out     dx, al

            outport 3c2h, 0e3h

            outp    3d4h,  0h, 05fh
            outp    3d4h,  1h, 03fh
            outp    3d4h,  2h, 039h
            outp    3d4h,  3h, 082h
            outp    3d4h,  4h, 04ah
            outp    3d4h,  5h, 09ah
            outp    3d4h,  6h, 06fh
            outp    3d4h,  7h, 0b2h
            outp    3d4h,  8h, 0h
            outp    3d4h,  9h, 061h
            outp    3d4h, 10h, 028h
            outp    3d4h, 11h, 08ah
            outp    3d4h, 12h, 0ffh
            outp    3d4h, 13h, 020h
            outp    3d4h, 14h, 040h
            outp    3d4h, 15h, 07h
            outp    3d4h, 16h, 01ah
            outp    3d4h, 17h, 0a3h
            outp    3c4h,  1h, 01h
            outp    3c4h,  3h, 0h
            outp    3c4h,  4h, 0eh
            outp    3ceh,  5h, 040h
            outp    3ceh,  6h, 05h

            mov     UnSetVideoMode_, offset DRIVER_VGA_UnSetVideoMode
            mov     ShowPage_, offset DRIVER_VGA_ShowPage
            mov     GetAvailPage_, offset DRIVER_VGA_GetAvailPage
            mov     WaitRetrace_, offset DRIVER_VGA_WaitRetrace
            mov     GetMemoryPtr_, offset DRIVER_VGA_GetMemoryPtr
            jmp     DVGA_SVM_OKExit

DVGA_SVM_OKExit:
            mov     eax, SGL_OK
            clc
            ret
DVGA_Emulatedmode:
;            ret
DVGA_SETErrorExit:
            mov     eax, SGL_ERROR
            stc
            ret
            endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  desinicializa un modo de video VGA
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VGA_UnsetVideoMode   proc
            mov     ebx, OriginalMemBuffer
            call    free
            mov     eax, SGL_OK
            clc
            ret
            endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Devuelve la pagina actual
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VGA_GetAvailPage proc
            mov         eax, MemBuffer
            clc
            ret
            endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Finaliza la pagina actual
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VGA_Showpage     proc
            or          eax, eax
            jz          DVGA_notwaitvr

            mov     dx,3dah         ; Esperamos al fin del retrazo vertical
retraceend:
            in      al,dx
            test    al,8
            jnz     retraceend

            mov     dx,3dah         ; Esperamos al retrazo vertical
retracestart:
            in      al,dx
            test    al,8
            jz      retracestart

DVGA_notwaitvr:
            mov         esi, MemBuffer
            mov         edi, 0a0000h
            mov         ecx, ModeSize2Q
            jmp         Fast2QCopy
;           ret
            endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Espera del retrazo
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VGA_WaitRetrace  proc
            mov     dx,3dah         ; Esperamos al fin del retrazo vertical
DRIVER_VGA_WR001:
            in      al,dx
            test    al,8
            jnz     DRIVER_VGA_WR001

            mov     dx,3dah         ; Esperamos al retrazo vertical
DRIVER_VGA_WR002:
            in      al,dx
            test    al,8
            jz      DRIVER_VGA_WR002
            ret
            endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Obtiene el puntero de acceso directo a memoria
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DRIVER_VGA_GetMemoryPtr  proc
            mov     eax, 0a0000h
            clc
            ret
            endp

