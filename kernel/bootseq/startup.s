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
    ;- check CPU                                  ;
    MOV si, OFFSET BOOT_cpucheck                  ;
    CALL DPT_printStr                             ;
                                                  ;
    CALL CPUID_check                              ;
                                                  ;
    MOV si, OFFSET BOOT_PRINT_DONE                ;
    CALL DPT_printStr                             ;
.386P                                             ; we have established this!
                                                  ;
    ;- VESA                                       ;
    MOV si, OFFSET BOOT_vesacheck                 ;
    CALL DPT_printStr                             ;
                                                  ;
    ;-- setup VESA                                ;
    CALL DRV_VESA_setup                           ;
                                                  ;
    MOV si, OFFSET BOOT_PRINT_DONE                ;
    CALL DPT_printStr                             ;
                                                  ;
    ;-- boot into the graphics mode               ;
    CALL DRV_VESA_bootIntoGraphicsMode            ;
                                                  ;
    ;- ACPI                                       ;
    MOV si, OFFSET BOOT_acpicheck                 ;
    CALL DPT_printStr                             ;
                                                  ;
    CALL DRV_ACPI_setup                           ; 
                                                  ;
    MOV si, OFFSET BOOT_PRINT_DONE                ;
    CALL DPT_printStr                             ;
                                                  ;
    ;-                                            ;
    RET                                           ;
startup ENDP                                      ;
                                                  ;
;- variables                                      ;
    BOOT_cpucheck DB "Checking CPU and system for compatibility . . . ", 0
    BOOT_vesacheck DB "Checking for VESA compatibility . . . ", 0
    BOOT_acpicheck DB "ACPI: parsing devices . . . ", 0
    BOOT_pmode DB "Switching to protected mode . . . ", 0
    BOOT_PRINT_DONE DB "Done!", 13, 10, 0         ; 
    BOOT_realmodeTests DB "Running unit tests for real mode . . . ", 0
                                                  ;
;-------------------------------------------------;
; INCLUDES                                        ;
;-------------------------------------------------;
include greeter.s                                 ;
include cpuid.s                                   ;
include switch_to_pmode.s                         ;
include ../drivers/graphics/vesa.s                ;
include ../drivers/acpi/parse_devices.s           ;
                                                   
