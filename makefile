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

# create proper support for floppy and hard drive images, both 
# have boot written at first sector and then within file system 
# they must have STAGE2.SYS added to file system on images
image: floppy hdrive

floppy:
	$(MAKE) -C boot FAT12 FAT12_DBG
	dd if=/dev/zero of=out/FLOPPY.img bs=512 count=2880
	mformat -i out/FLOPPY.img -f 1440 -B bin/BOOT::STAGE1::FAT12.SYS ::
	mcopy -i out/FLOPPY.img bin/BOOT::STAGE2::FAT12.SYS ::/STAGE2.SYS

setup:
	mkdir -p ${BIN_DIR}
	mkdir -p ${OUT_DIR}
	mkdir -p ${LIB_DIR}

clean:
	rm ${BIN_DIR} -rf
	rm ${OUT_DIR} -rf
	rm ${LIB_DIR} -rf
