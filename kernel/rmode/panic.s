;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;---------------------------------------;
; real mode kernel panic                ;
;-( synopsis )--------------------------;
; RM_panic                              ;
;---------------------------------------;
.8086                                   ;
                                        ;
;---------------------------------------;
; RM_Panic                              ;
;-( input )-----------------------------;
; ax = kernel panic code                ; (signed)
; -2 = CPU not supported (<i386)        ;
; -1 = CPU not supported (<i286)        ;
; 50 = GDT: limit exceeds bounds        ;
;---------------------------------------;
RM_panic PROC                           ;
    ;- print message and code           ;
    MOV si, OFFSET RM_PANIC_MSG         ;
    CALL DPT_printStr                   ;
    CALL DPT_printNumSigned             ;
    MOV si, OFFSET RM_PANIC_MSG_CONT    ;
    CALL DPT_printStr                   ;
                                        ;
    ;- await keypress                   ;
    XOR ax, ax                          ;
    INT 16H                             ;
                                        ;
    ;- give away control                ;
    INT 19H                             ;
    ;- doesn't return                   ;
RM_panic ENDP                           ;
    ;-                                  ;
    RM_PANIC_MSG DB 13, 10, "=============================", 13, 10
                 DB "Kernel fault - Error code: ", 0
    RM_PANIC_MSG_CONT DB 13, 10, "Press the any key to continue", 13, 10, 0
