//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
// fichero: player.h
//
//  Fichero de cabecera para el Player
//
//    by Javier Rodr¡guez Caminero, a.k.a. Demon / #Trouble# Team
//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

#define INT3    _asm {        int 3        }


//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° LoadModule °°
// Entrada :     DS:EDX - Puntero al nombre del fichero
// Salida  :     CF = 0 + EAX = 0 si no hay error,
//               CF = 1 + EAX = C¢digo de error:
//                               01 = No se encuentra el fichero
//                               02 = No hay memoria
//                               03 = No es formato MOD ni S3M
//                               04 = Error interno de carga del fichero
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
DWORD LoadModule(BYTE *filename);
#pragma aux LoadModule "*"  parm   [edx] \
                            modify [eax ebx ecx edx esi edi ebp] \
                            value  [eax];

//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° InitPlayer °°
// Entrada :     EAX = Frecuencia
// Salida  :     CF = 0 + EAX = 0 si no hay error,
//               CF = 1 + EAX = C¢digo de error:
//                               01 = SB no detectada
//                               02 = No hay memoria para el buffer DMA
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
DWORD InitPlayer(DWORD freq);
#pragma aux InitPlayer "*"  parm   [eax] \
                            modify [eax ebx ecx edx esi edi ebp] \
                            value  [eax];

//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° PLAY °°
void PLAY(void);
#pragma aux PLAY "*" modify [eax ebx ecx edx esi edi ebp];

//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° STOP °°
void STOP(void);
#pragma aux STOP "*" modify [eax ebx ecx edx esi edi ebp];

//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° Check4Sync °°
// Salida  :     CF = 1 + EAX = -1 si no hay ninguna marca de sincronizaci¢n,
//               CF = 0 + EAX = marca de sincronizaci¢n
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
DWORD Check4Sync(void);
#pragma aux Check4Sync "*"  modify [eax ebx ecx edx esi edi ebp] \
                            value  [eax];


void SetVolume(DWORD vol);
#pragma aux SetVolume "*"   parm   [eax] \
                            modify [eax ebx ecx edx esi edi ebp];

void SetGlobalVolume(DWORD vol);
#pragma aux SetGlobalVolume "*"   parm   [eax] \
                            modify [eax ebx ecx edx esi edi ebp];


void PlayNote(DWORD instr, DWORD canal, DWORD period, DWORD volume);
#pragma aux PlayNote "*"    parm   [eax][ebx][edx][ecx] \
                            modify [eax ebx ecx edx esi edi ebp];






extern BYTE *pattern[];
#pragma aux pattern "*";
extern BYTE NumChannels;
#pragma aux NumChannels "*";
extern WORD PattNRows[];
#pragma aux PattNRows "*";
extern BYTE orders[];
#pragma aux orders "*";
extern BYTE SongName[];
#pragma aux SongName "*";


extern BYTE PlayerFlags;
#pragma aux PlayerFlags "*";




extern WORD current_period[];
#pragma aux current_period "*";



/*



;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° PLAY °°
        extrn PLAY:NEAR



;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° STOP °°
        extrn STOP:NEAR



;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° Check4Sync °°
; Salida  :     CF = 1 + EAX = -1 si no hay ninguna marca de sincronizaci¢n,
;               CF = 0 + EAX = marca de sincronizaci¢n
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
        extrn Check4Sync:NEAR



;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° flags °°
; Bit 0 : Enable surround
; Bit 1 : Enable row & pattern info
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
        extrn PlayerFlags:BYTE


















;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° ReadMixer °°
; Entrada :     AL - Registro del Mixer
; Salida  :     AL - Valor del registro del Mixer
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
        EXTRN ReadMixer:NEAR

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° WriteMixer °°
; Entrada :     AL - Valor a escribir en el DSP
;               AH - Registro del Mixer
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
        EXTRN WriteMixer:NEAR

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° ReadDSP °°
; Salida  :     AL - Valor le¡do del DSP
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
        EXTRN ReadDSP:NEAR

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° WriteDSP °°
; Entrada :     AL - Valor a escribir en el DSP
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
        EXTRN WriteDSP:NEAR


;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° SBReset °°
; Entrada :     Se tiene que haber inicializado la SB
; Salida  :     CF=0 y EAX=0 si no hay error,
;               CF=1 y EAX=N£mero de error:
;                               01 = SB no inicializada
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
        EXTRN SBReset:NEAR

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° SBDetect °°
; Salida  :     CF=0 y EAX=0 si no hay error,
;               CF=1 y EAX=N£mero de error:
;                               01 = SB no detectada
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
        EXTRN SBDetect:NEAR

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° SBInfo °°
; Salida  :     ESI - Puntero al nombre de la tarjeta de sonido
;               EDI - Configuraci¢n de los puertos
;               AX  - Versi¢n del DSP (ax=040d -> ver=4.13)
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
        EXTRN SBInfo:NEAR

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° SBPlay °°
; Entrada :     EAX    - Frecuencia
;               ECX    - Tama¤o del buffer (bit31=1 para usar t‚cnica del
;                                           doble buffer)
;               CS:EBX - IRQ de la SB (EBX=0 para no cambiarla, EBX=-1 para
;                                                   poner una rutina dummy)
;               DS:ESI - Buffer DMA (m x 64 Kb, direcci¢n f¡sica)
;               DL     - Flags (no implementados --> siempre en Stereo)
; Salida  :     CF = 0 + EAX = 0 si no hay error,
;               CF = 1 + EAX = C¢digo de error:
;                               01 = La SB no hab¡a sido inicializada
;                               02 = Tarjeta incompatible
;                               03 = No es formato MOD ni S3M
;                               04 = Error interno de carga del fichero
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
        EXTRN SBPlay:NEAR

        EXTRN SBStop:NEAR


        EXTRN GetSBDMAptr:NEAR


        EXTRN SetVolume:NEAR
        EXTRN SetGlobalVolume:NEAR


;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° SBManualSetup °°
; Entrada :     AX = Puerto
;               BL = IRQ
;               BH = DMA
;               CH.CL = DSP Ver
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
        EXTRN SBManualSetup:NEAR



;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° SBPlay °°
; Entrada :     CS:EBX - IRQ de la SB (EBX=0 para no cambiarla, EBX=-1 para
;                                                   poner una rutina dummy)
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
        EXTRN   ChangeMixR:NEAR
        EXTRN   GetMixR:NEAR


*/

