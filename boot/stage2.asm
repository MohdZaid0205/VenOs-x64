[BITS 16]           ;; work is still needed in real mode hence 16 bits

jmp _start          ;; jump instruction just to make sure _start is run
                    ;; immidiately after jump to stage 2 was initiated

%macro put 1
    jmp %%_CALL         ;; jump to calling print, ignore data
    %%_MSG: db %1, 0x0d ;; store data under a referable label
    %%_END: db 0x00     ;; store data under a referable label
%%_CALL:
    mov si, %%_MSG      ;; move data into printable register
    call print_string   ;; call to start printing process
%endmacro

_start:
    mov ax, 0x00    ;; ax must contain offset of code segment
                    ;; till then we keep it cleared
    mov ds, ax      ;; clean ds
    mov es, ax      ;; clean es
    mov fs, ax      ;; clean fs
    mov ss, ax      ;; clean ss
    mov gs, ax      ;; clean gs
    
    mov ebp, 0x7c00 ;; previous stack pointer to newly created pointer
    mov esp, 0x7c00 ;; currnet stack pointer to beginning of stack

    in al, 0x92     ;; boilerplate for A20 activation
    or al, 0x02     ;; boilerplate for A20 activation
    out 0x92, al    ;; boilerplate for A20 activation

    ;; using 0x92 may be neccessry and may be dangerous, please see:
    ;; https://aeb.win.tue.nl/linux/kbd/A20.html#:~:text=Using%200x92%20
    ;; may%20be%20necessary
    
    jmp $

print_string:
    
    pusha           ;; store context to restore after call returns
    mov ah, 0x0E    ;; required parameter for int 0x10

    .loop:
        lodsb               ;; Load byte at DS:SI into AL
        cmp al, 0           ;; if end string
        je  .done           ;; completed
        int 0x10            ;; print
        jmp .loop           ;; loop and print next chat
    
    .done:
        mov ah, 0x03        ;; to get current cursor position
        xor bh, bh          ;; no page is to be specified
        int 0x10            ;; invoke interrupt 0x10

        mov ah, 0x02        ;; to set cursor to next line
        xor dl, dl          ;; column number set = 0
        add dh, 0x01        ;; row number set += 1
        int 0x10

        popa        ;; restore context before retutning to caller
ret

