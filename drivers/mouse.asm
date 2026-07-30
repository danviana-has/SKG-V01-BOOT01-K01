[BITS 32]

global mouse_init
global mouse_get_x
global mouse_get_y
global mouse_get_buttons
global mouse_process_byte
global mouse_draw_cursor
global mouse_x
global mouse_y

extern kms_lfb_ptr
extern kms_pitch

section .data
align 4
mouse_x:       dd 512          ; Posição X inicial (centro de 1024x768)
mouse_y:       dd 384          ; Posição Y inicial
old_mouse_x:   dd 512
old_mouse_y:   dd 384
first_draw:    db 1

mouse_cycle:   db 0
mouse_byte:    times 3 db 0
mouse_buttons: db 0

saved_bg:      times 272 dd 0  ; Buffer para salvar o fundo sob o cursor (16x17 pixels)

mouse_cursor_shape:
    db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 1,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 1,2,2,1,0,0,0,0,0,0,0,0,0,0,0,0
    db 1,2,2,2,1,0,0,0,0,0,0,0,0,0,0,0
    db 1,2,2,2,2,1,0,0,0,0,0,0,0,0,0,0
    db 1,2,2,2,2,2,1,0,0,0,0,0,0,0,0,0
    db 1,2,2,2,2,2,2,1,0,0,0,0,0,0,0,0
    db 1,2,2,2,2,2,2,2,1,0,0,0,0,0,0,0
    db 1,2,2,2,2,2,2,2,2,1,0,0,0,0,0,0
    db 1,2,2,2,2,2,1,1,1,1,1,0,0,0,0,0
    db 1,2,2,1,2,2,1,0,0,0,0,0,0,0,0,0
    db 1,2,1,0,1,2,2,1,0,0,0,0,0,0,0,0
    db 1,1,0,0,0,1,2,2,1,0,0,0,0,0,0,0
    db 1,0,0,0,0,0,1,2,2,1,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,1,2,2,1,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0

header_gmd:
    db "GMD1"                  ; Assinatura de Driver GMK
    dd mouse_init
    dd mouse_dispatch
    dd 0x00010003              ; Versão do Driver (v1.3)

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

    ; Limpa qualquer byte pendente no buffer do mouse
.flush_mouse:
    in al, 0x64
    test al, 1
    jz .flushed
    test al, 0x20
    jz .flushed
    in al, 0x60
    jmp .flush_mouse
.flushed:

    ; Desenha o cursor inicial no centro da tela (512, 384)
    call mouse_draw_cursor

    popa
    ret

mouse_process_byte:
    pusha
    mov bl, [mouse_cycle]
    cmp bl, 0
    jne .chk_cycle_1

    test al, 0x08              ; Bit 3 deve ser 1 para sincronismo PS/2
    jz .done
    mov [mouse_byte], al
    mov byte [mouse_cycle], 1
    jmp .done

.chk_cycle_1:
    cmp bl, 1
    jne .chk_cycle_2
    mov [mouse_byte + 1], al
    mov byte [mouse_cycle], 2
    jmp .done

.chk_cycle_2:
    mov [mouse_byte + 2], al
    mov byte [mouse_cycle], 0
    call mouse_parse_packet
    call mouse_draw_cursor

.done:
    popa
    ret

; Processa pacote de 3 bytes enviado pelo Mouse PS/2
mouse_parse_packet:
    pusha
    mov al, [mouse_byte]
    mov [mouse_buttons], al    ; Botão Esquerdo (bit 0), Direito (bit 1), Meio (bit 2)

    test al, 0x08              ; Garante sincronismo
    jz .done

    ; Processa Deslocamento X (Sinalizado 8-bit estendido para 32-bit)
    movsx eax, byte [mouse_byte + 1]
    add [mouse_x], eax

    ; Processa Deslocamento Y (Sinalizado 8-bit estendido para 32-bit, invertido no PS/2)
    movsx eax, byte [mouse_byte + 2]
    sub [mouse_y], eax

    ; Limita coordenadas à tela 1024x768
    cmp dword [mouse_x], 0
    jge .chk_max_x
    mov dword [mouse_x], 0
.chk_max_x:
    cmp dword [mouse_x], 1023
    jle .chk_min_y
    mov dword [mouse_x], 1023

.chk_min_y:
    cmp dword [mouse_y], 0
    jge .chk_max_y
    mov dword [mouse_y], 0
.chk_max_y:
    cmp dword [mouse_y], 767
    jle .done
    mov dword [mouse_y], 767

.done:
    popa
    ret

; Desenha o ponteiro preto do mouse sem destruir o fundo e sem deixar rastros
mouse_draw_cursor:
    pusha

    ; 1. Se nao for a primeira renderizacao, restaura o fundo sob a posicao antiga
    cmp byte [first_draw], 1
    je .save_new

    mov ecx, 0                  ; ecx = row (0..16)
