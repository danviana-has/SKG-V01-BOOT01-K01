[BITS 32]
global keyboard_init
global keyboard_handler
global keyboard_getchar

section .bss
key_buffer:     resb 256
buf_head:       resd 1
buf_tail:       resd 1

section .data
scancode_table:
    db 0,  27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8
    db 9, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 13, 0
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'", '`', 0, '\'
    db 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' '

section .text
keyboard_init:
    mov dword [buf_head], 0
    mov dword [buf_tail], 0
    ret

keyboard_handler:
    in al, 0x60
    test al, 0x80
    jnz .done

    movzx ebx, al
    cmp ebx, 58
    jae .done

    mov dl, [scancode_table + ebx]
    test dl, dl
    jz .done

    mov edi, [buf_tail]
    mov [key_buffer + edi], dl
    inc edi
    and edi, 0xFF
    mov [buf_tail], edi

.done:
    ret

keyboard_getchar:
    push ebx
    push edi

.wait:
    cli
    mov edi, [buf_head]
    cmp edi, [buf_tail]
    jne .read
    sti
    hlt                         ; Aguarda a proxima interrupcao de hardware
    jmp .wait

.read:
    mov al, [key_buffer + edi]
    inc edi
    and edi, 0xFF
    mov [buf_head], edi
    sti

    pop edi
    pop ebx
    ret
