.8086                                   ;
                                        ;
;=======================================;
; VARIABLES                             ;
;=======================================;
    DRIVE EQU relocate                  ; BYTE
    CURTOP EQU DRIVE + 1                ;
    SEGFAT EQU CURTOP + 2               ;
                                        ;
LOADER SEGMENT USE16                    ;
    ORG 0                               ;
    ASSUME CS:LOADER                    ;
    ASSUME DS:LOADER                    ;
;=======================================;
; BPB                                   ;
;=======================================;
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
BPB_driveNum       DB ?                 ;
BPB_winNTFlags     DB ?                 ;
BPB_sig            DB ?                 ;
BPB_volId          DD ?                 ;
BPB_label          DB 11 DUP (?)        ;
BPB_sysIdentString DB 8 DUP (?)         ;
                                        ;
;=======================================;
; Execution starts                      ;
;=======================================;
relocate PROC                           ;
    ;- set CS to 0                      ;
    DB 0EAH                             ; Opcode Farjmp
    DW OFFSET resume                    ;
    DW 07C0H                            ;
                                        ;
resume:                                 ;
    ;- setup DS                         ;
    PUSH cs                             ;
    POP ds                              ; DS = 0
                                        ;
    ;- DI and SI = 0                    ;
    XOR di, di                          ;
    XOR si, si                          ;
                                        ;
    ;- find top seg                     ;
    INT 12H                             ; AX = memory size in 1k blocks
    MOV cl, 06H                         ;
    SHL ax, cl                          ; AX = topmost segment
                                        ;
    ; calculate new memory position     ;
    loader_size EQU 020H                ; the loader is 200h byte big - divide by 10h for segment-representation
    stack_size EQU 020H                 ;
    boundary_offset EQU 01H             ; align to the boundaries
    location_subtract EQU loader_size + stack_size + boundary_offset
                                        ;
    ;- calculate new loc segment        ;
    SUB ax, location_subtract           ; AX = where to put the new loc
    MOV es, ax                          ;
                                        ;
    ;- copy the bytes                   ;
    MOV ch, 1                           ; CX = 256 - we are moving words so, half the size of BL
    CLD                                 ; Fix 8086/8088 bug
    REP MOVSW                           ;
                                        ;
    ;- JUMP                             ;
    ; manipulate the stack in order for RETF
    ; to return to the newly relocated code
    ; some badly implemented anti-virus programs might
    ; detect us for this
    PUSH es                             ;
    MOV ax, OFFSET setup                ;
    PUSH ax                             ;
    RETF                                ;
    ;- done                             ;
                                        ;
setup:                                  ;
    ;- setup DS                         ;
    PUSH cs                             ;
    POP ds                              ;
                                        ;
    ;- setup stack                      ;
    PUSH cs                             ;
    POP ss                              ;
    MOV sp, 400H                        ; SP points to the TOP of the stack!!
                                        ;
    ;- setup                            ;
    STI                                 ; re-enable interrupts
    MOV BYTE PTR [DRIVE], dl            ;
    MOV WORD PTR [CURTOP], cs           ;
                                        ;
    ;- calculate FAT                    ;
    MOV ax, WORD PTR [BPB_secPerFat]    ;
    MUL WORD PTR [BPB_bytPerSec]        ;
    CALL allocate                       ; ES:BX -> where to write the FAT
    MOV WORD PTR [SEGFAT], es           ;
    MOV ax, WORD PTR [BPB_resSec]       ;
    ADD ax, WORD PTR [BPB_hiddenSec]    ; should probably be double? not sure what to do here, but hiddenSecs are not super common anyway
                                        ; AX = start of FAT in disk
    PUSH ax                             ; preserve, will be relevant later
    CALL readSectors                    ;



    MOV es, WORD PTR [SEGFAT]
    PUSH es
    POP ds
    MOV si, 0
    MOV cx, 100
    MOV ah, 0EH                         
@@LOOP:
    LODSB
    INT 10H
    LOOP @@LOOP

@@JMP:
    JMP @@JMP
relocate ENDP                           ;

;---------------------------------------;
; ALLOCATE                              ;
;---------------------------------------;
; AX - size in Bytes                    ;
;---------------------------------------;
; ES:BX - new section                   ;
; CX - size in chunks of 512b           ;
;---------------------------------------;
allocate PROC                           ;
    ;- preserve size                    ;
    PUSH ax                             ;
    ;- convert to sectors               ;
    MOV cl, 04H                         ;
    SHR ax, cl                          ;
    ;- clear DX                         ;
    CWD                                 ; saves us one byte, since we know that AX is positive
    ;- calculate new start              ;
    INC ax                              ; the conversion to sector was a floored division, add one segment as buffer
    MOV bx, WORD PTR [CURTOP]           ;
    SUB bx, ax                          ;
    ;- setup location                   ;
    MOV es, bx                          ;
    XOR bx, bx                          ;
    ;- save new top                     ;
    MOV WORD PTR [CURTOP], es           ;
    ;- calculate sector count (for readSectors)
    POP ax                              ;
    DIV WORD PTR [BPB_bytPerSec]        ;
    MOV cx, ax                          ;
    ;-                                  ;
    RET                                 ;
