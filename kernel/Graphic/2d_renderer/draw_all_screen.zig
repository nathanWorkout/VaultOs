// Draw all the screen with 1 color

const limine = @import("../../limine.zig");
const fb = @import("../framebuffer.zig");

pub fn color_screen(cv: *const fb.Canvas, color: u32) void {
    const stride = cv.pitch / 4;
    const row: [*]volatile u32 = @ptrCast(@alignCast(cv.address));
    for (0..cv.height) |y| {
        for (0..cv.width) |x| {
            row[y * stride + x] = color;
        }
    }
}
