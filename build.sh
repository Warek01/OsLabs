nasm -f bin bootloader.asm -o bootloader.bin &&
nasm -f bin code.asm -o code.bin &&

rm -f floppy.img &&
truncate -s 1474560 floppy.img &&

dd if=bootloader.bin of=floppy.img bs=512 seek=0 count=1 conv=notrunc &&
dd if=code.bin of=floppy.img bs=512 seek=1171 count=4 conv=notrunc &&

rm -f bootloader.bin code.bin