allocate ENDP                           ;
                                        ;
;---------------------------------------;
; Read sectors                          ;
;---------------------------------------;
; DX:AX - absolute start sector         ;
; CX - amount of sectors to read        ;
; ES:BX - destination buffer            ; needs to be free!
;---------------------------------------;
readSectors PROC                        ;
    PUSH cx                             ;
readSectors ENDP                        ;
readSector PROC                         ;
    ;- setup retry-counter              ;
    MOV di, 0005H                       ;
                                        ;
@@retry:                                ;
    ;- preserve start sector            ;
    PUSH dx                             ;
    PUSH ax                             ;
                                        ;
    ;- calculate CHS                    ;
    ; temp = LBA / sec per track        ;
    ; Sector = (LBA % sec per track) + 1; -> CL
    ; Head = temp % number of heads     ; -> DH
    ; Cyl = temp / number of heads      ; -> CH
    CWD                                 ; DX = 0
    DIV WORD PTR [BPB_secPerTrack]      ;
    MOV cx, dx                          ;
    INC cx                              ; CL = sector
    CWD                                 ; DX = 0
    DIV WORD PTR [BPB_headCount]        ; AX = CYLINDER - DX = HEAD
    MOV dh, dl                          ; DH = head
    MOV ch, al                          ; CH = cylinder
                                        ;
    ;-- ??                              ;
    PUSH cx                             ;
    MOV cl, 06H                         ;
    SHL al, cl                          ;
    POP cx                              ;
    OR cl, al                           ;
                                        ;
    ;- read actual drive                ;
    MOV dl, BYTE PTR [DRIVE]            ;
    MOV ax, 0201H                       ;
    STC                                 ; Fix bios bug whre int13 would not always properly reset CF
    INT 13H                             ;
                                        ;
    ;- restore absolute sector          ;
    POP ax                              ;
    POP dx                              ;
                                        ;
    ;- if no error, consider read done! ;
    JNC readDone                        ;
                                        ;
    ;- reset drive                      ;
    PUSH ax                             ;
    XOR ax, ax                          ;
    INT 13H                             ;
    POP ax                              ;
                                        ;
    ;- count retries                    ;
    DEC di                              ;
    JNZ @@retry                         ;
                                        ;
    ;- no more retries, show error message
    MOV si, OFFSET DISK_MSG             ;
                                        ;
readSector ENDP                         ;
                                        ;
;---------------------------------------;
; DisplayError                          ;
;---------------------------------------;
; displays a *null-terminated* string   ;
; WILL ALWAYS REBOOT ON DISPLAY         ;
;---------------------------------------;
; DS:SI - message                       ;
;---------------------------------------;
displayError PROC                       ;
    ;- setup                            ;
    XOR bx, bx                          ;
    MOV ah, 0EH                         ;
                                        ;
    ;- printloop                        ;
@@LOOP:                                 ;
    LODSB                               ;
    INT 10H                             ;
    OR al, al                           ;
    JNZ @@LOOP                          ;
displayError ENDP                       ;
                                        ;
;---------------------------------------;
; Reboot                                ;
;---------------------------------------;
; waits for keypress and givs back control
; to BIOS-bootmanager                   ;
;---------------------------------------;
reboot PROC                             ;
    ;- wait for keypress                ;
    XOR ax, ax                          ;
    INT 16H                             ;
                                        ;
    ;- give back control                ;
    INT 19H                             ;
reboot ENDP                             ;
                                        ;
;---------------------------------------;
; readDone                              ;
;---------------------------------------;
; readSector jumps here after a single  ;
; sector is read. This pops CX (sector count)
; and reads the next sector             ;
;---------------------------------------;
readDone PROC                           ;
    ;- pop sector count                 ;
    POP cx                              ;
                                        ;
    ;- new sector pointers              ;
    INC ax                              ;
    ADC dx, 0                           ;
    ADD bx, CS:[BPB_bytPerSec]          ;
                                        ;
    ;- loop loading sectors             ;
    LOOP readSectors                    ;
                                        ;
    ;- exit if enough is read           ;
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
    MOV ax, ' '
    CALL debugMSG
    ;MOV ax, 0AH 
    ;CALL debugMSG
    ;MOV ax, 0DH
    ;CALL debugMSG
    POP ax
    RET
printNL ENDP
    ;- print string                     ;
    DISK_MSG DB "DISK IO ERROR", 0      ;
    ;- mark as bootable                 ;
    ORG 510                             ; Flag must be at position 510
    DB 055H                             ;
    DB 0AAH                             ;
                                        ;
LOADER ENDS                             ;
END                                     ;
