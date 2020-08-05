;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
;北   Machine Status Registers' routines                Coded by Nitro!
;北   for speed and code eficiency testing              #Trouble# Team
;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北

WRMSR   macro
        db 0fh, 30h
        endm
RDMSR   macro
        db 0fh, 32h
        endm
RDTSC   macro
        db 0fh, 31h
        endm
;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
;   Events for Set_counter#

data_read                                                   equ 00h
data_write                                                  equ 01h
data_TLB_miss                                               equ 02h
data_read_miss                                              equ 03h
data_write_miss                                             equ 04h
write_hit_to_ModifiedExclusive_cache_line                   equ 05h
data_cache_lines_written_back                               equ 06h
external_data_cache_snoops                                  equ 07h
external_data_cache_snoop_hits                              equ 08h
simultaneous_memory_accesses_in_both_pipes                  equ 09h
data_bank_access_conflict_between_U_and_V_pipes             equ 0Ah
misaligned_data_memory_or_IO_references                     equ 0Bh
code_read                                                   equ 0Ch
code_TLB_miss                                               equ 0Dh
code_cache_miss                                             equ 0Eh
any_segment_register_load                                   equ 0Fh
segment_descriptor_cache_accessed                           equ 10h
segment_descriptor_cache_hit                                equ 11h
any_branch                                                  equ 12h
BTB_hit                                                     equ 13h
taken_branch__BTB_hit                                       equ 14h
pipeline_flushes                                            equ 15h
total_instructions_executed                                 equ 16h
instruction_executed_in_V_pipe                              equ 17h
bus_utilization                                             equ 18h
pipeline_stalled_by_write_backups                           equ 19h
pipeline_stalled_by_data_memory_read                        equ 1Ah
pipeline_stalled_by_write_to_ModifiedExclusive_cache_line   equ 1Bh
locked_bus_cycle                                            equ 1Ch
IO_cycle                                                    equ 1Dh
noncacheable_memory_references                              equ 1Eh
pipeline_stalled_by_Address_Generation_Interlock            equ 1Fh
AGIS                                                        equ 1Fh
floatingpoint_operations                                    equ 22h
Breakpoint0_match                                           equ 23h
Breakpoint1_match                                           equ 24h
Breakpoint2_match                                           equ 25h
Breakpoint3_match                                           equ 26h
hardware_interrupt                                          equ 27h
data_read_or_data_write                                     equ 28h
data_readwrite_miss                                         equ 29h

;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
;    Values for Feature_Control (EAX)
Cache_Inhibit                                               equ 1000b
SinglePipe_Execution                                        equ 100b
Disable_Branch_Prediction                                   equ 1b

        extrn   SetCounter0Event:near
        extrn   SetCounter1Event:near
        extrn   ReadCounter0:near
        extrn   ReadCounter1:near
        extrn   ResetCounter0:near
        extrn   ResetCounter1:near
        extrn   FeatureControl:near

CountClocks     equ     100000000b

SetCounter0     macro   event
        mov     ebx, event
        call    SetCounter0Event
        endm

SetCounter1     macro   event
        mov     ebx, event
        call    SetCounter1Event
        endm
