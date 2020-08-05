;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같 LoadModule 같
; Entrada :     DS:EDX - Puntero al nombre del fichero
; Salida  :     CF = 0 + EAX = 0 si no hay error,
;               CF = 1 + EAX = C줰igo de error:
;                               01 = No se encuentra el fichero
;                               02 = No hay memoria
;                               03 = No es formato MOD ni S3M
;                               04 = Error interno de carga del fichero
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        global LoadModule:NEAR



;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같 InitPlayer 같
; Salida  :     CF = 0 + EAX = 0 si no hay error,
;               CF = 1 + EAX = C줰igo de error:
;                               01 = SB no detectada
;                               02 = No hay memoria para el buffer DMA
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        global InitPlayer:NEAR



;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같 PLAY 같
        global PLAY:NEAR



;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같 STOP 같
        global STOP:NEAR



;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같 Check4Sync 같
; Salida  :     CF = 1 + EAX = -1 si no hay ninguna marca de sincronizaci줻,
;               CF = 0 + EAX = marca de sincronizaci줻
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        global Check4Sync:NEAR



;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같� flags 같
; Bit 0 : Enable surround
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
        global PlayerFlags:BYTE

        global  frecuencia: DWORD
