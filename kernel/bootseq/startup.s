;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;---------------------------------------;
; startup                               ;
;---------------------------------------;
; runs the different startup initialization
; routines one after the other          ;
;---------------------------------------;
startup PROC                            ;
    CALL displayGreeter                 ;

    RET                                 ;
startup ENDP                            ;
                                        ;
;=======================================;
; INCLUDES                              ;
;=======================================;
include greeter.s                       ;
