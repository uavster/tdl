;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; file: filesys.asm
;
;  TX32's file system.
;
;       by Xavier Rubio Jansana, a.k.a. Teknik / #Trouble# Team, July 1998
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

        .386p
        .model  flat

        .code

        INCLUDE stderror.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ENTRY   struc

fname   db  13 dup (?)
foffset dd  ?
len     dd  ?

        ends

VIRTUAL_FAT struc

free_slot       dd  ?                   ; slot lliure o ocupat
true_handle     dd  ?                   ; handle real del fitxer
start_offset    dd  ?                   ; comen‡ament real del fitxer
file_len        dd  ?                   ; longitud virtual del fitxer
current_pos     dd  ?                   ; posici¢ actual al fitxer

        ends

MAX_ENTRIES equ 200                     ; n£mero d'entrades de fitxers

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

        include filesys.inc
        include alloc.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Inicialitza el sistema de fitxers virtuals de la TTL.
;
;  parameters:
;    edx - punter al nom del fitxer de llibreria.
;
;  returns:
;    cf - set if error
;    eax - 0 on error, -1 si ok
;
;  modifies:
;    eax, ebx, ecx, edx, esi, edi
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ttl_initFS proc

        mov     esi, edx                ; Copia el nom del fitxer
        mov     edi, offset vfname
        mov     ecx, 12 / 4
        rep     movsd

        mov     ah, 3dh                 ; Obre el fitxer de llibreria
        int     21h
        jc      ifs_error

        mov     ebx, eax
        mov     ah, 42h                 ; Comprova si ho ‚s o no
        mov     al, SEEK_END
        mov     edx, -4
        shld    ecx, edx, 16            ; cx:dx <- file position
        int     21h
        jc      ifs_error

        mov     edx, offset sign
        mov     ah, 3fh
        mov     ecx, 4
        int     21h
        jc      ifs_error

        cmp     dword ptr sign, "KCPT"  ; "TPCK" :'( TASM
        jc      ifs_error

        mov     ah, 42h                 ; Carrega la taula d'entrades
        mov     al, SEEK_END
        mov     edx, -8
        shld    ecx, edx, 16            ; cx:dx <- file position
        int     21h
        jc      ifs_error

        mov     edx, offset off
        mov     ah, 3fh
        mov     ecx, 4
        int     21h
        jc      ifs_error

        mov     ah, 42h
        mov     al, SEEK_SET
        mov     edx, off
        shld    ecx, edx, 16            ; cx:dx <- file position
        int     21h
        jc      ifs_error

        mov     edx, offset entries
        mov     ah, 3fh
        mov     ecx, 4
        int     21h
        jc      ifs_error

        mov     edx, offset rpck_files
        mov     ecx, entries
        cmp     ecx, MAX_ENTRIES
        ja      ifs_error
        imul    ecx, ecx, size ENTRY
        mov     ah, 3fh
        int     21h
        jc      ifs_error

        mov     ah, 3eh                 ; Tanca el fitxer
        int     21h

        mov     eax, -1
        clc
        ret

ifs_error:
        mov     ah, 3eh                 ; Tanca el fitxer
        int     21h

        xor     eax, eax
        stc
        ret

        endp
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Opens a file with the desired access.
;
;  parameters:
;    edx - pointer to file name to open
;    al - access rights
;
;  returns:
;    cf - set if error
;    eax - handle of file (NULL on error)
;
;  modifies:
;    eax
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ttl_open proc

comment ~²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²

        cmp     virtual_filesys, 1
        je      virtual_open

        ²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²~

        mov     ah, 3dh                 ; Obre el fitxer normal
        int     21h
        jnc     o_ok
o_error:
        xor     eax, eax
        stc
o_ok:   ret

comment ~²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²

virtual_open:                           ; Registra l'apertura del fitxer

        push    edx
        mov     edx, offset vfname
        mov     ah, 3dh
        int     21h
        jc      o_error

        call    search_free_slot

        mov     ebx, curr_vfat_entry
        add     curr_vfat_entry, size VIRTUAL_FAT
        mov     [ebx + true_handle], eax
        mov     ecx, curr_handle
        inc     curr_handle
        mov     [ebx + virtual_handle], ecx

        call    GetOffset

        d

virtual_handle  dd  ?                   ; handle virtual del fitxer
true_handle     dd  ?                   ; handle real del fitxer
start_offset    dd  ?                   ; comen‡ament real del fitxer
file_len        dd  ?                   ; longitud virtual del fitxer
current_pos     dd  ?                   ; posici¢ actual al fitxer

        ²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²~

        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Creates a file.
;
;  parameters:
;    edx - pointer to file name to create
;
;  returns:
;    cf - set if error
;    eax - handle of file (NULL on error)
;
;  modifies:
;    eax
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ttl_create proc

        push    ecx
        xor     ecx, ecx
        mov     ah, 3ch
        int     21h
        pop     ecx
        jnc     c_ok
        xor     eax, eax
        stc
c_ok:   ret

        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Closes a file.
;
;  parameters:
;    ebx - file handle
;
;  returns:
;    cf - set if error
;
;  modifies:
;    eax
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ttl_close proc

        mov     ah, 3eh
        int     21h
        ret

        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Reads from a file.
;
;  parameters:
;    edx - pointer to buffer
;    ebx - file handle
;    ecx - number of bytes to read
;
;  returns:
;    cf - set if error
;    eax - number of bytes read (zero on error)
;
;  modifies:
;    eax
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ttl_read proc

        mov     ah, 3fh
        int     21h
        jnc     r_ok
        xor     eax, eax
        stc