.restore_row:
    cmp ecx, 17
    jge .save_new

    mov ebx, [old_mouse_y]
    add ebx, ecx                ; ebx = y = old_mouse_y + row
    cmp ebx, 768
    jge .restore_next_row

    mov edx, 0                  ; edx = col (0..15)
.restore_col:
    cmp edx, 16
    jge .restore_next_row

    mov eax, [old_mouse_x]
    add eax, edx                ; eax = x = old_mouse_x + col
    cmp eax, 1024
    jge .restore_next_col

    ; Endereço no LFB: edi = kms_lfb_ptr + y * pitch + x * 4
    mov edi, ebx
    imul edi, [kms_pitch]
    shl eax, 2
    add edi, eax
    add edi, [kms_lfb_ptr]

    ; Endereço no saved_bg: esi = saved_bg + (ecx * 16 + edx) * 4
    mov esi, ecx
    shl esi, 4
    add esi, edx
    shl esi, 2
    add esi, saved_bg

    mov eax, [esi]              ; Le pixel guardado
    mov [edi], eax              ; Restaura no LFB

.restore_next_col:
    inc edx
    jmp .restore_col

.restore_next_row:
    inc ecx
    jmp .restore_row

.save_new:
    mov byte [first_draw], 0
    mov eax, [mouse_x]
    mov [old_mouse_x], eax
    mov eax, [mouse_y]
    mov [old_mouse_y], eax

    ; 2. Salva os pixels do fundo na posicao atual (mouse_x, mouse_y)
    mov ecx, 0                  ; ecx = row (0..16)
.save_row:
    cmp ecx, 17
    jge .draw_cursor

    mov ebx, [mouse_y]
    add ebx, ecx                ; ebx = y = mouse_y + row
    cmp ebx, 768
    jge .save_next_row

    mov edx, 0                  ; edx = col (0..15)
.save_col:
    cmp edx, 16
    jge .save_next_row

    mov eax, [mouse_x]
    add eax, edx                ; eax = x = mouse_x + col
    cmp eax, 1024
    jge .save_next_col

    ; Endereço no LFB: esi = kms_lfb_ptr + y * pitch + x * 4
    mov esi, ebx
    imul esi, [kms_pitch]
    shl eax, 2
    add esi, eax
    add esi, [kms_lfb_ptr]

    ; Endereço no saved_bg: edi = saved_bg + (ecx * 16 + edx) * 4
    mov edi, ecx
    shl edi, 4
    add edi, edx
    shl edi, 2
    add edi, saved_bg

    mov eax, [esi]              ; Le pixel do LFB
    mov [edi], eax              ; Salva em saved_bg

.save_next_col:
    inc edx
    jmp .save_col

.save_next_row:
    inc ecx
    jmp .save_row

.draw_cursor:
    ; 3. Desenha o cursor preto do Windows no LFB na posicao (mouse_x, mouse_y)
    mov ecx, 0                  ; ecx = row (0..16)
.cursor_row:
    cmp ecx, 17
    jge .done

    mov ebx, [mouse_y]
    add ebx, ecx                ; ebx = y = mouse_y + row
    cmp ebx, 768
    jge .cursor_next_row

    mov edx, 0                  ; edx = col (0..15)
.cursor_col:
    cmp edx, 16
    jge .cursor_next_row

    mov eax, [mouse_x]
    add eax, edx                ; eax = x = mouse_x + col
    cmp eax, 1024
    jge .cursor_next_col

    ; Endereço na matriz do cursor: esi = mouse_cursor_shape + (ecx * 16 + edx)
    mov esi, ecx
    shl esi, 4
    add esi, edx
    add esi, mouse_cursor_shape

    mov bl, [esi]               ; 0 = transp, 1 = branco, 2 = preto
    cmp bl, 0
    je .cursor_next_col

    ; Endereço no LFB: edi = kms_lfb_ptr + y * pitch + x * 4
    push ebx
    mov ebx, [mouse_y]
    add ebx, ecx
    mov edi, ebx
    imul edi, [kms_pitch]
    shl eax, 2
    add edi, eax
    add edi, [kms_lfb_ptr]
    pop ebx

    cmp bl, 1
    je .color_white

    mov dword [edi], 0x00000000 ; Preto Puro do Windows
    jmp .cursor_next_col

.color_white:
    mov dword [edi], 0x00FFFFFF ; Contorno Branco de Alto Contraste

.cursor_next_col:
    inc edx
    jmp .cursor_col

.cursor_next_row:
    inc ecx
    jmp .cursor_row

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