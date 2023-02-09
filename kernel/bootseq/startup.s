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
    MAC_DPT_PRINTIMM "Checking CPU and system for compatibility. . . "
    CALL CPUID_check                    ;
    ;-- CPU is valid! Validation message;
    MOV si, OFFSET BOOT_PRINT_DONE      ;
    CALL DPT_printStr                   ;
                                        ;
    ;- VSA                              ;
    ;-- message                         ;
    MAC_DPT_PRINTIMM "Checking for VESA compatibility . . . "
    CALL DRV_VESA_setup                 ;
    ;- done                             ;
    MOV si, OFFSET BOOT_PRINT_DONE      ;
    CALL DPT_printStr                   ;
                                        ;
    RET                                 ;
startup ENDP                            ;
                                        ;
;- variables                            ;
    BOOT_PRINT_DONE DB "Done!", 13, 10, 0 
                                        ;
;=======================================;
; INCLUDES                              ;
;=======================================;
include greeter.s                       ;
include cpuid.s                         ;
include ../drivers/graphics/vesa.s      ;
                                        ;
