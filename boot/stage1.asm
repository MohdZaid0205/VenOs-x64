[BITS 16]           ;; Use 16 bit mode as BIOS runs following code in
                    ;; something called REAL MODE which uses 16 bit
                    ;; registers in order to process everything.
                    ;; although it is possible for one to use whole 64
                    ;; bit of provided registers, but this would make
                    ;; compiled code larger than allowed code for bios

%ifndef DEBUG
    [ORG 0x7c00]    ;; This is LEGACY BIOS implementation, which loads
                    ;; bootable section into a predefined address of
                    ;; 0x7c00 in memory.
%endif

;; Boot Record
;; BPB (Bios Parameter Block) holding required information about files
;; it is necessary for safely loading stage2-bootloader and saving all
;; necessary information for later programs into memory

jmp SHORT _start    ;; jump to _start: to initiate stage1 skip record 
nop

_start:
    jmp $           ;; loop here indefinitely for the time being [tmp]

;; fill all part of code till last 2 magic bytes with 0x00, why:
;; we need magic number at specific location, ie 511 and 512, so in
;; order to reach 511th byte we need to dump bytes into our binary
;; this makes sure that enough bytes are filled to achive 511.
times 510 - ($ - $$) db 0

;; magic address 511 & 512 with magic number 0xAA & 0x55 as rewuired
dw 0xAA55       ;; write final magic number that tells cpu that this
                ;; binary is a boot loader and boot loader needs to
                ;; be invloked.

