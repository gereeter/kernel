#![allow(non_upper_case_globals)]

#[repr(packed)]
pub struct DtPointer {
    _size: u16,
    _table: &'static [u64; 3]
}

pub static gdt: [u64; 3] = [
    // All GDTs must start with a null entry
    0,
    // The code segment (readable + executable + is a data or code segment + present + is a 64-bit code segment)
    1<<41 | 1<<43 | 1<<44 | 1<<47 | 1<<53,
    // The data segment (writeable + is a data or code segment + present)
    1<<41 | 1<<44 | 1<<47
];

#[no_mangle]
pub static gdt_pointer: DtPointer = DtPointer {
    _size: 3 * 8,
    _table: &gdt
};
