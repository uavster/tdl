//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
// fitxer: ttl.h
//
//  Fitxer de cap‡alera per la llibreria de #Trouble# Team.
//
//    by Xavier Rubio Jansana, a.k.a. Teknik / #Trouble# Team
//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

typedef unsigned char   BYTE;
typedef unsigned short  WORD;
typedef unsigned long   DWORD;

#define NULL        0

//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

void CreateLitTable(BYTE *pbPaleta, BYTE *pbLitTable, int nType);
#pragma aux CreateLitTable "*" parm   [esi] [edi] [eax] \
                               modify [eax ebx ecx edx esi edi];

#define COLOR2WHITE 0   // 0 - Original .... 31 - Blanco
#define BLACK2COLOR 1   // 0 - Negro    .... 31 - Original
#define BLACK2WHITE 2   // 0 - Negro ... 15 - Original ... 31 - Blanco
#define ORIGINAL    3   // 0 - Original

//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

#define SGL_OK      0
#define SGL_ERROR   -1
#define SGL_NOVBE   -2

short InitSGL(void);
#pragma aux InitSGL "*" modify [eax ebx ecx edx esi edi] \
                        value  [ax];

int GetModeInfo(int nMode);
#pragma aux GetModeInfo "*" modify [eax ebx ecx edx esi edi] \
                            value  [eax];

int SetVideoMode(int xRes, int yRes, int nBits);
#pragma aux SetVideoMode "*" parm   [eax] [ebx] [ecx] \
                             modify [eax ebx ecx edx esi edi] \
                             value  [eax];

#define LINEAR      0
#define LINEAR1PAGE 1
#define BANKED      2
#define OEM         3

int UnSetVideoMode(int nMode);
#pragma aux UnSetVideoMode "*" parm   [eax] \
                               modify [eax ebx ecx edx esi edi] \
                               value  [eax];

#define DONTCHANGE  0

BYTE *GetAvailPage(void);
#pragma aux GetAvailPage "*" value [eax];

void ShowPage(void);
#pragma aux ShowPage "*" modify [eax ebx ecx edx esi edi];

void SetStartAddress(int xPos, int yPos);
#pragma aux SetStartAddress "*" parm   [ecx] [edx] \
                                modify [eax ebx];

short SetScanLineLength(WORD wBytes);
#pragma aux SetScanLineLength "*" parm   [ecx] \
                                  modify [eax ebx ecx edx esi edi] \
                                  value  [cx];

void SetBank(int nBank);
#pragma aux SetBank "*" parm   [edx] \
                        modify [eax ebx];

BYTE *GetDDaddress(void);
#pragma aux GetDDaddress "*" value [eax];

void ScreenOff(void);
#pragma aux ScreenOff "*" modify [eax edx];

void ScreenOn(void);
#pragma aux ScreenOn "*" modify [eax edx];

void VerticalRStart(void);
#pragma aux VerticalRStart = \
  "   mov     dx, 3dah" \
  "retrazo:"            \
  "   in      al, dx"   \
  "   test    al, 8"    \
  "   jz      retrazo"  \
  modify [al edx];

void VerticalREnd(void);
#pragma aux VerticalREnd = \
  "   mov     dx, 3dah" \
  "retrazo:"            \
  "   in      al, dx"   \
  "   test    al, 8"    \
  "   jnz     retrazo"  \
  modify [al edx];

void HoritzontalRStart(void);
#pragma aux HoritzontalRStart = \
  "   mov     dx, 3dah" \
  "retrazo:"            \
  "   in      al, dx"   \
  "   test    al, 1"    \
  "   jz      retrazo"  \
  modify [al edx];

