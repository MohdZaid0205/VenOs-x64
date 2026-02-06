# makefile to compile each component of bootloader for VenOs in
# order to create and assemble bootloader stages into one as per
# description of specified loader

default: FAT12 FAT12_DBG FAT32 FAT32_DBG

stage1 = nasm stage1.asm -o ${BIN_DIR}/BOOT::STAGE1::FAT12.bin -f bin
stage2 = nasm stage2.asm -o ${BIN_DIR}/BOOT::STAGE2::FAT12.bin -f bin

# TODO: for each specified target a bootable image is required

FAT12:
	nasm stage1.asm -o ${BIN_DIR}/BOOT::STAGE1::FAT12.SYS -f bin -DFAT12
	nasm stage2.asm -o ${BIN_DIR}/BOOT::STAGE2::FAT12.SYS -f bin -DFAT12

FAT32:
	nasm stage1.asm -o ${BIN_DIR}/BOOT::STAGE1::FAT32.SYS -f bin -DFAT32
	nasm stage2.asm -o ${BIN_DIR}/BOOT::STAGE2::FAT32.SYS -f bin -DFAT32

FAT12_DBG:
	nasm stage1.asm -o ${BIN_DIR}/BOOT::STAGE1::FAT12.ELF -f elf64 -g -F dwarf -DDEBUG -DFAT12
	nasm stage2.asm -o ${BIN_DIR}/BOOT::STAGE2::FAT12.ELF -f elf64 -g -F dwarf -DDEBUG -DFAT12


FAT32_DBG:
	nasm stage1.asm -o ${BIN_DIR}/BOOT::STAGE1::FAT32.ELF -f elf64 -g -F dwarf -DDEBUG -DFAT32
	nasm stage2.asm -o ${BIN_DIR}/BOOT::STAGE2::FAT32.ELF -f elf64 -g -F dwarf -DDEBUG -DFAT32

