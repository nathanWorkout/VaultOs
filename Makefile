# Outils
CC  = x86_64-elf-gcc
AS  = nasm
LD  = x86_64-elf-ld
LDFLAGS = -m elf_x86_64 -T linker.ld -nostdlib

# Dossiers
KERNEL  = kernel
GEN     = build
OBJ     = $(GEN)/obj
BIN     = $(GEN)/bin
IMG_DIR = $(GEN)/img
ISO_DIR = $(GEN)/iso
ISO_ROOT = $(ISO_DIR)/root

# Fichiers générés
KERNEL_ELF = $(BIN)/kernel.elf
IMG        = $(IMG_DIR)/boot.img
ISO        = $(ISO_DIR)/VaultOS.iso

LIMINE ?= /usr/share/limine

# Flags compilateur
CFLAGS = \
    -m64                  \
    -mcmodel=kernel       \
    -mno-red-zone         \
    -mno-mmx              \
    -mno-sse              \
    -ffreestanding        \
    -fno-stack-protector  \
    -O0                   \
    -Wall -Wextra         \
    -I kernel             \
    -I kernel/idt         \
    -I kernel/tty         \
    -I kernel/serial      \
    -I kernel/pic         \
    -I kernel/io          \
    -I kernel/pit         \
    -I kernel/memory      \
    -I kernel/drivers     \
    -I kernel/drivers/keyboard \
    -I kernel/drivers/mouse \
    -I kernel/shell       \
    -I kernel/lib         \
    -I kernel/proc        \
    -I kernel/Graphic     \
    -I kernel/Graphic/core \
    -I kernel/Graphic/renderer \
    -I kernel/Graphic/ui  \
    -I kernel/Graphic/ui/wallpaper \
    -I kernel/VaultFs/

ASFLAGS = -f elf64

# Wallpaper (embarqué via objcopy)
WALLPAPER     = kernel/Graphic/ui/wallpaper/wallpaper.png
WALLPAPER_OBJ = $(OBJ)/wallpaper.o

