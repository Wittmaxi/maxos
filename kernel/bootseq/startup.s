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
    ;-- message                                   ;
    MAC_DPT_PRINTIMM "Checking CPU and system for compatibility. . . "
    CALL CPUID_check                              ;
    ;-- CPU is valid! Validation message          ;
    MOV si, OFFSET BOOT_PRINT_DONE                ;
    CALL DPT_printStr                             ;
                                                  ;
    ;- VSA                                        ;
    ;-- message                                   ;
    MAC_DPT_PRINTIMM "Checking for VESA compatibility . . . "
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

; SP + 2 = pointer to GDT                         ; W
; SP + 4 = limit                                  ; DW - first byte will effectively be empty - and ignored by code!
; SP + 8 = flags                                  ; W (first byte unused)
; SP + 10 = base                                  ; DW
; SP + 14 = unused                                ;
; SP + 15 = access                                ;

    MOV ax, 42
    PUSH ax
    PUSH ax
    PUSH ax
    PUSH ax
    PUSH ax
    PUSH ax
    PUSH ax
    MOV ax, OFFSET GDT_space
    MOV BYTE PTR DS:[ax + 2], 50
    PUSH ax
    CALL GDT_encodeEntry

    MOV cx, 8
    MOV ax, 0
    MOV bx, OFFSET GDT_space

@@l:
    MOV al, BYTE PTR [DS:bx]
    CALL DPT_printNum
    MAC_DPT_PRINTIMM " "
    INC bx
    LOOP @@l

@@stop:
    HLT
    JMP @@stop
                                                  ;
    RET                                           ;
startup ENDP                                      ;

    GDT_space DB 1
    DB 2
    DB 3
    DB 4
    DB 5
    DB 6
    DB 7
    DB 8
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
                                                   
