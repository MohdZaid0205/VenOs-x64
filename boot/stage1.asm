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
    
    cli             ;; temporarily stop interrupts.
    xor ax, ax      ;; set ax to 0x00  (register R-AX)
    mov ds, ax      ;; set ds to 0x00  (data  segment)
    mov es, ax      ;; set es to 0x00  (extra segment)
    mov ss, ax      ;; set ss to 0x00  (stack segment)
    mov sp, 0x7c00  ;; set sp to BEGIN (stack pointer)
    sti             ;; star taking interrupts.
    

    mov ax, 0x01    ;; temporarily test by loading sector 1
    mov cl, 0x01
    mov dl, 0x00
    mov bx, 0x1000
    call disk_read
    
    jmp 0x1000           ;; loop here indefinitely for the time being [tmp]

;; fight with Logaical base Addressing and Cylender Head Sector (CHS)
;; sector   = (LBA % SECTORS_PER_TRACK) + 1
;; head     = (LBA / SECTORS_PER_TRACK) % HEADS_PER_CYLENDER
;; cylender = (LBA / SECTORS_PER_TRACK) / HEADS_PER_CYLENDER

;; take LBA as an input into eax = [ah] [ax]
;; returns ch, cl and dh as required by read instruction
lba_to_chs:
    push ax         ;; store the argument that has been provided in ax
    push dx         ;; store the contents of temporarily used register

    xor dx, dx      ;; clear (to remove garbage) and store sector num
    div word [BPB_SECTORS_PER_TRACK]
                    ;; dx = LBA % SECTORS_PER_TRACK
                    ;  ax = LBA / SECTORS_PER_TRACK

    inc dx          ;; increment by one (first lelement = sector 1)
    mov cx, dx      ;; store result into cx register as required
    
    xor dx, dx      ;; clear (to remove garbage) and store sector num
    div word [BPB_HEADS_PER_CYLENDER]
                    ;; dx = (LBA / SECTORS_PER_TRACK) % HEADS_PER_CYLENDER
                    ;; ax = (LBA / SECTORS_PER_TRACK) / HEADS_PER_CYLENDER
    
    ;; cx contains index of sectors that we need to read.
    ;; dx contains index of head over cylender heads we need to read.
    ;; ax contains index od cylender/face we need to read.

    mov dh, dl      ;; prepare dh with head number
    mov ch, al      ;; prepare ch with cylender number
    shl ah, 6       ;; shift left by 6 in in order to have upper 2 bits 
    or cl, ah       ;; prepate cl by storing upper 2 bits

    pop ax          ;; store dx temporaily into ax
    mov dl, al      ;; copy lower 8 bits for device specifier
    pop ax          ;; store initial argument of lba_to_chs
ret

;; take arguments ax=LBA, cl=n_sectors_t_read, dl=drive_number, es:bx=buff
;; and fills es:bx buffer memory with loaded values from disk
disk_read:
    ;; assuming everytihg has beed set properly before calling this function
    push cx         ;; save [cl] number of sectors to read
    call lba_to_chs ;; populate required registers with chs values
    pop ax          ;; set number of sectors to read properly for int13

    mov ah, 0x02    ;; read from memory BIOS interrupt ah value (required)
    int 0x13        ;; finally call the interrupt to load values into it
ret

;; fill all part of code till last 2 magic bytes with 0x00, why:
;; we need magic number at specific location, ie 511 and 512, so in
;; order to reach 511th byte we need to dump bytes into our binary
;; this makes sure that enough bytes are filled to achive 511.
times 510 - ($ - $$) db 0

;; magic address 511 & 512 with magic number 0xAA & 0x55 as rewuired
dw 0xAA55       ;; write final magic number that tells cpu that this
                ;; binary is a boot loader and boot loader needs to
                ;; be invloked.

