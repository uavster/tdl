;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; file: filesys.inc
;
;  TX32's file system.
;
;       by Xavier Rubio Jansana, a.k.a. Teknik / #Trouble# Team, July 1998
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

READ_ONLY       equ     0               ; access rights
WRITE_ONLY      equ     1
READ_WRITE      equ     2

SEEK_SET        equ     0               ; start of file
SEEK_CUR        equ     1               ; current file position
SEEK_END        equ     2               ; end of file

                global  ttl_open        : near
                global  ttl_create      : near
                global  ttl_close       : near
                global  ttl_read        : near
                global  ttl_write       : near
                global  ttl_seek        : near
                global  ttl_file_length : near
                global  ttl_load_file   : near
                global  file_size       : dword

                global  load_data_chunk : near  ; [B52]

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Loads a file and returns a pointer to it.
;
;  parameters:
;    fname - file name
;
;  returns:
;    cf - set if error
;    esi - pointer to file in memory, NULL if error
;
;  modifies:
;    eax, ebx, ecx, edx, esi
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

load    MACRO fname
        LOCAL continua, filename

        mov     edx, offset filename
        call    ttl_load_file
        jmp     continua
filename db     fname,0
        continua:

        ENDM

;�[B52]컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Loads a piece of data from the given file to the destination buffer
;
; INPUT  : EDX -> File name
;          ECX = Size of data to load
;          ESI = Start of data into file from initial position
;          EDI -> destination buffer
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if error
;               EAX = Error code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
LoadChunk       MACRO   fname,fpos,dstart,dsize
LOCAL   file_name,lc_end
        mov     edx,offset file_name
        mov     ecx,dsize
        mov     esi,fpos
        mov     edi,dstart
        call    load_data_chunk
        jmp     lc_end
file_name       db fname
        lc_end:
        ENDM

