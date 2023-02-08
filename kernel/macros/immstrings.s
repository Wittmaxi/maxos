;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;---------------------------------------;
; Macros to generate immediate strings  ;
;-( synopsis )--------------------------; NAMESPACE MAC
; MAC_IMMSTRING                         ; create an immediate string
; MAC_PRINTIMM                          ; print an immediate string
;---------------------------------------;
                                        ;
;---------------------------------------;
; MAC_PRINTIMM                          ;
;-( input )-----------------------------;
; PARAM1 - String                       ;
;---------------------------------------;
; Uses the kernel-own DISPLAYTOOLS (DPT) library
; to print an immediate string. requires real mode
; to function                           ;
;---------------------------------------;
MAC_DPT_PRINTIMM MACRO string           ;
    MAC_IMMSTRING string                ;
    CALL DPT_printStr                   ;
ENDM                                    ;
;---------------------------------------;
; MAC_IMMSTRING                         ;
;---------------------------------------;
; generates an immedate string in-place ;
; and loads it'S index in "si", ready to;
; be printed or loaded by LODSB.        ;
; does NULL-terminate the string        ;
;-( input )-----------------------------;
; PARAM1 - String to put into si        ;
;-( output )----------------------------;
; SI - pointer to string                ;
;-( warning )---------------------------;
; o takes up more resources than required for a stringdef
;   performs a nonbranching jump and    ;
;   invalidates pipelining in between of;
;   code. SHOULD ONLY BE USED if speed is not a concern
;                                       ;
; o will not work with 32 bit addressing;
;                                       ;
; o assumes CS = SD. will not work after GDT is setup
;---------------------------------------;
MAC_IMMSTRING MACRO string              ;
Local @@defineString                    ;
    ;-                                  ;
    JMP @F                              ; skip the "immediate string" inside of the code
@@defineString:                         ;
    DB string                           ;
    DB 0                                ;
@@:                                     ;
    MOV si, OFFSET @@defineString       ; load the string into SI
ENDM                                    ;
