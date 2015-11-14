#![feature(asm, core_intrinsics, lang_items, no_std)]

#![no_std]

use core::intrinsics;

fn halt() -> ! {
    unsafe {
        asm!("hlt");
        intrinsics::unreachable();
    }
}

#[no_mangle]
pub extern "C" fn start64() -> ! {
    halt()
}


#[lang = "eh_personality"]
fn eh_personality() { }

#[lang = "panic_fmt"]
fn panic_fmt() -> ! {
    halt()
}
