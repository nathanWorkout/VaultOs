// functions for memory

export fn memcpy(dest: [*]u8, src: [*]const u8, size: usize) callconv(.c) void {
    var i: usize = 0;
    while (i < size) : (i += 1) {
        dest[i] = src[i];
    }
}

export fn memset(dest: [*]u8, c: u8, size: usize) callconv(.c) void {
    var i: usize = 0;
    while (i < size) : (i += 1) {
        dest[i] = c;
    }
}

export fn memmove(dest: [*]u8, src: [*]const u8, size: usize) callconv(.c) [*]u8 {
    if (@intFromPtr(dest) < @intFromPtr(src)) {
        var i: usize = 0;
        while (i < size) : (i += 1) {
            dest[i] = src[i];
        }
    } else {
        var i: usize = size;
        while (i > 0) {
            i -= 1;
            dest[i] = src[i];
        }
    }
    return dest;
}
