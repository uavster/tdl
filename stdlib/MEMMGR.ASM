;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; file: memmgr.asm
;
;  Memory manager for Trouble's DOS extender.
;
;       by Teknik/Trouble, November of 1997
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

        JUMPS
        .386p
        .model flat

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

;DBG_NFO     equ     1                   ; comment out to avoid debug info
;SHEAP       equ     1                   ; comment out to not compile show_heap

HARDWIRED   equ     1                   ; uses "heap" as default value for eax
;DOS4G       equ     1                   ; fucking DOS4G !!!! I hate it!!!

ifdef   DBG_NFO

dbginfo macro title                     ; print debug info
        local txt

        pushad
        mov     ah, 9
        mov     edx, offset txt
        int     21h
        call    show_heap
        popad

        .data
txt     db      13, 10, "***** [", title, "] *****", 13, 10, "$"

        .code

        endm

SHEAP   equ     1                       ; we need it...

else    ; defined DBG_NFO

dbginfo macro                           ; don't need debug info
        endm

endif   ; defined DBG_NFO

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

;  All block lengths are a multiple of 4.

THEAP   struc

start   dd      ?               ; ptr to first block of heap
hlen    dd      ?               ; length of heap

        ends

TBLOCK  struc

blen    dd      ?               ; block length, without this header
status  db      ?               ; 'A' allocated, 'F' free
more    db      ?               ; 'M' more blocks, 'E' end of heap
sign    dw      ?               ; block signature "TX", not reversed as TASM does
prev    dd      ?               ; offset of previous block header, origin DS
next    dd      ?               ; offset of next block header, origin DS

        ends

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

BLOCKS  equ     100             ; we can get up to BLOCKS blocks

        .code

        include alloc.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes C heap. It gets all the DPMI extended memory and inits the
; memory pool using initheap and addheap.
;
;  modifies:
;    ecx, eax, ebx, edx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ


init_c_heap     proc

        mov     dl, BLOCKS              ; allocation counter
        xor     dh, dh                  ; heap initialized flag

    ich_loop:

            mov     ax, 500h                ; get memory info
            mov     edi, offset dpminfo
            int     31h

            mov     ebx, dword ptr [dpminfo]; allocate the memory
            or      ebx, ebx
            jz      ich_end

ifdef   DOS4G   ; --------------------------------

            shr     ebx, 1                  ; to allow debugging with
            add     ebx, dword ptr [dpminfo];  fucking DOS@#$&%!!! >:-(
            shr     ebx, 1
            cmp     ebx, 4096               ; si < 4 kb => 0
            jae     ich_DOS4G
            xor     ebx, ebx
        ich_DOS4G:
            mov     dword ptr [dpminfo], ebx

endif           ; --------------------------------

            mov     cx, bx
            shr     ebx, 16
            mov     ax, 501h
            int     31h
            jc      ich_end

            mov     eax, [blockptr]         ; save it's handle
            shl     esi, 16
            mov     si, di
            mov     [eax * 4 + handles], esi
            inc     [blockptr]

            mov     eax, offset heap        ; add block to heap
            shl     ebx, 16
            mov     bx, cx
            mov     ecx, dword ptr [dpminfo]
            push    edx

            or      dh, dh
            jz      ich_init

            call    addheap
            jmp     ich_continue

        ich_init:

            call    initheap

        ich_continue:

            pop     edx
            mov     dh, 1

        dec     dl
        jnz     ich_loop

    ich_end:

        ret

init_c_heap     endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes heap. All other procedures assume that this is the first proc
; called, just before doing something.
;
;  parameters:
;    eax - ptr to heap info
;    ebx - address of memory
;    ecx - length of heap (including headers)
;
;  modifies:
;    ecx, eax, ebx, edx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

