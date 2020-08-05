.386p
.model flat
.stack 100h
.code
        INCLUDE utils.inc
start:
        InitDPMI
        print cadena
        Exit

.data
cadena  db "Me gustan los %us"
        dd offset subc
        db 13,10,0
subc    db "donuts",0
end start
