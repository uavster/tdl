.386p
.model flat
.code

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

        public  __CHK

    ; NOTA: Comprova stack overflow. Necessari per quan es compila sense
    ;       l'opci� -s, normalment quan es depura.

__CHK:
        ret     4

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

        public  __8087
        public  _fltused_
        public  __CHP

__8087:
_fltused_:
__CHP:
        ret

end
