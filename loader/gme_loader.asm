[BITS 32]
global gme_load_and_run

extern gmfs_read
extern vga_print

section .data
err_gme_not_found: db "Erro: Arquivo .gme nao encontrado no GMFS!", 0x0A, 0

section .text
gme_load_and_run:
    pusha

    ; Busca o ponteiro do arquivo no sistema de arquivos GMFS
    call gmfs_read
    test eax, eax
    jz .not_found

    ; EAX contem o endereço exato dos bytes do arquivo Flat Binary
    call eax                    ; Executa as instrucoes x86 do aplicativo diretamente

    popa
    ret

.not_found:
    mov esi, err_gme_not_found
    call vga_print
    popa
    ret
