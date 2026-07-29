CC = gcc
AS = nasm
LD = ld

CFLAGS = -m32 -ffreestanding -fno-pie -fno-stack-protector -nostdlib
ASFLAGS = -f elf32
LDFLAGS = -m elf_i386 -T linker.ld

OBJS = boot/boot.o \
       kernel/main.o \
       kernel/gdt.o \
       kernel/idt.o \
       drivers/mouse.o \
       drivers/vbe.o \
       drivers/bmp.o

ISO_FILE = SKG.iso

all: syskernelapp.gmk iso

syskernelapp.gmk: $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

%.o: %.asm
	$(AS) $(ASFLAGS) $< -o $@

iso: syskernelapp.gmk
	@echo "Atualizando diretorio ISO..."
	cp syskernelapp.gmk iso/boot/syskernelapp.gmk
	@echo "Gerando nova imagem bootavel com GRUB..."
	grub-mkrescue -o $(ISO_FILE) iso

clean:
	rm -rf boot/*.o kernel/*.o drivers/*.o syskernelapp.gmk