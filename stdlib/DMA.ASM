;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Routines for DMA data transfers
;       Ignacio Mellado Bataller ( B52 / the DarkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.386p
.model flat
.code

        INCLUDE list.inc
        INCLUDE stderror.inc
        INCLUDE dma.inc
        INCLUDE alloc.inc

DMABuffer       STRUC
        Selector        dd ?
        Buffer          dd ?
ENDS

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes DMA extensions
;
; OUTPUT : CF = 0 if ok
;               EAX = NULL
;          CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
InitDMA proc
        call    NewList
        ErrorCode eax
        mov     BufferList,ebx
        ret
InitDMA endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Closes DMA extensions
;
; OUTPUT : CF = 0 if ok
;               EAX = NULL
;          CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CloseDMA        proc
        mov     eax,BufferList
        call    ResetListPtr
        free_all_buffers:
                mov     eax,BufferList
                call    GetNextElement
                jc      no_more_buffs
                mov     edx,[ebx.Selector]
                mov     ax,101h
                push    ebx
                int     31h
                pop     ebx
                ErrorCode FREE_ERROR
                call    free
                ErrorCode FREE_ERROR
        jmp     free_all_buffers
        no_more_buffs:
        mov     eax,BufferList
        call    DeleteList
        ret
CloseDMA        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Adds a DMA buffer to the list
;
; INPUT  : EAX -> DMA buffer
;          DX = Memory selector
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if no memory
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
NewInfoBlock    proc
        push    eax edx
        mov     ecx,size DMABuffer
        call    malloc
        pop     edx eax
        jc      new_ib_error
        mov     [ebx.Selector],edx
        mov     [ebx.Buffer],eax
        mov     eax,BufferList
        xor     ecx,ecx
        call    AddElement
        new_ib_error:
        ret
NewInfoBlock    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Allocates a DMA buffer (64Kb aligned) and maintains a list of all allocated
; buffers for freeing
;
; INPUT  : ECX = Buffer size
;
; OUTPUT : CF = 0 if ok
;               EBX -> DMA buffer aligned on 64Kb boundaries
;          CF = 1 if no memory for buffer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
AllocDMABuffer  proc
        mov     ax,100h
        mov     ebx,ecx
        shr     ebx,4                   ; Need size in paragraphs
        add     ebx,(64*1024)/16        ; Enough size to align
        int     31h
        and     eax,0f000h
        add     eax,1000h
        shl     eax,4
        push    eax
        call    NewInfoBlock
        pop     ebx
        ret
AllocDMABuffer  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Frees a DMA buffer
;
; INPUT  : EBX -> DMA buffer returned by AllocDMABuffer
; OUTPUT : CF = 0 if ok
;          CF = 1 if error freeing
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FreeDMABuffer   proc
        mov     eax,BufferList
        push    ebx
        call    ResetListPtr
        pop     ecx
        SearchBlock:
                mov     eax,BufferList
                push    ecx                        
                call    GetNextElement
                pop     ecx
                jc      error_freeing
                cmp     [ebx.Buffer],ecx
        jnz     SearchBlock
        mov     ax,101h
        mov     edx,[ebx.Selector]
        push    ebx
        int     31h
        pop     ebx
        jc      error_freeing
        mov     eax,BufferList
        push    ebx
        call    DeleteElement
        pop     ebx
        jc      error_freeing
        call    free
        ret

        error_freeing:
        stc
        ret
FreeDMABuffer   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; "DMA_Setup"   PROGRAM A CHANNEL ON THE 8237 DMA CONTROLLER                
;             A general routine to program the DMA controler.               
;                                                                           
; By Adam Seychell                                                          
;                                                                           
;                                                                           
; INPUT:        AL    Mode Register  ( bits 0..1 ignored )                  
;               AH    channel   ( 0..7 )                                    
;               EBX   Physical Base Address ( 0..0ffffffh )                 
;               ECX   Bytes to transfer     ( 1..10000h )                   
;                                                                           
;                                                                           
;Destroys:  EAX, EDX & ECX                                                  
;                                                                           
;        code has been optimized and fully tested.                          
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DMASetup PROC
        push    edi
        push    ebx
        xor     edx,edx
        and     ah,7
        mov     DMA_channel,ah
        and     al,NOT 3
        mov     mode,al

        ; -----  set channel mask register ------
        movzx   edi,DMA_channel
        mov     eax,edi
        shr     edi,2
        and     al,0011b
        or      al,0100b
        mov     dl,DMA_SNGL[edi]
        out     dx,al

        ; ----- set mode register ------
        and     al,03h
        or      al,mode
        mov     dl,DMA_MODE[edi]
        out     dx,al

        ; ------  clear MSB/LSB flip flop -----------
        xor     al,al                   ; B52
        mov     dl,DMA_CLRFF[edi]
        out     dx,al



        ;---- set byte count register ----
        movzx   edi,DMA_channel
        mov     eax,ecx
        mov     ecx,edi
        shr     ecx,2
        shr     eax,cl                ; divide count address by 2 for DMA # 2
        dec     eax                     ; count - 1
        mov     dl,DMA_CNT[edi]         ; bits 0..7
        out     dx,al
        shr     eax,8
        out     dx,al                   ; bits 8..15


        ;---- set channel base address ---
        shr     ebx,cl                ; divide base address by 2 for DMA # 2
        mov     al,BL                       ; set bits 0..7
        mov     dl,DMA_ADDR[edi]
        out     dx,al
        mov     al,BH                       ; set bits 8..15
        out     dx,al

        shr     ebx,15           ; divide base address by 8000h for DMA # 2
        xor     cl,1
        shr     ebx,cl           ; divide base address by 10000h for DMA # 1
        mov     al,BL            ; set bits 16..23 ( in LSB page register )
        mov     dl,DMA_PAGE[edi]
        out     dx,al


        ; -----  clear channel (mask register) ------
        mov     eax,edi
        shr     edi,2
        and     al,03h
        mov     dl,DMA_SNGL[edi]
        out     dx,al
        pop     ebx
        pop     edi
        ret


mode            Db  ?
DMA_channel     Db  ?


;* 1st & 2nd DMA Controler's ports *;

  DMA_STAT   db 008h,0D0h        ;* read status register *;
  DMA_CMD    db 008h,0D0h        ;* write command register *;
  DMA_REQ    db 009h,0D2h        ;* write request register *;
  DMA_SNGL   db 00Ah,0D4h        ;* write single bit register *;
  DMA_MODE   db 00Bh,0D6h        ;* write mode register *;
  DMA_CLRFF  db 00Ch,0D8h        ;* clear byte ptr flip;flop *;
  DMA_MCLR   db 00Dh,0DAh        ;* master clear register *;
  DMA_CLRM   db 00Eh,0DCh        ;* clear mask register *;
  DMA_WRTALL db 00Fh,0DEh        ;* write all mask register *;

; * ports for 8 channels *;

DMA_PAGE        db 087h,083h,081h,082h,08Fh,08Bh,089h,08Ah ; page register
DMA_ADDR        db 000h,002h,004h,006h,0C0h,0C4h,0C8h,0CCh ; base adddress
DMA_CNT         db 001h,003h,005h,007h,0C2h,0C6h,0CAh,0CEh ; base count

DMASetup   Endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Programs DMA chip to write to a device
;
; INPUT : AL = DMA_AUTOINIT for autoinitialize transfer, or DMA_SINGLECYCLE for single-cycle transfer
; 		  AH = DMA channel to use
;         EBX = Physical base address to make transfer from
;         ECX = Bytes to transfer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DMAWriteToDevice        proc
        or      al,DMA_READ OR DMA_SIGNAL
        call    DMASetup
        ret
DMAWriteToDevice        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Programs DMA chip to read from a device
;
; INPUT : AL = DMA_AUTOINIT for autoinitialize transfer, or DMA_SINGLECYCLE for single-cycle transfer
; 		  AH = DMA channel to use
;         EBX = Physical base address to make transfer to
;         ECX = Bytes to transfer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DMAReadFromDevice       proc
        or      al,DMA_WRITE OR DMA_SIGNAL
        call    DMASetup
        ret
DMAReadFromDevice       endp

.data?
BufferList      dd ?

end
