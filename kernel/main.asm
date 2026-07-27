[BITS 32]
global kernel_main

extern gdt_init
extern idt_init
extern pit_init
extern keyboard_init
extern paging_init
extern heap_init
extern gmfs_init
extern gmfs_create
extern vga_clear
extern vga_print
extern shell_start
extern gme_load_and_run

section .data
banner_init:    db "Inicializando Source Kernel GM (SKG)", 0x0A, 0
banner_corp:    db "GM Corporation (C)", 0x0A, 0
banner_rights:  db "Todos os direitos reservados.", 0x0A, 0x0A, 0

readme_filename: db "readme.txt", 0
readme_content:  db "Bem-vindo ao Source Kernel GM (SKG)! Arquivo lido com sucesso do GMFS.", 0

setup_filename:  db "setupsys.gme", 0

align 4
setup_binary_start:
    incbin "apps/setupsys.gme"
setup_binary_end:

section .text
kernel_main:
    ; 1. Inicializacao de Hardware
    call gdt_init
    call idt_init
    call pit_init
    call keyboard_init
    call paging_init
    call heap_init
    call gmfs_init

    ; 2. Registro dos Arquivos Iniciais no GMFS
    mov esi, readme_filename
    mov ebx, readme_content
    mov ecx, 70
    call gmfs_create

    mov esi, setup_filename
    mov ebx, setup_binary_start
    mov ecx, (setup_binary_end - setup_binary_start)
    call gmfs_create

    ; 3. Exibicao dos Cabecalhos
    call vga_clear

    mov esi, banner_init
    call vga_print

    mov esi, banner_corp
    call vga_print

    mov esi, banner_rights
    call vga_print

    ; 4. Executa o Instalador no Boot
    mov esi, setup_filename
    call gme_load_and_run

    ; 5. Transicao para a Shell Interativa
    call shell_start

.kernel_halt:
    cli
    hlt
    jmp .kernel_halt
