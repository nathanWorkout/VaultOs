export fn kmain() void {
    while (true) {
        asm volatile ("hlt");
    }
}
