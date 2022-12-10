EXTERN putchar: PROC

;--------------------------------------------------
; CONSTANTS
;--------------------------------------------------
MAGIC EQU 1BADB002H          ; Magic number defined by standard
FLAGS EQU 3H                       ; 0000 0000 0000 0001 for "Align on 4KB boundaries" 
                                   ; 0000 0000 0000 0010 for "Please pass me the memory map"
CHECK EQU - (MAGIC + FLAGS ) ; 
;-------------------------------------------------;
; MULTIBOOT SEGMENT                               ;
; https://www.gnu.org/software/grub/manual/multiboot/multiboot.html
;-------------------------------------------------;
MULTIBOOT SEGMENT DWORD      ;
        align 4              ;
        ;--------------------;
        DD MAGIC             ;
        DD FLAGS               ;
        DD CHECK             ;
        ;--------------------;
MULTIBOOT ENDS               ;


BSS SEGMENT                  ;
        ;--------------------;
        align 16             ; Align to 16 to comply with System V ABI
        ;--------------------;
        STACK_TOP LABEL FAR  ;
        BYTE 16342 DUP (0)   ;
        stack_bottom LABEL FAR          ;
        ;--------------------;
BSS ENDS                     ;

TEXT SEGMENT                 ;

PUBLIC _start
_start PROC                  ;
        MOV rsp, OFFSET BSS:stack_bottom ; set the stack pointer to our newly created stack
        ;--------------------;
        ;                    ; This is a good place to (later) initialize CPU state before entering the kernel
        ;--------------------;
@@loop:                      ;
        CALL kernel_main     ; 
        jmp @@loop           ; Print infinitely, for now
        ;--------------------; 
        ; Put machine into infinite loop
        ;--------------------;
@@infoloop:                      ;
        CLI                  ;
        HLT                  ;
        JMP @@infoloop       ;
        ;--------------------;
_start ENDP                  ; 
;-------------------------------------------------;
; KERNEL_MAIN 
;-------------------------------------------------;
; print "hello world"
;-------------------------------------------------;     
kernel_main PROC             ;
        MOV al, 65
        CALL putchar
        MOV al, 66
        CALL putchar
        MOV al, 67
        CALL putchar
@@lop: 
        JMP @@lop
        ;--------------------;
@@printloop:                 ;
        MOV rsi, OFFSET hello_world; base pointer
        LODSB                ; loads single byte from SI into ax
        OR al, al            ; should we leave the loop? is \0 reached?
        JZ @@done            ;
        CALL putchar         ;
        JNZ short @@printloop;
        ;--------------------;
@@done:                      ;
        JMP @@done
kernel_main ENDP             ;
        hello_world BYTE "Hello World", 0;
        ;--------------------;
TEXT ENDS                    ;
END                          ;
;-------------------------------------------------;
