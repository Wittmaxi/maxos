.8086                                   ;
                                        ;
LOADER SEGMENT USE16                    ;
    ORG 0                               ;
    ASSUME CS:LOADER                    ;
    ASSUME DS:LOADER                    ; Disable prefixing
;---------------------------------------;
; Variable index-table                  ;
;---------------------------------------;
    BOOT_DRIVE EQU relocate             ;
    CURTOP EQU BOOT_DRIVE + 2           ;
;---------------------------------------;
; skip BPB section                      ;
;---------------------------------------;
skip_bpb PROC NEAR                      ;
    CLD                                 ; Clear direction flag - all string operations will go forwards
    DB 0EBH                             ; JMP near
    DB offset_value                     ;
    ;- calculate how many bytes to skip ;
skip_start:                             ;
    offset_value EQU relocate - skip_start
skip_bpb ENDP                           ;
;---------------------------------------;
; BPB                                   ;
;---------------------------------------;
BPB_oem         DB 8 DUP (?)            ;
BPB_bytPerSec   DW ?                    ;
BPB_secPerClus  DB ?                    ;
BPB_resSec      DW ?                    ;
BPB_numberFAT   DB ?                    ;
BPB_rootEntr    DW ?                    ;
BPB_totalSec    DW ?                    ;
BPB_mediaDesc   DB ?                    ;
BPB_secPerFAT   DW ?                    ;
BPB_secPerTrack DW ?                    ;
BPB_headCount   DW ?                    ;
BPB_hiddenSec   DD ?                    ;
BPB_largeSecs   DD ?                    ;
;---------------------------------------;
; Extended BPB                          ;
;---------------------------------------;
BPB_DriveNum       DB ?                 ;
BPB_winNTFlags     DB ?                 ;
BPB_sig            DB ?                 ;
BPB_volId          DD ?                 ;
BPB_label          DB 11 DUP (?)        ;
BPB_sysIdentString DB 8 DUP (?)         ;
                                        ;
;---------------------------------------;
; Relocate                              ;
;---------------------------------------;
; relocate the boot-code                ;
;---------------------------------------;
; DL - boot drive                       ;
;---------------------------------------;
relocate PROC NEAR                      ;
    ;- set CS to 0                      ;
    DB 0EAH                             ; OPCODE far jump
    DW OFFSET resume                    ;
    DW 07C0H                            ; We were loaded into this segment
resume:                                 ;
    ;- Set DS                           ;
    PUSH cs                             ;
    POP ds                              ;
    ;- set DI and SI to zero            ;
    XOR di, di                          ;
    XOR si, si                          ; DS:SI = current code
    ;- find topmost segment (where to relocate to);
    INT 12H                             ; AX = Amount of 1K memory bocks
    MOV cl, 06H                         ;
    SHL ax, cl                          ; AX = topmost segment
    ;- calculate new location           ;
    loader_size EQU 020H                ; the loader is 200h byte big - divide by 10h for segment-representation
    stack_size EQU 020H                 ;
    boundary_offset EQU 01H             ; align to the boundaries
    location_subtract EQU loader_size + stack_size + boundary_offset
    ;- find new location segment        ;
    SUB ax, location_subtract           ; Calculate where to move the new bootloader
    MOV es, ax                          ;
    XOR di, di                          ; ES:DI = location for new kernel
    ;- copy bootcode                    ;
    MOV cx, 100H                        ; how much code to copy / 2 (we are moving words)
    CLI                                 ; FIX 8086/8088 Bug!!
    REP MOVSW                           ; Code is copied over!
    ;- Jump to the new code             ;
    PUSH es                             ; Push the new segment
    MOV ax, OFFSET setup                ; Calculate the offset for the new function
    PUSH ax                             ;
    RETF                                ; We manipulated the stack so that "RETF" jumps to where we want to
    ; Done relocating                   ;
relocate ENDP                           ;
;---------------------------------------;
; setup                                 ;
;---------------------------------------;
; DL - boot drive                       ;
;---------------------------------------;
setup PROC NEAR                         ;
    ;- we are here! small notif - TODO REMOVE        ;
    MOV al, 'A'                         ;
    MOV ah, 0EH                         ;
    XOR bx, bx                          ;
    INT 10h                             ;
    ;- setup stack                      ;
    PUSH cs                             ;
    POP ss                              ; SS = CS
    MOV sp, 0A00H                       ; SP = 2,5kb above code
    ;- enable interrupts back           ;
    STI                                 ;
    ;- preserve Data                    ;
    MOV [BOOT_DRIVE], dl                ;
    MOV [CURTOP], cs                    ;
    ;- Calculate FAT                    ;
    MOV AX, [BPB_secPerFAT]             ;
    DIX [BPB_bytPerSec]                 ; AX = size of FAT
    MOV cx, ax                          ; !! CX = size of FAT
    XOR ax, ax                          ;
    ADD ax, PTR WORD [BPB_resSec]       ; AX = fat sector
    MOV 
    ;- 

    
    
    ;
