bootsector.BIN: bootsector/bootsector.s
	uasm -bin $^

kernel.BIN: kernel/kernel.s
	uasm -bin $^

bootdisc.bin: bootsector.BIN kernel.BIN
	-mkdir kerneldir
	mv kernel.BIN ./kerneldir/KERNEL.BIN
	mkfatbin -b bootsector.BIN -d kerneldir -o bootdisc.bin

run: bootdisc.bin
	qemu-system-x86_64 -fda $<

debug: bootdisc.bin
	qemu-system-x86_64 -d int -fda $<
