.8086                                   ;
                                        ;
LOADER SEGMENT USE16                    ;
    ORG 0                               ;
    ASSUME CS:LOADER                    ;
    ASSUME DS:LOADER                    ; Disable prefixing
;---------------------------------------;
; skip BPB section                      ;
;---------------------------------------;
skip_bpb PROC NEAR                      ;
    CLD                                 ; Forward direction - string OPs
    DB 0EBH                             ; JMP near
    DB offset_value                     ;
skip_start:                             ;
    offset_value EQU relocate - skip_start
skip_bpb ENDP                           ;
                                        ;
;---------------------------------------;
; BPB                                   ;
;---------------------------------------;
    DB "MAXWITT", 0                     ; OEM identifier
    DW 0200H                            ; Bytes per sector
    DB 01H                              ; sectors per cluster
    DW 0001H                            ; Reserved sectors
    DB 02H                              ; Number of FATs
    DW 00E0H                            ; Number of Root entries
    DW 0B40H                            ; Total sectosr in entire volume
    DB 0F0H                             ; Media descriptor
    DW 0009H                            ; Sectors per FAT
    DW 0012H                            ; Sectors per TRACK
    DW 0020                             ; headcount
    DW 0000H                            ; Hidden sectors
                                        ;
;---------------------------------------;
; Relocate                              ;
;---------------------------------------;
; relocate the boot-code                ;
;---------------------------------------;
; DL - boot drive                       ;
;---------------------------------------;
relocate PROC NEAR                      ;
    ; Set DS                            ;
    PUSH cs                             ;
    POP ds                              ;
    ; find topmost segment (where to relocate to);
    INT 12H                             ; AX = Amount of 1K memory bocks
    MOV cl, 06H                         ;
    SHL ax, cl                          ; AX = topmost segment
    ; calculate new location            ;
    loader_size EQU 020H                ; the loader is 200h byte big - divide by 10h for segment-representation
    stack_size EQU 020H                 ;
    boundary_offset EQU 01H             ; align to the boundaries
    location_subtract EQU loader_size + stack_size + boundary_offset
    ;                                   ;
    SUB ax, 041H                        ; Calculate where to move the new bootloader
    MOV es, ax                          ;
    XOR di, di                          ; ES:DI = location for new kernel
    ; find current location             ;
    CALL delta                          ; Call pushes the location onto the stack
delta:                                  ;
    POP si                              ;
;---8<-------CODE ABOVE THIS LINE DISCARDED ---8<-----------8<-----;
    SUB si, OFFSET delta                ; DS:SI = current code 
    ; copy bootcode                     ;
    MOV cx, 100H                        ; how much code to copy / 2 (we are moving words)
    CLI                                 ; FIX 8086/8088 Bug!!
    REP MOVSW                           ; Code is copied over!
    ; Jump to the new code              ;
    PUSH es                             ; Push the new segment
    MOV ax, OFFSET setup                ; Calculate the offset for the new function
    PUSH ax                             ;
    RETF                                ; We manipulated the stack so that "RETF" jumps to where we want to
relocate ENDP                           ;
                                        ;
;---------------------------------------;
; SETUP                                 ;
;---------------------------------------;
;---------------------------------------;
; DL - boot drive                       ;
;---------------------------------------;
setup PROC NEAR
    MOV al, 'A'
    MOV ah, 0EH
    XOR bx, bx
    INT 10h
@@h:
    HLT
    JMP @@h
setup ENDP
;---------------------------------------;

;---------------------------------------;
; write_banner                          ;
;---------------------------------------;
; writes the banner message             ;
;---------------------------------------;
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
;---------------------------------------;
; reads from the disc and               ;
; loads the kernel into 7E0H:0          ;
;---------------------------------------;
; DL - drive number                     ;
;---------------------------------------;
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
    JZ @@endload                        ; NO error, return from function
                                        ;
    JMP @@retry                         ; Floppy might fail, give motor time to spin up
    ; validate that everything went well;
@@endload:                              ;
    ; call loaded kernel                ;
    DB 0EAH                             ; FAR JUMP
    DW 0                                ; Byte 0
    DW 07E0H                            ; Segment 7E0H, where we previously loaded our kernel into
    ; control has been given over, our job is done
;---------------------------------------;
    msg DB "MaxOS - Booting", 10, 13, 0 ;
;---------------------------------------;
    ORG 510                             ; Flag must be at position 510
    DW 0xAA55                           ; Bootsector flag
                                        ;
LOADER ENDS                             ;
END                                     ;
