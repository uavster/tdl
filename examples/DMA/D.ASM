.386p
.model flat
.stack 1000h
.code
        INCLUDE utils.inc
        INCLUDE dma.inc
start:
        InitDPMI

        mov     ecx,2*1024
        call    AllocDMABuffer
        ErrorExit "Error allocating DMA buffer"
        mov     buffer,ebx

        print   string

        mov     ebx,buffer
        call    FreeDMABuffer
        ErrorExit "Error freeing DMA buffer"
        LPrintS "Buffer freed"

        mov     ecx,8*1024
        call    AllocDMABuffer
        ErrorExit "Error allocating DMA buffer"
        mov     buffer2,ebx

        print   string2

        Exit

.data
string  db "DMA buffer allocated at %dhn"
        dd offset buffer
        db "h",13,10,0

string2 db "DMA buffer allocated at %dhn"
        dd offset buffer2
        db "h",13,10,0

.data?
buffer  dd ?
buffer2 dd ?

end start
