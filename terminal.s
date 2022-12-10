
TEXT SEGMENT                ;
        caret DWORD 923H                     ;
        ; Constants --------;
        rows EQU 25         ;
        cols EQU 80         ;
        ; Colors -----------;
        BLACK EQU 0         ;
        BLUE EQU 1          ;
        GREEN EQU 2         ;
        WHITE EQU 15        ;
        ;-------------------;
;--------------------------------------------------
; create_color_code
;--------------------------------------------------
; Creates the color byte
;- input ------------------------------------------
; al = foreground
; bl = background
;- output -----------------------------------------
; AH = color byte
;--------------------------------------------------
PUBLIC create_color_code     ;
create_color_code PROC FAR   ;
        PUSH bx              ;
        ;--------------------; 
        SHL bl, 4            ; Color Byte = BBBB FFFF
        OR al, bl            ;
        ;--------------------;
        MOV ah, al           ;
        POP bx               ;
        RET                  ;
create_color_code ENDP       ;
;-----------------------------------------------
; putchar_at
;--------------------------------------------------
; Puts a char at a given position
;- input ------------------------------------------
; bx = char - vga formatted
; cx = position
;--------------------------------------------------
PUBLIC putchar_at            ;
putchar_at PROC NEAR         ;
        PUSH bx              ;
        PUSH cx              ;
        PUSH rdx             ;
        ;--------------------;
        XOR rdx, rdx         ;
        MOV dx, cx           ;
        ;--------------------;
        MOV rdi, 0B8000H     ; Default position for character start
        ADD rdi, rdx         ;
        ;--------------------;
        MOV WORD PTR [rdi], bx;
        ;--------------------;
        POP rdx              ;
        POP cx               ;
        POP bx               ;
        ;--------------------;
        RET                  ;
putchar_at ENDP              ;
;--------------------------------------------------
; putchar
;--------------------------------------------------
; Puts a char at the next good position
;--------------------------------------------------
; AL = Character to be printed
;--------------------------------------------------
PUBLIC putchar                          ;
putchar PROC NEAR                       ;
        PUSH ax                         ;
        PUSH bx                         ;
        PUSH cx                         ;
        PUSH dx                         ;
        MOV cx, 0                       ;
        ;--------------------           ;
        MOV dl, al                      ;
        ; Get Color Byte ----           ;
        MOV al, WHITE                   ;
        MOV bl, BLACK                   ;
        CALL create_color_code          ; AH = Color
        ; Get Position of next write;   ;
        MOV cx, WORD PTR[caret]            ;
        ADD [caret], 2             ;
        ; Write char --------           ;
        MOV bl, dl                      ; BL = character to write
        MOV bh, ah                      ; BH = color code
        CALL putchar_at                 ;
        MOV rax, offset caret
        MOV rcx, 0
        MOV cx, WORD PTR [caret]
        ;--------------------           ;
        POP dx                          ;
        POP cx                          ;
        POP bx                          ;
        POP ax                          ;
        RET                             ;
putchar ENDP                            ;
TEXT ENDS                               ;
END                                     ;
