# ─────────────────────────────────────────────────────────────────────────────
# game/Makefile — Compila game.asm → game.efi para pruebas independientes
#
# Para probar sin el bootloader:
#   make run   → copia game.efi como BOOTX64.EFI y lanza QEMU
# ─────────────────────────────────────────────────────────────────────────────

AS      := nasm
LD      := lld-link

TARGET  := game.efi
ESP_DIR := esp/EFI/BOOT

ASFLAGS := -f win64                 # formato PE/COFF de 64 bits

LDFLAGS := \
    /subsystem:efi_application      \
    /entry:efi_main                 \
    /nodefaultlib

OVMF := $(firstword \
    $(wildcard /usr/share/ovmf/OVMF.fd) \
    $(wildcard /usr/share/OVMF/OVMF.fd) \
    $(wildcard /usr/share/edk2/ovmf/OVMF.fd))

.PHONY: all run clean check-deps

all: $(TARGET)

game.o: game.asm
	$(AS) $(ASFLAGS) -o $@ $<

$(TARGET): game.o
	$(LD) $(LDFLAGS) /out:$@ $<

$(ESP_DIR)/BOOTX64.EFI: $(TARGET)
	mkdir -p $(ESP_DIR)
	cp $(TARGET) $(ESP_DIR)/BOOTX64.EFI

#run: check-deps $(ESP_DIR)/BOOTX64.EFI
#	qemu-system-x86_64              \
#	    -bios $(OVMF)               \
#	    -drive format=raw,file=fat:rw:esp \
#	    -net none                   \
#	    -nographic
# Alternativa con ventana gráfica (descomentar y comentar la anterior):
run: check-deps $(ESP_DIR)/BOOTX64.EFI
	qemu-system-x86_64                     \
		-bios $(OVMF)                      \
		-drive format=raw,file=fat:rw:esp  \
		-net none

check-deps:
	@which nasm > /dev/null 2>&1 || (echo "ERROR: nasm no encontrado. Instalar: sudo apt install nasm" && exit 1)
	@which lld-link > /dev/null 2>&1 || (echo "ERROR: lld-link no encontrado." && exit 1)
	@test -n "$(OVMF)" || (echo "ERROR: OVMF.fd no encontrado." && exit 1)
	@echo "✓ Dependencias OK"

clean:
	rm -f game.o $(TARGET)
	rm -rf esp/