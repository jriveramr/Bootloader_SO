ASM     = nasm
QEMU    = qemu-system-i386
BOOT    = boot.asm
GAME    = game.asm
BOOT_BIN = boot.bin
GAME_BIN = game.bin
IMG     = disk.img

all: run

$(BOOT_BIN): $(BOOT)
	$(ASM) -f bin $(BOOT) -o $(BOOT_BIN)

$(GAME_BIN): $(GAME)
	$(ASM) -f bin $(GAME) -o $(GAME_BIN)

$(IMG): $(BOOT_BIN) $(GAME_BIN)
	dd if=/dev/zero    of=$(IMG) bs=512 count=2880
	dd if=$(BOOT_BIN)  of=$(IMG) bs=512 seek=0 conv=notrunc
	dd if=$(GAME_BIN)  of=$(IMG) bs=512 seek=1 conv=notrunc

run: $(IMG)
	$(QEMU) -fda $(IMG) -boot a

clean:
	rm -f *.bin *.img