pub const LIMINE_COMMON_MAGIC = [2]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b };

// Framebuffer
pub const LIMINE_FRAMEBUFFER_RGB: u8 = 1;

pub const limine_video_mode = extern struct {
    pitch: u64, // byte number per line
    width: u64,
    height: u64,
    bpp: u16, // byte per pixel
    memory_model: u8,
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
};

pub const limine_framebuffer = extern struct {
    address: *anyopaque,
    width: u64,
    height: u64,
    pitch: u64,
    bpp: u16,
    memory_model: u8,
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
    unused: [7]u8,
    edid_size: u64,
    edid: *anyopaque,
    mode_count: u64,
    modes: [*]*limine_video_mode,
};

pub const limine_framebuffer_response = extern struct {
    revision: u64,
    framebuffer_count: u64,
    framebuffers: [*]*limine_framebuffer,
};

pub const LIMINE_FRAMEBUFFER_REQUEST = extern struct {
    id: [4]u64 = .{
        LIMINE_COMMON_MAGIC[0],
        LIMINE_COMMON_MAGIC[1],
        0x9d5827dcd881dd75,
        0xa3148604f6fab11b,
    },
    revision: u64 = 0,
    response: ?*limine_framebuffer_response = null,
};
