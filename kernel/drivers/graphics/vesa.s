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
; AX; BX; CX; DX; FS; ES                ;
;---------------------------------------;
DRV_VESA_setup PROC                     ;
    ENTER 4, 0                          ;
    ;- initialize variables             ;
    DRV_VESA_bestSize EQU SS:bp - 0     ;
    DRV_VESA_bestMode EQU SS:bp - 2     ;
    MOV WORD PTR [DRV_VESA_bestSize], 0 ;
    MOV WORD PTR [DRV_VESA_bestMode], 0 ;
    ;-                                  ;
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
    JZ @@sigMatch                       ;
    MAC_DPT_PRINTIMM "VESA buffer: signature does not match!"
    DRV_VESA_panic                      ;
                                        ;
@@sigMatch:                             ;
    ;-- check vesa version              ;
    MOV ax, ES:[DRV_VESA_infoBlock].version
    CMP ax, 00102H                      ;
    JGE @@versionOk                     ;
    MAC_DPT_PRINTIMM "VESA: version to low"
    DRV_VESA_panic                      ;
@@versionOk:                            ;
    ;- check what modes VESA supports and choose best one
    MOV bx, OFFSET DRV_VESA_infoBlock   ;
    ASSUME bx: PTR DRV_VESA_VBE_INFO_STRUCT
                                        ;
    ;-- get vesa modes buffer address   ;
    MOV ax, WORD PTR [bx].DRV_VESA_VBE_INFO_STRUCT.modesOff
    MOV si, ax
    MOV ax, WORD PTR [bx].DRV_VESA_VBE_INFO_STRUCT.modesSeg
    PUSH ax                             ;
    POP fs                              ; FS:SI = info struct
                                        ;
    ;-- read modes                      ;
    PUSH cs                             ;
    POP es                              ;
    MOV di, OFFSET DRV_VESA_modeInfo    ; ES:DI = mode info
    ASSUME DI:PTR DRV_VESA_VBE_MODE_INFO_STRUCT
@@displayModeLoop:                      ;
    MOV cx, WORD PTR fs:[si]            ; CX = mode code
    CMP cx, 0FFFFH                      ;
    JE @@displayModeEndLoop             ;
    ;-- get mode information            ;
    MOV ax, 04F01H                      ;
    INT 10H                             ;
    CALL DRV_VESA_bioscallErrorCheck    ;
    ;-- compare with current best mode  ;
    ;--- screenSize                     ;
    XOR dx, dx                          ;
    MOV ax, WORD PTR [di].DRV_VESA_VBE_MODE_INFO_STRUCT.scrHeight
    MUL WORD PTR [di].DRV_VESA_VBE_MODE_INFO_STRUCT.scrWidth
    CMP ax, WORD PTR [DRV_VESA_bestSize]; is this mode's scren size bigger than the previous mode?
    JLE @@skipThisMode                  ; No? check next mode!
    ;--- linear frame buffer?           ;
    MOV ax, WORD PTR [di].DRV_VESA_VBE_MODE_INFO_STRUCT.attributes
    AND ax, 090H                        ; BIT 7: LFB accessible
    OR ax, ax                           ;
    JZ @@skipThisMode                   ;
    ;--- good memory model?             ; we want true color or packed pixel
    MOV ax, WORD PTR [di].DRV_VESA_VBE_MODE_INFO_STRUCT.memoryModel
    CMP ax, 04H                         ; packed pixel mode
    JE @@memoryModelGood                ;
    CMP ax, 06H                         ; true color mode
    JNE @@skipThisMode                  ;
@@memoryModelGood:                      ;
    ;-- preserve best mode for future loops;
    XOR dx, dx                          ;
    MOV ax, WORD PTR [di].DRV_VESA_VBE_MODE_INFO_STRUCT.scrHeight
    MUL WORD PTR [di].DRV_VESA_VBE_MODE_INFO_STRUCT.scrWidth
    MOV WORD PTR [DRV_VESA_bestSize], ax;
    MOV WORD PTR [DRV_VESA_bestMode], cx;
@@skipThisMode:                         ;
    ADD si, 2                           ;
    JMP @@displayModeLoop               ;
@@displayModeEndLoop:                   ;
    ;- saveguard best mode              ;
    MOV cx, WORD PTR [DRV_VESA_bestMode];
    MOV WORD PTR [DRV_VESA_displayMode], cx
    ;-                                  ;
    LEAVE                               ;
    RET                                 ;
DRV_VESA_setup ENDP                     ;
                                        ;
                                        ;
include vesa_structures.s               ;
                                        ;
    DRV_VESA_displayMode DW ?           ; will be found in setup
    ALIGN DWORD                         ; some bioses might require the structs to be aligned
    DRV_VESA_infoBlock DRV_VESA_VBE_INFO_STRUCT  {}
    ALIGN DWORD                         ;
    DRV_VESA_modeInfo DRV_VESA_VBE_MODE_INFO_STRUCT {}
