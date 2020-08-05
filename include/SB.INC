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

        extrn   DSPVerH: BYTE
