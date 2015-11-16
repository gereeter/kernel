.PHONY: run clean

run: bin/kernel.bin32
	qemu-system-x86_64 -kernel $<

clean:
	rm -rf bin/
	rm -rf lib/patched
	rm -rf lib/core/target
	rm -rf lib/rlibc/target
	rm -rf src/rust/target

bin/.dir_created:
	mkdir -p bin/
	touch $@

lib/patched/.dir_created:
	mkdir -p lib/patched/
	touch $@

# Basic Multiboot only understands elf32
bin/kernel.bin32: bin/kernel.bin
	objcopy -I elf64-x86-64 -O elf32-i386 $< $@

bin/kernel.bin: bin/.dir_created bin/boot.o bin/boot64.a bin/multiboot.o src/ld/kernel.ld
	ld -n -m elf_x86_64 -o $@ -T src/ld/kernel.ld bin/boot.o bin/boot64.a bin/multiboot.o

bin/boot.o: src/asm/boot.asm bin/.dir_created
	nasm -f elf64 -o $@ $<

bin/multiboot.o: src/asm/multiboot.asm bin/.dir_created
	nasm -f elf64 -o $@ $<

bin/boot64.a: src/rust/target/x86_64-unknown-none-gnu/debug/libkernel.a bin/.dir_created
	cp $< $@

src/rust/target/x86_64-unknown-none-gnu/debug/libkernel.a: src/rust/src/kernel.rs lib/patched/core.done
	cargo build --target x86_64-unknown-none-gnu --manifest-path src/rust/Cargo.toml

lib/patched/core/.dir_created: lib/patched/.dir_created
	cp -r submodules/rust/src/libcore/ lib/patched/core
	touch $@

lib/patched/core.done: lib/patched/core/.dir_created lib/core_nofp.patch
	patch -d lib/patched/ -p0 < lib/core_nofp.patch
	touch $@
