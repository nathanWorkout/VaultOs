// get the canvas from framebuffer

const limine = @import("../limine.zig");
pub export var fb_request: limine.LIMINE_FRAMEBUFFER_REQUEST = .{};

pub const Canvas = struct {
    address: *anyopaque,
    width: u64,
    height: u64,
    pitch: u64,
};

pub fn fb_get_canvas() Canvas {
    const fb = fb_request.response.?.framebuffers[0];
    return Canvas{
        .address = fb.address,
        .width = fb.width,
        .height = fb.height,
        .pitch = fb.pitch,
    };
}
