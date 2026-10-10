const gfx = @import("Graphic/2d_renderer/imports_gfx.zig");
const colors = @import("Graphic/rgba.zig");
const debug = @import("serial/com1.zig");

export fn kmain() void {
    comptime {
        _ = @import("libc/memory.zig");
    }

    if (gfx.framebuffer.fb_get_canvas()) |canvas| {
        gfx.draw_all_screen.color_screen(&canvas, colors.rgb(255, 0, 255));
    }

    debug.serial_println("Hello, World !");
    while (true) {
        asm volatile ("hlt");
    }
}
