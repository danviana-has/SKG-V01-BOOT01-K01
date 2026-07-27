NASM = nasm
LD = ld
LDFLAGS = -m elf_i386 -T linker.ld

ASM_SRCS = boot/boot.asm \
           kernel/main.asm \
           kernel/gdt.asm \
           kernel/idt.asm \
           kernel/isr.asm \
           kernel/syscalls.asm \
           drivers/vga.asm \
           drivers/keyboard.asm \
           drivers/pit.asm \
           memory/paging.asm \
           memory/heap.asm \
           filesystem/gmfs.asm \
           loader/gme_loader.asm \
           shell/shell.asm

OBJS = $(ASM_SRCS:.asm=.o)

all: build/skg_flat.iso

# Compila o app diretamente como Flat Binary (sem cabeçalho ELF)
apps/setupsys.gme: apps/setupsys.asm
	mkdir -p apps
	$(NASM) -f bin apps/setupsys.asm -o apps/setupsys.gme

# Garantia de que apps/setupsys.gme existe antes de compilar main.asm
kernel/main.o: kernel/main.asm apps/setupsys.gme
	$(NASM) -f elf32 kernel/main.asm -o kernel/main.o

%.o: %.asm
	$(NASM) -f elf32 $< -o $@

kernel.gmb: apps/setupsys.gme $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

build/skg_flat.iso: kernel.gmb apps/setupsys.gme
	mkdir -p iso/boot/grub
	mkdir -p build
	cp kernel.gmb iso/boot/kernel.gmb
	cp apps/setupsys.gme iso/setupsys.gme
	grub-mkrescue -o build/skg_flat.iso iso

clean:
	rm -rf $(OBJS) kernel.gmb apps/*.o apps/*.gme iso/boot/kernel.gmb iso/setupsys.gme build/skg_flat.iso
