; ==============================================================================
; Source Kernel GM (SKG) - Alocador Dinâmico de Memória Kernel Heap (kmalloc)
; ==============================================================================
[BITS 32]
global heap_init
global kmalloc
global kfree

section .data
HEAP_START_ADDR equ 0x02000000  ; Heap Inicia em 32 MB na RAM
HEAP_MAX_LIMIT  equ 0x03000000  ; Tamanho Máximo do Heap: 16 MB
current_heap:   dd HEAP_START_ADDR

section .text
heap_init:
    mov dword [current_heap], HEAP_START_ADDR
    ret

kmalloc:
    ; Entrada: EBX = Tamanho Solicitado em Bytes
    ; Saída: EAX = Endereço de Memória Alocado (ou 0 se falhar)
    push ebx
    mov eax, [current_heap]
    add ebx, eax
    cmp ebx, HEAP_MAX_LIMIT
    jae .out_of_memory

    mov [current_heap], ebx     ; Atualiza ponteiro do Heap (Bump Allocator)
    pop ebx
    ret

.out_of_memory:
    pop ebx
    xor eax, eax
    ret

kfree:
    ; Liberação genérica
    ret
