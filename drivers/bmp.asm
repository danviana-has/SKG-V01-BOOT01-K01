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

; Rotina de renderização de BMP 32bpp REAL
; ESI = Ponteiro na memória para o arquivo BMP
; EDX = Posição X na tela
; EDI = Posição Y na tela
bmp_draw_32bpp:
    pusha

    ; Validar Assinatura 'BM' (0x4D42 em Little-Endian)
    cmp word [esi], 0x4D42
    jne .invalid_bmp

    ; Ler Offset dos Pixels (Byte 10 do Header)
    mov ebp, [esi + 10]

    ; Ler Largura (Byte 18) e Altura (Byte 22)
    mov ecx, [esi + 18]        ; ECX = Largura (Width)
    mov ebx, [esi + 22]        ; EBX = Altura (Height)

    ; Ler BPP (Byte 28)
    cmp word [esi + 28], 32
    jne .invalid_bmp           ; Suporta apenas 32 bits por pixel (True Color)

    ; Ponteiro de origem dos pixels = ESI + Offset
    add ebp, esi               ; EBP aponta para os pixels brutos

    ; BMPs convencionais são gravados da última linha para a primeira (Bottom-Up)
    mov eax, ebx
    dec eax

.row_loop:
    push eax
    push ecx

    ; Posição Y na tela = Y_inicial + (Height - 1 - Linha_Atual)
    mov eax, ebx
    dec eax
    sub eax, [esp + 4]          ; EAX = Índice da linha real de cima para baixo
    add eax, edi                ; Adiciona Offset Y da tela
    push eax                    ; Guarda Y de destino na tela

    mov edx, 0                  ; EDX = Índice da coluna (X)

.col_loop:
    ; Lê Pixel 32-bit (BGRA) direto da memória apontada por EBP
    mov eax, [ebp]              ; EAX = 0xAARRGGBB

    ; Avança ponteiro da imagem em 4 bytes (32-bit)
    add ebp, 4

    inc edx
    cmp edx, [esp + 4]          ; Compara com a largura da imagem
    jl .col_loop

    add esp, 4                  ; Desempilha Y de destino
    pop ecx
    pop eax

    dec eax
    cmp eax, 0
    jge .row_loop

.invalid_bmp:
    popa
    ret