;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;---------------------------------------;
; Implement the driver for text-based VGA.
; requires setup first                  ;
; for this, the 'setup' method is exposed
;---------------------------------------;
; VGAT_setup                            ; sets up the variables, probes the system for buffers
; VGAT_putCh                            ; puts a character at the next available location
; VGAT_putStr                           ; Writes a string at the next available location
; VGAT_createColor                      ; creates a color byte that can be used with putStr
; VGAT_setCursor                        ; sets the cursor to a specific position
;---------------------------------------;
                                        ;
;---------------------------------------;
; VGAT_setup                            ;
;---------------------------------------;
; no parameters, sets up different data ;
; for VGA                               ;
;---------------------------------------;
VGAT_setup PROC                         ;
    ;- does computer support colors?    ;
    MOV WORD PTR [VGAT_baseSegment], 08000H; DANGEROUS! Can break computers that don't have support for color. TODO
                                        ;
    ;- set high-res video mode          ;
    MOV al, 01H                         ;
    MOV dx, 03B8H                       ;
    OUT dx, al                          ;
                                        ;
    ;- flush all characters from screen ;
    CALL VGAT_INT_flushScreen           ;
                                        ;
    RET                                 ;
VGAT_setup ENDP                         ;
                                        ;
;=======================================;
; internals                             ;
;=======================================;
VGAT_INT_flushScreen PROC               ;
    ;- setup es:di                      ;
    MOV es, [VGAT_baseSegment]          ;
    MOV di, 0                           ;
                                        ;
    ;- setup data                       ;
    MOV al, 'a'                         ;
    MOV cx, VGAT_screenBufLen           ;
                                        ;
    ;- empty buffer                     ;
    REP STOSB                           ;
                                        ;
    ;- done                             ;
    RET                                 ;
VGAT_INT_flushScreen ENDP               ;
                                        ;
    ;- variables                        ;
    ;-- buffer access                   ;
    VGAT_baseSegment DW ?               ;
    VGAT_currentOffset DW 0             ;
    ;- params                           ;
    VGAT_screenLen EQU 80 * 25          ;
    VGAT_screenBufLen EQU VGAT_screenLen * 2;
