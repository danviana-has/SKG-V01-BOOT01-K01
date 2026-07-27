; ==============================================================================
; Source Kernel GM (SKG) - Header de Especificação Multiboot v1
; Desenvolvido em Assembly x86 (NASM) para boot direto via GRUB
; ==============================================================================

MULTIBOOT_HEADER_MAGIC     equ 0x1BADB002
MULTIBOOT_HEADER_FLAGS     equ 0x00000003 ; ALIGN | MEMINFO
MULTIBOOT_CHECKSUM         equ -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)

; Estrutura de informações passadas pelo GRUB no registrador EBX
struc MultibootInfo
    .flags:        resd 1
    .mem_lower:    resd 1
    .mem_upper:    resd 1
    .boot_device:  resd 1
    .cmdline:      resd 1
    .mods_count:   resd 1
    .mods_addr:    resd 1
    .syms:         resd 4
    .mmap_length:  resd 1
    .mmap_addr:    resd 1
endstruc
