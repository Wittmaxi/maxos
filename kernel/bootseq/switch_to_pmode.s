;-------------------------------------------------;
; Copyright 2023 Maximilian Wittmer               ;
;-( synopsis )------------------------------------; Namespace BOOT
; BOOT_pmodeSwitch                                ;
;-------------------------------------------------;
.386P                                             ;
;-------------------------------------------------;
; BOOT_pmodeSwitch                                ;
;-------------------------------------------------;
; o sets the A20 line                             ;
; o Sets up a GDT                                 ;
; o switches CPU to pmode                         ;
;-------------------------------------------------;
BOOT_pmodeSwitch PROC                             ;
    CALL CPU_enableA20                            ;
    CALL GDT_setupKernelGDT                       ;
                                                  ;
    RETN                                          ;
BOOT_pmodeSwitch ENDP                             ;
