.PHONY: run clean

run: bin/kernel.bin32
	qemu-system-x86_64 -kernel $<

clean:
	rm -rf bin/

bin/folder_creation_hack:
	mkdir -p bin/
	touch $@

# Basic Multiboot only understands elf32
bin/kernel.bin32: bin/kernel.bin
	objcopy -I elf64-x86-64 -O elf32-i386 $< $@

bin/kernel.bin: bin/folder_creation_hack bin/boot.o bin/boot64.o bin/multiboot.o src/ld/kernel.ld
	ld -n -m elf_x86_64 -o $@ -T src/ld/kernel.ld bin/boot.o bin/boot64.o bin/multiboot.o

bin/boot.o: src/asm/boot.asm
	nasm -f elf64 -o $@ $<

bin/boot64.o: src/rust/main.rs
	rustc --crate-type staticlib --target x86_64-unknown-linux-gnu -C no-redzone -C target-feature=-mmx,-sse,-sse2,-sse3,-ssse3,-sse4.1,-sse4.2,-3dnow,-3dnowa,-avx,-avx2 -o $@ $<

bin/multiboot.o: src/asm/multiboot.asm
	nasm -f elf64 -o $@ $<
