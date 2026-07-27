[BITS 32]
global isr_keyboard_wrapper
extern keyboard_handler

section .text
isr_keyboard_wrapper:
    pusha
    call keyboard_handler
    mov al, 0x20
    out 0x20, al                ; Envia EOI para o PIC
    popa
    iretd
