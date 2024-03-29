;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;---------------------------------------;
; Defines the structures used in the    ;
; Vesa driver                           ;
;-( synopsis )--------------------------; Namespace DRV_VESA
; DRV_VESA_VBE_INFO_STRUCT              ;
; DRV_VESA_VBE_MODE_INFO_STRUCT         ;
;---------------------------------------;
                                        ;
;---------------------------------------;
; DRV_VESA_VBE_INFO                     ;
;---------------------------------------;
DRV_VESA_VBE_INFO_STRUCT STRUCT         ;
    signature DB "VBE2"                 ; 0 NEEDS to be "VESA" on return
    version DW ?                        ; 4
    ;- OEM info string                  ;
    oemOff DW ?                         ; 6
    oemSeg DW ?                         ; 8
    capabilities DD ?                   ; 10
    ;- video modes array                ;
    modesOff DW ?                       ; 12
    modesSeg DW ?                       ;
    videoMemory DW ?                    ;
    softwareRevision DW ?               ;
    ;- vendor                           ;
    vendorOff DW ?                      ;
    vendorSeg DW ?                      ;
    ;- product name                     ;
    productNameOff DW ?                 ;
    productNameSeg DW ?                 ;
    ;- product revision                 ;
    productRevOff DW ?                  ;
    productRevSeg DW ?                  ;
    ;---8<-----------8<---------8<------; obligatory but can't use
    reserved DB 222 DUP (?)             ;
    oemData DB 256 DUP (?)             ;
DRV_VESA_VBE_INFO_STRUCT ENDS           ;
                                        ;
;---------------------------------------;
; DRV_VESA_VBE_MODE_INFO_STRUCT         ;
;---------------------------------------;
DRV_VESA_VBE_MODE_INFO_STRUCT STRUCT    ;
    attributes DW ?                     ;
    windowA DB ?                        ; deprecated
    windowB DB ?                        ; deprecated
    granularity DW ?                    ;
    windowSize DW ?                     ;
    segmentA DW ?                       ;
    segmentB DW ?                       ;
    winFuncPtr DD ?                     ;
    pitch DW ?                          ; bytes per horizontal line
    scrWidth DW ?                       ;
    scrHeight DW ?                      ;
    wChar DB ?                          ;
    yChar DB ?                          ;
    planes DB ?                         ;
    bpp DB ?                            ;
    banks DB ?                          ;
    memoryModel DB ?                    ;
    bankSize DB ?                       ;
    reserved0 DB ?                      ;
                                        ;
    redMask DB ?                        ;
    redPosition DB ?                    ;
    greenMask DB ?                      ;
    greenPosition DB ?                  ;
    blueMask DB ?                       ;
    bluePosition DB ?                   ;
    reservedMask DB ?                   ;
    reservedPosition DB ?               ;
    directColorAttributes DB ?          ;
                                        ;
    framebufferOff DW ?                 ;
    framebufferSeg DW ?                 ;
    offScreenMemOff DD ?                ;
    offScreenMemSize DW ?               ;
    reserved1 DB 206 DUP (?)            ;
DRV_VESA_VBE_MODE_INFO_STRUCT ENDS      ;
