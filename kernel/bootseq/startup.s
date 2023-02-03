;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;---------------------------------------;
; startup                               ;
;---------------------------------------;
; runs the different startup initialization
; routines one after the other          ;
;---------------------------------------;
.8086                                   ;
startup PROC                            ;
    CALL displayGreeter                 ;
                                        ;
    ;- check CPU                        ;
    ;-- message                         ;
    MOV si, OFFSET BOOT_CHECK_CPU       ;
    CALL DPT_printStr                   ;
                                        ;
    ;-- perform the check               ;
    CALL CPUID_check                    ;
                                        ;
    ;-- CPU is valid! Validation message;
    MOV si, OFFSET BOOT_PRINT_DONE      ;
    CALL DPT_printStr                   ;
                                        ;
    ;- VSA                              ;
    ;-- message                         ;
    MOV si, OFFSET BOOT_CHECK_VESA      ;
    CALL DPT_printStr                   ;
    ;- done                             ;
    RET                                 ;
startup ENDP                            ;
                                        ;
                                        ;
;=======================================;
; INCLUDES                              ;
;=======================================;
include greeter.s                       ;
include cpuid.s                         ;
include gdt.s                           ;
                                        ;
;- variables                            ;
    BOOT_INIT_GDT DB "Creating global descriptor table (GDT) . . . ", 0
    BUG DB 0
    BUG2 DB 0
    BOOT_CHECK_CPU DB "Checking CPU for compatibility . . . ", 0
    BUG3  DB 0
    BOOT_CHECK_VESA DB "Checking for VESA compatibility . . .", 0
    BUG4  DB 0
    BOOT_PRINT_DONE DB "Done!", 13, 10, 0 
