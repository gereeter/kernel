.PHONY: run clean start

run: bin/kernel.bin
	qemu-system-i386 -kernel $<

clean:
	rm -rf bin/

start:
	mkdir -p bin/

bin/kernel.bin: start bin/boot.o bin/multiboot.o src/ld/kernel.ld
	ld -n -m elf_i386 -o $@ -T src/ld/kernel.ld bin/boot.o bin/multiboot.o

bin/boot.o: src/asm/boot.asm
	nasm -f elf -o $@ $<

bin/multiboot.o: src/asm/multiboot.asm
	nasm -f elf -o $@ $<
