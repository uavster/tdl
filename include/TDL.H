#ifndef __TDL_INCLUDED__
#define __TDL_INCLUDED__

#ifdef __cplusplus
  extern "C" {
#endif

// ��������������������������������������������������������
// std.tDL
// ��������������������������������������������������������

typedef unsigned char   BYTE;
typedef unsigned short  WORD;
typedef unsigned long   DWORD;

#define NULL        0

// ��������������������������������������������������������
// new!SGL
// ��������������������������������������������������������
#define    SGL_OK       0
#define    SGL_DRIVER   1
#define    SGL_NOMEM    2
#define    SGL_FILE     3
#define    SGL_REINIT   4
#define    SGL_NOINIT   5
#define    SGL_ERROR   -1

#define    SGL_MemoryBuffer 0x80000000
int InitSGL(void);
#pragma aux InitSGL "*" modify [eax ebx ecx edx esi edi ebp] \
                        value  [eax];

int SetVideoMode(int xRes, int yRes, int nBits);
#pragma aux SetVideoMode "*" parm   [eax] [ebx] [ecx] \
                             modify [eax ebx ecx edx esi edi ebp] \
                             value  [eax];
int UnSetVideoMode(int nMode);
#pragma aux UnSetVideoMode "*" parm   [eax] \
                               modify [eax ebx ecx edx esi edi ebp] \
                               value  [eax];
void UnInitSGL(void);
#pragma aux UnInitSGL "*" modify [eax ebx ecx edx esi edi ebp];

#define DONTCHANGE  0

BYTE *GetAvailPage(void);
#pragma aux GetAvailPage "*" value [eax];

BYTE *GetMemoryPtr(void);
#pragma aux GetMemoryPtr "*" value [eax];

void ShowPage(void);
#pragma aux ShowPage "*" modify [eax ebx ecx edx esi edi];

void WaitRetrace(void);
#pragma aux WaitRetrace "*" modify [eax ebx ecx edx esi edi];

// ��������������������������������������������������������
// files
// ��������������������������������������������������������

#define READ_ONLY   0   // Access rights
#define WRITE_ONLY  1
#define READ_WRITE  2

#define SEEK_SET    0   // start of file
#define SEEK_CUR    1   // current file position
#define SEEK_END    2   // end of file

DWORD ttl_open(char *szName, DWORD dwAccess);
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
  //                 pas de par�metres com li rota... :(

DWORD ttl_seek(DWORD dwHandle, int dwPos, DWORD bWhence);
#pragma aux ttl_seek "*" parm [ebx] [edx] [eax] \
                         modify [eax] \
                         value  [eax];

// ��������������������������������������������������������
// std.tDL
// ��������������������������������������������������������
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


// ��������������������������������������������������������
// memory
// ��������������������������������������������������������

void init_c_heap(void);
#pragma aux init_c_heap "*"  modify [ecx eax ebx edx];


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

// ��������������������������������������������������������
// std.tDL
// ��������������������������������������������������������

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

//����������������������������������������������������������������������������

BYTE *ReadBMP(char *fname, DWORD off, BYTE *pal, int *sx, int *sy);

//����������������������������������������������������������������������������

// ��������������������������������������������������������
// timers
// ��������������������������������������������������������
void enable_timer(DWORD fOldHandlerFreq);
#pragma aux enable_timer "*" parm   [eax] \
                             modify [eax ebx ecx edx esi edi];

void disable_timer(void);
#pragma aux disable_timer "*" modify [eax ebx ecx edx esi edi];

void add_timer(DWORD fFreq, void (*pFn)());
#pragma aux add_timer "*" parm   [eax] [ebx] \
                          modify [eax ebx ecx edx esi edi];

void remove_timer(void (*pFn)());
#pragma aux remove_timer "*" parm   [ebx] \
                             modify [eax ebx ecx edx esi edi];

void force_frequency(DWORD fFreq);
#pragma aux force_frequency "*" parm   [eax] \
                                modify [eax ebx ecx edx esi edi];

// ��������������������������������������������������������
// SLI's
// ��������������������������������������������������������

//    Blitting basic methodes
#define SLIBlitCopy       0
#define SLIBlitAlpha      1
#define SLIBlitAlphaMap   2

#define SLIMaskedColor    4

//   Estructura de punto
typedef struct
{
    int SLPX;
    int SLPY;
} SLP;

//   Estructura de rectangulo
typedef struct
{
    SLP SLRR1;
    SLP SLRR2;
} SLR;

#define SLI_TEMP_VARS   8

typedef struct
{
    DWORD SLIMethode; //M�todos de la imagen

    SLP SLIPos; // Posicion del sprite en destino
    SLP SLIRef; // Posicion de referencia dentro del sprite
    SLR SLIClip; //Zona de clipping (en coordenadas de pantalla)

    DWORD SLIXSize;// Ancho
    DWORD SLIYSize;// Alto

    DWORD SLIPitch;// ancho en bytes de cada línea
    DWORD SLIColorBits;// densidad de color
                        //    ; para  8, 16, 24, 32 bits
                        //    ; valor 1,  2,  3,  4

    DWORD SLIBlitType ; // 1 - SLIBlitCopy
                        //    ; 2 - SLIBlitAlpha
                        //    ; 3 - SLIBlitAlphaMap

    DWORD SLIAlpha ;// Puntero al canal alpha o al alpha constante
                    // (Si es NULL con SLIBltAlphaMap, el alpha est� como B:G:R:A)

    DWORD SLIMask ;// Color de m�scara

    DWORD SLIFrame          ; //Frame actual de la animacion 16.16
    DWORD SLITotalFrames    ; //Numero de frames de la animacion 16.16
    DWORD SLIFrameRate      ; //Incremento de frames en 16.16
    BYTE  *SLIFramePtr       ; //Puntero al frame actual

    DWORD SLIPImages        ; //puntero a la lista de punteros de frames

    DWORD SLITemp[SLI_TEMP_VARS];// Espacio para variables temporales

    DWORD SLIPalette[256]; // paleta asociada si no la tiene = NULL
    BYTE  *SLILitTable    ; // puntero a una tabla de conversion si no la tiene = NULL
    DWORD SLISBufferNfo  ; // Datos para los sbufferSLI's
} SLI;


/*
;���������������������������������������������������������������������������
;� CreateSLI:           aloja una animaci�n vacia en SLI
;���������������������������������������������������������������������������
;�      Entrada:        EAX : Size X
;�                      EBX : Size Y
;�                      ECX : ColorBits
;�                      EDX : Number of frames
;���������������������������������������������������������������������������
;�      Salida:         EBX : puntero al SLI
;���������������������������������������������������������������������������
*/
SLI *CreateSLI(int X, int Y, int colorbits, int nframes);
#pragma aux CreateSLI "*" parm   [eax] [ebx] [ecx] [edx] \
                          modify [eax ebx ecx edx esi edi ebp] \
                          value  [ebx];
/*
;���������������������������������������������������������������������������
;� CreateVoidSLI:       aloja una animaci�n vacia en SLI sin buffer
;���������������������������������������������������������������������������
;�      Entrada:        EAX : Size X
;�                      EBX : Size Y
;�                      ECX : ColorBits
;�                      EDX : Number of frames
;���������������������������������������������������������������������������
;�      Salida:         EAX : puntero al SLI
;���������������������������������������������������������������������������
*/
SLI *CreateVoidSLI(int X, int Y, int colorbits, int nframes);
#pragma aux CreateVoidSLI "*" parm   [eax] [ebx] [ecx] [edx] \
                          modify [eax ebx ecx edx esi edi ebp] \
                          value  [ebx];
/*
;���������������������������������������������������������������������������
;� DestroySLI:          Desaloja una imagen vacia en SLI
;���������������������������������������������������������������������������
;�      Entrada:        EAX : puntero al SLI
;���������������������������������������������������������������������������
;�      Salida:         nada.
;���������������������������������������������������������������������������
*/
void DestroySLI(SLI *punterosli);
#pragma aux DestroySLI "*" parm   [eax] \
                          modify [eax ebx ecx edx esi edi ebp];

/*
;���������������������������������������������������������������������������
;� CreateVideoSLI:      Crea la superficie de video SLI
;���������������������������������������������������������������������������
;�      Entrada:        EAX : Size X
;�                      EBX : Size Y
;�                      ECX : ColorBits
;�      Nota:           Si ECX+SGL_MemoryBuffer se fuerza a un buffer en
;�                      memoria principal
;���������������������������������������������������������������������������
;�      Salida:         Error si hay Carry
;���������������������������������������������������������������������������
*/
int CreateVideoSLI(int X, int Y, int colorbits);
#pragma aux CreateVideoSLI "*" parm   [eax] [ebx] [ecx] \
                          modify [eax ebx ecx edx esi edi ebp] \
                          value  [eax];
/*
;���������������������������������������������������������������������������
;� GetVideoSLI:         Obtiene la superficie de video SLI
;���������������������������������������������������������������������������
;�      Entrada:        nada.
;���������������������������������������������������������������������������
;�      Salida:         EAX : ptr to Video SLI
;���������������������������������������������������������������������������
*/
SLI *GetVideoSLI(void);
#pragma aux GetVideoSLI "*" modify [eax ebx ecx edx esi edi ebp] \
                            value  [eax];
/*
;���������������������������������������������������������������������������
;� ShowVideoSLI:        Muestra la superficie de video SLI
;���������������������������������������������������������������������������
;�      Entrada:        nada.
;���������������������������������������������������������������������������
;�      Salida:         nada.
;���������������������������������������������������������������������������
*/
void ShowVideoSLI(void);
#pragma aux ShowVideoSLI "*" modify [eax ebx ecx edx esi edi];

/*
;���������������������������������������������������������������������������
;� DestroyVIdeoSLI:          desaloja el VideoSLI
;���������������������������������������������������������������������������
;�      Entrada:        EAX <> 0 modo de video a seleccionar
;���������������������������������������������������������������������������
;�      Salida:         nada.
;���������������������������������������������������������������������������
*/
void DestroyVideoSLI(int nmode);
#pragma aux DestroyVideoSLI "*" parm [eax]\
                          modify [eax ebx ecx edx esi edi ebp];
/*
;���������������������������������������������������������������������������
;� SetPalette:          Pone el puntero a una paleta B:G:R:0
;���������������������������������������������������������������������������
;�      Entrada:        EAX -> SLI
;�                      EBX -> Palette
;���������������������������������������������������������������������������
;�      Salida:         nada.
;���������������������������������������������������������������������������
*/
void SetPalette(SLI *punterosli, BYTE *paleta);
#pragma aux SetPalette "*" parm [eax] [ebx]\
                          modify [eax ebx ecx edx esi edi ebp];
/*
;���������������������������������������������������������������������������
;� ClearCurrentFrame:   Borra el frame actual al color dado
;���������������������������������������������������������������������������
;�      Entrada:        EAX -> SLI
;�                      EBX -> color en el formato del SLI
;���������������������������������������������������������������������������
;�      Salida:         nada.
;���������������������������������������������������������������������������
*/
void ClearCurrentFrame(SLI *punterosli, DWORD color);
#pragma aux ClearCurrentFrame "*" parm [eax] [ebx]\
                          modify [eax ebx ecx edx esi edi ebp];
/*
;�����������������������������������������������������������������������������
; Makes a blit of source SLI to target SLI
;
; INPUT : ESI -> Source SLI
;         EDI -> Target SLI
;�����������������������������������������������������������������������������
*/
void Blit(SLI *destino, SLI *fuente);
#pragma aux Blit "*" parm [edi] [esi]\
                     modify [eax ebx ecx edx esi edi ebp];
/*
;�����������������������������������������������������������������������������
; Loads a graphic file into a memory SLI
;
; INPUT  : EAX -> GFX file name
;          EBX = Output SLI color depth (number of bits)
;
; OUTPUT : CF = 0 if success
;               EAX = NULL
;               EBX -> Memory SLI
;          CF = 1 if error
;               EAX = Error code
;�����������������������������������������������������������������������������
*/
SLI *LoadGFX(char *name, int colorbits);
#pragma aux LoadGFX "*" parm [eax] [ebx]\
                     modify [eax ebx ecx edx esi edi ebp]\
                     value [ebx];
/*
;�����������������������������������������������������������������������������
; Pone el color de m�scara
;
; INPUT : EAX -> SLI
;         EBX = Color de m�scara en formato B:G:R:0
;�����������������������������������������������������������������������������
global  SetMaskColor : NEAR
*/
void SetMaskColor(SLI *slip, int color);
#pragma aux SetMaskColor "*" parm [eax] [ebx]\
                     modify [eax ebx ecx edx esi edi ebp];
/*
;�����������������������������������������������������������������������������
; Pone el m�todo de blitting
;
; INPUT : EAX -> SLI
;         EBX = Tipo de blit ('SLIBlitCopy', 'SLIBlitAlpha', 'SLIBlitAlphaMap'
;                             y los mismos con '+ SLIMaskedColor' para poner
;                             con m�scara)
;�����������������������������������������������������������������������������
global  SetBlitType : NEAR
 */
void SetBlitType(SLI *slip, int type);
#pragma aux SetBlitType "*" parm [eax] [ebx]\
                     modify [eax ebx ecx edx esi edi ebp];
/*
;�����������������������������������������������������������������������������
; Pone el n�mero de frame actual
;
; INPUT  : EAX -> SLI
;          EBX = Frame
;
; OUTPUT : CF = 0 si ok
;               EAX = NULL
;          CF = 1 si error
;               EAX = Error code (INVALID_FRAME)
;�����������������������������������������������������������������������������
global  SetFrame : NEAR
*/
int SetFrame(SLI *slip, int frame);
#pragma aux SetFrame "*" parm [eax] [ebx]\
                     modify [eax ebx ecx edx esi edi ebp]\
                     value [eax];
/*
;�����������������������������������������������������������������������������
; Devuelve el n�mero de frame actual
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX = Frame
;�����������������������������������������������������������������������������
global  GetFrame : NEAR
*/
int GetFrame(SLI *slip);
#pragma aux GetFrame "*" parm [eax]\
                     modify [eax ebx ecx edx esi edi ebp]\
                     value [eax];

/*
;�����������������������������������������������������������������������������
; Pone el rect�ngulo de clipping
;
; INTPUT : EAX = x1
;          EBX = y1
;          ECX = x2
;          EDX = y2
;          EDI -> SLI
;�����������������������������������������������������������������������������
global  SetClip : NEAR
*/
void SetClip(SLI *slip, int x1, int y1, int x2, int y2);
#pragma aux SetClip "*" parm [edi] [eax] [ebx] [ecx] [edx]\
                     modify [eax ebx ecx edx esi edi ebp];

/*
;�����������������������������������������������������������������������������
; Pone la posicion
;
; INTPUT : EAX = x1
;          EBX = y1
;          EDI -> SLI
;�����������������������������������������������������������������������������
global  SetPos : NEAR
*/
void SetPos(SLI *slip, int x1, int y1);
#pragma aux SetPos "*" parm [edi] [eax] [ebx]\
                       modify [eax ebx ecx edx esi edi ebp];

//����������������������������������������������������������������������������

void CreateLitTableSLI(SLI *slip, int nType, int niveles);
#pragma aux CreateLitTableSLI "*" parm   [eax] [ebx] [ecx] \
                               modify [eax ebx ecx edx esi edi ebp];

#define COLOR2WHITE 0   // 0 - Original .... 31 - Blanco
#define BLACK2COLOR 1   // 0 - Negro    .... 31 - Original
#define BLACK2WHITE 2   // 0 - Negro ... 15 - Original ... 31 - Blanco
#define ORIGINAL    3   // 0 - Original

typedef struct
{
  DWORD u;
  DWORD v;
  DWORD l;
} GRIDELEM;

typedef struct
{
  DWORD     GRIDXSize;
  DWORD     GRIDYSize;
  GRIDELEM  *GRIDPtr;
} GRID;

GRID *CreateGrid(DWORD dwXSize, DWORD dwYSize);
#pragma aux CreateGrid "*" parm   [eax] [ebx] \
                           value  [eax] \
                           modify [eax ebx ecx edx esi edi];

void Draw8x8Grid32Lit(SLI *output, GRID *Grid, SLI *texture);
#pragma aux Draw8x8Grid32Lit "*" parm   [edi] [esi] [edx] \
                            modify [eax ebx ecx edx esi edi ebp];

short int random(short int maxvalue);
#pragma aux random "*" parm [ax] \
                            modify [eax ebx ecx edx esi edi ebp]\
                            value [ax];

/*
;����������������������������������������������������������������������͸
;�  new!SpanBuffer                              Coded by Nitro! / [tDR] �
;����������������������������������������������������������������������͵
;�  INCLUDE                                                             �
;������������������������������������������������������������������������
*/
/*
;����������������������������������������������������������������������͸
;�  Estructura de los SPAN's                                            �
;����������������������������������������������������������������������͵
;�  SPAN con soporte de n variables de interpolacion                    �
;������������������������������������������������������������������������
 */
#define SPAN_MAX_INTERPOLATE_VARS 4

typedef struct
{
       BYTE *SPNext       ;// Puntero al siguiente span en la cadena
       BYTE *SPBack       ;// Puntero al span anterior en la cadena
       BYTE *SPTexture    ;// Puntero a la textura
       BYTE *SPLightMap   ;// Puntero a la tabla de conversion o paleta
       BYTE *SPAlpha      ;// Puntero al canal Alpha
       DWORD SPType       ;// Informacion del tipo de poly
/*                            ; 1 - Flat poly salida en 32 bits
                            ; 2 - Textured poly UV en 32 bits textura 8 bits
                            ; 3 - Gouraud poly UVL en 32 bits textura 8 bits (tabla de 7 bits)
                            ; 4 - SemiPhong UVL1L2 en 32 bits textura 8 bits Foco 7 bits (packed in 8)
                            ; 5 - Texture + 50% alphaEnvironment UV EU EV, textura y env. 7 bits (packed in 8)
                            ; 6 - Texture poly UV en 32 bits textura 32 bits
                            ; 7 - Flat poly alpha constante en 32 bits
                            ; 8 - Textured poly UV alpha constante en 32 bits textura 8 bits
                            ; 9 - Textured poly con canal alpha UV AU AV en 32 bits textura y alpha 8 bits
                            ; 10 - Textured poly con mascara color UV en 32 bits textura en 8 bits
                            ; 11 - Gouraud poly con mascara color UVL en 32 bits textura en 8 bits
                            ; SPT_PERS_CORRECTED Bandera para el calculo con correcion de perspectiva
                            ; SPT_ANTIALIASED    Bandera para bordes antialiaseados
                            ; SPT_BILINEAR_FILTERING Bandera para el filtro bilineal
                            ; SPT_TRANS_OR_MASK  Bandera para indicar algun tipo de transparencia
 */
       int   SPX1         ;// X inicial del segmento
       int   SPX2         ;// X final del segmento
       DWORD SPN          ;// Numero de variables a interpolar+1
       float SPVars[(SPAN_MAX_INTERPOLATE_VARS+1)*2]; // Variables + Incrementos
}    SPAN;
/*
;���������������������������������������������������������������������������
;� CreateSbufferSLI:    aloja un SBufferSLI en 32bits
;���������������������������������������������������������������������������
;�      Entrada:        EAX : Size X
;�                      EBX : Size Y
;���������������������������������������������������������������������������
;�      Salida:         EBX : puntero al SLI
;�                      EAX : ErrorCode
;���������������������������������������������������������������������������
    GLOBAL      CreateSBufferSLI : near*/
SLI *CreateSBufferSLI(int x, int y);
#pragma aux CreateSBufferSLI "*" parm   [eax] [ebx] \
                              modify [eax ebx ecx edx esi edi ebp] \
                              value  [ebx];
/*
;���������������������������������������������������������������������������
;� SLI2SBuffer:         Prepara un SLI para ser un SBuffer
;���������������������������������������������������������������������������
;�      Entrada:        EAX : Puntero al SLI de 32bits a convertir
;���������������������������������������������������������������������������
;�      Salida:         EAX : Standard ErrorCode
;���������������������������������������������������������������������������
    GLOBAL      SLI2SBuffer : near
 */
int SLI2SBuffer(SLI *slip);
#pragma aux SLI2SBuffer "*" parm   [eax] \
                            modify [eax ebx ecx edx esi edi ebp] \
                            value  [eax];
/*
;���������������������������������������������������������������������������
;� InitSBufferSLI:      Prepara un SLI para ser un SBuffer
;���������������������������������������������������������������������������
;�      Entrada:        EAX : Puntero al SBufferSLI
;���������������������������������������������������������������������������
;�      Salida:         nada.
;���������������������������������������������������������������������������
    GLOBAL      InitSBufferSLI : near
*/
void InitSBufferSLI(SLI *slip);
#pragma aux InitSBufferSLI "*" parm   [eax] \
                              modify [eax ebx ecx edx esi edi ebp];
/*
;����������������������������������������������������������������������͸
;�  InsertSpan: Inserta un Span       [Internal use only]               �
;����������������������������������������������������������������������͵
;�         Entrada   :   EAX - Puntero al SpanBufferSLI                 �
;�                       EBX - Puntero al Span                          �
;�                       ECX - Scanline donde insertar el Span          �
;�          Salida   :   nada.                                          �
;������������������������������������������������������������������������
    GLOBAL      InsertSpan : near
*/
void InsertSpan(SLI *slip, SPAN *spanp, int y);
#pragma aux InsertSpan  "*" parm   [eax] [ebx] [ecx] \
                            modify [eax ebx ecx edx esi edi ebp];
/*
;����������������������������������������������������������������������͸
;�  RenderSBufferSLI :   Renderiza el SBufferSLI                        �
;����������������������������������������������������������������������͵
;�         Entrada   :   EAX - Puntero al SpanBufferSLI                 �
;�          Salida   :   nada.                                          �
;������������������������������������������������������������������������
    GLOBAL      RenderSBufferSLI:near
*/

void RenderSBufferSLI(SLI *slip);
#pragma aux RenderSBufferSLI "*" parm [eax] \
                                 modify [eax ebx ecx edx esi edi ebp];

typedef struct
{
        float   x,y,z;
} POINT3D;

typedef struct
{
  float X, Y, k[SPAN_MAX_INTERPOLATE_VARS+1];
  POINT3D       PointPos;
  int           PointFlags;
  POINT3D       OrigPointPos,OrigNormal,Normal;
} RENDERPOINT;

typedef struct
{
  DWORD Type;
  DWORD N;
  RENDERPOINT *P1;
  RENDERPOINT *P2;
  RENDERPOINT *P3;
  SLI *Texture1;
  SLI *Texture2;
  int   PolyFlags;
  POINT3D PNormal;
} RENDERPOLY;

typedef struct
{
        int             polygons;
        RENDERPOLY      *polydata;
        int             points;
        RENDERPOINT     *pointdata;
        POINT3D         Pivot;
        char            MeshName[128];
} RENDERMESH;

typedef struct
{
        POINT3D         CamPos,CamOrientation;
        int             CamFocus;
        // Useful precalculated values
        int             sin_alpha,cos_alpha,sin_beta,cos_beta,sin_gamma,cos_gamma;
        // The useful name
        char            CamName[128];
} RENDERCAMERA;

typedef struct
{
        SLI             MatSLI;
        char            MatName[128];
} RENDERMATERIAL;

typedef struct
{
        POINT3D         LightPos,LightVector;
        int             LightIntensity;
        char            LightName[128];
} RENDERLIGHT;

typedef struct
{
        int             NumMeshes;
        RENDERMESH      *MeshArray;
        int             NumCameras;
        RENDERCAMERA     *CameraArray;
        int             NumLights;
        RENDERLIGHT     *LightArray;

        void            *WorldDestructor;
} RENDERWORLD;

void NormalizeVector(POINT3D *v);
#pragma aux NormalizeVector "*" parm   [eax] \
                             modify [eax ebx ecx edx esi edi ebp];

void GenericTriangleMapper(SLI *sbuffer, RENDERPOLY *p);

extern SLI *OS;

int InitGraph(int *modelist);

void ShowFrame(void);

/*
; Inicializa el contador de frames a la frecuencia del refresco de pantalla
;
; INPUT  -> AL = Screen sync. flag
;                (0 : don't synchronize , 1 : synchronize with vert. retrace)
;
; OUTPUT -> CF = 0 if success
;           CF = 1 if error
;               AL = error code
;                       01h - no room for timers
;                       02h - sync error (we are under Windows 95+)
;�����������������������������������������������������������������������������*/
void InitVirtualFrameRate(int flag);
#pragma aux InitVirtualFrameRate "*" parm   [eax] \
                             modify [eax ebx ecx edx esi edi ebp];

/*
 �����������������������������������������������������������������������������
; Fuerza el controlador de virtual frame rate a funcionar a una frecuencia
; concreta
; INPUT  -> EAX = 32 bit floating point frequency
; OUTPUT -> CF = 0 if success
;           CF = 1 if error
;�����������������������������������������������������������������������������*/
void  ForceVirtualFrameRate(float freq);
#pragma aux ForceVirtualFrameRate "*" parm   [eax] \
                             modify [eax ebx ecx edx esi edi ebp];

/*
;�����������������������������������������������������������������������������
; Finaliza el controlador de virtual frame rate
;�����������������������������������������������������������������������������
 */
void    EndVirtualFrameRate(void);
#pragma aux EndVirtualFrameRate "*" modify [eax ebx ecx edx esi edi ebp];

/*
;�����������������������������������������������������������������������������
; Gets elpased time from last call to routine
;�����������������������������������������������������������������������������
*/
void GetElapsedTime(void);
#pragma aux  GetElapsedTime "*" modify [eax ebx ecx edx esi edi ebp];

/*
;�����������������������������������������������������������������������������
; Increments a float with virtual frame rate
;
; INPUT : EAX -> Float
;         EBX = Float increment
;�����������������������������������������������������������������������������
 */
void IncFloat (float *out, float in);
#pragma aux  IncFloat "*" parm [eax] [ebx]\
                          modify [eax ebx ecx edx esi edi ebp];


#include <video.h>

#ifdef __cplusplus
  };
#endif

#endif
