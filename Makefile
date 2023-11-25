lab2:
	fasm lab2.asm && \
	qemu-system-x86_64 --drive format=raw,file=lab2.bin,cache=none -device VGA,vgamem_mb=4 -display gtk -m 4M

lab3:
	fasm stage1.asm && \
	fasm stage2.asm && \
	dd if=/dev/zero of=image.img bs=1024 seek=0 count=1440 && \
	dd if=stage1.bin of=image.img seek=0 bs=512 count=1 conv=notrunc && \
	dd if=stage2.bin of=image.img seek=1 bs=512 count=1 conv=notrunc && \
	qemu-system-x86_64 --drive format=raw,file=image.img,cache=none -device VGA,vgamem_mb=4 -display gtk -m 4M
