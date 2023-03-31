;-------------------------------------------------;
; Copyright 2023 Maximilian Wittmer               ;
;-------------------------------------------------;
; the main file of the kernel.                    ;
;-------------------------------------------------;
; kernelMain                                      ; the main function of the kernel. MUST be located at byte 0
;-------------------------------------------------;
.8086                                             ; we have not yet checked what kind of processor is running us
KERN SEGMENT USE16                                ; thus, we still write strictly 16bit 8086 compatible code to avoid problems
ORG 0                                             ;
;-------------------------------------------------;
; kernel_main                                     ;
;-------------------------------------------------;
; assumes CS = DS                                 ;
; assumes a stack is set up                       ;
; assumes loading at 51:00                        ; probably not strictly necessary
; assumes real mode                               ; We will leave the real mode ourselves
; Assumes stack in highest 2k addresses           ; memory management will assume this. If not loaded correctly, will crash
;-------------------------------------------------;
kernelMain PROC                                   ;
    CALL startup                                  ; initialize
                                                  ;
    ;- everything done, we loop until hard stop   ;
@@loop:                                           ;
    HLT                                           ;
    JMP @@loop                                    ;
                                                  ;
kernelMain ENDP                                   ;
                                                  ;
;-------------------------------------------------;
; includes                                        ;
;-------------------------------------------------;
include macros/macros.s                           ;
include rmode/tools.s                             ;
include cpu/cpu.s                                 ;
include bootseq/startup.s                         ;
                                                  ;
    ;- this parameter should be located in macros/params.s but can't because it needs to be at the very tail of the code
    PARAM_KERNEL_SIZE EQU $                       ;
KERN ENDS                                         ;
                                                  ;
END                                               ;
