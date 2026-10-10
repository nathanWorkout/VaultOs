// serial port for debug

const io = @import("../io/io.zig");
const com1 = 0x3F8;

fn serial_init() void {
    io.outb(com1 + 1, 0x00); // stop interrupts
    io.outb(com1 + 3, 0x80); // enable dlab to access the baud rate
    io.outb(com1, 115200 / 38400); // UART frequency divider = 3 (38400 bauds)
    io.outb(com1 + 1, 0); // DLM register (Divisor Latch High) : write 0 (DLL = 3, DLM = 0)
    io.outb(com1 + 3, 0x03); // LCR (Line Control Register) : 8N1 format : start, data (8 bits), stop bit
}

fn serial_putchar(c: u8) void {
    // com1 + 5 = LSR register from UART
    // bit 5 = empty emission register
    // 0x20 = 32 in hexa or 00100000 (position of bit 5)
    while ((io.inb(com1 + 5) & 0x20) == 0) {} // wait until bit 5 is at 1
    io.outb(com1, c);
}

pub fn serial_print(str: []const u8) void {
    for (str) |c| {
        serial_putchar(c);
    }
}

pub fn serial_println(str: []const u8) void {
    serial_print(str);
    serial_print("\n");
}

pub fn serial_print_hex(n: u64) void {
    const hex = "0123456789ABCDEF";
    var value = n;
    var buffer: [18]u8 = undefined;

    buffer[0] = '0';
    buffer[1] = 'x';

    for (0..16) |i| {
        buffer[17 - i] = hex[@intCast(value & 0xF)];
        value >>= 4;
    }

    serial_print(&buffer);
}
