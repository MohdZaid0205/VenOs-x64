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

;; BOOT RECORDS 
BPB_OEM:                        db "VENTURE1"
BPB_BYTES_PER_SECTOR:           dw 0x0200
BPB_SECTORS_PER_CLUSTER:        db 0x01
BPB_RESERVED_SECTORS:           dw 0x0001
BPB_NUMBER_OF_FATS:             db 0x02
BPB_ROOT_ENTRIES:               dw 0x00E0
BPB_TOTAL_SECTORS:              dw 0x0B40
BPB_MEDIA:                      db 0xF0
BPB_SECTORS_PER_FAT:            dw 0x0009
BPB_SECTORS_PER_TRACK:          dw 0x0012
BPB_HEADS_PER_CYLENDER:         dw 0x0002
BPB_HIDDEN_SECTORS:             dd 0x00000000
BPB_LARGE_SECTORS:              dd 0x00000000

;; EXTENDED_BOOT_RECORDS
BS_DRIVE_NUMBER:                db 0x00
BS_UNUSED:                      db 0x00
BS_EXTENDED_BOOT_SIGNATURE:     db 0x29
BS_SERIAL_NUMBER:               dd 0xA0A1A2A3
BS_VOLUME_LABEL:                db "VENTURE-v01"
BS_FILE_SYSTEM:                 db "FAT12   "

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

