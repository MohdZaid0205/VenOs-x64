# makefile to compile each component of bootloader for VenOs in
# order to create and assemble bootloader stages into one as per
# description of specified loader

default: bootable_floppy

stage1 = nasm stage1.asm -o ${BIN_DIR}/BOOT::STAGE1.bin -f bin
stage2 = nasm stage2.asm -o ${BIN_DIR}/BOOT::STAGE2.bin -f bin

bootable_floppy:
	dd if=/dev/zero of=${OUT_DIR}/BOOTABLE_FLOPPY.img bs=1024 count=1440
	${stage1} -DFAT12
	dd if=${BIN_DIR}/BOOT::STAGE1.bin of=${OUT_DIR}/BOOTABLE_FLOPPY.img conv=notrunc bs=512 count=1
	${stage2} -DFAT12
	dd if=${BIN_DIR}/BOOT::STAGE1.bin of=${OUT_DIR}/BOOTABLE_FLOPPY.img conv=notrunc bs=512 count=1
bootable_hdrive:
	${stage1} -DFAT32
	${stage2} -DFAT32