void HoritzontalREnd(void);
#pragma aux HoritzontalREnd = \
  "   mov     dx, 3dah" \
  "retrazo:"            \
  "   in      al, dx"   \
  "   test    al, 1"    \
  "   jnz     retrazo"  \
  modify [al edx];

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//³      Estructura de informacion VESA
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
typedef struct
{
  //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
  //³ Estructura del estandar VESA v1.0
  //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
  DWORD VESASignature;          // Firma del estandar VESA
  WORD  VESAVersion;            // Version de VESA
  DWORD OEMNamePtr;             // Puntero al nombre OEM
  DWORD CapabFlags;             // Banderas de capacidades
  DWORD ModeListPtr;            // Puntero a la lista de modos
  WORD  TotalVidMemory;         // Memoria de video en bloques de 64k
  //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
  //³ Estandar VESA v2.0
  //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
  WORD  OEMSoftVersion;         // Version del software VESA
  DWORD VendorNamePtr;          // Puntero al nombre del vendedor
  DWORD ProductNamePtr;         // Puntero al nombre del producto
  DWORD ProductRevPtr;          // Puntero a la cadena de revision del producto
  BYTE  Reserved[222];          // Reservado
  BYTE  OEMData[256];           // Reservado para OEM
} VESAInfo;

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//³      Estructura de informacion de modos VESA
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
typedef struct
{
  //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
  //³ Estructura del estandar VESA v1.0
  //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
  WORD  ModeAttrib;             // Atributos del modo de video
  BYTE  WinAAttrib;             // Atributos de la ventana A
  BYTE  WinBAttrib;             // Atributos de la ventana B
  WORD  WinGran;                // Granularidad de las ventanas en kb
  WORD  WinSize;                // Tama¤o de las ventanas en kb
  WORD  StartSegA;              // Segmento de inicio de la ven. A
  WORD  StartSegB;              // Segmento de inicio de la ven. B
  DWORD WinPosPtr;              // Puntero a la funcion de cambio de posicion
  WORD  ByteScanLine;           // Bytes por scanline
  //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
  //³ Parte opcional del estandar VESA v1.0 y v1.1 (Necesaria para OEM)
  //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
  WORD  XSize;                  // Tama¤o X del modo (pixels)
  WORD  YSize;                  // Tama¤o Y del modo (pixels)
  BYTE  XChar;                  // Tama¤o X de un caracter (pixels)
  BYTE  YChar;                  // Tama¤o Y de un caracter (pixels)
  BYTE  NumMemPlanes;           // Numero de planos de memoria
  BYTE  NumBitPixel;            // Numero de bits por pixel
  BYTE  NumBanks;               // Numero de bancos
  BYTE  MemModelType;           // Tipo de modelo de memoria
  BYTE  SizeOfBank;             // Tama¤o del banco en kb
  BYTE  NumPages;               // Numero de paginas de imagen
  BYTE  Reserved1;              // Reservado
  //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
  //³ Estandar VESA v1.2
  //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
  BYTE  RedMaskSize;            // Tama¤o de la mascara de rojo
  BYTE  RedFieldPos;            // Posicion del campo de rojo
  BYTE  GreenMaskSize;          // Tama¤o de la mascara de verde
  BYTE  GreenFieldPos;          // Posicion del campo de verde
  BYTE  BlueMaskSize;           // Tama¤o de la mascara de azul
  BYTE  BlueFieldPos;           // Posicion del campo de azul
  BYTE  ReservMaskSize;         // Reservado (tama¤o de la mascara)
  BYTE  ReservFieldPos;         // Reservado (posicion del campo)
  BYTE  DirectColorInfo;        // Informacion del modo DirectColor
  //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
  //³ Estandar VESA v2.0
  //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
  DWORD PhysAdress;             // Direccion fisica de la memoria lineal
  DWORD OffscreenPtr;           // Direccion de comienzo de la memoria
                                // que esta fuera de pantalla
  WORD  OffscreenSize;          // Tama¤o de la memoria fuera de pantalla
  BYTE  Reserved2[206];         // Reservado
} VESAModeInfo;

extern VESAInfo     VESAInfoBl;
extern VESAModeInfo VESAModeInfoBl;
#pragma aux VESAInfoBl "*";
#pragma aux VESAModeInfoBl "*";

//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

void CharSize(BYTE bHeight);
#pragma aux CharSize "*" parm   [bl] \
                         modify [edx al];

void ScreenStart(WORD wStart);
#pragma aux ScreenStart "*" parm   [bx] \
                            modify [eax edx];

void SetSplit(WORD wScanLine);
#pragma aux SetSplit "*" parm   [bx] \
                         modify [eax ebx edx];

void SetCurPos(WORD wOffset);
#pragma aux SetCurPos "*" parm   [bx] \
                          modify [eax edx];

WORD GetCurPos(void);
#pragma aux GetCurPos "*" modify [eax edx] \
                          value  [bx];

void VerticalPELPan(BYTE bPos);
#pragma aux VerticalPELPan = \
  "   mov     ah, al"     \
  "   mov     al, 8"      \
  "   mov     dx, 3d4h"   \
  "   out     dx, ax"     \
  parm [al] modify [ah dx];

//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

#define READ_ONLY   0   // Access rights
#define WRITE_ONLY  1
#define READ_WRITE  2

#define SEEK_SET    0   // start of file
#define SEEK_CUR    1   // current file position
#define SEEK_END    2   // end of file

DWORD ttl_open(char *szName, DWORD dwAccess);
/*
#pragma aux ttl_open =  \
  "   mov     ah, 0x3d" \
  "   int     0x21"     \
  "   jnc     o_ok"     \
  "   xor     eax, eax" \
  "o_ok:"               \
  parm [edx] [al] modify [eax] value [eax];
*/
#pragma aux ttl_open "*" parm [edx] [eax] \
                         modify [eax] \
                         value [eax];