initheap        proc

        mov     edx, ebx                ; align heap start...
        add     ebx, 3
        and     bl, 0fch
        sub     edx, ebx                ; ...and adjust the length too
        sub     ecx, edx
        add     ecx, 3
        and     cl, 0fch

        mov     [eax.hlen], ecx
        sub     ecx, 16
        mov     [ebx.blen], ecx
        mov     dword ptr [ebx.status], 'XTEF'  ; free, end, signature...
        xor     ecx, ecx                ; ... (TASM reverses this strings :( )
        mov     [ebx.prev], ecx
        mov     [ebx.next], ecx

        mov     [eax.start], ebx        ; saves ptr to the first block

        dbginfo "initheap"

        ret

initheap        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Adds another block of heap, as heap may not be continuous. This can be
; done at any time.
;
;  parameters:
;    eax - ptr to heap info
;    ebx - address of memory
;    ecx - length of block
;
;  modifies:
;    eax, ebx, ecx, edx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

addheap proc

        mov     edx, ebx                ; align new block start...
        add     ebx, 3
        and     bl, 0fch
        sub     edx, ebx                ; ...and adjust the length too
        sub     ecx, edx
        add     ecx, 3
        and     cl, 0fch

        mov     edx, [eax.start]
        add     [eax.hlen], ecx         ; calc new heap length
ah_lp:  cmp     [edx.more], 'E'         ; searchs last block
        je      ah_add
        mov     edx, [edx.next]
        jmp     short ah_lp

ah_add: mov     [edx.more], 'M'         ; add the new free block
        mov     [edx.next], ebx
        sub     ecx, 16
        mov     [ebx.blen], ecx
        mov     dword ptr [ebx.status], 'XTEF'
        mov     [ebx.prev], edx
        mov     [ebx.next], 0

        dbginfo "addheap (blocks not yet coalesced)"

        add     ebx, 16                 ; ebx -> ptr to *data area*
        call    free                    ; quick way to possibly collide blocks

        ret

addheap endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Allocates a memory block.
;
;  parameters:
;    eax - ptr to heap info
;    ecx - length of block to allocate in bytes
;
;  returns:
;    ebx - ptr to memory or NULL if not enough memory
;    ecx - real length of block (rounded up to a four multiple)
;
;  modifies:
;    eax
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

malloc  proc

;-------B52-------
if      MEM_STATS        
        add     mem_needed,ecx
        cmp     ecx,max_block
        jbe     not_the_largest
                mov     max_block,ecx
        not_the_largest:
endif
;-------B52-------

ifdef   HARDWIRED
        mov     eax, offset heap
endif

        mov     ebx, [eax.start]        ; search a free block
        add     ecx, 3                  ; round up to multiple of 4
        and     cl, 0fch
m_lp:   cmp     byte ptr [ebx.status], 'F'
        jne     m_next
        cmp     dword ptr [ebx.blen], ecx
        jb      m_next

        add     ecx, 16                 ; allocates block
        cmp     dword ptr [ebx.blen], ecx    ; if the remainder is less than
        jb      dont_split              ; ... 16 don't split the block

        mov     eax, [ebx.blen]         ; ebx + ecx -> ptr to new block
        sub     eax, ecx                ; ecx = len of allocated block + 16
        mov     [ebx + ecx.blen], eax
        mov     eax, dword ptr [ebx.status]     ; move status, more and sign
        mov     dword ptr [ebx + ecx.status], eax
        mov     [ebx + ecx.prev], ebx
        mov     eax, [ebx.next]
        mov     [ebx + ecx.next], eax

        mov     [ebx.more], 'M'         ; more blocks
        mov     [ebx.next], ebx         ; adjust ptr to next block
        add     [ebx.next], ecx

        sub     ecx, 16
        mov     [ebx.blen], ecx

dont_split:

        mov     [ebx.status], 'A'       ; allocated block

        mov     ecx, [ebx.blen]         ; ecx -> length of block
        add     ebx, 16                 ; ebx -> data area of block

        clc                             ; -------B52-------

        dbginfo "successful malloc"

        ret

m_next: cmp     byte ptr [ebx.more], 'M'
        jne     m_end
        mov     ebx, [ebx.next]
        jmp     short m_lp

m_end:  xor     ebx, ebx                ; not enought memory

        stc                             ; -------B52-------

        dbginfo "unsuccessful malloc"

        ret

malloc  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Coalesces two memory blocks.
;
;  parameters:
;    eax - ptr to lower block
;    ebx - ptr to upper block
;
;  modifies:
;    ecx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

coalesce macro label

        mov     ecx, eax                ; are two blocks adjacent?
        add     ecx, [eax.blen]
        add     ecx, 16
        cmp     ecx, ebx
        jne     label

        mov     cl, [ebx.more]          ; copy more flag
        mov     [eax.more], cl
        mov     ecx, [ebx.next]         ; relink blocks
        mov     [eax.next], ecx
        mov     [ecx.prev], eax
        mov     ecx, [ebx.blen]         ; readjust length
        add     ecx, 16
        add     [eax.blen], ecx

        endm

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Frees a memory block.
;
;  parameters:
;    ebx - ptr to data area of block
;
;  modifies:
;    eax, ecx, ebx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

free    proc

;-------B52-------
if      MEM_STATS
;       MEM_NEDED = MEM_NEEDED - BLOCK_LENGTH
        mov     eax,[ebx.blen]
        sub     mem_needed,eax
        jnc     freed_ok
                add     mem_needed,eax
        freed_ok:
endif
;-------B52-------

ifdef   HARDWIRED
        mov     eax, offset heap
endif

        sub     ebx, 16                 ; ebx -> ptr to block header

        mov     [ebx.status], 'F'       ; free it

        mov     eax, [ebx.prev]         ; coalesce with previous block
        or      eax, eax
        jz      f_next
        cmp     [eax.status], 'F'       ; is free? ...
        jne     f_next
        coalesce f_next                 ; ... yes, coalesce it
        mov     ebx, eax                ; now we have only first free block

f_next: mov     eax, [ebx.next]         ; coalesce with next block
        or      eax, eax
        jz      f_end
        cmp     [eax.status], 'F'       ; is free? ...
        jne     f_end
        xchg    eax, ebx
        coalesce f_end                  ; ... yes, coalesce it

f_end:  dbginfo "free"

        clc                             ; -------B52-------
        ret

free    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Resizes a memory block.
;
;  parameters:
;    eax - ptr to heap info (needen for possible mallocs)
;    ebx - ptr to data area of block
;    ecx - new block size
;
;  returns:
;    ebx - new block ptr, zero if not enought memory
;    ecx - new block size, rounded up to a multiple of four
;
;  modifies:
;    eax, edx, esi, edi
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

realloc proc

ifdef   HARDWIRED
        mov     eax, offset heap
endif

        sub     ebx, 16                 ; ebx -> ptr to block header

        add     ecx, 3                  ; round size up
        and     cl, 0fch
        cmp     ecx, [ebx.blen]         ; is new block bigger or smaller?
        ja      r_big

        ; ÍÍÍÍÍ new block size <= old block size ÍÍÍÍÍ

        push    ebx                     ; block won't change, so save ebx

        mov     eax, [ebx.next]         ; have we a free block after?
        or      eax, eax
        jz      r_newf
        cmp     [eax.status], 'F'
        jne     r_newf                  ; no, make a new free block (if we can)

        ; we have a free block after the resized block, so we move it

        mov     edx, ebx                ; move start of free block
        add     edx, ecx
        add     edx, 16
        mov     [ebx.next], edx
        push    [ebx.blen]
        mov     [ebx.blen], ecx
        mov     ebx, edx                ; ebx -> ptr to free block
        pop     edx
        add     edx, [eax.blen]
        sub     edx, ecx                ; edx = new length of block
        mov     [ebx.blen], edx
        mov     edx, dword ptr [eax.status]
        mov     dword ptr [ebx.status], edx
        mov     edx, [eax.prev]
        mov     [ebx.prev], edx
        mov     edx, [eax.next]
        mov     [ebx.next], edx
        or      edx, edx
        jz      r_s_end
        mov     [edx.prev], ebx
        jmp     short r_s_end

        ; we create a new free block if we can (i.e. free space >= 16)

r_newf: mov     edx, [ebx.blen]         ; calc the difference
        sub     edx, ecx
        sub     edx, 16                 ; we can't resize the block 'cos free
        jc      r_s_end                 ;  space is less than 16 bytes...
        mov     [16 + ebx + ecx.blen], edx      ; make a new block
        mov     eax, dword ptr [ebx.status]
        mov     dword ptr [16 + ebx + ecx.status], eax
        mov     [16 + ebx + ecx.status], 'F'

        mov     [ebx.more], 'M'         ; update the resized block
        mov     [ebx.blen], ecx

        mov     eax, [ebx.next]         ; relink the heap
        mov     [16 + ebx + ecx.next], eax
        mov     [ebx.next], ebx
        add     [ebx.next], ecx
        add     [ebx.next], 16
        mov     [16 + ebx + ecx.prev], ebx
        or      eax, eax
        jz      r_s_end
        mov     [eax.prev], ebx
        add     [eax.prev], ecx
        add     [eax.prev], 16

r_s_end:
        pop     ebx                     ; ebx -> ptr to data area of resized
        add     ebx, 16                 ;  block
        jmp     r_end

        ; ÍÍÍÍÍ new block size > old block size ÍÍÍÍÍ

r_big:  push    eax                     ; save ptr to heap info
        mov     eax, [ebx.next]         ; check next block to see if is a free
        cmp     [eax.status], 'F'       ;  one and if it's big enought
        jne     r_malloc

        mov     edx, ecx
        sub     edx, [ebx.blen]
        sub     edx, 16                 ; we can use the block header too
        cmp     [eax.blen], edx
        jb      r_malloc

        add     esp, 4                  ; discard ptr to heap info

        ; we have a free block just after the resized block and it's big
        ;  enought, so we use it

        add     edx, 16                 ; use all the block or only a little
        cmp     [eax.blen], edx
        jbe     r_kill

        mov     [ebx.blen], ecx          ; update lengths
        sub     edx, [eax.blen]
        neg     edx                     ; eax -> ptr old, ebx -> ptr reloc.
        add     ecx, ebx                ; ecx -> ptr to new block location
        add     ecx, 16
        mov     [ecx.blen], edx

        mov     edx, dword ptr [eax.status]     ; copy old block to new block
        mov     dword ptr [ecx.status], edx

        mov     [ebx.next], ecx         ; relink lists
        mov     edx, [eax.prev]
        mov     [ecx.prev], edx
        mov     edx, [eax.next]
        mov     [ecx.next], edx
        mov     ecx, [ebx.blen]         ; restore size
        or      edx, edx
        jz      r_end
        mov     [edx.prev], eax
        jmp     short r_end

r_kill: mov     edx, [eax.blen]         ; use all the block
        add     edx, 16
        add     [ebx.blen], edx
        mov     edx, [eax.next]         ; relink blocks
        mov     [ebx.next], edx
        or      edx, edx
        jz      r_nonext
        mov     [edx.prev], ebx
r_nonext:
        mov     dl, [eax.more]
        mov     [ebx.more], dl

        jmp     short r_end

        ; we haven't a free block after the resized block, or it's not big
        ;  enought, so we call malloc to get memory if we can, copy old
        ;  block to new block and free old block

r_malloc:
        pop     eax                     ; restore ptr to heap info
        push    ebx                     ; we have to allocate another block
        call    malloc                  ;  and copy data to it
        or      ebx, ebx                ; not enought memory, return zero ptr
        jz      r_notenought
        mov     edi, ebx                ; copy block
        pop     edx                     ; don't destroy ebx -> ptr to new block
        add     edx, 16                 ; edx must point to data area
        mov     esi, edx
        cld
        push    ecx
        shr     ecx, 2                  ; ecx is allways a multiple of four
        rep     movsd
        xchg    edx, ebx                ; free old block
        call    free
        mov     ebx, edx
        pop     ecx                     ; end with ebx -> ptr, ecx -> length

        clc                             ; -------B52-------

        jmp     short r_end

r_notenought:
        add     esp, 4                  ; just exit with ebx = 0

        stc                             ; -------B52-------

r_end:  dbginfo "realloc"

        ret

realloc endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Checks heap integrity.
;
;  parameters:
;    eax - ptr to heap info
;
;  returns:
;    eax - 0 if all is ok, or error code
;    ebx - ptr to block where error was detected, or to last block
;
;  modifies:
;    edx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

checkheap       proc

ifdef   HARDWIRED
        mov     eax, offset heap
endif

        mov     ebx, [eax.start]        ; start walking...
        mov     edx, [eax.hlen]         ; get total size of heap
        xor     eax, eax                ; ptr to previous block (1st block 0)

ch_lp:  cmp     [ebx.sign], 'XT'        ; first of all check signature
        jne     ch_err

        cmp     [ebx.prev], eax         ; check ptr to previous block
        jne     ch_err

        sub     edx, [ebx.blen]         ; hey, length is wrong!
        jc      ch_err
        sub     edx, 16
        jc      ch_err

        cmp     [ebx.status], 'A'       ; check status & more for valid values
        je      ch_sok
        cmp     [ebx.status], 'F'
        jne     ch_err
ch_sok: cmp     [ebx.more], 'M'
        je      ch_mok
        cmp     [ebx.more], 'E'
        jne     ch_err
        jmp     short ch_end

ch_mok: mov     eax, ebx                ; save current ptr
        mov     ebx, [ebx.next]
        jmp     short ch_lp

ch_end: cmp     [ebx.next], 0           ; as it's last block next should be 0
        jne     ch_err
        or      edx, edx                ; ...and total length should be ok
        jnz     ch_err
        xor     eax, eax
        ret

ch_err: mov     eax, -1
        ret

checkheap       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets memory info.
;
;  parameters:
;    eax - ptr to heap info
;
;  returns:
;    eax - maximum available block
;    ecx - total available memory
;
;  modifies:
;    ebx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

getmeminfo      proc

ifdef   HARDWIRED
        mov     eax, offset heap
endif

        mov     ebx, [eax.start]        ; walk thought the heap
        xor     eax, eax
        xor     ecx, ecx
gmi_lp: cmp     [ebx.status], 'F'       ; is free?
        jne     gmi_nxt
        cmp     [ebx.blen], eax         ; get maximum available block
        jb      gmi_c
        mov     eax, [ebx.blen]
gmi_c:  add     ecx, [ebx.blen]
gmi_nxt:
        cmp     [ebx.more], 'E'
        je      gmi_end
        mov     ebx, [ebx.next]
        jmp     short gmi_lp

gmi_end:

        dbginfo "getmeminfo", getmeminfo

        ret

getmeminfo      endp

ifdef   SHEAP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Shows the state of heap.
;
;  modifies:
;    everything but si, di :)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

