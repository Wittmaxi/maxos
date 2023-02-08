;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;-( synopsis )--------------------------; Namespace DRV_VESA
; DRV_VESA_setup                        ; 
; DRV_VESA_bioscallErrorCheck           ;
; DRV_VESA_panic                        ;
;---------------------------------------;
                                        ;
;---------------------------------------;
DRV_VESA_panic MACRO                    ;
    MOV ax, -3                          ;
    CALL RM_panic                       ;
ENDM                                    ;
                                        ;
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
    PUSH cs                             ;
    POP es                              ;
    ;- perform VESA check               ;
    PUSH es                             ; some BIOSes destroy ES with this call
    MOV di, OFFSET DRV_VESA_infoBlock   ; ES:DI buffer for at least 256 bytes (512 for VBE v2.0+)
    MOV ax, 04F00H                      ;
    INT 10H                             ;
    POP es                              ;
                                        ;
    ;- check for errors                 ;
    CALL DRV_VESA_bioscallErrorCheck    ;
                                        ;
    ;-- check buffer signature          ;
    PUSH CS                             ;
    POP ES                              ;
    MOV di, OFFSET DRV_VESA_infoBlock   ; ES:DI = buffer
    MOV cx, 4                           ;
    MAC_IMMSTRING "VESA"                ; DS:SI = "VESA" signature needs to match!
    REPZ CMPSB                          ;
    JZ @@noErrors                       ;
    MAC_DPT_PRINTIMM "VESA buffer: signature does not match!"
    DRV_VESA_panic                      ;
                                        ;
    ;-- check vesa version              ;
    MOV ax, CS:[DRV_VESA_infoBlock].version
    CMP ax, 00102H                      ;
    JGE @@noErrors                      ;
    MAC_DPT_PRINTIMM "VESA: version too low"
    DRV_VESA_panic                      ;
                                        ;
@@noErrors:                             ;
                                        ;
    ;- check what modes VESA supports and choose best one
    MOV bx, OFFSET DRV_VESA_infoBlock   ;
    ASSUME bx: PTR DRV_VESA_VBE_INFO_STRUCT
                                        ;
    ;-- get vesa modes buffer address   ;
    MOV dx, WORD PTR [bx].DRV_VESA_VBE_INFO_STRUCT.modesOff
    MOV ax, WORD PTR [bx].DRV_VESA_VBE_INFO_STRUCT.modesSeg
    MOV fs, ax                          ; display modes at fs:dx
                                        ;
    ;-- read modes                      ;
    MOV di, OFFSET DRV_VESA_modeInfo    ;
@@displayModeLoop:                      ;
    MOV cx, WORD PTR fs:[dx]            ;
    CMP cx, 0FFFFH                      ;
    JE @@displayModeEndLoop             ;
    MOV ax, cx                          ;
    CALL DPT_printNum                   ;
    ;--- get mode information           ;
    MOV ax, 04F01H                      ;
    INT 10H                             ;
    CALL DRV_VESA_bioscallErrorCheck    ;

    ADD dx, 2                           ;
    JMP @@displayModeLoop               ;
@@displayModeEndLoop:                   ;
                                        ;
    RET                                 ;
DRV_VESA_setup ENDP                     ;
                                        ;
                                        ;
include vesa_structures.s               ;
                                        ;
    ALIGN DWORD                         ; some bioses might require the structs to be aligned
    DRV_VESA_infoBlock DRV_VESA_VBE_INFO_STRUCT  {}
    ALIGN DWORD                         ;
    DRV_VESA_modeInfo DRV_VESA_VBE_MODE_INFO_STRUCT {}

