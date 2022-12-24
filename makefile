bootsector.BIN: bootsector/bootsector.s
	uasm -bin $^

kernel.BIN: kernel/kernel.s
	uasm -bin $^

kernel.bin: bootsector.BIN kernel.BIN
	cat $^ > $@
	rm *.BIN

run: kernel.bin
	qemu-system-x86_64 -fda $<

debug: kernel.bin
	qemu-system-x86_64 -d int -fda $<
