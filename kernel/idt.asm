[BITS 32]
global idt_init
global idt_set_gate

extern isr_keyboard_wrapper
extern syscall_dispatcher

section .bss
align 8
idt_entries: resb 2048
idt_ptr:
    resw 1
    resd 1

section .text
idt_init:
    pusha
    mov word [idt_ptr], (256 * 8) - 1
    mov dword [idt_ptr + 2], idt_entries

    mov edi, idt_entries
    mov ecx, 2048 / 4
    xor eax, eax
    rep stosd

    ; Remapeia PIC 8259
    mov al, 0x11
    out 0x20, al
    out 0xA0, al

    mov al, 0x20
    out 0x21, al
    mov al, 0x28
    out 0xA1, al

    mov al, 0x04
    out 0x21, al
    mov al, 0x02
    out 0xA1, al

    mov al, 0x01
    out 0x21, al
    out 0xA1, al

    ; Mascara todas as IRQs EXCETO Teclado (IRQ1 = Bit 1 desativado: 11111101b = 0xFD)
    mov al, 0xFD
    out 0x21, al
    mov al, 0xFF
    out 0xA1, al

    ; Configura IRQ1 (Teclado -> INT 0x21)
    mov eax, 0x21
    mov ebx, isr_keyboard_wrapper
    call idt_set_gate

    ; Configura INT 0x80 (Syscall)
    mov eax, 0x80
    mov ebx, syscall_dispatcher
    call idt_set_gate

    lidt [idt_ptr]
    sti
    popa
    ret

idt_set_gate:
    push ecx
    mov ecx, idt_entries
    lea ecx, [ecx + eax * 8]

    mov [ecx], bx
    mov word [ecx + 2], 0x08
    mov byte [ecx + 4], 0
    mov byte [ecx + 5], 0x8E

    cmp eax, 0x80
    jne .not_user
    mov byte [ecx + 5], 0xEE
.not_user:
    shr ebx, 16
    mov [ecx + 6], bx
    pop ecx
    ret
