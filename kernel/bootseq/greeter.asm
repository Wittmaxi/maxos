;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;---------------------------------------;
; display greeter                       ;
;---------------------------------------;
displayGreeter PROC                     ;
    ;- setup                            ;
    MOV si, OFFSET BOOT_MSG             ; we still assume that DS = CS
    MOV ah, 0EH                         ;
    XOR bx, bx                          ;
                                        ;
    ;- loop                             ;
@@loop:                                 ;
    LODSB                               ;
    ;- are we at the end of the string? ;
    OR al, al                           ;
    JZ @@done                           ;
                                        ;
    ;- No? Then print and do next byte! ;
    INT 10H                             ;
    JMP @@loop                          ;
                                        ;
    ;- done, return                     ;
@@done:                                 ;
    RET                                 ;
displayGreeter ENDP                     ;
                                        ;
    BOOT_MSG DB 13, 10, 10              ;
            DB "MAXOS - Initializing booting", 13, 10
            DB "    Copyright Maximilian Wittmer 2023", 13, 10
            DB "    Contact at maximilian.wittmer@gmx.de", 13, 10, 10
            DB 0                        ;
