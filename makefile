# makefile to compile each component of VenOs implementation,and bare minimum 
# code to run it is written. some directories are predefined to write to. 
# (just for convention in project)

BIN_DIR = ./bin
OUT_DIR = ./out
LIB_DIR = ./lib

# to compile bootloader with nasm and pust it into a binary file, 
# some other functions for visual clearence has been provided.
boot: boot.s
	nasm boot.s -o ${BIN_DIR}/boot.bin -f bin

boot-debug: boot
	nasm boot.s -o ${BIN_DIR}/boot.elf -f elf64 -g -F dwarf -DDEBUG
	# following code is to display different segments of bootloader in visual 
	# manner these lines can be commented as per the requirement to always see
	# the binary.
	
	# display boot record executable inst.
	xxd -s 0x0000 -l 0x01bd ${BIN_DIR}/boot.bin
	# display boot record partitions info.
	xxd -s 0x01be -l 0x0030 ${BIN_DIR}/boot.bin
	# display boot record magic numbers.
	xxd -s 0x01fe -l 0x0002 ${BIN_DIR}/boot.bin

qemu:
	qemu-system-x86_64 -drive file=./bin/boot.bin,format=raw,if=ide,index=0

clean:
	rm ${BIN_DIR}/*.bin
	rm ${OUT_DIR}/*.out
	rm ${LIB_DIR}/*.lib
