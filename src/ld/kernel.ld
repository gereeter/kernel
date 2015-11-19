ENTRY(start)

SECTIONS {
    . = 1M;

    .boot : {
        KEEP(*(.multiboot))
    }

    .text : {
        *(.text)
    }
}
