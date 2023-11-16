/*����������������������������������������������������������������������������
 Include file for SLI handling functions
 Author: Ignacio Mellado Bataller a.k.a. B52 / the DarkRising
����������������������������������������������������������������������������*/

#ifndef _SLI_INCLUDED_
#define _SLI_INCLUDED_

#include <stddef.h>

#ifdef __cplusplus
  extern "C" {
#endif

//    Blitting basic methodes
#define SLIBlitCopy       	0		// Default
#define SLIBlitAlpha      	1
#define SLIBlitAlphaMap   	2
#define SLIBlitAddSaturate	3

#define SLIMaskedColor    	4
#define SLIScaled			8

// Animation modes
#define SLIAnimNormal		0	// Default
#define SLIAnimForwardLoop	1
#define SLIAnimPingPongLoop	2

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

    SLR SLIPos; // Posicion del sprite en destino
    SLP SLIRef; // Posicion de referencia dentro del sprite
    SLR SLIClip; //Zona de clipping (en coordenadas de pantalla)

    DWORD SLIXSize;// Ancho
    DWORD SLIYSize;// Alto

    DWORD SLIPitch;// ancho de la imagen que la contiene
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
    DWORD SLIStartTicks		; //Valor del timer la �ltima vez que se cambi� el frame actual manualmente o la velocidad de reproducci�n
    DWORD SLIStartFrame		; //Frame de inicio de animaci�n en 16.16
    DWORD SLILoopStart		; //Frame de inicio del loop de animaci�n
    DWORD SLILoopEnd		; //Frame final del loop de animaci�n
    BYTE  *SLIFramePtr      ; //Puntero al frame actual

    void **SLIPImages        ; //puntero a la lista de punteros de frames

    DWORD SLITemp[SLI_TEMP_VARS];// Espacio para variables temporales

    DWORD SLIPalette[256]	; // paleta asociada si no la tiene = NULL
    BYTE  *SLILitTable    	; // puntero a una tabla de conversion si no la tiene = NULL
    DWORD SLISBufferNfo  	; // Datos para los sbufferSLI's
	int *SLIIntegralImage	; // Points at integral image, or NULL if not available.
  DWORD SLIIntegralImageMultiplier; // Factor by which entries are multiplied in the integral image
	// Loops will not work well when the end of the loop in fixed point 16.16
	// is above the range of a signed dword (2^31-1). That's 32,768 frames.
	BYTE SLIAnimMode		; //0 - Normal
							  //1 - Forward loop
							  //2 - Ping pong loop							
	BYTE SLIPlayingBackwards;
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
;�      Salida:         EBX : puntero al SLI o NULL
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
;� SetFrameData:       Set frame pointers to the given memory buffer. 
;					   The memory is owned by the caller and must be large
;					   enough to hold all frames.
;					   Frames must be contiguous in memory.
;���������������������������������������������������������������������������
;�      Entrada:        EDI : SLI pointer
;						ESI : Pointer to frame memory.
;���������������������������������������������������������������������������
*/
void SetFrameData(SLI *sli, void *data);
#pragma aux SetFrameData "*" parm	[edi] [esi] \
							 modify [eax ebx ecx edx esi edi ebp];

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
;               EBX = NULL
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
; Devuelve el n�mero total de frames
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EBX = N�mero de frames
;�����������������������������������������������������������������������������
global  GetNumFrames : NEAR
*/
int GetNumFrames(const SLI *slip);
#pragma aux GetNumFrames "*"	parm [eax]\
								modify [ebx]\
								value [ebx];
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
; Updates a SLI animation with the current synchronization timer ticks.
;
; INPUT  : ESI -> SLI
;�����������������������������������������������������������������������������
*/
void AnimateSLI(SLI *slip);
#pragma aux AnimateSLI "*" parm [esi]\
                     modify [eax ebx ecx edx esi edi ebp];

/*
;�����������������������������������������������������������������������������
; Updates a SLI animation with the passed timer ticks.
;
; INPUT  : ESI -> SLI
;		   EAX = Timer ticks
;�����������������������������������������������������������������������������
*/
void AnimateSLIWithTicks(SLI *slip, DWORD timer_ticks);
#pragma aux AnimateSLIWithTicks "*" parm [esi] [eax]\
                     modify [eax ebx ecx edx esi edi ebp]\
					 value [eax];

/*
;�����������������������������������������������������������������������������
; Sets the frame rate of a multiframe SLI.
;
; INPUT  : EAX -> SLI
;          EBX = Fixed point (16.16) frame rate in frames per second
;
; OUTPUT : CF = 0 if ok
;				EAX = NULL
;		   CF = 1 if error
;				EAX = Error code				
;�����������������������������������������������������������������������������
*/
int SetFrameRate(SLI *slip, DWORD frame_rate_fp);
#pragma aux SetFrameRate "*" parm [eax] [ebx]\
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

/*
;�����������������������������������������������������������������������������
; Devuelve el puntero a un frame determinado
;
; INPUT  : EAX -> SLI
;          EBX = Frame
;
; OUTPUT : CF = 0 si ok
;				EAX = 0
;               EBX -> Frame
;          CF = 1 si el frame no existe
;               EAX = Error code
;				EBX = NULL
;�����������������������������������������������������������������������������
global  GetFramePtr : NEAR
*/
void *GetFramePtr(SLI *slip, int frame);
#pragma aux GetFramePtr "*"	parm [eax] [ebx]\
							modify [eax ebx ecx edx esi edi ebp]\
							value [ebx];

/*
;�����������������������������������������������������������������������������
; Pone el puntero a un frame determinado
;
; INPUT  : EAX -> SLI
;          EBX = N�mero de frame
;          ECX -> Frame
;
; OUTPUT : CF = 0 si ok
;               EAX = NULL
;          CF = 1 si el frame no existe
;               EAX = Error code
;�����������������������������������������������������������������������������
global  SetFramePtr : NEAR
*/

/*
;�����������������������������������������������������������������������������
; Devuelve el puntero al frame actual
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX -> Frame actual
;�����������������������������������������������������������������������������
*/
void *GetCurrentFramePtr(SLI *slip);
#pragma aux GetCurrentFramePtr "*" parm [eax]\
                       modify [eax ebx ecx edx esi edi ebp]\
					   value [eax];

/*
;�����������������������������������������������������������������������������
; Devuelve las dimensiones (con escalado) del SLI
;
; INPUT  : EAX -> SLI
;
; OUTPUT : EAX = X size
;          EBX = Y size
;�����������������������������������������������������������������������������
global  GetDimensions : NEAR
*/

/*
;�����������������������������������������������������������������������������
; Pone el campo de alpha
;
; INPUT : EAX -> SLI
;         EBX = Alpha constante o puntero al mapa de alphas
;�����������������������������������������������������������������������������
*/
void SetAlpha(SLI *slip, void *alpha_value_or_map_ptr);
#pragma aux SetAlpha "*" 	parm [eax] [ebx]\
							modify [eax ebx ecx edx esi edi ebp];

/*
;�����������������������������������������������������������������������������
; Pone el modo de animaci�n
;
; INPUT : EAX -> SLI
;         BL = Modo de animaci�n
;�����������������������������������������������������������������������������
*/
void SetAnimMode(SLI *slip, BYTE anim_mode);
#pragma aux SetAnimMode "*" parm [eax] [ebx]\
							modify [eax ebx ecx edx esi edi ebp];

/*
;�����������������������������������������������������������������������������
; Pone el inicio del loop de animaci�n
;
; INPUT : EAX -> SLI
;         EBX = Frame inicial del loop
;�����������������������������������������������������������������������������
*/
void SetAnimLoopStartFrame(SLI *slip, DWORD start_frame);
#pragma aux SetAnimLoopStartFrame "*" parm [eax] [ebx]\
                       modify [eax ebx ecx edx esi edi ebp];

/*
;�����������������������������������������������������������������������������
; Pone el final del loop de animaci�n
;
; INPUT : EAX -> SLI
;         EBX = Frame final del loop
;�����������������������������������������������������������������������������
*/
void SetAnimLoopEndFrame(SLI *slip, DWORD end_frame);
#pragma aux SetAnimLoopEndFrame "*" parm [eax] [ebx]\
                       modify [eax ebx ecx edx esi edi ebp];

//����������������������������������������������������������������������������

void CreateLitTableSLI(SLI *slip, int nType, int niveles);
#pragma aux CreateLitTableSLI "*" parm   [eax] [ebx] [ecx] \
                               modify [eax ebx ecx edx esi edi ebp];

#define COLOR2WHITE 0   // 0 - Original .... 31 - Blanco
#define BLACK2COLOR 1   // 0 - Negro    .... 31 - Original
#define BLACK2WHITE 2   // 0 - Negro ... 15 - Original ... 31 - Blanco
#define ORIGINAL    3   // 0 - Original

#ifdef __cplusplus
  };
#endif

#endif
