; ==============================================================================
; Source Kernel GM (SKG) - Driver PIT (Programmable Interval Timer 8253/8254)
; Configurado para gerar interrupções de relógio a 100 Hz (10ms por tick)
; ==============================================================================
[BITS 32]
global pit_init
global pit_handler
global pit_get_ticks
global pit_sleep

section .bss
timer_ticks: resd 1

section .text
pit_init:
    mov dword [timer_ticks], 0
    mov al, 0x36                ; Modo 3 (Square Wave), Canal 0, LSB/MSB
    out 0x43, al

    ; Divisor de Frequência = 1193182 / 100 Hz = 11931 (0x2E9B)
    mov al, 0x9B
    out 0x40, al                ; LSB
    mov al, 0x2E
    out 0x40, al                ; MSB
    ret

pit_handler:
    inc dword [timer_ticks]
    ret

pit_get_ticks:
    mov eax, [timer_ticks]
    ret

pit_sleep:
    ; EBX = Quantidade de Ticks de Espera
    push eax
    push ebx
    add ebx, [timer_ticks]
.wait_loop:
    cmp [timer_ticks], ebx
    jl .wait_loop
    pop ebx
    pop eax
    ret
