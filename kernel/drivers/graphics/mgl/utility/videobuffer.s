;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;---------------------------------------;
; Maxi's graphic library. Assumes that            ;
; the VESA-Mode was already chosen by the VESA-Driver
;-( synopsis )--------------------------; Namespace MGL
;
;---------------------------------------;

;-------------------------------------------------;
; DRV_VESA_writeToVideoBuffer                     ;
;-( inputs )--------------------------------------;
; BP + 2 Position X                               ; W
; BP + 4 Position Y                               ; W
; TODO: implement color support                   ;
;-( outputs )-------------------------------------;
MGL_writeToVideoBuffer PROC                       ;
    ENTER 0, 0                                    ;
    PUSHA                                         ;
    ;-                                            ;
                                                  ;
    ASSUME bx: PTR DRV_VESA_VBE_MODE_INFO_STRUCT  ;
    MOV bx, OFFSET DRV_VESA_modeInfo              ;
    MOV es, WORD PTR [bx].DRV_VESA_VBE_MODE_INFO_STRUCT.framebufferSeg; ES = window start segment
    MOV ax, WORD PTR [bx].DRV_VESA_VBE_MODE_INFO_STRUCT.pitch; AX = bytes per scanline/pitch
    MOV dx, WORD PTR [bx].DRV_VESA_VBE_MODE_INFO_STRUCT.granularity; DX = granularity
    ;- calculate position                         ;
    MOV cx, WORD PTR [SS:BP + 6]                  ;
    MUL cx                                        ;
    ADD ax, WORD PTR [SS:BP + 4]                  ;
    ADD ax, WORD PTR [bx].DRV_VESA_VBE_MODE_INFO_STRUCT.framebufferOff
    MOV di, ax                                    ;
    MOV es:[di], 010101H                          ;
    ;-                                            ;
    POPA
    LEAVE                                         ;
    RET 4                                         ;
MGL_writeToVideoBuffer ENDP                       ;

;-------------------------------------------------;
