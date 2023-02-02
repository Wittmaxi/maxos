;-------------------------------------
; Copyright 2023 Maximilian Wittmer     ;
;---------------------------------------;
; display greeter                       ;
;---------------------------------------;
displayGreeter PROC                     ;
    CALL DPT_clearScr                   ;
                                        ;
    ;- message                          ;
    MOV si, OFFSET BOOT_MSG             ; we still assume that DS = CS
    CALL DPT_printStr                   ;
                                        ;
    ;- version number                   ;
    MOV ax, PARAM_KERNEL_VERSION        ;
    CALL DPT_printNumSigned             ;
    CALL DPT_newLine                    ;
                                        ;
    ;- return                           ;
    RET                                 ;
displayGreeter ENDP                     ;
                                        ;
    BOOT_MSG DB 13, 10, 10              ;
            DB "MAXOS - Initializing booting", 13, 10
            DB "    Copyright Maximilian Wittmer 2023", 13, 10
            DB "    Contact at maximilian.wittmer@gmx.de", 13, 10, 10
            DB "Kernel version: ", 0    ;
