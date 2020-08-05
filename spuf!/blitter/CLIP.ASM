;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Clipping between SLIs for normal and scaled images in 8,16,24 & 32 bits
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code

        INCLUDE clip.inc
        INCLUDE sli.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Performs clipping of input buffer into output buffer
;
; INPUT  -> ESI -> Input SLI header
;           EDI -> Output SLI header
;
; OUTPUT -> CF = 0 if some part of image is drawn
;                Input SLI temporary variables filled
;           CF = 1 if image is hidden
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Clip    proc
        ; Gonna clip source into target!!
        mov     [esi.SOURCE_PTR_INC_Y],0
        mov     [esi.SOURCE_PTR_INIT],0
        ;---
        mov     eax,[esi.SLIPos.SLRR1.SLPX]
        sub     eax,[edi.SLIClip.SLRR1.SLPX]
        mov     ebx,[esi.SLIPos.SLRR1.SLPY]
        sub     ebx,[edi.SLIClip.SLRR1.SLPY]
        ;---
        mov     ecx,eax                
        add     ecx,[esi.SLIXSize]
        mov     edx,ebx
        add     edx,[esi.SLIYSize]
        ;---
        mov     ebp,[edi.SLIClip.SLRR2.SLPX]
        sub     ebp,[edi.SLIClip.SLRR1.SLPX]
        inc     ebp
        cmp     eax,ebp
        jbe     X0_ok
                or      eax,eax
                jns     leave_clipping
                sub     [esi.SOURCE_PTR_INIT],eax
                sub     [esi.SOURCE_PTR_INC_Y],eax
                xor     eax,eax
        X0_ok:
        cmp     ecx,ebp
        jbe     X1_ok
                or      ecx,ecx
                js      leave_clipping
                add     [esi.SOURCE_PTR_INC_Y],ecx                
                mov     ecx,ebp
                sub     [esi.SOURCE_PTR_INC_Y],ecx
        X1_ok:
        mov     ebp,[edi.SLIClip.SLRR2.SLPY]
        sub     ebp,[edi.SLIClip.SLRR1.SLPY]
        inc     ebp
        cmp     ebx,ebp
        jbe     Y0_ok
                or      ebx,ebx
                jns     leave_clipping
                imul    ebx,[esi.SLIXSize]
                sub     [esi.SOURCE_PTR_INIT],ebx
                xor     ebx,ebx
        Y0_ok:
        cmp     edx,ebp
        jbe     Y1_ok
                or      edx,edx
                js      leave_clipping
                mov     edx,ebp
        Y1_ok:
        ;---
        sub     ecx,eax
        jz      leave_clipping
        mov     [esi.SOURCE_SIZE_X],ecx
        sub     edx,ebx
        jz      leave_clipping
        mov     [esi.SOURCE_SIZE_Y],edx
        ;---
        add     eax,[edi.SLIClip.SLRR1.SLPX]
        add     ebx,[edi.SLIClip.SLRR1.SLPY]
        mov     [esi.TARGET_PTR_INIT],ebx
        fild    [esi.TARGET_PTR_INIT]
        fimul   [edi.SLIXSize]
        mov     [esi.TARGET_PTR_INIT],eax
        fiadd   [esi.TARGET_PTR_INIT]
        fistp   [esi.TARGET_PTR_INIT]

        mov     eax,[edi.SLIXSize]
;        mov     eax,[esi.TARGET_PTR_INC_Y1]
        sub     eax,[esi.SOURCE_SIZE_X]
        mov     [esi.TARGET_PTR_INC_Y],eax

        ; Now we addjust offsets and increments to the SLI depths
        fild    [esi.SOURCE_PTR_INIT]
        fimul   [esi.SLIColorBits]
        fistp   [esi.SOURCE_PTR_INIT]
        fild    [esi.SOURCE_PTR_INC_X]
        fimul   [esi.SLIColorBits]
        fistp   [esi.SOURCE_PTR_INC_X]
        fild    [esi.SOURCE_PTR_INC_Y]
        fimul   [esi.SLIColorBits]
        fistp   [esi.SOURCE_PTR_INC_Y]

        fild    [esi.TARGET_PTR_INIT]
        fimul   [edi.SLIColorBits]
        fistp   [esi.TARGET_PTR_INIT]
        fild    [esi.TARGET_PTR_INC_Y]
        fimul   [edi.SLIColorBits]
        fistp   [esi.TARGET_PTR_INC_Y]
;        fild    [esi.TARGET_PTR_INC_Y1]
;        fimul   [edi.SLIColorBits]
;        fistp   [esi.TARGET_PTR_INC_Y1]

        clc
        ret

        leave_clipping:
        stc             ; Image won't be drawn
        ret
Clip    endp

end
