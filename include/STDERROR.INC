;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; C¢digos de error standard
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

NO_ERROR            EQU 0


MEMORY_ERROR        EQU 1 SHL 16    ; Errores de memoria

    MALLOC_ERROR        EQU MEMORY_ERROR OR 1
    REALLOC_ERROR       EQU MEMORY_ERROR OR 2
    FREE_ERROR          EQU MEMORY_ERROR OR 3


FORMAT_ERROR        EQU 2 SHL 16    ; Errores de formato (archivos,buffers,cadenas,...)

    INVALID_FORMAT      EQU FORMAT_ERROR OR 1
    INVALID_FIELD       EQU FORMAT_ERROR OR 2


FILE_ERROR          EQU 3 SHL 16    ; Errores de archivo

    FILE_OPEN_ERROR     EQU FILE_ERROR OR 1
    FILE_READ_ERROR     EQU FILE_ERROR OR 2
    FILE_WRITE_ERROR    EQU FILE_ERROR OR 3
    FILE_SEEK_ERROR     EQU FILE_ERROR OR 4
    FILE_CLOSE_ERROR    EQU FILE_ERROR OR 5


VIDEO_ERROR         EQU 4 SHL 16

    INVALID_VIDEO_MODE  EQU VIDEO_ERROR OR 1

PARAMETER_ERROR     EQU 5 SHL 16

    INVALID_PARAMETER   EQU PARAMETER_ERROR OR 1

BLITTER_ERROR       EQU 6 SHL 16

    UNIMPLEMENTED_PROC  EQU BLITTER_ERROR OR 1

SLI_ERROR           EQU 7 SHL 16

    INVALID_COLOR_DEPTH EQU SLI_ERROR OR 1
    INVALID_FRAME       EQU SLI_ERROR OR 2 

ENVIRONMENT_ERROR   EQU 8 SHL 16

    ENV_VAR_NOT_FOUND   EQU ENVIRONMENT_ERROR OR 1
    ENV_VAR_INCORRECT   EQU ENVIRONMENT_ERROR OR 2

WUF_ERROR           EQU 9 SHL 16

   NO_SOUND_DEVICE      EQU WUF_ERROR OR 1
   SDEV_OPEN_ERROR      EQU WUF_ERROR OR 2
   SDEV_CLOSE_ERROR     EQU WUF_ERROR OR 3

LIST_ERROR          EQU 10 SHL 16

   ELEMENT_NOT_FOUND    EQU LIST_ERROR OR 1

HARDWARE_ERROR      EQU 11 SHL 16

MIXER_ERROR         EQU 11 SHL 16

   NO_FREE_CHANNELS     EQU MIXER_ERROR OR 1

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Macro de salida de error codes
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ErrorCode   MACRO ECode
LOCAL   ok_label
        jnc     ok_label
            mov     eax, ECode
            ret
        ok_label:
        ENDM

ErrorCodePOP   MACRO ECode, popes:rest
LOCAL   ok_label
        jnc     ok_label
            pop     popes
            mov     eax, ECode
            ret
        ok_label:
        ENDM
