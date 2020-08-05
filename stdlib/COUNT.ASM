;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
;北   Machine Status Registers' routines                Coded by Nitro!
;北   for speed and code eficiency testing              #Trouble# Team
;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北


IF   ??Version ne 400h
        WRMSR   macro
                db 0fh, 30h
                endm
        RDMSR   macro
                db 0fh, 32h
                endm
        .386P
ELSE
        .586P
ENDIF

        JUMPS
        .MODEL  FLAT
        .CODE

RDTSC   macro
        db 0fh, 31h
        endm

CountClocks     equ     100000000b

        public  SetCounter0Event
        public  SetCounter1Event
        public  ReadCounter0
        public  ReadCounter1
        public  ResetCounter0
        public  ResetCounter1
        public  FeatureControl


SetCounter0Event  proc
        mov     ecx, 11h
        RDMSR
        or      eax,     011000000b ; Enable counter 0 in cpls 0,1,2,3
        and     eax, not 100000000b ; Count number of events
        test    ebx, CountClocks
        jz      dont_count_clocks
        or      eax,     100000000b ; Count number of clocks instead of events
dont_count_clocks:
        and     ebx,     111111b
        and     eax, not 111111b    ; Set event number
        or      eax, ebx
        mov     ecx, 11h
        WRMSR
        ret
        endp

SetCounter1Event  proc
        mov     ecx, 11h
        RDMSR
        or      eax, (1 shl 23) + (1 shl 22)
        and     eax, not (1 shl 24)
        test    ebx, CountClocks
        jz      dont_count_clocks1
        or      eax,     (1 shl 24)
dont_count_clocks1:
        and     ebx, 111111b
        shl     ebx, 16

        and     eax, not (111111b shl 16)
        or      eax, ebx
        mov     ecx, 11h
        WRMSR
        ret
        endp

ReadCounter0   proc
        push    ecx
        mov     ecx, 12h
        RDMSR
        pop     ecx
        ret
        endp
ResetCounter0  proc
        push    ecx eax edx
        xor     eax, eax
        xor     edx, edx
        mov     ecx, 12h
        WRMSR
        pop     edx eax ecx
        ret
        endp

ReadCounter1   proc
        push    ecx
        mov     ecx, 13h
        RDMSR
        pop     ecx
        ret
        endp

ResetCounter1  proc
        push    ecx eax edx
        xor     eax, eax
        xor     edx, edx
        mov     ecx, 13h
        WRMSR
        pop     edx eax ecx
        ret
        endp

FeatureControl proc
        push    ecx edx
        mov     ecx, 0eh
        xor     edx, edx
        WRMSR
        pop     edx ecx
        ret
        endp

        END

