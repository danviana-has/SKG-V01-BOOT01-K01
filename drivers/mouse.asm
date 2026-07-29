[BITS 32]

global mouse_init
global mouse_get_x
global mouse_get_y
global mouse_get_buttons

section .data
align 4
mouse_x:       dd 400          ; Posição X inicial (centro 800x600)
mouse_y:       dd 300          ; Posição Y inicial
mouse_cycle:   db 0
mouse_byte:    times 3 db 0
mouse_buttons: db 0

header_gmd:
    db "GMD1"                  ; Assinatura de Driver GMK
    dd mouse_init
    dd mouse_dispatch
    dd 0x00010001              ; Versão do Driver (v1.1)

section .text

; Aguarda buffer de entrada do controlador PS/2 ficar livre
mouse_wait_input:
    in al, 0x64
    test al, 0x02
    jnz mouse_wait_input
    ret

; Aguarda dados estarem disponíveis no buffer de saída
mouse_wait_output:
    in al, 0x64
    test al, 0x01
    jz mouse_wait_output
    ret

; Envia comando para o mouse PS/2
mouse_write:
    push eax
    call mouse_wait_input
    mov al, 0xD4               ; Escrever para a 2ª porta PS/2 (Mouse)
    out 0x64, al
    call mouse_wait_input
    pop eax
    out 0x60, al
    ret

mouse_read:
    call mouse_wait_output
    in al, 0x60
    ret

mouse_init:
    pusha
    ; Habilita porta aux do mouse
    call mouse_wait_input
    mov al, 0xA8
    out 0x64, al

    ; Habilita Interrupção IRQ12 do Mouse no Controller
    call mouse_wait_input
    mov al, 0x20
    out 0x64, al
    call mouse_read
    or al, 2
    mov bl, al
    call mouse_wait_input
    mov al, 0x60
    out 0x64, al
    call mouse_wait_input
    mov al, bl
    out 0x60, al

    ; Restaura padrão do mouse
    mov al, 0xF6
    call mouse_write
    call mouse_read            ; Espera ACK (0xFA)

    ; Habilita streaming de dados do mouse
    mov al, 0xF4
    call mouse_write
    call mouse_read            ; Espera ACK (0xFA)

    popa
    ret

; Processa pacote de 3 bytes enviado pelo Mouse PS/2
mouse_parse_packet:
    pusha
    mov al, [mouse_byte]
    mov [mouse_buttons], al    ; Botão Esquerdo (bit 0), Direito (bit 1), Meio (bit 2)

    ; Processa Deslocamento X
    movzx eax, byte [mouse_byte+1]
    mov bl, [mouse_byte]
    test bl, 0x10              ; Bit de sinal X
    jz .pos_x
    or eax, 0xFFFFFF00         ; Extensão de sinal para 32-bit
.pos_x:
    add [mouse_x], eax

    ; Processa Deslocamento Y (invertido no PS/2)
    movzx eax, byte [mouse_byte+2]
    test bl, 0x20              ; Bit de sinal Y
    jz .pos_y
    or eax, 0xFFFFFF00
.pos_y:
    sub [mouse_y], eax         ; Subtrai para ajustar o eixo cartesiano da tela

    ; Limita coordenadas (Clamping para tela 800x600 por padrão)
    cmp dword [mouse_x], 0
    jge .chk_max_x
    mov dword [mouse_x], 0
.chk_max_x:
    cmp dword [mouse_x], 799
    jle .chk_min_y
    mov dword [mouse_x], 799

.chk_min_y:
    cmp dword [mouse_y], 0
    jge .chk_max_y
    mov dword [mouse_y], 0
.chk_max_y:
    cmp dword [mouse_y], 599
    jle .done
    mov dword [mouse_y], 599

.done:
    popa
    ret

mouse_dispatch:
    ret

mouse_get_x:
    mov eax, [mouse_x]
    ret

mouse_get_y:
    mov eax, [mouse_y]
    ret

mouse_get_buttons:
    movzx eax, byte [mouse_buttons]
    ret