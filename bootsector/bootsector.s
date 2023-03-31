.8086                                   ;
                                        ;
;=======================================;
; VARIABLES                             ;
;=======================================;
    DRIVE EQU relocate                  ; BYTE
    CURTOP EQU DRIVE + 1                ; WORD
    SEGFAT EQU CURTOP + 2               ; WORD
    SEGROT EQU SEGFAT + 2               ; WORD
                                        ;
;- parameters                           ;
    KERNEL_NAME EQU "KERNEL  BIN"       ;
    KERNEL_LOAD_SEG EQU 0051H           ;
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
    CLD                                 ; Clear direction flag - all string operations will go forwards - "vanilla" FAT specs want a NOP here
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
    ;- get disk geometry                ; we can't rely on the BPB
    MOV ah, 08                          ;
    INT 13H                             ; only available on XT and newer. If not supported,
                                        ; we have to assume that the BPB gives us
                                        ; correct data on the disk geometry
    OR ah, ah                           ;
    JNZ @@assumeBPBCorrect              ; the syscall to get geometry is not supported
    MOV BYTE PTR [BPB_secPerTrack], cl  ;
    INC dh                              ; headcount - zero based, we need one based
    MOV BYTE PTR [BPB_headCount], dh    ;
@@assumeBPBCorrect:                     ;
                                        ;
    ;- FAT                              ;
    ;-- calculate FAT                   ;
    MOV ax, WORD PTR [BPB_secPerFat]    ;
    MUL WORD PTR [BPB_bytPerSec]        ;
    CALL allocate                       ; ES:BX -> where to write the FAT
    MOV WORD PTR [SEGFAT], es           ;
    MOV ax, WORD PTR [BPB_resSec]       ;
    ADD ax, WORD PTR [BPB_hiddenSec]    ; should probably be double? not sure what to do here, but hiddenSecs are not super common anyway
                                        ; AX = start of FAT in disk
    PUSH ax                             ; preserve, will be relevant later
                                        ;
    ;-- load FAT                        ;
    CALL readSectors                    ;
                                        ;
    ;- Root                             ;
    ;-- calculate ROOT start            ;
    MOV bp, sp                          ;
    MOV ax, WORD PTR [BPB_secPerFAT]    ;
    MUL BYTE PTR [BPB_numberFAT]        ;
    ADD ax, [BPB_resSec]                ;
    DEC ax                              ;
    ADD [bp], ax                        ; [BP] = start of root
                                        ;
    ;-- calculate ROOT size             ;
    MOV ax, 0020H                       ; size of one root entry
    MUL WORD PTR [BPB_rootEntr]         ; ax = size of root seg
    PUSH ax                             ;
                                        ;
    ;-- allocate                        ;
    CALL allocate                       ; ES = sector of ROOT
                                        ;
    ;-- load the ROOT                   ;
    CWD                                 ;
    MOV ax, [BP]                        ;
    CALL readSectors                    ;
                                        ;
    ;-- calculate start of data         ;
    POP ax                              ;
    DIV [BPB_bytPerSec]                 ;
    ADD [bp], ax                        ;
relocate ENDP                           ;
;---------------------------------------;
; Find kernel                           ;
;---------------------------------------;
; ES = segment to ROOT                  ;
;---------------------------------------;
findKernel PROC                         ;
    XOR di, di                          ; di -> root entries
    MOV cx, [BPB_rootEntr]              ; how many entries we need to look through (max)
@@entry:                                ;
    PUSH di                             ;
    PUSH cx                             ;
    MOV cx, 0BH                         ; compare 11 bytes = 8 name + 3 ext
    MOV si, OFFSET KERNEL               ; the filename
                                        ;
    ;- comparison                       ;
    CLI                                 ; fix 8086/8088 bug
    REPZ CMPSB                          ; compare filenames
    STI                                 ;
                                        ;
    ;- prepare next loop                ;
    POP cx                              ; restore counter
    POP di                              ; restore entry
    JZ loadKernel                       ;
    ADD DI, 0020H                       ; next entry - one entry is 32byte long - one entry is 32byte long
    LOOP @@entry                        ; Loop through ROOT
                                        ;
    ;- no success                       ;
    MOV si, OFFSET NOKERN_MSG           ; Handle error: Kernel not found!
    JMP displayError                    ;
