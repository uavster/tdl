extrn       get_pcx_info:NEAR
extrn       read_pcx:NEAR
extrn       pcx_decode:NEAR

LoadPCX MACRO pcxfile
LOCAL   pcxname,load_pcx_end
        mov     edx,offset pcxname
        call    read_pcx
        jmp     load_pcx_end
pcxname db pcxfile,0
        load_pcx_end:
ENDM
