;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; file: alloc.inc
;
;  TTL's memory system.
;
;       by Xavier Rubio Jansana, a.k.a. Teknik / #Trouble# Team, July 1998
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

    global init_c_heap  : near
    global malloc       : near
    global free         : near
    global realloc      : near
    global checkheap    : near
    global getmeminfo   : near

;-------B52-------
; finds out maximum memory needed and largest requested block
MEM_STATS       EQU 1

if      MEM_STATS
    global mem_needed   : dword
    global max_block    : dword
    global mem_statistix: near
endif
;-------B52-------
