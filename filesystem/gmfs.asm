[BITS 32]
global gmfs_init
global gmfs_create
global gmfs_list
global gmfs_read

extern vga_print
extern vga_putc

section .bss
; Estrutura da Tabela de Arquivos do GMFS (Maximo 16 Arquivos)
; Cada entrada: 32 bytes Nome | 4 bytes Endereco | 4 bytes Tamanho = 40 bytes
gmfs_table:     resb 640
gmfs_count:     resd 1

section .data
gmfs_header:    db "--- Arquivos no GMFS ---", 0x0A, 0
gmfs_empty:     db "(Nenhum arquivo encontrado)", 0x0A, 0
gmfs_sep:       db " - ", 0
gmfs_bytes:     db " B", 0x0A, 0

section .text
gmfs_init:
    mov dword [gmfs_count], 0
    mov edi, gmfs_table
    mov ecx, 640 / 4
    xor eax, eax
    rep stosd
    ret

gmfs_create:
    pusha
    mov eax, [gmfs_count]
    cmp eax, 16
    jae .create_done

    imul eax, 40
    mov edi, gmfs_table
    add edi, eax

    ; Copia Nome do Arquivo (32 bytes max)
    mov ecx, 0
.copy_name:
    mov al, [esi + ecx]
    mov [edi + ecx], al
    inc ecx
    cmp ecx, 31
    jae .pad_name
    test al, al
    jnz .copy_name

.pad_name:
    mov byte [edi + ecx], 0

    ; Salva Ponteiro do Binario e Tamanho
    mov [edi + 32], edi          ; Salva o apontador do buffer de dados
    mov [edi + 32], ebx          ; ebx = Endereco inicial dos dados
    mov [edi + 36], ecx          ; ecx = Tamanho original em bytes

.create_done:
    inc dword [gmfs_count]
    popa
    ret

gmfs_list:
    pusha
    mov ecx, [gmfs_count]
    test ecx, ecx
    jz .list_empty

    mov esi, gmfs_table
.list_loop:
    push ecx
    push esi
    
    ; Imprime Nome
    call vga_print

    mov esi, gmfs_sep
    call vga_print

    ; Imprime Tamanho (offset +36)
    pop esi
    push esi
    mov eax, [esi + 36]
    call print_dec_num

    mov esi, gmfs_bytes
    call vga_print

    pop esi
    pop ecx
    add esi, 40
    loop .list_loop
    popa
    ret

.list_empty:
    mov esi, gmfs_empty
    call vga_print
    popa
    ret

gmfs_read:
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov ecx, [gmfs_count]
    test ecx, ecx
    jz .read_fail

    mov edi, gmfs_table

.search_loop:
    push ecx
    push esi
    push edi

.cmp_name:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne .next_file
    test al, al
    jz .found
    inc esi
    inc edi
    jmp .cmp_name

.next_file:
    pop edi
    pop esi
    pop ecx
    add edi, 40
    loop .search_loop

.read_fail:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    xor eax, eax                ; Retorna NULL (0) em EAX
    ret

.found:
    pop edi
    pop esi
    pop ecx
    mov eax, [edi + 32]         ; Retorna o ponteiro para o inicio dos dados do arquivo em EAX
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

print_dec_num:
    pusha
    mov ecx, 0
    mov ebx, 10
.p_div:
    xor edx, edx
    div ebx
    push edx
    inc ecx
    test eax, eax
    jnz .p_div
.p_print:
    pop eax
    add al, '0'
    call vga_putc
    loop .p_print
    popa
    ret
