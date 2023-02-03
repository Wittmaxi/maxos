;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;-( synopsis )--------------------------; NAMESPACE CPUID
; CPUID_check                           ;
;---------------------------------------;
; compatible CPUs must be 32 bit        ;
; needs to be at least pentium          ;
; and 32 bit CPU                        ;
;---------------------------------------;
                                        ;
;---------------------------------------;
; CPUID_check                           ;
;-( panics )----------------------------;
; If CPU not compatible with .386       ;
;-( output )----------------------------;
;-( invalidated )-----------------------;
; AX; BX; CX; DX                        ;
;---------------------------------------;
CPUID_check PROC                        ;
    ;- Check: are we on 286 CPU?        ;
                                        ;
    ;-- 286 will increment SP after push, modern CPUs increment SP before
    PUSH sp                             ;
    POP bp                              ;
    CMP bp, sp                          ;
    JZ @@atleast286                     ;
                                        ;
    ;-- not supported!                  ;
    MOV ax, -1                          ;
    CALL RM_panic                       ;
@@atleast286:                           ;
                                        ;
.286                                    ; we can safely assume that .286 is supported
    ;- check: 386?                      ;
    MOV ax, 07000H                      ; '0111 0000 0000 0000'
    PUSH ax                             ;
    POPF                                ;
    PUSHF                               ;
    POP ax                              ;
    AND ah, 070H                        ;
    JNZ @@atleast386                    ;
                                        ;
    ;-- not supported                   ;
    MOV ax, -2                          ;
    CALL RM_panic                       ;
@@atleast386:                           ;
.386                                    ;
    RET                                 ;
CPUID_check ENDP                        ;
