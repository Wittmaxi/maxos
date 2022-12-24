.486P                                   ;
.model flat                             ;
                                        ;
    ; these variables will replace the boot code after it has been executed
    var_mem_size EQU 0                  ; Address = 7C00 or 7C0:0
    var_drive_num EQU var_mem_size + 2  ; 
    ; GDT addresses                     ;
    var_gdt_start EQU 0500H             ; GDT starts at 0H:500H (Just above BDA)
    var_gdt_end EQU var_gdt_start + 8 * 20; Space for 20 entries of 8 bytes in 32b mode
    ; stack                             ;
    var_stack_start EQU var_gdt_end + 8 ;
    var_stack_end EQU 07BFFH            ;
                                        ;
LOADER SEGMENT USE16                    ;
    ORG 0                               ;
;---------------------------------------;
; boot_start                            ;
;---------------------------------------;
; Entry point for the loader            ;
;---------------------------------------;
; DL - drive number                     ;
;---------------------------------------;
boot_start PROC                         ;
    ; Skip to set CS                    ;
    DB 0EAh                             ; OPCODE far jump, reused to store the drive number
    DW OFFSET skip                      ; Where to skip to
    DW 07C0H                            ; Where the BIOS loads my code to: 7c00H / 10H
skip:                                   ;
    ; setup stack                       ;
    MOV sp, var_stack_end               ;
    ; Set DS                            ;
    PUSH cs                             ;
    POP ds                              ;  DS sp
    ; store drive number                ;
    MOV BYTE PTR [var_drive_num], dl    ;
    ; get memory size                   ;
    INT 12H                             ; Report memory size
    MOV WORD PTR [var_mem_size], ax     ;
    ;                                   ;
    CALL set_gdtr                       ;
    CALL write_banner                   ;
    CALL load_kernel                    ; loads the kernel to memory
    ; call loaded kernel                ;
    DB 0EAH                             ; FAR JUMP
    DW 0                                ; Byte 0
    DW 07E0H                            ; Segment 7E0H, where we previously loaded our kernel into
    ; control has been given over, our job is done
boot_start ENDP                         ;
                                        ;
;---------------------------------------;
; set_gdtr                              ;
;---------------------------------------;
; set the GDTR to the most permissive   ;
; option - everything can be RW         ;
;---------------------------------------;
set_gdtr PROC                           ;
    ; calculate the position of GDT     ;
    MOV ax, ds                          ;
    SHR ax, 4                           ; calculate linear address of GDT
    ADD ax, OFFSET gdt                  ;
    MOV WORD PTR [gdt], ax              ;
    ; load the gdt into gdtr            ;
    LGDT FWORD PTR [gdt]                ;
set_gdtr ENDP                           ;
                                        ;
;---------------------------------------;
; reads from the disc and               ;
; loads the kernel into 7E0H:0          ;
;---------------------------------------;
; DL - drive number                     ;
;---------------------------------------;
load_kernel PROC                        ;
    ; set output location               ;
    MOV ax, 07E0H                       ;
    MOV es, ax                          ; ES = 7E0H
    MOV bx, 0                           ; BX = 0
    ; set drive read params             ;
    MOV ah, 2                           ; AH =  2 - INT 13,2 - read sectors
    MOV al, 10                          ; AL = 128 - read 10 sectors
    MOV ch, 0                           ; track/cylinder number
    MOV cl, 2                           ; sector number
    MOV dh, 0                           ; head number
    ; syscall                           ;
@@retry:                                ;
    INT 13H                             ;
    ; check for errors                  ;
    OR ah, ah                           ;
    JZ @@end                            ; NO error, return from function
                                        ;
    JMP @@retry                         ; Floppy might fail, give motor time to spin up
    ; validate that everything went well;
@@end:                                  ;
    RET                                 ;
load_kernel ENDP                        ;
                                        ;
;---------------------------------------;
; write_banner                          ;
;---------------------------------------;
; writes the banner message             ;
;---------------------------------------;
write_banner PROC                       ;
    MOV si, OFFSET MSG                  ;
    MOV ah, 0EH                         ; AH = 0EH, - int 10 "write to terminal" 
    MOV bx, 0                           ; BX = 0 - No paging, no color info
@@printloop:                            ;
    LODSB                               ;
    OR al, al                           ;
    JZ @@end                            ;
    INT 10h                             ; Write to terminal
    JMP @@printloop                     ;
@@end:                                  ;
    RET                                 ;
write_banner ENDP                       ;
                                        ;
    INCLUDE gdt.s                       ; Definition of the GDT - takes up 8 * 2 + 6 Bytes
                                        ;
;---------------------------------------;
    msg DB "MaxOS - Booting", 10, 13, 0 ;
;---------------------------------------;
    ORG 510                             ; Flag must be at position 510
    DW 0xAA55                           ; Bootsector flag
                                        ;
LOADER ENDS                             ;
END                                     ;
