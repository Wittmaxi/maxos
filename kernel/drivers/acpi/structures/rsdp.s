;-------------------------------------------------;
; Copyright 2023 Maximilian Wittmer               ;
;-( synopsis )------------------------------------;
; DRV_ACPI_RSDP                                   ;
;-------------------------------------------------;
DRV_ACPI_RSDP STRUCT                              ;
    signature DB 8 DUP (?)                        ;
    checksum DB ?                                 ;
    oemID DB 6 DUP (?)                            ;
    revision DB ?                                 ;
    rsdtAddress DD ?                              ;
DRV_ACPI_RSDP ENDS                                ;

