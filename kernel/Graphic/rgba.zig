// rgb and rgba colors

pub fn rgba(r: u8, g: u8, b: u8, a: u8) u32 {
    return (@as(u32, a) << 24) | (@as(u32, r) << 16) | (@as(u32, g) << 8) | @as(u32, b);
}

pub fn rgb(r: u8, g: u8, b: u8) u32 {
    return rgba(r, g, b, 0xFF);
}
