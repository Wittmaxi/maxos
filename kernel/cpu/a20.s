;-------------------------------------------------;
; Copyright 2023 Maximilian Wittmer               ;
;-( synopsis )------------------------------------; Namespace CPU
; CPU_enableA20                                   ;
;-------------------------------------------------;
                                                  ;
;-------------------------------------------------;
; CPU_enableA20                                   ;
;-------------------------------------------------;
; Checks if a20 is enabled and if not, will enable;
;-------------------------------------------------;
CPU_enableA20 PROC                                ;
    ;- is a20 enabled already?                    ;
    CALL CPU_checkA20                             ;
    OR ax, ax                                     ;
    JNZ @@a20Enabled                              ;
                                                  ;
    ;- try BIOS A20                               ;
    MOV ax, 02401H                                ;
    INT 15H                                       ;
                                                  ;
@@noA20InBios:                                    ;
    ;-- is a20 enabled already?                   ;
    CALL CPU_checkA20                             ;
    OR ax, ax                                     ;
    JNZ @@a20Enabled                              ;
                                                  ;
    MAC_DPT_PRINTIMM "try 0EEH "                  ;
    ;- try 0EEH                                   ;
    IN al, 0EEH                                   ;
                                                  ;
    ;-- is a20 enabled already?                   ;
    CALL CPU_checkA20                             ;
    OR ax, ax                                     ;
    JNZ @@a20Enabled                              ;
                                                  ;
    ;- try keyboard controller                    ;
@@keyboardWaitForDone:
    

@@a20Enabled:                                     ;
    MAC_DPT_PRINTIMM "A20 enabled!"
    CALL CPU_checkA20                             ;
@@spinlock:
    OR ax, ax
    JZ @@spinlock                                 ;

    RET                                           ;
CPU_enableA20 ENDP                                ;

;-------------------------------------------------;
; CPU_waitUntilKeyboardReceivedData               ;
;-------------------------------------------------;
; waits for the keyboard controller to be done    ;
; https://www.win.tue.nl/~aeb/linux/kbd/scancodes-11.html 
;-------------------------------------------------;
CPU_waitUntilKeyboardReceivedData PROC            ;
    in al, 064H                                   ;
    test al, 2                                    ;
    jnz CPU_waitUntilKeyboardReceivedData         ;
    ret                                           ;
CPU_waitUntilKeyboardReceivedData ENDP            ;
                                                  ;
;-------------------------------------------------;
; CPU_checkA20                                    ;
;-( output )--------------------------------------;
; AX = boolean: A20 enabled or not?               ;
;-( invalidates )---------------------------------;
; GS                                              ;
;-------------------------------------------------;
CPU_checkA20 PROC                                 ;
    ;- check if A20 is already enabled            ;
    ;-- write to 0:500                            ;
    XOR ax, ax                                    ;
    MOV gs, ax                                    ;
    MOV BYTE PTR GS:[500], 0                      ;
    ;-- write to ffff:510                         ;
    NOT ax                                        ;
    MOV fs, ax                                    ;
    MOV BYTE PTR FS:[510], 0FFH                   ;
    ;-- check 0:500                               ;
    XOR ax, ax                                    ;
    MOV gs, ax                                    ;
    CMP BYTE PTR GS:[500], 0                      ;
    JNE @@a20Enabled                              ;
    MOV ax, 0                                     ;
    CALL DPT_printNum                             ;
    RET                                           ;
@@a20Enabled:                                     ;
    MOV ax, 1                                     ;
    CALL DPT_printNum                             ;
    CALL DPT_printNum                             ;
    CALL DPT_printNum                             ;
    CALL DPT_printNum                             ;
    CALL DPT_printNum                             ;
    RET                                           ;
CPU_checkA20 ENDP                                 ;
                                                  ;
