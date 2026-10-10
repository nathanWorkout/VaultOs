const limine = @import("../limine.zig");
const requests = @import("../requests.zig");

pub const Canvas = struct {
    address: *anyopaque,
    width: u64,
    height: u64,
    pitch: u64,
};

pub fn fb_get_canvas() ?Canvas {
    const resp = requests.fb_request.response orelse return null;
    const fb = resp.framebuffers[0];
    return .{
        .address = fb.address,
        .width = fb.width,
        .height = fb.height,
        .pitch = fb.pitch,
    };
}
