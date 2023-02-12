;-------------------------------------------------;
; Copyright 2023 Maximilian Wittmer               ;
;-------------------------------------------------; NAMESPACE BGDT (boot gdt)
; BGDT_setup                                      ;
;-------------------------------------------------;
.686                                              ;
                                                  ;
                                                  ;
;-------------------------------------------------;
; BGDT_setup                                      ;
;-------------------------------------------------;
; creates a GDT that enabels the kernel to        ;
; enable the A20 line                             ;
;-( invalidates )---------------------------------;
; ax, bx, cx, dx                                  ;
;-( invalidates )---------------------------------;
BGDT_setup PROC                                   ;

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

    RET                                           ;
BGDT_setup ENDP                                   ;
                                                  ;
    ;- variables                                  ;
    BGDT_spaceNullDesc DQ ?                       ; space for the GDT to be created
    BGDT_spaceCodeDesc DQ ?                       ;
    BGDT_spaceDataDesc DQ ?                       ;
    BGDT_spaceTSSDesc DQ ?                        ;
