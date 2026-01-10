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

%macro rdis 2       ;; real mode display message in output stream
    pusha                   ;; store current context of code (swith).
    
    jmp %1_C                ;; jump to code part to execute
    %1_M: db %2             ;; dump message under any label
    %1_E: db 0h             ;; dump end of massage to a label

    ;; essentially firstly we get position of cursor and store
    ;; poition of cursor at specified position in display for print

%1_C:
    mov ah, 0x03            ;; to get current sursor position
    xor bh, bh              ;; no page is to be specified
    int 0x10                ;; invoke interrupt 0x10

    cli                     ;; temporarily stop interrupts
    
    mov bh, 0x01            ;; string is stored in current page
    mov bp, %1_M            ;; move message into bp for print
    mov cx, %1_E - %1_M     ;; subtract length of dumped byte
    mov bx, 0x02            ;; font color (0x02 = green color)
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

%endmacro

;; following is layout of physical memory during bootloader process.
;;          +-------------------------------------------------------+
;; 0x0000 : | 0x7c00        ;; point to where boot.asm is loaded    |
;; 0x____ : |~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|
;; 0x7c00 : | 0x____        ;; Binary code of boot.asm is here      |
;; 0x____ : |               ;; this code is partioned into ins      |
;; 0x____ : |               ;; parts and final magic numbers        |
;;          +-------------------------------------------------------+

_start:             ;; Bootloader main entrypoint.
    ;; rdis R_MODE, "BIOS Running in Real Mode."

    cli             ;; temporarily stop interrupts.
    xor ax, ax      ;; set ax to 0x00  (register R-AX)
    mov ds, ax      ;; set ds to 0x00  (data  segment)
    mov es, ax      ;; set es to 0x00  (extra segment)
    mov ss, ax      ;; set ss to 0x00  (stack segment)
    mov sp, 0x7c00  ;; set sp to BEGIN (stack pointer)
    sti             ;; star taking interrupts.
    
    ;; jmp _prm        ;; switch to protected mode.

    ;; currently BIOS stores type of drive that is used for
    ;; booting into the bios, inside register @dl.
    
    mov [boot_drive_id], dl     ;; store boot drive id
    ;; cmp dl, 0x80                ;; compare id to first hdrive
    ;; jae __boot_device_hdrive    ;; above or equal => hdrive
    ;; jmp __boot_device_floppy    ;; lower than 126 => floppy
    jmp _rme
 
    ;; structured data compartment for storing relevent
    ;; data that bios has to lode in real mode
    boot_drive_id: db 0x01    ;; contains boot drive id

;; __boot_device_hdrive:
    ;; rdis HDRIVE, "BIOS Booting from HDRIVE."
    ;; jmp _rme

;; __boot_device_floppy:
    ;; rdis FLOPPY, "BIOS Booting from FLOPPY."
    ;; jmp _rme        ;; jump to real mode exit

_rme:               ;; real mode exits here
    
    ;; we need to load kernel main into memory _kernel
    ;; we use CHS system in order to load kernel into
    ;; memory, more specifically DRAM, as only 0x1000
    ;; bytes were loaded by the bootloader at start.
    
    mov dl, [boot_drive_id]     ;; device to load from
    mov ch, 0x00                ;; [C]ylinder number
    mov cl, 0x02                ;; [S]ector   number
    mov dh, 0x00                ;; [H]ead     number
    mov al, 0x01                ;; num sector to load
    mov bx, 0x1000              ;; address to load to
    mov ah, 0x02                ;; load from device int
    int 0x13

    jmp _prm        ;; init switch to protected mode

_prm:               ;; protected mode swith 
    ;; rdis P_MODE, "BIOS Switched to Protected Mode."

    cli             ;; clear all interrupts
    lgdt[_gdt.des]  ;; load gdt information into GDTR
    mov eax, cr0    ;; boilerplate
    or  al, 0x01    ;; boilerplate
    mov cr0, eax    ;; boilerplate
    
    ;; real mode has stopped here, none of the real mode
    ;; interrupts and bios functions work here and next.

    jmp 0x08:_pmode ;; switch to ProtectedModeMain


_gdt:               ;; initialization for GDT
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
_pmode:             ;; protected mode main method
    ;; pdis RPM, "BIOS Running in Protected Mode."

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
    
    ;; pdis END, "BIOS Looping to Stop Termination"
    ;; jmp $
    
    ;; jump to kernel entrypoint and start executing.
    jmp 0x1000     ;; address of where we loaded it.

;; fill all part of code till last 2 magic bytes with 0x00, why:
;; we need magic number at specific location, ie 511 and 512, so in
;; order to reach 511th byte we need to dump bytes into our binary
;; this makes sure that enough bytes are filled to achive 511.
times 510 - ($ - $$) db 0

;; magic address 511 & 512 with magic number 0xAA & 0x55 as rewuired
dw 0xAA55       ;; write final magic number that tells cpu that this
                ;; binary is a boot loader and boot loader needs to
                ;; be invloked.

