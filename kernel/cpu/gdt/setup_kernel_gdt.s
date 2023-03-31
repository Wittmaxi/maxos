;-------------------------------------------------;
; Copyright 2023 Maximilian Wittmer               ;
;-( synopsis )------------------------------------; Namespace GDT
; GDT_setupKernelGDT                              ;
;-------------------------------------------------;
.386P                                             ;
                                                  ;
;-------------------------------------------------;
; GDT_setupKernelGDT                              ;
;-------------------------------------------------;
; sets up the GDT for the kernel. Out bootloader  ;
; doesn't do this for us (and if it does, we don't;
; know what's in the GDT). hence the need to set  ;
; one up for ourselves.                           ;
; We setup a GDT for a flat model, unlocking all  ;
; 4 GIGs of memory, we setup a TSS segment        ;
; the stack lives in our normal memory            ;
;-( outputs )-------------------------------------;
; GDTP register = our new GDT                     ;
;-------------------------------------------------;
GDT_setupKernelGDT PROC                           ;
    ;- create GDTR structure                      ;
    ;-- calculate GDT_buffer "flat" address       ;
    XOR eax, eax                                  ;
    MOV ax, ds
    MOV cl, 4                                     ;
    SHL eax, cl                                   ;
    ADD eax, OFFSET GDT_buffer                    ;
    ;-- fill GDTP base                            ;
    MOV DWORD PTR [GDT_ptrBuffer].GDT_ptr.base, eax;
    ;-- fill GDTP limit                           ;
    MOV ax, GDT_gdtSize                           ;
    DEC ax                                        ;
    MOV WORD PTR [GDT_ptrBuffer].GDT_ptr.sz, ax   ;
    ;- flush GDT                                  ;
    CLI
    LGDT FWORD PTR [GDT_ptrBuffer]                ;


    mov eax, cr0 
    or al, 1       ; set PE (Protection Enable) bit in CR0 (Control Register 0)
    mov cr0, eax                                   ;

;-- change CS                                 ;
    DB 0EAH                                       ;
    DW OFFSET @@skipGDT
    DW 3 SHL 3

@@skipGDT:                                        ;

    DB "HELLO WORLD"

    ;- update segment registers                   ;
    MOV ax, 4 SHL 3                               ;
    MOV ds, ax                                    ;
    MOV ax, 2 SHL 3                               ;
    MOV es, ax                                    ;
    MOV fs, ax                                    ;
    MOV gs, ax                                    ;
    MOV ss, ax                                    ;


@@hlt:
    HLT
    JMP @@hlt
   

    MAC_DPT_PRINTIMM " hello "
    RET                                           ;
GDT_setupKernelGDT ENDP                           ;
include helpers.s                                 ;
                                                  ;

    MSG_text DB "hello", 0
    ALIGN DWORD                                   ;
    GDT_ptrBuffer:                                ;
        DF ?                                      ;
    GDT_buffer:                                   ;
        GDT_nullentry GDT_entry <0,0,0,0,0,0>
        GDT_flatCode GDT_entry <0FFFFH, 0, 0, 010011010B,011001111B,0>
        GDT_flatData GDT_entry <0FFFFH, 0, 0, 010010010B,011001111B,0>
        GDT_kernelCode GDT_entry <0FFFFH, 051H SHL 4, 0, 010011010B,011001111B,0>
        GDT_kernelData GDT_entry <0FFFFH, 051H SHL 4, 0, 010010010B,011001111B,0>
    GDT_gdtSize EQU $ - GDT_buffer                ;
                                                  ;
