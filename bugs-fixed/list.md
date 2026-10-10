## Framebuffer : Triple fault on `fb_get_canvas` call

Even replacing the body of `fb_get_canvas` with `return null` caused a triple fault.

### Cause

Zig/LLVM even in debug mode uses SSE instructions to copy structs.
Limine resets CR4 before jumping to the kernel, so SSE was disabled.
The CPU raised `#UD` on the first XMM instruction → triple fault.

### Fix

Activate SSE in `entry.asm` before calling `kmain`.