DWORD ttl_create(char *szName);
#pragma aux ttl_create "*" parm   [edx] \
                           modify [eax] \
                           value  [eax];

void ttl_close(DWORD dwHandle);
#pragma aux ttl_close "*" parm   [ebx] \
                          modify [eax];

DWORD ttl_read(void *pvBuffer, DWORD dwSize, DWORD dwHandle);
#pragma aux ttl_read "*" parm   [edx] [ecx] [ebx] \
                         modify [eax] \
                         value  [eax];

DWORD ttl_write(void *pvBuffer, DWORD dwSize, DWORD dwHandle);
#pragma aux ttl_write "*" parm   [edx] [ecx] [ebx] \
                          modify [eax] \
                          value  [eax];

  // NOTA IMPORTANT: si posas "al" com a parm no va be, fa la convencio de
  //                 pas de par…metres com li rota... :(

int ttl_seek(DWORD dwHandle, DWORD dwPos, DWORD bWhence);
#pragma aux ttl_seek "*" parm [ebx] [edx] [eax] \
                         modify [eax] \
                         value  [eax];

//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

void puts(char *sz);
#pragma aux puts =        \
  "   mov     ecx, 0ffffh"\
  "   mov     edi, edx"   \
  "   xor     al, al"     \
  "   cld"                \
  "   repne   scasb"      \
  "   dec     edi"        \
  "   mov     [edi], '$'" \
  "   mov     ah, 9"      \
  "   int     21h"        \
  "   mov     [edi], al"  \
  parm [edx] modify [eax ecx edi];

int getch(void);
#pragma aux getch =   \
  "   mov     ah, 8"  \
  "   int     21h"    \
  "   movzx   eax, al"\
  value [eax];

int kbhit(void);
#pragma aux kbhit =   \
  "   mov     ah, 0bh"\
  "   int     21h"    \
  "   movsx   eax, al"\
  value [eax];

//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

void *malloc(DWORD dwSize);
#pragma aux malloc "*" parm   [ecx] \
                       modify [eax ecx] \
                       value  [ebx];

void free(void *pv);
#pragma aux free "*" parm   [ebx] \
                     modify [eax ebx ecx];

void *realloc(void *pv, DWORD dwSize);
#pragma aux realloc "*" parm   [ebx] [ecx] \
                        modify [eax ecx edx esi edi] \
                        value  [ebx];

int checkheap(void);
#pragma aux checkheap "*" modify [eax ebx edx] \
                          value  [eax];

#define CH_ERROR    -1
#define CH_OK       0

DWORD getmeminfo(void);
#pragma aux getmeminfo "*" modify [eax ebx ecx] \
                           value  [eax];

//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

void memset(void *ptr, BYTE c, DWORD len);
#pragma aux memset =      \
  "   mov     ah, al"     \
  "   mov     edx, eax"   \
  "   shl     eax, 16"    \
  "   mov     ax, dx"     \
  "   push    ecx"        \
  "   shr     ecx, 2"     \
  "   cld"                \
  "   rep     stosd"      \
  "   pop     ecx"        \
  "   and     ecx, 3"     \
  "   rep     stosb"      \
  parm [edi] [al] [ecx] modify [eax edi ecx edx];

void memcpy(void *dest, void *src, DWORD len);
#pragma aux memcpy =      \
  "   push    ecx"        \
  "   shr     ecx, 2"     \
  "   cld"                \
  "   rep     movsd"      \
  "   pop     ecx"        \
  "   and     ecx, 3"     \
  "   rep     movsb"      \
  parm [edi] [esi] [ecx] modify [edi esi ecx];

//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

BYTE *ReadBMP(char *fname, DWORD off, BYTE *pal, int *sx, int *sy);

//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

//void enable_timer(float fOldHandlerFreq);
void enable_timer(DWORD fOldHandlerFreq);
#pragma aux enable_timer "*" parm   [eax] \
                             modify [eax ebx ecx edx esi edi];

void disable_timer(void);
#pragma aux disable_timer "*" modify [eax ebx ecx edx esi edi];

//void add_timer(float fFreq, void (*pFn)());
void add_timer(DWORD fFreq, void (*pFn)());
#pragma aux add_timer "*" parm   [eax] [ebx] \
                          modify [eax ebx ecx edx esi edi];

void remove_timer(void (*pFn)());
#pragma aux remove_timer "*" parm   [ebx] \
                             modify [eax ebx ecx edx esi edi];

//void force_frequency(float fFreq);
void force_frequency(DWORD fFreq);
#pragma aux force_frequency "*" parm   [eax] \
                                modify [eax ebx ecx edx esi edi];

//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

