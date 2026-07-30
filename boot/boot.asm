[BITS 32]

section .multiboot
align 4
    dd 0x1BADB002                 ; Magic Multiboot (GRUB)
    dd 0x00000004                 ; Flag 2 = Solicitacao de Framebuffer
    dd -(0x1BADB002 + 0x00000004) ; Checksum

    ; Offsets 12 a 31: Campos de endereco reservados (zerados)
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000

    ; Offsets 32 a 47: Configuracao Grafica (Console 1024x768 @ 32bpp)
    dd 0x00000000                 ; mode_type (0 = Linear Framebuffer)
    dd 1024                       ; Width
    dd 768                        ; Height
    dd 32                         ; Depth (32bpp)

section .text
global start
global _start
extern kernel_main

start:
_start:
    cli                           ; Desativa interrupcoes

    ; Preserva EAX e EBX em registradores seguros antes de mexer na memoria
    mov ecx, eax                  ; Salva o Magic Multiboot (0x2BADB002)
    mov edx, ebx                  ; Salva o ponteiro multiboot_info

    ; Seta registradores de segmento usando o seletor 0x18 (data descriptor do GRUB)
    mov ax, 0x18
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax                    ; Grava o seletor 0x18 em SS

    ; Configura a pilha em area segura
    mov esp, 0x90000
    mov ebp, esp

    ; Empilha os parametros limpos para o kernel_main
    push edx                      ; multiboot_info
    push ecx                      ; Magic Number
    call kernel_main

.hang:
    hlt
    jmp .hang