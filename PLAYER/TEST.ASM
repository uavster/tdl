.386p
.model flat
.stack 100h
.code
        INCLUDE utils.inc
        INCLUDE player.inc
start:
        InitDPMI

        mov     edx,offset filename
        call    LoadModule
        ErrorExit "Error loading module"

        mov     eax,44100
        call    InitPlayer
        ErrorExit "Error initilizing player"

        call    Play

        wait_escape:                
        in      al,60h
        dec     al
        jnz     wait_escape

        call    Stop

        Exit
filename        db "c:\demos\over\overhead.s3m",0
end start
