[BITS 16]       ;; Use 16 bit mode as BIOS runs following code in
                ;; something called REAL MODE which uses 16 bit
                ;; registers in order to process everything.
                ;; although it is possible for one to use whole 64
                ;; bit of provided registers, but this would make
                ;; compiled code larger than allowed code for bios

[ORG 0x7c00]    ;; This is LEGACY BIOS implementation, which loads
                ;; bootable section into a predefined address of
                ;; 0x7c00 in memory.

;; following is layout of physical memory during bootloader process.
;;          +-------------------------------------------------------+
;; 0x0000 : | 0x7c00        ;; point to where boot.asm is loaded    |
;; 0x____ : |~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|
;; 0x7c00 : | 0x____        ;; Binary code of boot.asm is here      |
;; 0x____ : |               ;; this code is partioned into ins      |
;; 0x____ : |               ;; parts and final magic numbers        |
;;          +-------------------------------------------------------+

_start:
    
    cli             ;; temporarily stop interrupts.
    xor ax, ax      ;; set ax to 0x00  (register R-AX)
    mov ds, ax      ;; set ds to 0x00  (data  segment)
    mov es, ax      ;; set es to 0x00  (extra segment)
    mov ss, ax      ;; set ss to 0x00  (stack segment)
    mov sp, 0x7c00  ;; set sp to BEGIN (stack pointer)
    mov si, ax      ;; set si to INFOS (source indexs)
    sti             ;; star taking interrupts.
    
    jmp _end        ;; jump to end this program.

_end:
    hlt             ;; end execution part of program.

;; fill all part of code till last 2 magic bytes with 0x00, why:
;; we need magic number at specific location, ie 511 and 512, so in
;; order to reach 511th byte we need to dump bytes into our binary
;; this makes sure that enough bytes are filled to achive 511.
times 510 - ($ - $$) db 0

;; magic address 511 & 512 with magic number 0xAA & 0x55 as rewuired
dw 0xAA55       ;; write final magic number that tells cpu that this
                ;; binary is a boot loader and boot loader needs to
                ;; be invloked.

