# makefile to compile each component of VenOs implementation, and 
# bare minimum code to run it is written. some directories are 
# predefined to write to. (just for convention in project)
.PHONY: setup bootloader clean

BIN_DIR = $(shell pwd)/bin
OUT_DIR = $(shell pwd)/out
LIB_DIR = $(shell pwd)/lib

export BIN_DIR OUT_DIR LIB_DIR

# to compile bootloader with nasm and pust it into a binary file, 
# some other functions for visual clearence has been provided.
# all sope dependent parts have been moved to theyr corresponding
# directories where they are supposed to operate in
default: setup bootlaoder

# compile bootlaoder | Contains STAGE1 STAGE2 and image creation
# for corresponding file system as per requirement of FAT_XX
bootlaoder:
	$(MAKE) -C boot

setup:
	mkdir -p ${BIN_DIR}
	mkdir -p ${OUT_DIR}
	mkdir -p ${LIB_DIR}

clean:
	rm ${BIN_DIR} -rf
	rm ${OUT_DIR} -rf
	rm ${LIB_DIR} -rf
