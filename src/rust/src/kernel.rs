#![feature(asm, core_slice_ext, lang_items, no_std)]

#![no_std]

extern crate rlibc;
extern crate typenum;

mod port;
pub mod gdt;

#[inline(always)]
fn halt() {
    unsafe {
        asm!("hlt"::::"volatile");
    }
}

fn write_str(message: &[u8], color: u8) {
    let screen = 0xb8000 as *mut u16;
    for (index, &char) in message.iter().enumerate() {
        unsafe {
            *screen.offset(index as isize) = (color as u16) << 8 | char as u16;
        }
    }
}

#[no_mangle]
pub extern "C" fn start64() -> ! {
    write_str(b"Hello, world!", 0x0b);
    loop { halt() }
}


#[lang = "eh_personality"]
fn eh_personality() { }

#[lang = "eh_unwind_resume"]
fn eh_unwind_resume() -> ! {
    loop { halt() }
}

#[lang = "panic_fmt"]
fn panic_fmt() -> ! {
    loop { halt() }
}
