[BITS 32]
section .multiboot
align 4
    dd 0x1BADB002               ; Magic
    dd 0x00000000               ; Flags (Modo Texto VGA 80x25)
    dd -(0x1BADB002 + 0x00000000) ; Checksum

section .text
global start
global _start
extern kernel_main

start:
_start:
    push ebx                    ; Multiboot Struct Pointer
    push eax                    ; Magic Multiboot
    call kernel_main
    cli
.hang:
    hlt
    jmp .hang
