# makefile to compile each component of VenOs implementation,and bare minimum 
# code to run it is written. some directories are predefined to write to. 
# (just for convention in project)

BIN_DIR = ./bin
OUT_DIR = ./out
LIB_DIR = ./lib
SRC_DIR = ./src

# to compile bootloader with nasm and pust it into a binary file, 
# some other functions for visual clearence has been provided.
boot: ${SRC_DIR}/boot.s
	nasm ${SRC_DIR}/boot.s -o ${BIN_DIR}/boot.bin -f bin

kernel: ${SRC_DIR}/kernel.s
	nasm ${SRC_DIR}/kernel.s -o ${BIN_DIR}/kernel.bin -f bin 

boot-debug: boot
	nasm ${SRC_DIR}/boot.s -o ${BIN_DIR}/boot.elf -f elf64 -g -F dwarf -DDEBUG
	# following code is to display different segments of bootloader in visual 
	# manner these lines can be commented as per the requirement to always see
	# the binary.
	
	# display boot record executable inst.
	xxd -s 0x0000 -l 0x01bd ${BIN_DIR}/boot.bin
	# display boot record partitions info.
	xxd -s 0x01be -l 0x0030 ${BIN_DIR}/boot.bin
	# display boot record magic numbers.
	xxd -s 0x01fe -l 0x0002 ${BIN_DIR}/boot.bin

kernel-debug: kernel
	nasm ${SRC_DIR}/kernel.s -o ${BIN_DIR}/kernel.elf -f elf64 -g -F dwarf -DDEBUG
	
	# display kernel entry point informations
	xxd -s 0x0000 ${BIN_DIR}/kernel.bin
	# display all headers present in elf file
	objdump -x ${BIN_DIR}/kernel.elf
	# display defined symbols within kernel
	readelf ${BIN_DIR}/kernel.elf -s
	

floppy: boot kernel
	# copy contents from *.bin to floppy.
	cat ${BIN_DIR}/*.bin > ${OUT_DIR}/floppy.img 
	# restrict size to maximum floppy size.
	truncate -s 1440k ${OUT_DIR}/floppy.img

floppy-debug: floppy boot-debug kernel-debug
  	# copy contents from boot.elf to floppy.elf
	cat ${BIN_DIR}/*.elf > ${OUT_DIR}/floppy.elf
	# restrict size to maximum floppy size.
	# truncate -s 1440k ${OUT_DIR}/floppy.elf

hdrive: boot kernel
	# copy boot sector to hard disk image file
	cat ${BIN_DIR}/*.bin > ${OUT_DIR}/hdrive.img
	truncate -s 8g ${OUT_DIR}/hdrive.img

# hdrive-debug: hdrive boot-debug
#	# copy boot sector debug file to disk debug file
#	cp ${BIN_DIR}/*.elf ${OUT_DIR}/hdrive.elf

clean:
	rm ${BIN_DIR}/*
	rm ${OUT_DIR}/*
	rm ${LIB_DIR}/*
