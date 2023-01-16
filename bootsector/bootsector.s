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
    CURTOP EQU BOOT_DRIVE + 1           ;
    FATTOP EQU CURTOP + 2               ;
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
    ;- setup stack                      ;
    PUSH cs                             ;
    POP ss                              ; SS = CS
    MOV sp, 0400H                       ; stack lives above the code 
    ;- enable interrupts back           ;
    STI                                 ;
    ;- preserve Data                    ;
    MOV al, 'a'
    CALL debugMSG
    MOV BYTE PTR [BOOT_DRIVE], dl       ; What's the boot drive? - important when we read sectors
    MOV WORD PTR [CURTOP], cs           ; What's the highest address that won't overwrite kernel?
    MOV cx, WORD PTR [CURTOP]
    CALL printNum
    ;- FAT                              ;
    ;-- read the FAT                    ;
    ;--- where to?                      ;
    MOV al, 'a'
    CALL debugMSG
    MOV ax, WORD PTR [BPB_secPerFAT]    ;
    MUL BYTE PTR [BPB_numberFAT]        ; AX = size of FATS
    CALL calcStart                      ; ES:BX = where to put FAT
                                        ; CX = amount of sectors to read
    CALL printNum
    MOV WORD PTR [FATTOP], es           ; Preserve FAT-TOP
    ;--- read from disc                 ;
    CALL readSectors                    ;
@@a:
    HLT
    JMP @@a
    ;--- display content of FAT         
    PUSH es                             
    POP ds                              
    MOV si, 0                           
    CALL display                        
    CALL debugMSG
    ;- root                             ;
    ;-- calculate locations             ;
    POP cx                              ; CX = size of FAT in secs
    POP ax                              ; AX = FAT start sector
    XCHG ax, cx                         ;
    MUL WORD PTR [BPB_numberFAT]        ;
    ADD ax, cx                          ;
    INC ax                              ; !! AX = sector on disk of ROOT
    ;-- read from DISC                  ;
    MOV cx, 1                           ; read one sector
    
    
    
    ;-                                  ;

    
    
    ;
@@h:                                    ;
    HLT                                 ;
    JMP @@h                             ;
setup ENDP                              ;
                                        ;
;---------------------------------------;
; calcStart                             ;
;---------------------------------------;
; Calculates the start of a new segment ;
;---------------------------------------;
; AX - required Size in segments        ;
;---------------------------------------;
; ES:BX = new area; ES:00               ;
; CX = FAT sectors to read              ;
;---------------------------------------;
calcStart PROC                          ;
    ;- preserve size                    ;
    PUSH ax                             ;
    ;- calculate new beginning          ;
    MOV bx, WORD PTR [CURTOP]           ; BX = current top
    SUB bx, ax                          ; BX = new segment start
    ;- save new top position            ;
    MOV WORD PTR [CURTOP], bx           ;
    ;- setup location pointer           ;
    MOV es, bx                          ; !! ES = location
    XOR bx, bx                          ; !! BX = 0
    ;- calculate location size in SEGS  ; used for the readSectors calls
    POP ax                              ;
    MOV cx, ax                          ; !! CX = size
    ;-                                  ;
    RET                                 ;
calcStart ENDP                          ;
                                        ;
;---------------------------------------;
; readSectors                           ;
;---------------------------------------;
; AX = start sector - LBA               ;
; ES:BX = position in ram               ;
; CX = amount of sectors                ;
;---------------------------------------;
; ES:BX - Buffer filled with content of ;
;       - Disc                          ;
;---------------------------------------;
readSectors PROC                        ;
    PUSH cx                             ; will roll over into the next function
readSectors ENDP                        ;
;---------------------------------------;
; readSector                            ;
;---------------------------------------;
; AX = start sector - LBA               ;
; ES:BX = position in Ram               ;
;---------------------------------------;
; ES:BX = filled with sector from disc  ;
;---------------------------------------;
readSector PROC                         ;
    ;- setup retry counter              ;
    MOV di, 0005h                       ;
    ;- preserve start sector            ;
