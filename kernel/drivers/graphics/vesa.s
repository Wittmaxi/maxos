;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;-( synopsis )--------------------------; Namespace DRV_VESA
; DRV_VESA_setup                        ; 
; DRV_VESA_bioscallErrorCheck           ;
; DRV_VESA_panic                        ;
;---------------------------------------;

;---------------------------------------;
DRV_VESA_panic MACRO                    ;
    MOV ax, -3                          ;
    CALL RM_panic                       ;
ENDM                                    ;

;---------------------------------------;
; DRV_VESA_bioscallErrorCheck           ;
;---------------------------------------;
; checks the return codes of a bios-call;
; to INT10H/AH=4fH                      ;
;-( inputs )----------------------------;
; AX = function status directly after INT10H call
;---------------------------------------;
DRV_VESA_bioscallErrorCheck PROC        ;
    ;- check for success                ;
    CMP al, 04FH                        ;
    JE @@a                              ;
    ;- function not supported!          ;
    MAC_DPT_PRINTIMM "Function 10H/ah=4FH: not supported"
    DRV_VESA_panic                      ;
@@a:                                    ;
    ;- is there an error at al?         ;
    SHR ax, 8                           ; that way we can CMP al which is encoded more efficiently
    CMP al, 0                           ;
    JE @@noError                        ;
    ;- check error codes                ;
    CMP al, 1                           ;
    JNE @@b                             ;
    MAC_DPT_PRINTIMM "Function 10H/al=4FH: failed"
    DRV_VESA_panic                      ;
@@b:                                    ;
    CMP al, 2                           ;
    JNE @@c                             ;
    MAC_DPT_PRINTIMM "Function 10H/al=4FH: Software supports this function, but hardware does not"
    DRV_VESA_panic                      ;
@@c:                                    ;
    CMP al, 3                           ;
    JNE @@d                             ;
    MAC_DPT_PRINTIMM "Function 10H/al=4FH: Not supported in current video mode"
    DRV_VESA_panic                      ;
@@d:                                    ;
    MAC_DPT_PRINTIMM "Function 10H/al=4FH: unrecognized error code: "
    CALL DPT_printNum                   ; print error code
    DRV_VESA_panic                      ;
                                        ;
@@noError:                              ;
    ;- will never be reached            ;
    RET                                 ;
DRV_VESA_bioscallErrorCheck ENDP        ;
                                        ;
;---------------------------------------;
; DRV_VESA_setup                        ;
;---------------------------------------;
; checks for VESA compatibility and sets;
; up the correct buffers                ;
;-( invalidates )-----------------------;
; AX; BX; CX; DX                        ;
;---------------------------------------;
DRV_VESA_setup PROC                     ;
    ;
    ;- perform VESA check               ;
    PUSH cs                             ;
    POP es                              ;
    MOV di, OFFSET DRV_VESA_INFO_BLOCK  ; ES:DI buffer for at least 256 bytes (512 for VBE v2.0+)
    MOV ax, 04F00H                      ;
    INT 10H                             ;
                                        ;
    ;- check for errors                 ;
    CALL DRV_VESA_bioscallErrorCheck    ;
    ;-- check buffer signature          ;
    PUSH CS                             ;
    POP ES                              ;
    MOV di, OFFSET DRV_VESA_INFO_BLOCK  ; ES:DI = buffer
    MOV cx, 4                           ;
    MAC_IMMSTRING "VESA"                ; DS:SI = "VESA" signature needs to match!
    REPZ CMPSB                          ;
    JZ @@bufSigMatch                    ;
    MAC_DPT_PRINTIMM "VESA buffer: signature does not match!"
    DRV_VESA_panic                      ;
@@bufSigMatch:                          ;
    ;- check what modes VESA supports and choose best one
    MOV ax, OFFSET DRV_VESA_INFO_BLOCK  ;
    ;-- get vesa modes buffer address   ;
    

    RET                                 ;
DRV_VESA_setup ENDP                     ;
    DRV_VESA_INFO_BLOCK DB 256 DUP (?)         ; http://www.techhelpmanual.com/84-supervga_info_block.html
    DRV_VESA_MODE_INFO_BUF DB 256 DUP (?); http://www.techhelpmanual.com/86-supervga_mode_info_block.html
