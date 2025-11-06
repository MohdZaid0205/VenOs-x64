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
    sti             ;; star taking interrupts.
    
    jmp _prm        ;; switch to protected mode.

_prm:
    cli             ;; clear all interrupts
    lgdt[_gdt.des]  ;; load gdt information into GDTR
    mov eax, cr0    ;; boilerplate
    or  al, 0x01    ;; boilerplate
    mov cr0, eax    ;; boilerplate
    jmp 0x08:_pmode ;; switch to ProtectedModeMain


_gdt:
    .start:
        ;; remember start address for _gdt

    ;; first entry of Global descriptor table (NULL)
    ;; often required by hardware (but not necessary)
    db 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0xf0, 0xe0

    ;; kernel mode code segment entry for gdt ar 0x08
    db 0xff, 0xff   ;; gdt_entry[0 :15] = limit[0 :15]
    db 0x00, 0x00   ;; gdt_entry[16:31] = base [0 :15]
    db 0x00         ;; gdt_entry[32:39] = base [16:23]
    db 0b10011010   ;; gdt_entry[40:47] = access bits
    db 0b11001111   ;; gdt_entry[48:55] = limit[16:20] | flag bits
    db 0b00         ;; gdt_entry[56:63] = base [24:32]

    ;; kernel mode data segment entry for gdt ar 0x08
    db 0xff, 0xff   ;; gdt_entry[0 :15] = limit[0 :15]
    db 0x00, 0x00   ;; gdt_entry[16:31] = base [0 :15]
    db 0x00         ;; gdt_entry[32:39] = base [16:23]
    db 0b10010010   ;; gdt_entry[40:47] = access bits
    db 0b11001111   ;; gdt_entry[48:55] = limit[16:20] | flag bits
    db 0b00         ;; gdt_entry[56:63] = base [24:32]

    .end:
        ;; remember end address for_gdt
    
    .des:
        dw .end - .start - 0x01
        dd .start

[BITS 32]
_pmode:
    mov ax, 0x10    ;; ax must contain offset of code segment
    mov ds, ax      ;; clean ds
    mov es, ax      ;; clean es
    mov fs, ax      ;; clean fs
    mov ss, ax      ;; clean ss
    mov gs, ax      ;; clean gs

    mov ebp, 0x9c00 ;; previous stack pointer to newly created pointer
    mov esp, 0x9c00 ;; currnet stack pointer to beginning of stack

    in al, 0x92     ;; boilerplate for A20 activation
    or al, 0x02     ;; boilerplate for A20 activation
    out 0x92, al    ;; boilerplate for A20 activation

    jmp $
    

;; fill all part of code till last 2 magic bytes with 0x00, why:
;; we need magic number at specific location, ie 511 and 512, so in
;; order to reach 511th byte we need to dump bytes into our binary
;; this makes sure that enough bytes are filled to achive 511.
times 510 - ($ - $$) db 0

;; magic address 511 & 512 with magic number 0xAA & 0x55 as rewuired
dw 0xAA55       ;; write final magic number that tells cpu that this
                ;; binary is a boot loader and boot loader needs to
                ;; be invloked.

