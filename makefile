build: bootstrap.s linker.ld check_multiboot.sh
	uasm -elf64 bootstrap.s
	uasm -elf64 terminal.s
	../cross/bin/ld -T linker.ld -o myos.bin bootstrap.o terminal.o -O2 -nostdlib -g
	./check_multiboot.sh
	cp myos.bin isodir/boot/myos.bin
	cp grub.cfg isodir/boot/grub/grub.cfg
	grub-mkrescue -o myos.iso isodir
   
run: build 
	qemu-system-x86_64 myos.iso

debug: build
	qemu-system-x86_64 myos.iso -monitor stdio