r_ok:   ret

        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Writes to a file.
;
;  parameters:
;    edx - pointer to buffer
;    ebx - file handle
;    ecx - number of bytes to write
;
;  returns:
;    cf - set if error
;    eax - number of bytes written (zero on error)
;
;  modifies:
;    eax
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ttl_write proc

        mov     ah, 40h
        int     21h
        jnc     w_ok
        xor     eax, eax
        stc
w_ok:   ret

        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets current file position
;
;  parameters:
;    al - origin of move
;    ebx - file handle
;    edx - file position
;
;  returns:
;    cf - set if error
;    eax - new file position
;
;  modifies:
;    eax
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ttl_seek proc

        mov     ah, 42h
        push    ecx
        push    edx
        shld    ecx, edx, 16            ; cx:dx <- file position
        int     21h
        shl     edx,16
        mov     dx,ax
        mov     eax, edx
        pop     edx
        pop     ecx
        ret

        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets file length
;
;  parameters:
;    ebx - file handle
;
;  returns:
;    cf - set if error
;    eax - file length or -1 if error
;
;  modifies:
;    eax
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ttl_file_length proc

        mov     al, SEEK_END
        xor     edx, edx
        call    ttl_seek
        jc      fl_error
        mov     file_size,eax
        ret

fl_error:
        mov     eax, -1
        stc
        ret

        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Loads a file and returns a pointer to it.
;
;  parameters:
;    edx - file name
;
;  returns:
;    cf - set if error
;    ebx - pointer to file in memory, NULL if error
;    ecx - file size
;
;  modifies:
;    eax, ebx, ecx, edx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ttl_load_file   proc

        mov     al, READ_ONLY
        call    ttl_open
        jc      load_error
        mov     file_handle,eax
        mov     ebx,eax
        call    ttl_file_length
        jc      load_error
        mov     ecx, eax
        call    malloc
        or      ebx,ebx
        stc
        jz      load_error
        mov     mem_ptr,ebx
        mov     al, SEEK_SET
        xor     edx, edx
        mov     ebx,file_handle
        call    ttl_seek
        jc      load_error
        mov     ecx, file_size
        mov     ebx,file_handle
        mov     edx,mem_ptr
        call    ttl_read
        jc      load_error
        mov     ebx,file_handle
        call    ttl_close
        jc      load_error
        clc
        mov     ecx,file_size
        load_error:
        mov     ebx,mem_ptr
        ret

        endp


;Ä[B52]ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
load_data_chunk proc
        mov     dest_ptr,edi
        mov     source_start,esi
        mov     data_size,ecx
        mov     al,READ_ONLY
        call    ttl_open
        ErrorCode FILE_OPEN_ERROR
        mov     fhandle,eax
        mov     ebx,eax
        mov     al,SEEK_SET
        mov     edx,source_start
        call    ttl_seek
        ErrorCode FILE_SEEK_ERROR
        mov     ebx,fhandle
        mov     ecx,data_size
        mov     edx,dest_ptr
        call    ttl_read
        ErrorCode FILE_READ_ERROR
        cmp     eax,data_size
        ErrorCode FILE_READ_ERROR
        mov     ebx,fhandle
        call    ttl_close
        ErrorCode FILE_CLOSE_ERROR
        mov     eax,NO_ERROR
        clc
        ret
load_data_chunk endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Busca un slot lliure a la taula virtual de fitxers.
;
;  returns:
;    cf - si no hi han slots lliures
;    ebx - punter al slot
;
;  modifies:
;    ecx, ebx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

search_free_slot    proc

        mov     ebx, offset vfat        ; Busca un lloc lliure
        mov     ecx, MAX_ENTRIES
sfs_lp: cmp     [ebx].free_slot, 1
        je      sfs_found
        add     ebx, size VIRTUAL_FAT
        dec     ecx
        jnz     sfs_lp

        stc
        ret

sfs_found:

        clc
        ret

        endp

;ÚÄ GetOffset ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                                                                          ³
;³ Descripci¢ : Obt‚ l'offset i longitud del fitxer fname dins lib.         ³
;³                                                                          ³
;³ Arguments  : eax - handle de la llibreria on buscar.                     ³
;³              edx - fitxer a buscar.                                      ³
;³                                                                          ³
;³ Retorna    : eax - offset de fname dins lib                              ³
;³              len - punter a la variable que rebr… la longitud (o NULL).  ³
;³                                                                          ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ*/

comment ~²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²

GetOffset   proc

        mov

  // Busca el fitxer
  for (i = 0; i < entries && strcmp(rpck_files[i].fname, fname); i++) ;
  if (i == entries)
    return -1;

  // Returna la informaci¢
  if (len != NULL)
    *len = rpck_files[i].len;
  return rpck_files[i].foffset;
}

        ²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²~

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

        .data

virtual_filesys dd      0               ; Activa virtualitzaci¢ de fitxers

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

        .data?

vfname      db          12 dup (?)          ; Nom del contenidor
rpck_files  ENTRY       MAX_ENTRIES dup (?) ; Taula d'entrades de fitxers
vfat        VIRTUAL_FAT MAX_ENTRIES dup (?) ; Taula de fitxers oberts

sign        dd          ?
off         dd          ?
entries     dd          ?

file_handle dd          ?
mem_ptr     dd          ?               ; Punter de mem•ria per fer el loadfile
file_size   dd          ?               ; s'omple amb ttl_file_length

;---'load_file_piece' data---[B52]--
fhandle         dd ?
data_size       dd ?
source_start    dd ?
dest_ptr        dd ?
;-----------------------------------
        end

