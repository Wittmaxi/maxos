;-------------------------------------------------;
; Copyright 2023 Maximilian Wittmer               ;
;-------------------------------------------------;
; startup                                         ;
;-------------------------------------------------;
; runs the different startup initialization       ;
; routines one after the other                    ;
;-------------------------------------------------;
.8086                                             ;
startup PROC                                      ;
    CALL displayGreeter                           ;
                                                  ;
    ;- run real mode unit tests                   ;
.IF PARAM_TESTS_RUN EQ TRUE                       ;
    MOV si, OFFSET BOOT_realmodeTests             ;
    CALL DPT_printStr                             ;
    ;--                                           ;
    CALL TST_rModeRun                             ;
    ;--                                           ;
    MOV si, OFFSET BOOT_PRINT_DONE                ;
    CALL DPT_printStr                             ;
.ENDIF
    ;- check CPU                                  ;
    ;-- message                                   ;
    MAC_DPT_PRINTIMM "Checking CPU and system for compatibility. . . "
    CALL CPUID_check                              ;
    ;-- CPU is valid! Validation message          ;
    MOV si, OFFSET BOOT_PRINT_DONE                ;
    CALL DPT_printStr                             ;
                                                  ;
    ;- VSA                                        ;
    ;-- message                                   ;
    MAC_DPT_PRINTIMM "Checking for VESA  ompatibility . . . "
    CALL DRV_VESA_setup                           ;
    ;- done                                       ;
    MOV si, OFFSET BOOT_PRINT_DONE                ;
    CALL DPT_printStr                             ;
                                                  ;
    ;- ACPI                                       ;
    MAC_DPT_PRINTIMM "ACPI: parsing devices . . . "
    CALL DRV_ACPI_setup                           ; 
    MOV si, OFFSET BOOT_PRINT_DONE                ;
    CALL DPT_printStr                             ;
                                                  ;
    RET                                           ;
startup ENDP                                      ;
                                                  ;
;- variables                                      ;
    BOOT_PRINT_DONE DB "Done!", 13, 10, 0         ; 
    BOOT_realmodeTests DB "Running unit tests for real mode . . . ", 0
                                                  ;
;-------------------------------------------------;
; INCLUDES                                        ;
;-------------------------------------------------;
include greeter.s                                 ;
include cpuid.s                                   ;
include ../drivers/graphics/vesa.s                ;
include ../drivers/acpi/parse_devices.s           ;
include ../tests/tests.s
                                                   
