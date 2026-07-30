[BITS 32]

global bmp_draw_32bpp

section .data
header_gmd:
    db "GMD1"
    dd bmp_init
    dd bmp_dispatch
    dd 0x00010001

section .text

bmp_init:
    ret

bmp_dispatch:
    ret

bmp_draw_32bpp:
    pusha

    cmp word [esi], 0x4D42
    jne .invalid_bmp

    mov ebp, [esi + 10]           ; Offset dos pixels
    mov ecx, [esi + 18]           ; ECX = Width
    mov ebx, [esi + 22]           ; EBX = Height

    cmp word [esi + 28], 32
    jne .invalid_bmp

    add ebp, esi                  ; EBP = Ponteiro dos pixels brutos
    mov eax, ebx
    dec eax

.row_loop:
    push eax
    push ecx

    mov eax, ebx
    dec eax
    sub eax, [esp + 4]
    add eax, edi                  ; Y destino

    mov edx, 0                    ; X = 0

.col_loop:
    mov eax, [ebp]                ; Lê Pixel 32-bit (BGRA)
    add ebp, 4
    inc edx
    cmp edx, [esp]                ; Compara diretamente com ECX empilhado
    jl .col_loop

    pop ecx
    pop eax

    dec eax
    cmp eax, 0
    jge .row_loop

.invalid_bmp:
    popa
    ret