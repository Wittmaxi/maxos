;-------------------------------------------------;
; Copyright 2023 Maximilian Wittmer               ;
;-( synopsis )------------------------------------;
; DRV_ACPI_setup                                  ;
; DRV_ACPI_findRSDP                               ;
;-------------------------------------------------;
                                                  ;
;-------------------------------------------------;
; Checks the signature of the RSDP specifically   ;
;-( input )---------------------------------------;
; ES:DI - string 1                                ;
; CX size                                         ;
;-( output )--------------------------------------;
; ZF - set if signatures match                    ;
;-------------------------------------------------;
DRV_ACPI_checkRSDPSig MACRO                       ;
    MOV si, OFFSET DRV_ACPI_RSDP_SIG              ;
    REPZ CMPSB                                    ;
ENDM                                              ;
DRV_ACPI_RSDP_SIG DB "RSD PTR "                   ;
                                                  ;
;-------------------------------------------------;
; DRV_ACPI_findRSDP                               ;
;-( output )--------------------------------------;
; ES:DI => pointer to RSDP                        ;
;-------------------------------------------------;
DRV_ACPI_findRSDP PROC                            ;
    ;- try the real mode pointer                  ;
    MOV ax, 040EH                                 ;
    MOV es, WORD PTR [ax]                         ;
    XOR di, di                                    ;
    DRV_ACPI_checkRSDPSig                         ;
    JZ @@rsdpFound                                ;
    ;- look for the structure in the EBDA         ;


@@rsdpFound:                                      ;
    RET                                           ;
DRV_ACPI_findRSDP ENDP                            ;
                                                  ;
;-------------------------------------------------;
; DRV_ACPI_setup                                  ;
;-------------------------------------------------;
DRV_ACPI_setup PROC                               ;
    CALL DRV_ACPI_findRSDP
    RET
DRV_ACPI_setup ENDP                               ;
                                                  ;
