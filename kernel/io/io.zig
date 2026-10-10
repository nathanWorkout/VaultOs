// in/out ports for com1, apic...

pub extern fn outb(port: u16, val: u8) void;
pub extern fn inb(port: u16) u8;