# Sources
C_SRCS = \
    $(wildcard $(KERNEL)/*.c)                           \
    $(wildcard $(KERNEL)/idt/*.c)                       \
    $(wildcard $(KERNEL)/tty/*.c)                       \
    $(wildcard $(KERNEL)/serial/*.c)                    \
    $(wildcard $(KERNEL)/lib/*.c)                       \
    $(wildcard $(KERNEL)/pic/*.c)                       \
    $(wildcard $(KERNEL)/pit/*.c)                       \
    $(wildcard $(KERNEL)/memory/*.c)                    \
    $(wildcard $(KERNEL)/drivers/*.c)                   \
    $(wildcard $(KERNEL)/drivers/keyboard/*.c)          \
    $(wildcard $(KERNEL)/drivers/mouse/*.c)             \
    $(wildcard $(KERNEL)/shell/*.c)                     \
    $(wildcard $(KERNEL)/proc/*.c)                      \
    $(wildcard $(KERNEL)/Graphic/*.c)                   \
    $(wildcard $(KERNEL)/Graphic/core/*.c)              \
    $(wildcard $(KERNEL)/Graphic/renderer/*.c)          \
    $(wildcard $(KERNEL)/Graphic/ui/*.c)                \
    $(wildcard $(KERNEL)/Graphic/ui/wallpaper/*.c)      \
    $(wildcard $(KERNEL)/VaultFs/*.c)

ASM_SRCS = \
    $(filter-out $(KERNEL)/entry.asm, $(wildcard $(KERNEL)/*.asm)) \
    $(wildcard $(KERNEL)/idt/*.asm)   \
    $(wildcard $(KERNEL)/proc/*.asm)

# Objets : on garde l'arborescence de kernel/ dans boot/obj/
C_OBJS   = $(patsubst $(KERNEL)/%.c,   $(OBJ)/%.o, $(C_SRCS))
ASM_OBJS = $(patsubst $(KERNEL)/%.asm, $(OBJ)/%.o, $(ASM_SRCS))
ENTRY_OBJ = $(OBJ)/entry.o

# ------------------------------------------------------------
#  Kernel
# ------------------------------------------------------------
all: $(KERNEL_ELF)

$(KERNEL_ELF): $(ENTRY_OBJ) $(ASM_OBJS) $(C_OBJS) $(WALLPAPER_OBJ) linker.ld
	@mkdir -p $(@D)
	$(LD) $(LDFLAGS) -o $@ $(ENTRY_OBJ) $(ASM_OBJS) $(C_OBJS) $(WALLPAPER_OBJ)
	@echo "[OK] kernel.elf généré -> $@"

$(OBJ)/%.o: $(KERNEL)/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ)/%.o: $(KERNEL)/%.asm
	@mkdir -p $(@D)
	$(AS) $(ASFLAGS) $< -o $@

$(WALLPAPER_OBJ): $(WALLPAPER)
	@mkdir -p $(@D)
	objcopy -O elf64-x86-64 -B i386 -I binary $< $@

# ------------------------------------------------------------
#  Images disque (boot/img/boot.img)
# ------------------------------------------------------------
img: img-uefi img-bios

img-uefi: $(KERNEL_ELF)
	@mkdir -p $(IMG_DIR)
	dd if=/dev/zero of=$(IMG) bs=512 count=524288
	printf '\x00\x00\x02\x00\xef\xfe\xff\xff\x00\x08\x00\x00\x00\xf8\x07\x00' | dd of=$(IMG) bs=1 seek=446 conv=notrunc
	printf '\x55\xaa' | dd of=$(IMG) bs=1 seek=510 conv=notrunc
	mformat -i $(IMG)@@1M -F -v VAULTOS ::
	mmd -i $(IMG)@@1M ::/EFI
	mmd -i $(IMG)@@1M ::/EFI/BOOT
	mmd -i $(IMG)@@1M ::/boot
	mcopy -i $(IMG)@@1M $(LIMINE)/BOOTX64.EFI ::/EFI/BOOT/BOOTX64.EFI
	mcopy -i $(IMG)@@1M $(KERNEL_ELF) ::/boot/kernel.elf
	mcopy -i $(IMG)@@1M limine.conf ::/boot/limine.conf
	limine enroll-config $(IMG) $(shell b2sum limine.conf | awk '{print $$1}' | tr -d '\n')
	@echo "[OK] Image UEFI générée -> $(IMG)"

img-bios: $(KERNEL_ELF)
	@mkdir -p $(IMG_DIR)
	dd if=/dev/zero of=$(IMG) bs=512 count=524288
	printf '\x00\x00\x02\x00\xef\xfe\xff\xff\x00\x08\x00\x00\x00\xf8\x07\x00' | dd of=$(IMG) bs=1 seek=446 conv=notrunc
	printf '\x55\xaa' | dd of=$(IMG) bs=1 seek=510 conv=notrunc
	mformat -i $(IMG)@@1M -F -v VAULTOS ::
	mmd -i $(IMG)@@1M ::/boot
	mcopy -i $(IMG)@@1M $(LIMINE)/limine-bios.sys ::/boot/limine-bios.sys
	mcopy -i $(IMG)@@1M $(KERNEL_ELF) ::/boot/kernel.elf
	mcopy -i $(IMG)@@1M limine.conf ::/boot/limine.conf
	limine bios-install $(IMG)
	@echo "[OK] Image BIOS générée -> $(IMG)"

img-dual: $(KERNEL_ELF)
	@mkdir -p $(IMG_DIR)
	dd if=/dev/zero of=$(IMG) bs=512 count=524288
	printf '\x00\x00\x02\x00\xef\xfe\xff\xff\x00\x08\x00\x00\x00\xf8\x07\x00' | dd of=$(IMG) bs=1 seek=446 conv=notrunc
	printf '\x55\xaa' | dd of=$(IMG) bs=1 seek=510 conv=notrunc
	mformat -i $(IMG)@@1M -F -v VAULTOS ::
	mmd -i $(IMG)@@1M ::/EFI
	mmd -i $(IMG)@@1M ::/EFI/BOOT
	mmd -i $(IMG)@@1M ::/boot
	mcopy -i $(IMG)@@1M $(LIMINE)/BOOTX64.EFI ::/EFI/BOOT/BOOTX64.EFI
	mcopy -i $(IMG)@@1M $(LIMINE)/limine-bios.sys ::/boot/limine-bios.sys
	mcopy -i $(IMG)@@1M $(KERNEL_ELF) ::/boot/kernel.elf
	mcopy -i $(IMG)@@1M limine.conf ::/boot/limine.conf
	limine bios-install $(IMG)
	limine enroll-config $(IMG) $(shell b2sum limine.conf | awk '{print $$1}' | tr -d '\n')
	@echo "[OK] Image dual BIOS+UEFI générée -> $(IMG)"

# ------------------------------------------------------------
#  ISO (boot/iso/VaultOS.iso) - BIOS + UEFI
#  Nécessite : xorriso, limine
# ------------------------------------------------------------
iso: $(ISO)

$(ISO): $(KERNEL_ELF) limine.conf
	@rm -rf $(ISO_ROOT)
	@mkdir -p $(ISO_ROOT)/boot $(ISO_ROOT)/EFI/BOOT
	cp $(KERNEL_ELF)                    $(ISO_ROOT)/boot/kernel.elf
	cp limine.conf                      $(ISO_ROOT)/boot/limine.conf
	cp $(LIMINE)/limine-bios.sys        $(ISO_ROOT)/boot/
	cp $(LIMINE)/limine-bios-cd.bin     $(ISO_ROOT)/boot/
	cp $(LIMINE)/BOOTX64.EFI            $(ISO_ROOT)/EFI/BOOT/
	@# les fichiers du store Nix sont en lecture seule : on les rend modifiables
	chmod -R u+w $(ISO_ROOT)
	limine enroll-config $(ISO_ROOT)/EFI/BOOT/BOOTX64.EFI $(shell b2sum limine.conf | awk '{print $$1}' | tr -d '\n')
	@# image FAT El Torito pour le boot UEFI (limine-uefi-cd.bin n'existe plus dans les Limine récents)
	dd if=/dev/zero of=$(ISO_ROOT)/boot/efiboot.img bs=1M count=8
	mformat -i $(ISO_ROOT)/boot/efiboot.img ::
	mmd -i $(ISO_ROOT)/boot/efiboot.img ::/EFI
	mmd -i $(ISO_ROOT)/boot/efiboot.img ::/EFI/BOOT
	mcopy -i $(ISO_ROOT)/boot/efiboot.img $(ISO_ROOT)/EFI/BOOT/BOOTX64.EFI ::/EFI/BOOT/BOOTX64.EFI
	xorriso -as mkisofs -R -r -J \
	    -b boot/limine-bios-cd.bin \
	    -no-emul-boot -boot-load-size 4 -boot-info-table \
	    -hfsplus -apm-block-size 2048 \
	    --efi-boot boot/efiboot.img \
	    -efi-boot-part --efi-boot-image --protective-msdos-label \
	    $(ISO_ROOT) -o $(ISO)
	limine bios-install $(ISO)
	@echo "[OK] ISO générée -> $(ISO)"

# ------------------------------------------------------------
#  Exécution / outils
# ------------------------------------------------------------
usb: img-dual
	@echo "[!] Écriture de $(IMG) sur /dev/sda dans 3s... (Ctrl+C pour annuler)"
	@sleep 3
	sudo dd if=$(IMG) of=/dev/sda bs=4M status=progress
	sync
	@echo "[OK] Clé USB prête"

OVMF_CODE ?= /usr/share/edk2/x64/OVMF_CODE.4m.fd
OVMF_VARS ?= OVMF_VARS.fd

run: img-dual
	qemu-system-x86_64 \
	    -drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
	    -drive if=pflash,format=raw,file=$(OVMF_VARS) \
	    -drive format=raw,file=$(IMG),index=0,media=disk \
	    -serial stdio \
	    -m 256M \
	    -display sdl

run-bios: img-dual
	qemu-system-x86_64 \
	    -drive format=raw,file=$(IMG),index=0,media=disk \
	    -serial stdio \
	    -m 256M \
	    -display sdl

run-iso: iso
	qemu-system-x86_64 \
	    -drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
	    -drive if=pflash,format=raw,file=$(OVMF_VARS) \
	    -cdrom $(ISO) \
	    -serial stdio \
	    -m 256M \
	    -display sdl

debug: img-dual
	qemu-system-x86_64 \
	    -drive format=raw,file=$(IMG),index=0,media=disk \
	    -serial stdio \
	    -m 128M \
	    -s -S -display gtk

clean:
	rm -rf $(OBJ) $(BIN) $(IMG_DIR) $(ISO_DIR)

.PHONY: all img img-uefi img-bios img-dual iso run run-bios run-iso debug clean usb full

full: clean img run