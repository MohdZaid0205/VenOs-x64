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

;; Boot Record ---------------------------------------------------------+
;; BPB (Bios Parameter Block) holding required information about files  |
;; it is necessary for safely loading stage2-bootloader and saving all  |
;; necessary information for later programs into memory                 |
;; ---------------------------------------------------------------------+

jmp SHORT _start    ;; jump to _start: to initiate stage1 skip record 
nop

;; Add Support for FAT12(FLOPPY) and FAT32(H_DISK & H_DRIVE) by changing
;; BIOS PARAMETER BLOCK accordingly at places for compatiblity.
;; https://academy.cba.mit.edu/classes/networking_communications/SD/FAT.pdf

;; BOOT RECORDS 
BPB_OEM:                        db "VENTURE1"
BPB_BYTES_PER_SECTOR:           dw 0x0200
BPB_SECTORS_PER_CLUSTER:        db 0x01
BPB_RESERVED_SECTORS:           dw 0x0001
BPB_NUMBER_OF_FATS:             db 0x02

%ifdef FAT12
    BPB_ROOT_ENTRIES:           dw 0x00E0
    BPB_TOTAL_SECTORS_16:       dw 0x0B40
%endif
%ifdef FAT32
    BPB_ROOT_ENTRIES:           dw 0x0000
    BPB_TOTAL_SECTORS_16:       dw 0x0000
%endif

BPB_MEDIA:                      db 0xF0

%ifdef FAT12
    BPB_FAT_SIZE_16:            dw 0x0009
%endif
%ifdef FAT32
    BPB_FAT_SIZE_16:            dw 0x0000
%endif

BPB_SECTORS_PER_TRACK:          dw 0x0012
BPB_HEADS_PER_CYLINDER:         dw 0x0002
BPB_HIDDEN_SECTORS:             dd 0x00000000

%ifdef FAT12
    BPB_TOTAL_SECTORS_32:       dd 0x00000000
%endif
%ifdef FAT32
    BPB_TOTAL_SECTORS_32:       dd 0x00010000
%endif

;; EXTENDED_BOOT_RECORDS for FAT12(FLOPPY) devices
%ifdef FAT12
    BS_DRIVE_NUMBER:            db 0x00
    BS_UNUSED:                  db 0x00
    BS_BOOT_SIGNATURE:          db 0x29
    BS_SERIAL_NUMBER:           dd 0xA0A1A2A3
    BS_VOLUME_LABEL:            db "VENTURE-FLP"
    BS_FILE_SYSTEM:             db "FAT12   "
%endif

;; EXTENDED_BOOT_RECORDS for FAT32(H_DISK) devices
%ifdef FAT32
    BPB_FAT_SIZE_32:            dd 0x00000000
    BPB_EXTENDED_FLAGS:         dw 0x0000
    BPB_FILE_SYSTEM_VERSION:    dw 0x0000
    BPB_ROOT_CLUSTER:           dd 0x00000002
    BPB_FILE_SYSTEM_INFO:       dw 0x0001
    BPB_BACKUP_BOOT_SECTOR:     dw 0x0006
    BPB_RESERVED:               dd 0x00000000
                                dd 0x00000000
                                dd 0x00000000

    BS_DRIVE_NUMBER:            db 0x80
    BS_UNUSED:                  db 0x00
    BS_BOOT_SIGNATURE:          db 0x29
    BS_VOLUME_ID:               dd 0xA0A1A2A3
    BS_VOLUME_LABEL:            db "VENTURE-HDD"
    BS_FILE_SYSTEM:             db "FAT32   "
%endif

;; Following are macros used to create life easier for debugging and print
;; note that these used BIOS interupts in order to achive desired behaviour
;; therefore it can only be used while REAL-Mode is active, not ever after
;; switching out of real mode.

