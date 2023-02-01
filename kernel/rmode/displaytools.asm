;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;---------------------------------------;
; display tools using the realmode INT10H
; BIOS-call                             ;
;-( synopsis )--------------------------;
; DPT_printStr                          ; prints a null-terminated string
; DPT_clearScr                          ; clears the screen completely
; DPT_printNum                          ; prints a number
; DPT_printNumBase                      ; prints a number with specified base
;-( bugs )------------------------------;
;---------------------------------------;
                                        ;
;---------------------------------------;
; DPT_printStr                          ;
;-( input )-----------------------------;
; ES:DI - the string to print           ; must be null-terminated
;---------------------------------------;
DPT_printStr PROC                       ;
    ;- setup syscall                    ;
    XOR bx, bx                          ;
    MOV ah, 0EH                         ; prepare for int10h;EH
@@printLoop:                            ;
    LODSB                               ;
@@terminated:                           ;
    RET                                 ;
DPT_printStr ENDP                       ;