show_heap       proc

        mov     ebx, [heap.start]       ; start walking trought heap

        mov     edx, offset m_heap      ; print size of heap
        mov     ah, 9
        int     21h
        mov     eax, [heap.hlen]
        push    ebx
        call    dword2hex
        pop     ebx
        mov     edx, offset m_CRLF
        mov     ah, 9
        int     21h

sh_lp:  mov     edx, offset m_off       ; print offset
        mov     ah, 9
        int     21h
        mov     eax, ebx
        push    ebx
        call    dword2hex
        pop     ebx

        mov     edx, offset m_len       ; print length
        mov     ah, 9
        int     21h
        mov     eax, [ebx.blen]
        push    ebx
        call    dword2hex
        pop     ebx

        mov     eax, dword ptr [ebx.status]     ; print status, more & signature
        mov     [m_sms_st], al
        mov     [m_sms_m], ah
        shr     eax, 16
        mov     word ptr [m_sms_sg], ax
        mov     edx, offset m_sms
        mov     ah, 9
        int     21h

        mov     eax, [ebx.prev]         ; print previous
        push    ebx
        call    dword2hex
        pop     ebx

        mov     edx, offset m_nxt       ; print next
        mov     ah, 9
        int     21h
        mov     eax, [ebx.next]
        push    ebx
        call    dword2hex
        pop     ebx

        mov     edx, offset m_CRLF      ; print CRLF
        mov     ah, 9
        int     21h

        cmp     [ebx.more], 'E'         ; more blocks?
        je      sh_end
        mov     ebx, [ebx.next]
        jmp     short sh_lp