;; Display given string to screen, using int 0x10 and at current cursor pos
%macro put 1
    jmp %%_CALL             ;; jump to calling data, ignore data itself
    %%_BGN: db %1           ;; dump message into any label
    %%_END: db 0x00         ;; null terminate the string
%%_CALL:
    mov bp, %%_BGN          ;; point to stored message for print
    mov cx, %%_END - %%_BGN ;; length of string in bytes
    
    call print_line         ;; call routine for bios print line
%endmacro

;; following is layout of physical memory during bootloader process.
;;          +-----------------------------------------------------------+
;; 0x0000 : | 0x7c00        ;; point to where boot.asm is loaded        |
;; 0x____ : |~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|
;; 0x7c00 : | 0x____        ;; Binary code of boot.asm is here          |
;; 0x____ : |               ;; this code is partioned into ins          |
;; 0x____ : |               ;; parts and final magic numbers            |
;;          +-----------------------------------------------------------+

_start:
    
    cli                     ;; temporarily stop interrupts.
    xor ax, ax              ;; set ax to 0x00  (register R-AX)
    mov ds, ax              ;; set ds to 0x00  (data  segment)
    mov es, ax              ;; set es to 0x00  (extra segment)
    mov ss, ax              ;; set ss to 0x00  (stack segment)
    mov sp, 0x7c00          ;; set sp to BEGIN (stack pointer)
    sti                     ;; star taking interrupts.
    
    ;; initially dl register is set with device id of bootable device.
    mov [BS_DRIVE_NUMBER], dl   ;; store device id, in case if its not
                                ;; default address.

    jmp _panic

_panic:

    cli                     ;; stop interrupt before terminating
    hlt                     ;; halt execution (dont let bios fallback)

;; fight with Logaical base Addressing and Cylender Head Sector (CHS)
;;  +-------------------------------------------------------------------+
;;  |sector     = (LBA % SECTORS_PER_TRACK) + 1                         |
;;  +-------------------------------------------------------------------+
;;  |head       = (LBA / SECTORS_PER_TRACK) % HEADS_PER_CYLENDER        |
;;  +-------------------------------------------------------------------+
;;  |cylender   = (LBA / SECTORS_PER_TRACK) / HEADS_PER_CYLENDER        |
;;  +-------------------------------------------------------------------+
;; https://wiki.osdev.org/LBA

;; take LBA as an input into eax = [ah] [ax]
;; returns ch, cl and dh as required by read instruction

;; FUNCTION LBA_TO_CHS(ax=LBA_ADDRESS) (**)<0 .. BPB_TOTAL_SECTORS - 1>
;;  ax :: Takes in SECTOR NUMBER that must be strictly less within (**)
;;  -> :: SETs VALUES OF REGISTERS (cx, dh, dl and ax)
lba_to_chs:

    push ax                 ;; Save original LBA
    push dx                 ;; Save original Drive Number

    xor dx, dx              ;; Zero dx for division
    div word [BPB_SECTORS_PER_TRACK]   
    
    ;; here ------------------------------------------------------------+
    ;; dx = LBA % SECTORS_PER_TRACK                                     |
    ;; ax = LBA / SECTORS_PER_TRACK                                     |
    ;; -----------------------------------------------------------------+

    inc dx                  ;; Convert to 1-based Sector (1..63)
    mov cx, dx              ;; Move Sector to cx (cl = Sector, ch = 0)

    xor dx, dx              ;; Zero DX for second division
    div word [BPB_HEADS_PER_CYLINDER]
    
    ;; here ------------------------------------------------------------+
    ;; dx = (LBA / SECTORS_PER_TRACK) % HEADS_PER_CYLENDER              |
    ;; ax = (LBA / SECTORS_PER_TRACK) / HEADS_PER_CYLENDER              |
    ;; -----------------------------------------------------------------+

    mov dh, dl              ;; Move Head result to dh
    mov ch, al              ;; ch = Low 8 bits of Cylinder
    shl ah, 0x06            ;; Shift Cylinder high bits (8-9) to positions 6-7
    or  cl, ah              ;; Merge high Cylinder bits into cl (Sector)

    pop ax                  ;; Pop original dx (Drive ID) into ax
    mov dl, al              ;; Restore Drive id to dl
    pop ax                  ;; Restore original LBA to ax
