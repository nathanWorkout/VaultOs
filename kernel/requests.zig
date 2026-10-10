// requests from limine bootloader

const limine = @import("limine.zig");

pub export var requests_start: [4]u64 linksection(".limine_requests_start") = limine.LIMINE_REQUESTS_START_MARKER;
pub export var base_revision: limine.LIMINE_BASE_REVISION linksection(".limine_requests") = .{};
pub export var fb_request: limine.LIMINE_FRAMEBUFFER_REQUEST linksection(".limine_requests") = .{};
pub export var stack_request: limine.LIMINE_STACK_SIZE_REQUEST linksection(".limine_requests") = .{};
pub export var requests_end: [2]u64 linksection(".limine_requests_end") = limine.LIMINE_REQUESTS_END_MARKER;
