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

        extrn   DSPVerH: BYTE
