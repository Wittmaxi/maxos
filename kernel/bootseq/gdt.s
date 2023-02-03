;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;-( synopsis )--------------------------; NAMESPACE BGDT (boot gdt)
; BGDT_setup                            ;
;---------------------------------------;
.686                                    ;
                                        ;
;---------------------------------------;
; BGDT_create                           ;
;---------------------------------------;
; creates a GDT at the required position;
;-( inputs )----------------------------;
; SS + 2 = pointer to GDT               ; W
; SS + 4 = limit                        ; DW
; SS + 8 = flags                        ; W
; SS + 10 = base                        ; DW
; SS + 14 = unused                      ;
; SS + 15 = access byte                 ; B
;-( output )----------------------------;
; *AX = the newly created GDT           ;
;---------------------------------------;
BGDT_create PROC                        ;
    MAC_PUSH_COMMON_REGS                ;
                                        ;
    ;- is the limit without bounds?     ;
    MOV bx, WORD PTR SS:[SP + 4]        ;
    CMP bx, 0FFH                        ;
    JLE @@limitOk                       ;
    MOV ax, 50                          ; Error code: GDT-limit not ok
    CALL RM_panic                       ;
                                        ;
    ;- encode limit                     ;
@@limitOk:                              ;
                                        ;
    MAC_POP_COMMON_REGS                 ;
    RET 16                              ; free the 15 bytes of stack params
BGDT_create ENDP                        ;
                                        ;
;---------------------------------------;
; BGDT_setup                            ;
;---------------------------------------;
; creates a GDT that enabels the kernel to 
; enable the A20 line                   ;
;-( invalidates )-----------------------;
; ax, bx, cx, dx                        ;
;---------------------------------------;
BGDT_setup PROC                         ;

    MOV ax, 42
    PUSH ax
    PUSH ax
    PUSH ax
    PUSH ax
    PUSH ax
    PUSH ax
    PUSH ax
    PUSH ax
    CALL BGDT_create

    RET                                 ;
BGDT_setup ENDP                         ;
                                        ;
    ;- variables                        ;
    BGDT_spaceNullDesc DQ ?             ; space for the GDT to be created
    BGDT_spaceCodeDesc DQ ?             ;
    BGDT_spaceDataDesc DQ ?             ;
    BGDT_spaceTSSDesc DQ ?              ;
