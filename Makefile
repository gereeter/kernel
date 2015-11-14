.PHONY: run clean start

run: bin/kernel.bin32
	qemu-system-x86_64 -kernel $<

clean:
	rm -rf bin/

start:
	mkdir -p bin/

# Basic Multiboot only understands elf32
bin/kernel.bin32: bin/kernel.bin
	objcopy -I elf64-x86-64 -O elf32-i386 $< $@

bin/kernel.bin: start bin/boot.o bin/multiboot.o src/ld/kernel.ld
	ld -n -m elf_x86_64 -o $@ -T src/ld/kernel.ld bin/boot.o bin/multiboot.o

bin/boot.o: src/asm/boot.asm
	nasm -f elf64 -o $@ $<

bin/multiboot.o: src/asm/multiboot.asm
	nasm -f elf64 -o $@ $<
