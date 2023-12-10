nasm -f bin lab3_boot.asm -o lab3_boot.com
nasm -f bin lab3.asm -o lab3.com

truncate -s 1474560 lab3_boot.com
mv lab3_boot.com floppy.img

dd if=lab3.com of=floppy.img bs=512 seek=1 count=4 conv=notrunc

rm -f lab3_boot.com lab3.com