findKernel ENDP                         ;
                                        ;
;---------------------------------------;
; load kernel                           ;
;---------------------------------------;
; ES:DI - root entry of kernel          ;
;---------------------------------------;
loadKernel PROC                         ;
    ;- find kernel start cluster        ;
    MOV si, ES:[di + 1AH]               ; SI = FAT cluster
                                        ;
    ;- setup for kernel loading         ;
    MOV ds, WORD PTR [SEGFAT]           ; DS = FAT segment
    MOV ax, KERNEL_LOAD_SEG             ;
    MOV es, ax                          ;
    XOR bx, bx                          ; ES:BX = kernel:0
                                        ;
loadKernel ENDP                         ;
                                        ;
;---------------------------------------;
; load from FAT12                       ;
;---------------------------------------;
; ES - destination segment              ;
; BX - destination offset               ;
; DS - FAT segment                      ;
; SI - FAT cluster                      ;
;---------------------------------------;
loadFromFAT PROC                        ;
    XOR dx, dx                          ;
    ;- convert cluster to LBA           ;
    MOV ax, si                          ; AX = cluster ID
    DEC ax                              ;
    DEC ax                              ; zero based!
    XOR cx, cx                          ;
    MOV cl, cs:[BPB_secPerClus]         ; CL = sector count
    MUL cx                              ; AX = start cluster
    ADD ax, SS:[bp]                     ; AX += data start (first cluster is behind root)
                                        ;
    ;- load                             ;
    CALL readSectors                    ;
                                        ;
    ;- find next cluster                ;
    MOV ax, si                          ;
    MOV dx, si                          ;
    SHR dx, 1                           ;
    ADD si, dx                          ; SI *= 1.5
    MOV si, DS:[si]                     ; SI = next cluster
    TEST al, 1                          ; are we in an even cluster?
    JE @@odd                            ;
@@even:                                 ; xxxx xxxx | xxxx ----
    MOV cl, 04H                         ;
    SHR si, cl                          ;
@@odd:                                  ; ---- xxxx | xxxx xxxx
    AND si, 0FFFH                       ; remove the first four bits
                                        ;
    ;- check for file End               ;
    CMP si, 0FF0H                       ;
    JLE loadFromFat                     ;
                                        ;
    ;- setup kernel environment         ;
    MOV ax, KERNEL_LOAD_SEG             ;
    PUSH ax                             ;
    POP ds                              ; DS = (new) cs
                                        ;
    ;- pass control to kernel           ;
    DB 0EAH                             ;
    DW 0                                ;
    DW KERNEL_LOAD_SEG                  ;
    ;- we are done!                     ;
loadFromFAT ENDP                        ;
                                        ;
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
    CWD                                 ; saves us one byte, since we know that AX is positive, replaces xor ax, ax
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
    DIV WORD PTR CS:[BPB_secPerTrack]   ;
    MOV cx, dx                          ;
    INC cx                              ; CL = sector
    CWD                                 ; DX = 0
    DIV WORD PTR CS:[BPB_headCount]     ; AX = CYLINDER - DX = HEAD
    MOV dh, dl                          ; DH = head
    MOV ch, al                          ; CH = cylinder
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
                                        ;
    ;- print string                     ;
    DISK_MSG DB "DISK I/O ERROR", 0     ;
    NOKERN_MSG DB "KERNEL NOT FOUND", 0 ;
    KERNEL DB KERNEL_NAME               ; The kernel filename will be mapped like this in memory
                                        ;
    ;- mark as bootable                 ;
    ORG 510                             ; Flag must be at position 510
    DB 055H                             ;
    DB 0AAH                             ;
LOADER ENDS                             ;
END                                     ;
