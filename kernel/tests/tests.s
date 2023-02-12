;-------------------------------------------------;
; Copyright 2023 Maximilian Wittmer               ;
;-( synopsis )------------------------------------; Namespace TST
; TST_rModeRun                                    ;
;-------------------------------------------------;
                                                  ;
;-------------------------------------------------;
; TST_rModeRun                                    ;
;-------------------------------------------------;
TST_rModeRun PROC                                 ;
    CALL TST_GDT_run                              ;

    ;- print the diagnostics of the unit tests    ;
    CALL TST_rmodeDiag                            ;
    RET                                           ;
TST_rModeRun ENDP                                 ;

include tools.s
include cpu/gdt/tests.s                           ;
