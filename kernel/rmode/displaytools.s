;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;---------------------------------------;
; display tools using the realmode INT10H
; BIOS-call                             ;
;-( synopsis )--------------------------;
; DPT_putChar                           ; puts a single char to terminal
; DPT_printStr                          ; prints a null-terminated string
; DPT_clearScr                          ; clears the screen completely
; DPT_printNum                          ; prints a number
; DPT_printNumSigned                    ; prints a number, treats input as unsigned
; DPT_newLine                           ; goes to the new line
;-( bugs )------------------------------;
;---------------------------------------;
.8086                                   ;
                                        ;
;---------------------------------------;
; DPT_putChar                           ;
;-( input )-----------------------------;
; al - the character                    ;
;---------------------------------------;
DPT_putChar PROC                        ;
    PUSH ax                             ;
    PUSH bx                             ;
                                        ;
    MOV ah, 0EH                         ;
    XOR bx, bx                          ;
    INT 10H                             ;
                                        ;
    POP bx                              ;
    POP ax                              ;
    RET                                 ;
DPT_putChar ENDP                        ;
                                        ;
;---------------------------------------;
; DPT_printStr                          ;
;-( input )-----------------------------;
; DS:DI - the string to print           ; must be null-terminated
;---------------------------------------;
DPT_printStr PROC                       ;
    PUSH ax                             ;
    PUSH bx                             ;
                                        ;
    ;- setup syscall                    ;
    XOR bx, bx                          ;
    MOV ah, 0EH                         ; prepare for int10h;EH
@@printLoop:                            ;
    LODSB                               ;
                                        ;
    ;- check for zero termination       ;
    OR al, al                           ; 
    JZ @@terminated                     ;
                                        ;
    ;- print and loop                   ;
    INT 10H                             ; the actual print command
    JMP @@printLoop                     ;
                                        ;
    ;- all done                         ;
@@terminated:                           ;
    POP bx                              ;
    POP ax                              ;
    RET                                 ;
DPT_printStr ENDP                       ;
                                        ;
;---------------------------------------;
; DPT_clearScr                          ;
;---------------------------------------;
DPT_clearScr PROC                       ;
    MAC_PUSH_COMMON_REGS                ;
                                        ;
    ;- get amount of video columns      ;
    MOV ah, 0FH                         ;
    INT 10H                             ; AH = amount of columns
                                        ;
    ;- multiply with rows               ;
    MOV al, ah                          ;
    XOR ah, ah                          ;
    CWD                                 ; DX = 0
    MOV cx, 25                          ; 
    MUL cx                              ; Multiply columns with 25 rows
    MOV cx, ax                          ; AX = how many times to write
                                        ;
    ;- prepare writes                   ;
    MOV ax, 0E00H                       ; AH = 0EH, AL = 0
    XOR bx, bx                          ;
                                        ;
    ;- write loop                       ;
@@writeLoop:                            ;
    INT 10H                             ;
    LOOP @@writeLoop                    ;
                                        ;
    ;- set cursor to 0;0                ;
    MOV ah, 02H                         ;
    MOV bh, 0                           ;
    MOV dx, 0                           ; CH = 0; CL = 0
    INT 10H                             ;
                                        ;
    ;- done                             ;
    MAC_POP_COMMON_REGS                 ;
    RET                                 ;
DPT_clearScr ENDP                       ;
                                        ;
;---------------------------------------;
; DPT_printNum                          ;
;-( input )-----------------------------;
; AX = number to print                  ;
;---------------------------------------;
DPT_printNum PROC                       ;
    MAC_PUSH_COMMON_REGS                ;
                                        ;
    ;- setup division                   ;
    MOV bx, 0AH                         ; BX for division by 10 (base 10)
    XOR cx, cx                          ; CX keeps track of the amount of digits
                                        ;
    ;- first divide the number into digits;
@@divideLoop:                           ;
    XOR dx, dx                          ;
    DIV bx                              ;
    PUSH dx                             ; populate the stack with the digits
    INC cx                              ; count how many digits
    OR ax, ax                           ; Is ax zero already?
    JNZ @@divideLoop                    ;
                                        ;
    ;- prepare printloop                ;
    XOR bx, bx                          ;
                                        ;
@@printLoop:                            ;
    POP ax                              ;
    MOV ah, 0EH                         ; this was overwritten by pop
    ADD al, '0'                         ; we print in ASCII
    INT 10H                             ;
    LOOP @@printLoop                    ; with CX = amount of digits we divided into
                                        ;
    MAC_POP_COMMON_REGS                 ;
    RET                                 ;
DPT_printNum ENDP                       ;

;---------------------------------------;
; DPT_printNumSigned                    ; assumes sign bit in bit 16
;-( input )-----------------------------;
; AX = number to print                  ;
;---------------------------------------;
DPT_printNumSigned PROC                 ;
    MAC_PUSH_COMMON_REGS                ;
                                        ;
    MOV bx, ax                          ;
    ;- do we need to adjust for 2s complement?
    MOV cl, 15                          ; separate the first bit
    SHR bx, cl                          ;
    AND bl, 1                           ; is first bit set? then ax is negative!
    JZ @@skipAdjust                     ;
                                        ;
    ;- adjust                           ;
    XOR ax, 0FFFFH                      ; invert ax
    INC ax                              ; to avoid having 0 and -0. We use 2s complement!!
    PUSH ax                             ; preserve
                                        ;
    ;- print sign                       ;
    MOV al, '-'                         ;
    CALL DPT_putChar                    ;
                                        ;
    POP ax                              ;
    ;- resume printing                  ;
@@skipAdjust:                           ;
    CALL DPT_printNum                   ;
                                        ;
    MAC_POP_COMMON_REGS                 ;
    RET                                 ;
DPT_printNumSigned ENDP                 ;
                                        ;
;---------------------------------------;
; DPT_newLine                           ;
;---------------------------------------;
DPT_newLine PROC                        ;
    PUSH ax                             ;
                                        ;
    ;- print the control chars          ;
    MOV al, 0DH                         ;
    CALL DPT_putChar                    ;
    MOV al, 0AH                         ;
    CALL DPT_putChar                    ;
                                        ;
    ;- done                             ;
    POP ax                              ;
    RET                                 ;
DPT_newLine ENDP                        ;