ret

;; FUNCTION DISK_READ(ax=LBA, cl=N_SECTORS, dl=DRIVE, es:bx=BUFFER)
;;  ax    :: LBA Address to read from
;;  cl    :: Number of sectors to read (1 .. 128 recommended limit)
;;  dl    :: Drive number (e.g., 0x00 for floppy, 0x80 for HDD)
;;  es:bx :: Pointer to the buffer where data will be stored
;;  ->    :: Fills memory at [es:bx] with data from disk
;;  ->    :: Sets Carry Flag (cf) if an error occurs (ch = Error Code)
disk_read:

    push cx                 ;; Save sector count (cl). The LBA conversion
                            ;; routine will overwrite cx with Cylinder data,
                            ;; so we must stash the count on the stack.

    call lba_to_chs         ;; Calculate CHS from LBA.
                            ;; cx (Cyl/Sec)
                            ;; dh (Head)
                            ;; dl (Drive)
                            ;; ax (LBA)

    pop  ax                 ;; Restore the sector count.
    mov ah, 0x02            ;; Read Sectors From Drive
    
    int 0x13                ;; INVOKE BIOS

    cmp ah, 0x00            ;; check for error
    jne disk_error          ;; error routine for reporting
ret

;; DISK_ERROR label
;; default action to disk error suggest to reset disk system and try again
;; atleast 3 times in order to get proper data in DRAM, but for purpose of 
;; this project i am assuming that modern hardware is more than capable to
;; required data once and for all, if any kind of error was raised we report
disk_error:

    put "disk_error"        ;; display disk error
    jmp _panic              ;; stop execution of bootloader

;; FUNCTION_PRINT_LINE(bp=STRING_POINTER, cx=LENGTH_OF_SPECIFIED STRING)
;;  bp      :: contains pointer to string that is to be printed
;;  cx      :: contains length of string to print to screen
;;  ->      :: Calls int 0x13 and moves to next line (no_return)
print_line:

    pusha                   ;; store current context.

    push cx                 ;; this is overwritten by cursor pos intr...
    mov ah, 0x03            ;; to get current cursor position
    xor bh, bh              ;; no page is to be specified
    int 0x10                ;; invoke interrupt 0x10
    pop cx                  ;; restore length of string

    cli                     ;; temporarily stop interrupts
    
    mov bh, 0x01            ;; string is stored in current page
    mov bx, 0x02            ;; font color (0x02 = GREEN color)
    mov ah, 0x13            ;; print command inst number
    mov al, 0x01            ;; remember that ah=0x13 and
                            ;; al = 0x01 therefore ax = ...
    int 0x10                ;; invoke interrupt 0x10

    sti                     ;; start taking interrupts

    mov ah, 0x02            ;; to set cursor to next line
    xor dl, dl              ;; column number set = 0
    add dh, 0x01            ;; row number set += 1
    int 0x10

    popa                    ;; resotore execution context for code.

ret
    

;; ---------------------------------------------------------------------+
;; fill all part of code till last 2 magic bytes with 0x00, why:        |
;; we need magic number at specific location, ie 511 and 512, so in     |
;; order to reach 511th byte we need to dump bytes into our binary      |
;; this makes sure that enough bytes are filled to achive 511.          |
;; ---------------------------------------------------------------------+
times 510 - ($ - $$) db 0

;; magic address 511 & 512 with magic number 0xAA & 0x55 as rewuired
dw 0xAA55       ;; write final magic number that tells cpu that this
                ;; binary is a boot loader and boot loader needs to
                ;; be invloked.

