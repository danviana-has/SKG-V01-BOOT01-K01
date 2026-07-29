[BITS 32]

global vbe_init
global vbe_put_pixel_32
global vbe_lfb_ptr

section .data
header_gmd:
    db "GMD1"
    dd vbe_init
    dd vbe_dispatch
    dd 0x00010001

vbe_lfb_ptr:   dd 0xE0000000   ; Endereço Base Padrão do Linear Framebuffer VESA
vbe_width:     dw 800
vbe_height:    dw 600
vbe_bpp:       db 32
vbe_pitch:     dd 3200         ; Pitch de linha (800 * 4 bytes por pixel)

section .text

vbe_init:
    ; Mantido preparado no Ring 0 para troca de modo via chamadas BIOS VESA (VBE 2.0/3.0)
    ret

vbe_dispatch:
    ret

; Plota um pixel 32-bit (ARGB/RGBA) diretamente no Framebuffer Linear
; EAX = X, EBX = Y, ECX = Cor (0xAARRGGBB)
vbe_put_pixel_32:
    pusha
    ; Checagem de limites da tela
    cmp ax, [vbe_width]
    jge .done
    cmp bx, [vbe_height]
    jge .done

    ; Cálculo Offset = (Y * Pitch) + (X * 4)
    mov edx, ebx
    imul edx, [vbe_pitch]
    mov edi, eax
    shl edi, 2                 ; Multiplica X por 4 (32 bits = 4 bytes)
    add edi, edx

    add edi, [vbe_lfb_ptr]     ; Adiciona o ponteiro do Framebuffer
    mov [edi], ecx             ; Grava pixel diretamente na VRAM

.done:
    popa
    ret