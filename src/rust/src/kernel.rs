#![feature(asm, core_intrinsics, core_slice_ext, lang_items, no_std)]

#![no_std]

extern crate rlibc;

use core::intrinsics;

fn halt() -> ! {
    unsafe {
        asm!("hlt");
        intrinsics::unreachable();
    }
}

fn write_str(message: &[u8], color: u8) {
    let mut screen = 0xb8000 as *mut u16;
    for (index, &char) in message.iter().enumerate() {
        unsafe {
            *screen.offset(index as isize) = (color as u16) << 8 | char as u16;
        }
    }
}

#[no_mangle]
pub extern "C" fn start64() -> ! {
    write_str(b"Hello, world!", 0x0b);
    halt()
}


#[lang = "eh_personality"]
fn eh_personality() { }

#[lang = "eh_unwind_resume"]
fn eh_unwind_resume() -> ! {
    halt()
}

#[lang = "panic_fmt"]
fn panic_fmt() -> ! {
    halt()
}