/*


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; file: utils.inc
;
;  Some utility routines.
;
;       by C‚sar Guirao Robles, a.k.a. Nitro! / #Trouble# Team
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Rutina para obtener cada uno de los parametros de la linea de
;       comandos.
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI   puntero a la linea de commandos del psp
;                       EDI   puntero donde guardar el parametro
;       Salida:         [EDI] parametro acabado en 0
;                       ECX   tama¤o en bytes del parametro
;                             Si es cero no hay mas parametros
;                       ESI   puntero para volver a llamar a la funcion
;                             para obtener el siguiente parametro

        extrn           GetCommandParam:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Rutina para imprimir cadenas con subcadenas o numeros...
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI   puntero a la cadena a imprimir
;          '%us',dword puntero
;          Imprime una cadena, la u hace que el texto sea mostrado en
;          mayusculas.
;          '%(d,w,b)[+,-][0][numero][h,o,i]n',dword puntero
;          Imprime el numero apuntado por el puntero. Seguido se debe
;          poner uno de los identificadores de tama¤o. El mas y el menos
;          indica que el numero es un numero con signo. El mas hace que
;          aunque el numero sea positivo se ponga el signo en pantalla.
;          El cero indica que los espacios de relleno que se indican a
;          continuacion se han de rellenar con ceros en vez de con espacios
;          Las letras h o i indican la base, si no se pone nada es en
;          base decimal. La h es hexadecimal, la o octal y la i binario.
;       Salida:         Nada.

        extrn           printf:near
Print   macro   etiqueta
        push    esi
        mov     esi,offset etiqueta
        call    printf
        pop     esi
        endm

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Rutina para imprimir un caracter
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        AL
;       Salida:         Nada.

        extrn           PrintChar:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Rutina para convertir un numero a string en una base determinada
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        EAX     Numero a convertir
;                       ESI     String donde copiar el numero convertido
;                       EBX     Base en la que convertir el numero
;       Salida:         Nada.

        extrn           TransToBase:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Transforma una cadena numerica a un integer
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI     String donde buscar el numero
;       Salida:         ECX     Numero obtenido
;                               Carry activado si no hay numero
;                               Si no Carry desactivado
        extrn           GetInteger:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Inserta en la posicion indicada el caracter dado
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI     String donde insertar el caracter
;                       DL      Caracter a insertar
;       Salida:         Nada.
;

        extrn           PushToString:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Copia una cadena sobre otra
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI     String fuente
;                       EDI     String destino
;       Salida:         Nada.
;

        extrn           CopyString:near

CopyS   macro   destino,fuente
        mov     edi,offset destino
        mov     esi,offset fuente
        call    CopyString
        endm

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Busca el tama¤o de una cadena
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI     String
;       Salida:         ECX     Tama¤o
;

        extrn           StringLength:near
strlen  macro   string
        mov     esi,offset string
        call    StringLength
        endm

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Copia el nombre de un archivo sobre otro pero sin la unidad ni
;       la ruta.
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI     Nombre de fichero fuente
;                       EDI     Nombre de fichero destino
;       Salida:         Nada.
;

        extrn           CopyFilename:near
CopyFN  macro   destino,fuente
        mov     edi,offset destino
        mov     esi,offset fuente
        call    CopyFilename
        endm

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Busca la extension del archivo
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI     Nombre de fichero fuente
;       Salida:         AL      0  Si el archivo no tiene extension
;                               -1 Si el archivo si tiene extension
;                       ESI     Si el archivo tiene extension apunta
;                               a la extension, sino apunta al final
;                               del nombre del fichero.
;

        extrn           SearchExtension:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Lee una linea de texto del archivo
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        BX      Handle del archivo
;                       EDI     Buffer donde escribir
;                       ECX     Tama¤o maximo del buffer
;       Salida:         Carry=1 Error en la lectura
;                       ECX =-1 La linea era mayor de lo permitido
;                       ECX =-2 Se ha llegado al final del archivo

        extrn           ReadLine:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Pasa a mayusculas
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        AL      Car cter a convertir
;       Salida:         Nada.

        extrn           UpperCase:near

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Compara dos cadenas
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;       Entrada:        ESI     Cadena 1
;                       EDI     Cadena 2
;       Salida:         carry = 0  Si son iguales
;                       carry = 1  Si son diferentes
;

        extrn           CompareString:near

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; file: dpmi.asm
;
;  DPMI interface routines.
;
;       by C‚sar Guirao Robles, a.k.a. Nitro! / #Trouble# Team
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

global  RealInterrupt   : near
global  MapMemory       : near
global  RealAddress     : near

global  RealStackCopy   : dword
global  RealDSSegment   : word
global  RealESSegment   : word
global  RealGSSegment   : word
global  RealFSSegment   : word

*/
