use core::mem;
use typenum::consts;
use typenum::uint::Unsigned;

use port::Port;

struct Pic<DataId: Unsigned, ControlId: Unsigned> {
    data: Port<DataId>,
    control: Port<ControlId>
}

pub struct ChainedPics {
    master: Pic<consts::U32, consts::U33>, // 0x20 and 0x21
    slave: Pic<consts::U160, consts::U161> // 0xa0 and 0xa1
}

impl ChainedPics {
    pub unsafe fn get() -> ChainedPics {
        ChainedPics {
            master: Pic {
                data: Port::get(),
                control: Port::get()
            },
            slave: Pic {
                data: Port::get(),
                control: Port::get()
            }
        }
    }

    pub fn remap(&mut self, offset: u8) {
        unsafe {
            fn wait() {
                unsafe {
                    Port::<consts::U128>::get().write_u8(mem::uninitialized());
                }
            }

            let mask_master = self.master.data.read_u8();
            let mask_slave = self.slave.data.read_u8();

            self.master.control.write_u8(0x11);
            wait();
            self.slave.control.write_u8(0x11);
            wait();

            self.master.data.write_u8(offset);
            wait();
            self.slave.data.write_u8(offset + 8);
            wait();

            self.master.data.write_u8(4);
            wait();
            self.slave.data.write_u8(2);
            wait();

            self.master.data.write_u8(1);
            wait();
            self.slave.data.write_u8(1);
            wait();

            self.master.data.write_u8(mask_master);
            self.slave.data.write_u8(mask_slave);
        }
    }
}
