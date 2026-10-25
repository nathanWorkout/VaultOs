#include "mouse.h"
#include "io.h"
#include "pic8089.h"
#include "framebuffer.h"
#include "../../serial/com1.h"
#include <stdint.h>

static MouseState state;
static uint8_t packet[3];
static uint8_t packet_idx = 0;

// we wait for the input buffer to be empty (at 0)
static void ps2_wait_write() {
    while (inb(PS2_STATUS) & 0x02);
}

// as long as the buffer is filled (to 1) we can read the data
static void ps2_wait_read() {
    while (!(inb(PS2_STATUS) & 0x01));
}


static void ps2_send_cmd(uint8_t cmd) {
    ps2_wait_write();
    outb(PS2_CMD, cmd);
}

static void ps2_send_data(uint8_t data) {
    ps2_wait_write();
    outb(PS2_DATA, data);
}

static uint8_t ps2_read() {
    ps2_wait_read();
    return inb(PS2_DATA);
}

static void ps2_flush() {
    int timeout = 1000;
    while ((inb(PS2_STATUS) & 0x01) && timeout--) {
        inb(PS2_DATA);
    }
}

void mouse_init(void) {
    serial_println("[MOUSE] init start");
    Canvas cv = fb_get_canvas();

    state.x = cv.width / 2;
    state.y = cv.height / 2;
    state.x_min = 0;
    state.y_min = 0;
    state.x_max = (int32_t)cv.width - 1;
    state.y_max = (int32_t)cv.height - 1;
    state.left = state.right = state.middle = 0;
    packet_idx = 0;

    __asm__ volatile ("cli");

    ps2_send_cmd(0xAD); // désactive le clavier pendant la config
    ps2_flush();

    ps2_send_cmd(0xA8); // active le port souris

    ps2_send_cmd(0x20);
    uint8_t config = ps2_read();
    serial_print("[MOUSE] config byte : 0x");
    serial_print_hex(config);                      
    serial_print("\n");

    config |= 0x02; // IRQ12 on
    config &= ~0x20; // horloge souris on
    ps2_send_cmd(0x60);
    ps2_send_data(config);

    ps2_send_cmd(0xD4);
    ps2_send_data(0xF4);
    uint8_t ack = ps2_read();

    ps2_send_cmd(0xAE);                 // réactive le clavier
    ps2_flush();

    pic_clear_mask(2);       
    pic_clear_mask(12);

    __asm__ volatile ("sti");
    serial_println("[MOUSE] init done");
}

void mouse_irq_handler() {
    while ((inb(PS2_STATUS) & 0x21) == 0x21) {
        packet[packet_idx++] = inb(PS2_DATA);
        if (packet_idx < 3) continue;
        packet_idx = 0;

        if (!(packet[0] & 0x08)) continue;

        state.left   = packet[0] & 1;
        state.right  = (packet[0] >> 1) & 1;
        state.middle = (packet[0] >> 2) & 1;

        int32_t dx = (int32_t)packet[1] - ((packet[0] & 0x10) ? 256 : 0);
        int32_t dy = (int32_t)packet[2] - ((packet[0] & 0x20) ? 256 : 0);

        state.x += dx;
        state.y -= dy;

        if (state.x < state.x_min) state.x = state.x_min;
        if (state.x > state.x_max) state.x = state.x_max;
        if (state.y < state.y_min) state.y = state.y_min;
        if (state.y > state.y_max) state.y = state.y_max;
    }
}

MouseState *mouse_get_state() {
    return &state;
}