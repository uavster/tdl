//컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
// fichero: player.h
//
//  Fichero de cabecera para el Player
//
//    by Javier Rodr죊uez Caminero, a.k.a. Demon / #Trouble# Team
//컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

#define INT3    _asm {        int 3        }


//같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같� LoadModule 같
// Entrada :     DS:EDX - Puntero al nombre del fichero
// Salida  :     CF = 0 + EAX = 0 si no hay error,
//               CF = 1 + EAX = C줰igo de error:
//                               01 = No se encuentra el fichero
//                               02 = No hay memoria
//                               03 = No es formato MOD ni S3M
//                               04 = Error interno de carga del fichero
//같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
DWORD LoadModule(BYTE *filename);
#pragma aux LoadModule "*"  parm   [edx] \
                            modify [eax ebx ecx edx esi edi ebp] \
                            value  [eax];

//같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같� InitPlayer 같
// Entrada :     EAX = Frecuencia
// Salida  :     CF = 0 + EAX = 0 si no hay error,
//               CF = 1 + EAX = C줰igo de error:
//                               01 = SB no detectada
//                               02 = No hay memoria para el buffer DMA
//같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
DWORD InitPlayer(DWORD freq);
#pragma aux InitPlayer "*"  parm   [eax] \
                            modify [eax ebx ecx edx esi edi ebp] \
                            value  [eax];

//같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같� PLAY 같
void PLAY(void);
#pragma aux PLAY "*" modify [eax ebx ecx edx esi edi ebp];

//같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같� STOP 같
void STOP(void);
#pragma aux STOP "*" modify [eax ebx ecx edx esi edi ebp];

//같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같� Check4Sync 같
// Salida  :     CF = 1 + EAX = -1 si no hay ninguna marca de sincronizaci줻,
//               CF = 0 + EAX = marca de sincronizaci줻
//같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
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



;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같 PLAY 같
        extrn PLAY:NEAR



;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같 STOP 같
        extrn STOP:NEAR



;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같 Check4Sync 같
; Salida  :     CF = 1 + EAX = -1 si no hay ninguna marca de sincronizaci줻,
;               CF = 0 + EAX = marca de sincronizaci줻
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        extrn Check4Sync:NEAR



;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같� flags 같
; Bit 0 : Enable surround
; Bit 1 : Enable row & pattern info
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        extrn PlayerFlags:BYTE


















;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같� ReadMixer 같
; Entrada :     AL - Registro del Mixer
; Salida  :     AL - Valor del registro del Mixer
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        EXTRN ReadMixer:NEAR

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같 WriteMixer 같
; Entrada :     AL - Valor a escribir en el DSP
;               AH - Registro del Mixer
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        EXTRN WriteMixer:NEAR

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같� ReadDSP 같
; Salida  :     AL - Valor le죆o del DSP
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        EXTRN ReadDSP:NEAR

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같 WriteDSP 같
; Entrada :     AL - Valor a escribir en el DSP
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        EXTRN WriteDSP:NEAR


;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같� SBReset 같
; Entrada :     Se tiene que haber inicializado la SB
; Salida  :     CF=0 y EAX=0 si no hay error,
;               CF=1 y EAX=N즡ero de error:
;                               01 = SB no inicializada
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        EXTRN SBReset:NEAR

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같 SBDetect 같
; Salida  :     CF=0 y EAX=0 si no hay error,
;               CF=1 y EAX=N즡ero de error:
;                               01 = SB no detectada
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        EXTRN SBDetect:NEAR

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같 SBInfo 같
; Salida  :     ESI - Puntero al nombre de la tarjeta de sonido
;               EDI - Configuraci줻 de los puertos
;               AX  - Versi줻 del DSP (ax=040d -> ver=4.13)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        EXTRN SBInfo:NEAR

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같 SBPlay 같
; Entrada :     EAX    - Frecuencia
;               ECX    - Tama쨚 del buffer (bit31=1 para usar t괹nica del
;                                           doble buffer)
;               CS:EBX - IRQ de la SB (EBX=0 para no cambiarla, EBX=-1 para
;                                                   poner una rutina dummy)
;               DS:ESI - Buffer DMA (m쟸 64 Kb, direcci줻 f죛ica)
;               DL     - Flags (no implementados --> siempre en Stereo)
; Salida  :     CF = 0 + EAX = 0 si no hay error,
;               CF = 1 + EAX = C줰igo de error:
;                               01 = La SB no hab죂 sido inicializada
;                               02 = Tarjeta incompatible
;                               03 = No es formato MOD ni S3M
;                               04 = Error interno de carga del fichero
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        EXTRN SBPlay:NEAR

        EXTRN SBStop:NEAR


        EXTRN GetSBDMAptr:NEAR


        EXTRN SetVolume:NEAR
        EXTRN SetGlobalVolume:NEAR


;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같� SBManualSetup 같
; Entrada :     AX = Puerto
;               BL = IRQ
;               BH = DMA
;               CH.CL = DSP Ver
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        EXTRN SBManualSetup:NEAR



;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같 SBPlay 같
; Entrada :     CS:EBX - IRQ de la SB (EBX=0 para no cambiarla, EBX=-1 para
;                                                   poner una rutina dummy)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        EXTRN   ChangeMixR:NEAR
        EXTRN   GetMixR:NEAR


*/

