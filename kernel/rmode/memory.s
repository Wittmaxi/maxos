;---------------------------------------;
; Copyright 2023 Maximilian Wittmer     ;
;---------------------------------------;
; tools for memory management inside of ;
; the real mode. Uses a very naive system
; of arenas and linked lists            ;
; Memory management is setup as a simple linked list.
; flat memory model, assumes that CS is at the base of the kernel
;-( Synopsis )--------------------------; NAMESPACE RMEM
; RMEM_setup                            ; sets up system
;---------------------------------------;
.8086                                   ;
                                        ;
;---------------------------------------;
; MEM_ENTRY                             ;
;---------------------------------------;
; set this up as a linked list          ;
;---------------------------------------;
RMEM_ENTRY STRUCT                       ;
    sz DW ?                             ;
    mayUse DB ?                         ; for bad clusters
    inUse DB ?                          ;
    nextEntry DW ?                      ; especially relevant since we might want to skip a few bytes
RMEM_ENTRY ENDS                         ; aligned to word
                                        ;
;---------------------------------------;
; RMEM_setup                            ;
;---------------------------------------;
; set us up, populate references, emplace 
; markers in right positions            ;
;---------------------------------------;
; CAUTION: invalidates registers!       ;
; # ax                                  ;
; # bx                                  ;
;-( TODOS )-----------------------------;
; o we don't map the lower memory parts ;
;                                       ;
; o we are never mapping the EBDA       ;
;                                       ;
; o are there any higher-up areas to    ;
;   take care of?                       ;
;---------------------------------------;
RMEM_setup PROC                         ;
    ;- get total memory size            ;
    INT 12H                             ;
    MOV WORD PTR [RMEM_totalMemSize], ax;
                                        ;
    ;- create first entry               ;
    ASSUME ax: PTR MEM_ENTRY            ; we will use ax as pointer to our memory entries
    RMEM_FIRST_ENTRY EQU 0 + PARAM_KERNEL_SIZE + 1; emplace after kernel
                                        ;
    ;-- find first entry position       ;
    MOV ax, RMEM_FIRST_ENTRY            ;
                                        ;
    ;-- check alignment                 ;
    MOV bx, ax                          ;
    AND bx, 1                           ;
    JZ @@noAlignFirstEntry              ;
    INC ax                              ;
@@noAlignFirstEntry:                    ; make sure AX is even!
                                        ;
    ;-- populate first entry            ;
    MOV WORD PTR [ax].RMEM_ENTRY.sz, -1 ; no size yet, nothing allocated!
    MOV BYTE PTR [ax].RMEM_ENTRY.mayUse, 1; we already have skipped the EBDA
    MOV BYTE PTR [ax].RMEM_ENTRY.inUse, 0; cluster is free!
    MOV WORD PTR [ax].RMEM_ENTRY.nextEntry, 0; TODO should I map the stack that was created by bootloader?
                                        ;
    ;- set variables                    ;
    MOV WORD PTR [RMEM_firstEntry], ax  ;
                                        ;
    ;- done                             ;
    RET                                 ;
RMEM_setup ENDP                         ;
                                        ;
;---------------------------------------;
; RMEM_alloc                            ;
;---------------------------------------;
; allocates contiguous memory           ;
;-( input )-----------------------------;
; ax = size to allocate in bytes        ;
;-( output )----------------------------;
; ax = pointer to newly allocated memory;
;---------------------------------------;
RMEM_alloc PROC                         ;
    PUSH bx                             ;
    PUSH cx                             ;
    PUSH dx                             ;
                                        ;
    ;-                                  ;
    ADD ax, SIZEOF RMEM_ENTRY           ; we need to allocat a few more bytes for our mem marker
                                        ;
    ;- initialize mem entry pointer     ;
    ASSUME cx: PTR RMEM_ENTRY           ;
    MOV cx, WORD PTR [RMEM_firstEntry]  ;
                                        ;
    ;- search next free entry that is big enough
@@searchMemEntry:                       ;
    ;-- is the current entry in use?    ;
    MOV dl, BYTE PTR [cx].RMEM_ENTRY.inUse;
    OR dl, dl                           ;
    JNZ @@nextMemEntry                  ; memory entry already given, look for next
    ;-- memory is free - is it big enough?
    MOV dx, WORD PTR [cx].RMEM_ENTRY.sz ;
    CMP dx, -1                          ; -1 for "this block has no given size!". If enough RAM is available, we can allocate here!
    JE @@allocateHere                   ;
    CMP dx, ax                          ;
    JGE @@allocateHere                  ;
@@nextMemEntry:                         ;
    ;- load next memory marker          ;
    MOV cx, WORD PTR [cx].RMEM_ENTRY.nextEntry
    OR cx, cx                           ; is memory marker unset? if so, panic!
    JNZ @@searchMemEntry                ;
    ;CALL realmodeKernelPanic            ; TODO IMPLEMENT AND CALL!
@@allocateHere:                         ; CX is a good entry, we can allocate here
                                        ;
    ;- do we need to emplace a new marker?
    MOV dx, WORD PTR [cx].RMEM_ENTRY.nextEntry
    OR dx, dx                           ;
    JNZ @@returnAddress                 ;

@@returnAddress:                        ; everything is prepared, we can return the address of the memory!
    MOV ax, cx                          ;
    ADD ax, SIZEOF RMEM_ENTRY           ; first free byte AFTER memory marker
                                        ;
    POP dx                              ;
    POP cx                              ;
    POP bx                              ;
RMEM_alloc ENDP                         ;
                                        ;
    ;- variables                        ;
    RMEM_totalMemSize DW ?              ;
    RMEM_firstEntry DW ?                ;
