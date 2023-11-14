# input file name, no extenstion
i ?= input

run: compile emulate

compile: $(i).asm
	fasm $(i).asm

emulate: $(i).bin
	qemu-system-x86_64 --drive format=raw,file=$(i).bin,cache=none -device VGA,vgamem_mb=4 -display gtk -m 4M

img: $(i).bin
	dd if=/dev/zero of=$(i).img bs=1024 seek=0 count=1440 && \
	dd if=$(i).bin of=$(i).img seek=0 conv=notrunc
