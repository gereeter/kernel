use core::marker::PhantomData;

use typenum::uint::Unsigned;

pub struct Port<Id: Unsigned> {
    _marker: PhantomData<Id>
}

impl<Id: Unsigned> Port<Id> {
    pub unsafe fn get() -> Port<Id> {
        Port { _marker: PhantomData }
    }

    #[inline(always)]
    pub unsafe fn read_u8(&mut self) -> u8 {
        let value: u8;
        asm!("inb $1, $0" : "={al}"(value) : "i"(Id::to_u16()) : : "volatile");
        value
    }

    #[inline(always)]
    pub unsafe fn write_u8(&mut self, value: u8) {
        asm!("outb $0, $1" : : "{al}"(value), "i"(Id::to_u16()) : : "volatile");
    }
}
