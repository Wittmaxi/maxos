;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;---------------------------------------;
; startup                               ;
;---------------------------------------;
; runs the different startup initialization
; routines one after the other          ;
;---------------------------------------;
startup PROC                            ;
    CALL displayGreeter                 ;
                                        ;
    ;- memory services
    MOV si, OFFSET BOOT_INIT_MEM        ;
    CALL DPT_printStr                   ;
    CALL RMEM_setup                     ;
    MOV si, OFFSET BOOT_PRINT_DONE      ;
    CALL DPT_printStr                   ;


    RET                                 ;
startup ENDP                            ;
                                        ;
;=======================================;
; INCLUDES                              ;
;=======================================;
include greeter.s                       ;
                                        ;
;- variables                            ;
    BOOT_PRINT_DONE DB "Done!", 13, 10, 0 
    BOOT_INIT_MEM DB "Initializing memory allocation services . . . ", 0
