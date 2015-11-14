.PHONY: run clean

run: bin/kernel.bin32
	qemu-system-x86_64 -kernel $<

clean:
	rm -rf bin/
	rm -rf lib/out
	rm -rf src/rust/target

bin/:
	mkdir -p bin/

lib/out/:
	mkdir -p lib/out/

# Basic Multiboot only understands elf32
bin/kernel.bin32: bin/kernel.bin
	objcopy -I elf64-x86-64 -O elf32-i386 $< $@

bin/kernel.bin: bin/ bin/boot.o bin/boot64.a bin/multiboot.o src/ld/kernel.ld
	ld -n -m elf_x86_64 -o $@ -T src/ld/kernel.ld bin/boot.o bin/boot64.a bin/multiboot.o

bin/boot.o: src/asm/boot.asm
	nasm -f elf64 -o $@ $<

bin/multiboot.o: src/asm/multiboot.asm
	nasm -f elf64 -o $@ $<

bin/boot64.a: src/rust/target/x86_64-unknown-none-gnu/debug/libkernel.a
	cp $< $@

src/rust/target/x86_64-unknown-none-gnu/debug/libkernel.a: src/rust/src/kernel.rs lib/out/core_patched.done
	cargo build --target x86_64-unknown-none-gnu --manifest-path src/rust/Cargo.toml

lib/out/core_patched.done: lib/out/ lib/core_nofp.patch
	mkdir -p lib/out/core_patched/
	rm -rf lib/out/core_patched/
	cp -r submodules/rust/src/libcore/ lib/out/core_patched/
	patch -d lib/out/ -p0 < lib/core_nofp.patch
	touch lib/out/core_patched.done
