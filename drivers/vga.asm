[BITS 32]
global vga_clear
global vga_print
global vga_putc
global vga_backspace
global vga_set_color

section .data
VGA_MEM         equ 0xB8000
VGA_WIDTH       equ 80
VGA_HEIGHT      equ 25

cursor_x:       db 0
cursor_y:       db 0
vga_color_attr: db 0x0F

section .text
vga_clear:
    pusha
    mov edi, VGA_MEM
    mov ah, [vga_color_attr]
    mov al, ' '
    mov ecx, VGA_WIDTH * VGA_HEIGHT
    rep stosw
    mov byte [cursor_x], 0
    mov byte [cursor_y], 0
    call update_hardware_cursor
    popa
    ret

vga_set_color:
    mov [vga_color_attr], al
    ret

vga_putc:
    pusha
    cmp al, 0x0A
    je .newline
    cmp al, 0x0D
    je .newline

    movzx ebx, byte [cursor_y]
    imul ebx, VGA_WIDTH
    movzx ecx, byte [cursor_x]
    add ebx, ecx
    shl ebx, 1

    mov edi, VGA_MEM
    add edi, ebx
    mov ah, [vga_color_attr]
    mov [edi], ax

    inc byte [cursor_x]
    cmp byte [cursor_x], VGA_WIDTH
    jl .update
.newline:
    mov byte [cursor_x], 0
    inc byte [cursor_y]
    cmp byte [cursor_y], VGA_HEIGHT
    jl .update
    call vga_scroll
.update:
    call update_hardware_cursor
    popa
    ret

vga_backspace:
    pusha
    cmp byte [cursor_x], 0
    je .prev_line
    dec byte [cursor_x]
    jmp .erase
.prev_line:
    cmp byte [cursor_y], 0
    je .bs_done
    dec byte [cursor_y]
    mov byte [cursor_x], VGA_WIDTH - 1
.erase:
    movzx ebx, byte [cursor_y]
    imul ebx, VGA_WIDTH
    movzx ecx, byte [cursor_x]
    add ebx, ecx
    shl ebx, 1
    mov edi, VGA_MEM
    add edi, ebx
    mov ah, [vga_color_attr]
    mov al, ' '
    mov [edi], ax
    call update_hardware_cursor
.bs_done:
    popa
    ret

vga_scroll:
    pusha
    mov esi, VGA_MEM + (VGA_WIDTH * 2)
    mov edi, VGA_MEM
    mov ecx, (VGA_WIDTH * (VGA_HEIGHT - 1))
    rep movsw

    mov edi, VGA_MEM + (VGA_WIDTH * (VGA_HEIGHT - 1) * 2)
    mov ah, [vga_color_attr]
    mov al, ' '
    mov ecx, VGA_WIDTH
    rep stosw
    mov byte [cursor_y], VGA_HEIGHT - 1
    popa
    ret

vga_print:
    pusha
.loop:
    lodsb
    test al, al
    jz .end
    call vga_putc
    jmp .loop
.end:
    popa
    ret

update_hardware_cursor:
    pusha
    movzx ebx, byte [cursor_y]
    imul ebx, VGA_WIDTH
    movzx ecx, byte [cursor_x]
    add ebx, ecx

    mov al, 0x0F
    mov dx, 0x3D4
    out dx, al
    mov al, bl
    mov dx, 0x3D5
    out dx, al

    mov al, 0x0E
    mov dx, 0x3D4
    out dx, al
    mov al, bh
    mov dx, 0x3D5
    out dx, al
    popa
    ret
