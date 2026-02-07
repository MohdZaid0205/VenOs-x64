[BITS 16]           ;; work is still needed in real mode hence 16 bits

jmp _start          ;; jump instruction just to make sure _start is run
                    ;; immidiately after jump to stage 2 was initiated

_start:
    
    in al, 0x92     ;; boilerplate for A20 activation
    or al, 0x02     ;; boilerplate for A20 activation
    out 0x92, al    ;; boilerplate for A20 activation

    ;; using 0x92 may be neccessry and may be dangerous, please see:
    ;; https://aeb.win.tue.nl/linux/kbd/A20.html#:~:text=Using%200x92%20
    ;; may%20be%20necessary
