/* Tell multiboot where our kernel code starts. */
ENTRY(start)

SECTIONS {
    /* We base our kernel at the 1M mark in memory. This is for a few reasons:
       - I think (TODO: verify) that the first megabyte is where the bootloader lives. Therefore,
         starting any earlier would interfere with bootloader operation. On QEMU, linking at
         1020K fails with "fatal: Trying to execute code outside RAM or ROM at 0x00000000000a0000".
       - We only identity map the first 2M, so sticking past there is a bad idea. Therefore, we want to
         map as early as possible. Starting at 1M gives us plenty of room.
       - It is good to be page (4K) aligned. */
    . = 1M;

    /* We put the multiboot header first so that it can be quickly and easily found by the bootloader. */
    .boot : {
        /* Since we garbage collect unused sections, the boot section would normally get destroyed,
           as it isn't referenced by anything. The KEEP here tells the linker that despite being
           seemingly unused, this section is still useful. */
        KEEP(*(.multiboot))
    }

    /* This is just here to make sure that the code comes after the multiboot header. */
    .text : {
        *(.text)
    }
}
