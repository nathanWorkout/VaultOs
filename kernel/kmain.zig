const gfx = @import("../kernel/Graphic/2d_renderer/imports_gfx.zig");
const colors = @import("../kernel/Graphic/rgba.zig");
const fb = @import("Graphic/framebuffer.zig");
const debug = @import("serial/com1.zig");

export fn kmain() void {
    comptime {
        _ = @import("libc/memory.zig");
    }
    // const cv = gfx.framebuffer.fb_get_canvas();
    // gfx.draw_all_screen.color_screen(&cv, colors.rgb(255, 0, 255));

    debug.serial_print("Hello, World !");
    debug.serial_print_hex(0xDEADBEEF);
    while (true) {
        asm volatile ("hlt");
    }
}