RETRY:                                  ;
    PUSH AX                             ;
    ;- calculate CHS                    ; AX = LBA sector ; DX => Discarded
    ; temp = LBA / sec per track        ;
    ; Sector = (LBA % sec per track) + 1; -> CL
    ; Head = temp % number of heads     ; -> DH
    ; Cyl = temp / number of heads      ; -> CH
    DIV WORD PTR CS:[BPB_secPerTrack]   ; AX = TEMP ; DX = SECTOR - 1
    MOV cx, dx                          ;
    INC cx                              ; !! CX = CL = CHS sector
    DIV WORD PTR CS:[BPB_headCount]     ; AX = CYL ; DX = Head
    MOV dh, dl                          ; !! DH = Head
    MOV ch, al                          ; !! CH = cyl
    ;- Read the sector                  ;
    MOV dl, BYTE PTR cs:[BOOT_DRIVE]    ; DL = drive number
    MOV ax, 0201H                       ; AL = 1 ; AH = 2
    STC                                 ; Some bioses have a bug not setting IF and CF correctly
    INT 13H                             ;
    ;- restore absolute sector          ;
    POP ax                              ;
    ;- exit if no error                 ;
    PUSH AX
    MOV ax, 'A'
    CALL debugMSG
    POP ax
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
; readSector will jump here after a read;
; we will loop through the number of sectors if needed
;---------------------------------------;
readDone PROC                           ;
    PUSH ax
    MOV ax, 'B'
    CALL debugMSG
    POP ax
    ;- recover sector size              ;
    POP cx                              ;
    DEC cx                              ;
    ;- calculate next location          ;
    INC ax                              ;
    ADD bx, cs:[BPB_bytPerSec]          ;
    ;- loop loading sectors             ;
    PUSH ax
    MOV ax, 'C'
    CALL debugMSG
    POP ax
    CALL printNL

    call printNum

    PUSH ax
    MOV ax, 'D'
    CALL debugMSG
    POP ax

    LOOP readSectors                    ; Loop automatically checks if CX is zero
    ;- return to caller of readSector   ;
    MOV al, "U"                          
    MOV ah, 0EH
    XOR bx, bx
    INT 10H
    RET                                 ;
readDone ENDP                           ;

; al = char
debugMSG PROC
    OR al, al
    JNZ @@doStuff
    MOV al, 'D'
@@doStuff:
    PUSH ax
    PUSH bx
    MOV ah, 0EH
    MOV bx, 0
    INT 10h
    POP bx
    POP ax
    RET
debugMSG ENDP

; cx = number
printNum PROC
    PUSH ax
    PUSH bx
    PUSH cx
    PUSH dx
    MOV ax, cx
    MOV cx, 0
@@loop:
    MOV bx, 010D                        ; BX = 10
    MOV dx, 0                           ; 
    DIV bx                              ; AX = next iterations number

    PUSH dx

    INC cx
    OR ax, ax
    JNZ @@loop

@@print:
    POP dx
    ADD dl, '0'
    MOV al, dl
    CALL debugMSG
    LOOP @@print

    CALL printNL
    POP dx
    POP cx
    POP bx
    POP ax
    RET
printNum ENDP

printNL PROC
    PUSH ax
    MOV ax, 0AH 
    CALL debugMSG
    MOV ax, 0DH
    CALL debugMSG
    POP ax
    RET
printNL ENDP
                                        ;
;---------------------------------------;
    msg DB "MaxOS - Booting", 10, 13, 0 ;
    MSG_DISK DB "DISK IO FAILURE", 0    ;
;---------------------------------------;
    ORG 510                             ; Flag must be at position 510
    DW 0xAA55                           ; Bootsector flag
                                        ;
LOADER ENDS                             ;
END                                     ;
