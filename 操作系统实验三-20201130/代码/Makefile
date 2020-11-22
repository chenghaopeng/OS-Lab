clean:
	rm -f boot.bin
	rm -f loader.bin
	rm -f kernel.bin
	rm -f a.img

all: clean
	dd if=/dev/zero of=a.img bs=512 count=2880 conv=notrunc
	nasm ./boot.asm -o boot.bin
	nasm ./loader.asm -o loader.bin
	nasm ./kernel.asm -o kernel.bin
	dd if=boot.bin of=a.img bs=512 count=1 conv=notrunc
	dd if=loader.bin of=a.img bs=512 count=1 seek=1 conv=notrunc
	dd if=kernel.bin of=a.img bs=512 count=16 seek=2 conv=notrunc

run: all
	bochs