@@h:                                    ;
    HLT                                 ;
    JMP @@h                             ;
setup ENDP                              ;
                                        ;
;---------------------------------------;
; readSectors                           ;
;---------------------------------------;
; AX:DX = start sector                  ;
; ES:BX = position in ram               ;
; CX = amount of sectors                ;
;---------------------------------------;
; ES:BX - Buffer filled with content of ;
;       - Disc                          ;
;---------------------------------------;
readSectors PROC                        ;
    PUSH CX                             ; will roll over into the next function
readSectors ENDP                        ;
;---------------------------------------;
; readSector                            ;
;---------------------------------------;
; DX:AX = start sector                  ;
; ES:BX = position in Ram               ;
;---------------------------------------;
; ES:BX = filled with sector from disc  ;
;---------------------------------------;
readSector PROC                         ;
    ;- setup retry counter              ;
    MOV di, 0005h                       ;
    ;- preserve start sector            ;
RETRY:                                  ;
    PUSH DX                             ;
    PUSH AX                             ;
    ;- calculate CHS                    ; AX = LBA sector
    ; temp = LBA / sec per track        ;
    ; Sector = (LBA % sec per track) + 1; -> CL
    ; Head = temp % number of heads     ; -> DH
    ; Cyl = temp / number of heads      ; -> CH
    DIV WORD PTR CS:[BPB_secPerTrack]   ; AX = TEMP ; DX = SECTOR - 1
    MOV cx, dx                          ;
    INC cx                              ; !! CX = CL = CHS sector
    XOR dx, dx                          ; DX = 0
    DIV WORD PTR CS:[BPB_headCount]     ; AX = CYL ; DX = Head
    MOV dh, dl                          ; !! DH = Head
    MOV ch, al                          ; !! CH = cyl
    ;- Read the sector                  ;
    MOV dl, cs:[BOOT_DRIVE]             ; DL = drive number
    MOV ax, 0201                        ; AL = 1 ; AH = 2
    INT 13h                             ;
    ;- restore absolute sector          ;
    POP ax                              ;
    POP dx                              ;
    ;- exit if no error                 ;
    JNC readDone                        ;
    ;- reset drive                      ;
    PUSH ax                             ;
    XOR ax, ax                          ;
    INT 13H                             ;
    POP ax                              ;
    ;- retry loading sector             ;
    DEC di                              ;
    JNZ retry                           ;
    ;- tried too often - display error  ;
    MOV si, OFFSET MSG_DISK             ;
readSector ENDP                         ;
;---------------------------------------;
; display                               ;
;---------------------------------------;
; DS:SI = message                       ;
;---------------------------------------;
display PROC                            ;
    ;- loop for each byte and display   ;
@@loop:                                 ;
    LODSB                               ;
    MOV ah, 0eh                         ;
    XOR bx, bx                          ;
    INT 10h                             ;
    OR al, al                           ; Is the string over? (is current byte NULL)
    JNZ @@loop                          ; If not, loop
display ENDP                            ;
;---------------------------------------;
; reboot                                ;
;---------------------------------------;
;---------------------------------------;
reboot PROC                             ;
    ;- await keypres
    XOR ax, ax                          ;
    INT 16h                             ;
    ;- re enter bios Boot selection service
    INT 19h                             ;
    ; kernel is now out                 ;
reboot ENDP                             ;
;---------------------------------------;
; readDone                              ;
;---------------------------------------;
; readSector will jump here after a read
; we will loop through the number of sectors if needed
;---------------------------------------;
readDone PROC                           ;
    ;- recover sector size              ;
    POP cx                              ;
    ;- calculate next location          ;
    INC ax                              ;
    ADC dx, 0                           ; DX:AX -> next sector
    ADD bx, cs:[BPB_bytPerSec]          ;
    ;- loop loading sectors             ;
    LOOP readSectors                    ; Loop automatically checks if CX is zero
    ;- return to caller of readSector   ;
    RET                                 ;
readDone ENDP                           ;
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
    MSG_DISK DB "DISK IO FAILURE", 0    ;
;---------------------------------------;
    ORG 510                             ; Flag must be at position 510
    DW 0xAA55                           ; Bootsector flag
                                        ;
LOADER ENDS                             ;
END                                     ;
