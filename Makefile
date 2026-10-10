ZIG       = zig
AS        = nasm
BUILD     = build
KERNEL    = kernel
IMG       = boot.img
LIMINE    ?= /usr/share/limine
OVMF_CODE ?= /usr/share/edk2/x64/OVMF_CODE.fd
OVMF_VARS ?= OVMF_VARS.fd

ASM_SRCS = $(KERNEL)/entry.asm $(KERNEL)/io/io.asm
ASM_OBJS = $(BUILD)/entry.o $(BUILD)/io.o

all: $(BUILD)/kernel.elf

$(BUILD)/entry.o: $(KERNEL)/entry.asm
	mkdir -p $(BUILD)
	$(AS) -f elf64 $< -o $@

$(BUILD)/io.o: $(KERNEL)/io/io.asm
	mkdir -p $(BUILD)
	$(AS) -f elf64 $< -o $@

$(BUILD)/main.o: $(KERNEL)/kmain.zig
	mkdir -p $(BUILD)
	$(ZIG) build-obj $< \
	    -target x86_64-freestanding-none \
	    -O Debug \
	    -mno-red-zone \
	    -femit-bin=$@

$(BUILD)/kernel.elf: $(ASM_OBJS) $(BUILD)/main.o $(KERNEL)/linker.ld
	x86_64-elf-ld -m elf_x86_64 -T $(KERNEL)/linker.ld -nostdlib \
	    -o $@ $(ASM_OBJS) $(BUILD)/main.o

img: $(BUILD)/kernel.elf
	dd if=/dev/zero of=$(IMG) bs=512 count=524288
	printf '\x00\x00\x02\x00\xef\xfe\xff\xff\x00\x08\x00\x00\x00\xf8\x07\x00' | dd of=$(IMG) bs=1 seek=446 conv=notrunc
	printf '\x55\xaa' | dd of=$(IMG) bs=1 seek=510 conv=notrunc
	mformat -i $(IMG)@@1M -F -v VAULTOS ::
	mmd -i $(IMG)@@1M ::/EFI
	mmd -i $(IMG)@@1M ::/EFI/BOOT
	mmd -i $(IMG)@@1M ::/boot
	mcopy -i $(IMG)@@1M $(LIMINE)/BOOTX64.EFI ::/EFI/BOOT/BOOTX64.EFI
	mcopy -i $(IMG)@@1M $(BUILD)/kernel.elf ::/boot/kernel.elf
	mcopy -i $(IMG)@@1M limine.conf ::/boot/limine.conf
	limine enroll-config $(IMG) $(shell b2sum limine.conf | awk '{print $$1}' | tr -d '\n')

run: $(IMG)
	qemu-system-x86_64 \
	    -drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
	    -drive if=pflash,format=raw,file=$(OVMF_VARS) \
	    -drive format=raw,file=$(IMG),index=0,media=disk \
	    -serial stdio \
	    -m 256M \
	    -display sdl

clean:
	rm -f $(BUILD)/*.o $(BUILD)/*.elf $(IMG)

full: clean all img run

.PHONY: all img run clean full