sh_end: xor     ah, ah                  ; wait a moment... :)
        int     16h
        ret

show_heap       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Prints a dword.
;
;  parameters:
;    eax - dword to print
;
;  modifies:
;    ebx, cl, dl
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

dword2hex       proc

        mov     cl, 8                   ; eight nibbles...
dh_lp:  rol     eax, 4
        mov     ebx, eax
        and     ebx, 0fh
        push    eax
        mov     ah, 2
        mov     dl, [ebx + too_lazy]
        int     21h
        pop     eax
        dec     cl
        jnz     dh_lp
        ret

dword2hex       endp

endif   ; defined SHEAP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

;-------B52-------
; Prints memory statistics
if      MEM_STATS
include utils.inc
mem_statistix   proc
        mov     eax,mem_needed
        shr     eax,10
        adc     eax,0   ; round up
        mov     mem_need_kb,eax
        mov     eax,max_block
        shr     eax,10
        adc     eax,0   ; round up
        mov     max_block_kb,eax
        print   memoria
        ret
mem_statistix   endp
endif
;-------B52-------

        .data

;-------B52-------
if      MEM_STATS
mem_needed      dd 0
max_block       dd 0

memoria         db "Total memory needed: %dn"
maxmem          dd offset mem_needed
                db " bytes (%dn"
                dd offset mem_need_kb
                db "Kb)",13,10,"Largest requested block: %dn"
maxblock        dd offset max_block
                db " bytes (%dn"
                dd offset max_block_kb
                db "Kb)",13,10,0
mem_need_kb     dd ?
max_block_kb    dd ?

endif
;-------B52-------

blockptr    dd      0                   ; ptr to currently allocated block's
                                        ;  handle

ifdef   SHEAP

    m_heap      db      13, 10, "Heap size: $"

    m_off       db      13, 10, "Starting offset of block: $"
    m_len       db      13, 10, "Length of block: $"
    m_sms       db      13, 10, "Status (allocated/free): "
    m_sms_st    db      0, " More (more/end): "
    m_sms_m     db      0, " Signature: "
    m_sms_sg    db      0, 0, 13, 10, "Previous block: $"
    m_nxt       db      13, 10, "Next block: $"
    m_CRLF      db      13, 10, "$"

    too_lazy db     "0123456789abcdef"

endif   ; defined SHEAP

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

        .data?

heap    THEAP   <>              ; heap info
handles dd      BLOCKS dup (?)  ; handles of allocated blocks
dpminfo db      48 dup (?)      ; DPMI memory info

        end

