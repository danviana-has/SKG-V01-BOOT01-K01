; ==============================================================================
; Source Kernel GM (SKG) - Sistema de Paginação Real de Dois Níveis (CR3/CR0)
; ==============================================================================
[BITS 32]
global paging_init

section .bss
align 4096
page_directory:   resb 4096     ; Diretório de Páginas (1024 entradas * 4 bytes)
first_page_table: resb 4096     ; Tabela para mapear os primeiros 4MB de RAM

section .text
paging_init:
    pusha
    ; Zera o Page Directory
    mov edi, page_directory
    mov ecx, 1024
    xor eax, eax
    rep stosd

    ; Preenche a primeira Page Table com Mapeamento Direto (Identity Mapping)
    ; Mapeia 0x00000000 até 0x003FFFFF (4 MB)
    mov edi, first_page_table
    mov eax, 0x00000003         ; Flag 0x03 = Page Present + Read/Write (Supervisor)
    mov ecx, 1024

.map_pt_loop:
    mov [edi], eax
    add eax, 4096
    add edi, 4
    loop .map_pt_loop

    ; Associa a primeira Page Table ao Diretório
    mov eax, first_page_table
    or eax, 0x00000003
    mov [page_directory], eax

    ; Carrega o endereço do Page Directory no Registrador Control Register 3 (CR3)
    mov eax, page_directory
    mov cr3, eax

    ; Ativa o Bit de Paginação (Bit 31) no CR0
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    popa
    ret
