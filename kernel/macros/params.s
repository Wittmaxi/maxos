;-------------------------------------------------;
; Copyright 2023 Maximilian Wittmer               ;
;-------------------------------------------------;
; Parameters for the kernel                       ;
;-------------------------------------------------; Namespace PARAM
                                                  ;
    TRUE EQU 1                                    ;
    FALSE EQU 0                                   ;
                                                  ;
    ;- kernel version. unsigned int               ;
    PARAM_KERNEL_VERSION EQU -10                  ;
                                                  ;
    ;- run unit tests ?                           ;
    PARAM_TESTS_RUN EQU TRUE                      ;
                                                  ;
    ;- segments of the kernel                     ; relevant when setting the GDT
    PARAM_KERNEL_CODE_SEG EQU 51                  ; CS == DS
    PARAM_KERNEL_DATA_SEG EQU 51                  ;
