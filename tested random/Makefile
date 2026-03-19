ASM=nasm
QEMU=qemu-system-x86_64

all: boot.bin

boot.bin: boot.asm random.asm
	$(ASM) -f bin boot.asm -o boot.bin

run: boot.bin
	$(QEMU) -fda boot.bin

clean:
	rm -f *.bin