; ==============================================================================
; Source Kernel GM (SKG) - Global Descriptor Table (GDT)
; Define o Modelo de Memória Plana (Flat Memory Model) de 32 bits
; ==============================================================================
[BITS 32]
global gdt_init

section .data
align 8
gdt_start:
    ; Descritor Nulo (0x00)
    dd 0x00000000
    dd 0x00000000

    ; Kernel Code Segment (0x08) - Base: 0x00000000, Limite: 4GB, Ring 0, RX
    dw 0xFFFF                   ; Limit (0-15)
    dw 0x0000                   ; Base (0-15)
    db 0x00                     ; Base (16-23)
    db 0x9A                     ; Access Byte: Present, Ring 0, Executable, Readable
    db 0xCF                     ; Flags: 4KB Granularity, 32-bit PM + Limit (16-19)
    db 0x00                     ; Base (24-31)

    ; Kernel Data Segment (0x10) - Base: 0x00000000, Limite: 4GB, Ring 0, RW
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92                     ; Access Byte: Present, Ring 0, Writable
    db 0xCF
    db 0x00

    ; User Code Segment (0x18) - Base: 0x00000000, Limite: 4GB, Ring 3, RX
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0xFA                     ; Access Byte: Present, Ring 3, Executable, Readable
    db 0xCF
    db 0x00

    ; User Data Segment (0x20) - Base: 0x00000000, Limite: 4GB, Ring 3, RW
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0xF2                     ; Access Byte: Present, Ring 3, Writable
    db 0xCF
    db 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Tamanho da GDT
    dd gdt_start                ; Endereço da GDT

section .text
gdt_init:
    pusha
    lgdt [gdt_descriptor]       ; Carrega a nova GDT no registrador GDTR

    ; Recarrega os registradores de segmento
    jmp 0x08:.reload_segments

.reload_segments:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    popa
    ret
