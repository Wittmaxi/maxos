;-------------------------------------------------;
; Copyright 2023 Maximilian Wittmer               ;
;-( synopsis )------------------------------------;
; GDT_encode_entry                                ; encode a single entry
;-------------------------------------------------;
.386P                                             ;
                                                  ;
;-------------------------------------------------;
; GDT_encode_entry                                ;
;-------------------------------------------------;
; creates a GDT at the required position          ;
;-( inputs )--------------------------------------;
; BP + 2 = pointer to GDT                         ; W
; BP + 4 = limit                                  ; DW - first byte will effectively be empty - and ignored by code!
; BP + 8 = flags                                  ; W (first byte unused)
; BP + 10 = base                                  ; DW
; BP + 14 = access byte                           ; W (first byte unused)
;-( output )--------------------------------------;
; [gdtptr] = the newly created GDT                ;
;-------------------------------------------------;
GDT_encodeEntry PROC                              ;
    ;- params                                     ;
    PUSH bp                                       ;
    MOV bp, sp                                    ;
                                                  ;
    GDT_GDTptr EQU SS:BP + 4                      ;
    GDT_limit EQU SS:BP + 6                       ;
    GDT_flags EQU SS:BP + 10                      ;
    GDT_base EQU SS:BP + 12                       ;
    GDT_accessByte EQU SS:BP + 16                 ;
    ;-                                            ;
    MAC_PUSH_COMMON_REGS                          ;
                                                  ;
    ;- is the limit without bounds?               ;
    MOV ebx, DWORD PTR [GDT_limit]                ;
    CMP ebx, 0FFFFFH                              ;
    JLE @@limitOk                                 ;
    MOV ax, 50                                    ; Error code: GDT problem
    CALL RM_panic                                 ;
                                                  ;
@@limitOk:                                        ;
    ;- encode entry                               ;
    ASSUME DI: PTR GDT_entry                      ;
    MOV di, WORD PTR [GDT_GDTptr]                 ;
    ;-- encode limit                              ; BX is still GDT_limit
    ;--- low limit                                ;
    MOV WORD PTR [CS:di].GDT_entry.limitLow, bx   ;
    ;--- high limit                               ;
    SHR ebx, 16                                   ;
    XOR bh, bh                                    ;
    AND bl, 00001111B                             ; don't make assumptions, we might get garbage passed
    MOV dl, BYTE PTR [di].GDT_entry.granularity   ;
    AND dl, 11110000B                             ; high limit goes into the high nibble
    OR dl, bl                                     ;
    MOV BYTE PTR [di].GDT_entry.granularity, dl   ;
    ;-- encode flag                               ;
    MOV bx, WORD PTR [GDT_flags]                  ;
    SHL bl, 4                                     ;
    MOV dl, BYTE PTR [di].GDT_entry.granularity   ;
    AND dl, 00001111B                             ; flags go into low nibble
    OR dl, bl                                     ;
    MOV BYTE PTR [di].GDT_entry.granularity, dl   ;
    ;-- encode base                               ;
    ;--- low base                                 ;
    MOV ebx, DWORD PTR [GDT_base]                 ;
    MOV WORD PTR [di].GDT_entry.baseLow, bx       ;
    ;--- high base                                ;
    SHR ebx, 16                                   ;
    MOV BYTE PTR [di].GDT_entry.baseHighest, bh   ;
    ;--- mid base                                 ;
    MOV BYTE PTR [di].GDT_entry.baseMid, bl       ;
    ;-- encode access byte                        ;
    MOV bl, BYTE PTR [GDT_accessByte]             ;
    MOV BYTE PTR [di].GDT_entry.accessByte, bl    ;
                                                  ;
    ;- all done!                                  ;
    MAC_POP_COMMON_REGS                           ;
    LEAVE                                         ;
    RET 16                                        ; free the 16 bytes of stack params
GDT_encodeEntry ENDP                              ;
                                                  ;
include structure.s                               ;
                                                  ;
