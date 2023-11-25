lab2:
	fasm lab2.asm && \
	qemu-system-x86_64 --drive format=raw,file=lab2.bin,cache=none -m 4M

lab3:
	nasm -f bin lab3_starter.asm -o lab3_starter.bin && \
	nasm -f bin lab3.asm -o lab3.bin && \
	dd if=/dev/zero of=lab3.img bs=1024 seek=0 count=1440 && \
	dd if=lab3_starter.bin of=lab3.img conv=notrunc && \
	dd if=lab3.bin of=lab3.img seek=1 bs=512 conv=notrunc && \
	dd if=name_1.txt of=lab3.img seek=1051 bs=512 conv=notrunc && \
	dd if=name_2.txt of=lab3.img seek=1171 bs=512 conv=notrunc && \
	dd if=name_3.txt of=lab3.img seek=1411 bs=512 conv=notrunc && \
	qemu-system-x86_64 --drive format=raw,file=lab3.img,cache=none -m 4M
