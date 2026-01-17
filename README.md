# [Ve]nture [Os] (x64)

an implementation of operating system to run on x64 architecure cpu.
This project is fun exercise to implement a complete or sudo-complete
Operating system from scratch by applying concepts learnt during OS sessions
at IIIT Delhi OS batch (2025).

## Usage

In order to use this project with `qemu` youll need some important toolsets
including `gcc-cross-compiler` for `i386:x86-64`, `nasm` assembler, emulator
`qemu-system-x86_64` and `mtools` for disk setup.

To compile and run the project use commands
```bash
make boot floppy
qemu-system-x86_64 -fda out/floppy.img
```
for degugging with gdb use commands
```bash
make boot-debug floppy-debug
qemu-system-x86_64 -fda out/floppy -S -s
```
```gdb
set architecture i386:x86-64
target remote:1234
add-symbol-file bin/boot.elf 0x7c00
```

## Contribution

Feel free to fork and modify. however no contribution to this main project
is required. (this is not supposed to be a real OS) just a dummy.

# Bibliography

- [overview](https://wiki.osdev.org/Bootloader) of a bootloader.
- intitial steps od creating [bootloader](https://wiki.osdev.org/Rolling_Your_Own_Bootloader).
- [gdt](https://wiki.osdev.org/Global_Descriptor_Table) table reference.
- [protected mode](https://wiki.osdev.org/Protected_Mode) and switching process.
- [a20 line](https://wiki.osdev.org/A20_Line) and how to enable.
- bios and real mode interrupts [odsev](https://wiki.osdev.org/BIOS), [wikipedia](https://en.wikipedia.org/wiki/BIOS_interrupt_call) and [parameters](http://employees.oneonta.edu/higgindm/assembly/DOS_AND_ROM_BIOS_INTS.htm)
- boot [disk and floppy](https://en.wikipedia.org/wiki/INT_13H#:~:text=%5Bedit%5D-,Drive%20Table,-DL%20%3D%2000h) information and [access](https://wiki.osdev.org/Disk_access_using_the_BIOS_(INT_13h))
- FAT12 Bios Parameter Block [contents](https://www.brokenthorn.com/Resources/OSDev6.html)
- FAT32 Bios Parameter Block [contents](https://academy.cba.mit.edu/classes/networking_communications/SD/FAT.pdf)
- Resource for [x86 instructions](https://c9x.me/x86/)
