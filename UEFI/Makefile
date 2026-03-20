# ─────────────────────────────────────────────────────────────────────────────
# Makefile raíz — Bootloader UEFI + Juego
#
# Dependencias:
#   sudo apt install clang lld nasm qemu-system-x86 ovmf
#
# Uso:
#   make        → compila todo
#   make run    → lanza QEMU con bootloader + juego
#   make clean  → limpia artefactos
# ─────────────────────────────────────────────────────────────────────────────

CC      := clang
AS      := nasm
LD      := lld-link

ESP_DIR := esp/EFI/BOOT

# ── Flags bootloader (C) ──────────────────────────────────────────────────────
CFLAGS := \
    --target=x86_64-unknown-windows \
    -fno-stack-protector            \
    -fshort-wchar                   \
    -mno-red-zone                   \
    -ffreestanding                  \
    -O2

# ── Flags juego (ASM) ─────────────────────────────────────────────────────────
ASFLAGS := -f win64

# ── Flags linker (compartidos) ────────────────────────────────────────────────
LDFLAGS := \
    /subsystem:efi_application \
    /entry:efi_main            \
    /nodefaultlib

# ── OVMF ──────────────────────────────────────────────────────────────────────
OVMF := $(firstword \
    $(wildcard /usr/share/ovmf/OVMF.fd) \
    $(wildcard /usr/share/OVMF/OVMF.fd) \
    $(wildcard /usr/share/edk2/ovmf/OVMF.fd))

# ─────────────────────────────────────────────────────────────────────────────
.PHONY: all run clean check-deps

all: $(ESP_DIR)/BOOTX64.EFI $(ESP_DIR)/game.efi

# ── Compilar bootloader ───────────────────────────────────────────────────────
boot.o: boot.c
	$(CC) $(CFLAGS) -c -o $@ $<

boot.efi: boot.o
	$(LD) $(LDFLAGS) /out:$@ $<

# ── Compilar juego ────────────────────────────────────────────────────────────
game/game.o: game/game.asm
	$(AS) $(ASFLAGS) -o $@ $<

game/game.efi: game/game.o
	$(LD) $(LDFLAGS) /out:$@ $<

# ── Copiar al ESP ─────────────────────────────────────────────────────────────
$(ESP_DIR)/BOOTX64.EFI: boot.efi
	mkdir -p $(ESP_DIR)
	cp boot.efi $(ESP_DIR)/BOOTX64.EFI

$(ESP_DIR)/game.efi: game/game.efi
	mkdir -p $(ESP_DIR)
	cp game/game.efi $(ESP_DIR)/game.efi

# ── Ejecutar en QEMU ──────────────────────────────────────────────────────────
run: check-deps all
	qemu-system-x86_64                    \
	    -bios $(OVMF)                     \
	    -drive format=raw,file=fat:rw:esp \
	    -net none

# ── Verificar dependencias ────────────────────────────────────────────────────
check-deps:
	@which clang    > /dev/null 2>&1 || (echo "ERROR: clang no encontrado.  sudo apt install clang" && exit 1)
	@which lld-link > /dev/null 2>&1 || (echo "ERROR: lld-link no encontrado.  sudo apt install lld" && exit 1)
	@which nasm     > /dev/null 2>&1 || (echo "ERROR: nasm no encontrado.  sudo apt install nasm" && exit 1)
	@which qemu-system-x86_64 > /dev/null 2>&1 || (echo "ERROR: qemu no encontrado.  sudo apt install qemu-system-x86" && exit 1)
	@test -n "$(OVMF)" || (echo "ERROR: OVMF.fd no encontrado.  sudo apt install ovmf" && exit 1)
	@echo "✓ Dependencias OK"
	@echo "✓ OVMF: $(OVMF)"

# ── Limpiar ───────────────────────────────────────────────────────────────────
clean:
	rm -f boot.o boot.efi
	rm -f game/game.o game/game.efi
	rm -rf esp/