[BITS 32]
global syscall_dispatcher
extern vga_print

section .text
syscall_dispatcher:
    pusha
    cmp eax, 1                  ; Syscall 1 = Print String
    jne .sys_done

    mov esi, ebx                ; EBX contem o ponteiro da mensagem
    call vga_print

.sys_done:
    popa
    iretd
