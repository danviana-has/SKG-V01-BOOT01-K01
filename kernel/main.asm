[BITS 32]
global kernel_main
extern gdt_init
extern idt_init
extern mouse_init
extern mouse_get_x
extern mouse_get_y

section .bss
align 4096
cmd_buffer: resb 256
cmd_len:    resd 1

; Sistema de Arquivos em RAM (VFS Dinamico)
vfs_names:  resb 512           ; 8 slots de 64 bytes para nomes
vfs_data:   resb 2048          ; 8 slots de 256 bytes para conteudo
vfs_used:   resb 8             ; 8 flags de uso (0 = livre, 1 = ocupado)

section .data
vga_ptr:    dd 0xB8000
cursor_pos: dd 0

msg_banner: db "================================--------------------------------", 10
            db "                 SKG CORE OS - ARQUITETURA GMK v1.1             ", 10
            db "================================--------------------------------", 10, 0
msg_m_load: db "[GMK] Carregando Gerenciador de Modulos GM Driver (.gmd)...", 10, 0
msg_d_vga:  db "  [OK] DRIVER REGISTRADO: vga.gmd      [0x00010000]", 10, 0
msg_d_kbd:  db "  [OK] DRIVER REGISTRADO: keyboard.gmd [0x00010000]", 10, 0
msg_d_pit:  db "  [OK] DRIVER REGISTRADO: pit.gmd      [0x00010000]", 10, 0
msg_d_gmfs: db "  [OK] DRIVER REGISTRADO: gmfs.gmd     [0x00010000]", 10, 0
msg_d_mse:  db "  [OK] DRIVER REGISTRADO: mouse.gmd    [0x00010001]", 10, 0
msg_d_vbe:  db "  [OK] DRIVER REGISTRADO: vbe32.gmd    [0x00010001]", 10, 0
msg_d_bmp:  db "  [OK] DRIVER REGISTRADO: bmp32.gmd    [0x00010001]", 10, 0
msg_ready:  db 10, "SKG Core v1.1 inicializado no Modo Texto VGA! Digite HELP.", 10, 0
msg_prompt: db "ROOT@SKG-CORE:~# ", 0
msg_newline:db 10, 0

msg_cmd_help: db 10, "Comandos SKG disponiveis:", 10
              db "  HELP                  - Exibe esta mensagem de ajuda", 10
              db "  VER                   - Versao do Kernel SKG Core", 10
              db "  SYSINFO               - Informacoes da arquitetura GMK", 10
              db "  DRIVERS               - Lista modulos .gmd ativos", 10
              db "  MOUSE                 - Exibe status do driver de Mouse PS/2", 10
              db "  VBEINFO               - Status dos drivers VBE/VESA 32bpp", 10
              db "  LS                    - Lista todos os arquivos da VFS", 10
              db "  WRITE <arq.txt> <txt> - Cria/escreve um arquivo de texto", 10
              db "  CAT <arquivo>         - Le e exibe o conteudo do arquivo", 10
              db "  DELETE <arquivo>      - Deleta um arquivo", 10
              db "  CLEAR                 - Limpa o terminal VGA", 10
              db "  REBOOT                - Reinicia o sistema", 10, 0

msg_cmd_ver:  db 10, "SKG Core Kernel v1.1.0 [GMK Architecture - 32-bit Ring0]", 10, 0
msg_cmd_sys:  db 10, "[SKG SYSINFO] Protected Mode 32-bit - GMK Dual Display Ready", 10, 0
msg_cmd_drv:  db 10, "Modulos: vga, keyboard, pit, gmfs, mouse, vbe32, bmp32", 10, 0
msg_cmd_mse:  db 10, "[MOUSE PS/2] Driver Ativo - Streaming IRQ12 Habilitado.", 10, 0
msg_cmd_vbe:  db 10, "[VBE/VESA 32bpp] LFB Ativo em 0xE0000000 (Compatibilidade pronta)", 10, 0

msg_write_ok: db 10, "Arquivo gravado na VRAM/VFS com sucesso!", 10, 0
msg_del_ok:   db 10, "Arquivo removido do sistema de arquivos.", 10, 0
msg_not_found:db 10, "Erro: Arquivo nao encontrado na VFS.", 10, 0
msg_unknown:  db 10, "Comando nao reconhecido. Digite HELP.", 10, 0

msg_panic_1:  db 10, 10, "!!! KERNEL PANIC: CRITICAL SYSTEM FILE DELETED !!!", 10, 0
msg_panic_2:  db "FATAL: SYSKERNELAPP.GMK FOI REMOVIDO DA MEMORIA!", 10, 0
msg_panic_3:  db "O SISTEMA OPERACIONAL ENTRARA EM AUTODESTRUICAO...", 10, 0

; Tabela de Scancodes Alinhada Corretamente
scancode_map:
    db 0, 27, "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", 8, 9
    db "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]", 13, 0
    db "A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'", "`", 0, "\"
    db "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/", 0, "*", 0, " "

section .text
kernel_main:
    cli
    call gdt_init
    call idt_init

    mov al, 0xAE
    out 0x64, al

    call mouse_init            ; Inicializa driver de Mouse PS/2

    ; Flush no Buffer PS/2 para descartar ACKs residuais da BIOS/VirtualBox
.flush_ps2:
    in al, 0x64
    test al, 1
    jz .ps2_clean
    in al, 0x60
    jmp .flush_ps2
.ps2_clean:

    call init_default_vfs

    call clear_vga
    mov esi, msg_banner
    call print_vga

    mov esi, msg_m_load
    call print_vga
    mov esi, msg_d_vga
    call print_vga
    mov esi, msg_d_kbd
    call print_vga
    mov esi, msg_d_pit
    call print_vga
    mov esi, msg_d_gmfs
    call print_vga
    mov esi, msg_d_mse
    call print_vga
    mov esi, msg_d_vbe
    call print_vga
    mov esi, msg_d_bmp
    call print_vga

    mov esi, msg_ready
    call print_vga
    call print_prompt

.cli_loop:
    call poll_keyboard
    jmp .cli_loop

init_default_vfs:
    pusha
    mov byte [vfs_used], 1
    mov dword [vfs_names], "SYSK"
    mov dword [vfs_names+4], "ERNE"
    mov dword [vfs_names+8], "LAPP"
    mov dword [vfs_names+12], ".GMK"
    mov byte [vfs_names+16], 0
    mov dword [vfs_data], "[CORE KERNEL BINARY DATA]"

    mov byte [vfs_used+1], 1
    mov dword [vfs_names+64], "READ"
    mov dword [vfs_names+68], "ME.T"
    mov dword [vfs_names+72], "XT"
    mov byte [vfs_names+74], 0
    mov dword [vfs_data+256], "BENV"
    mov dword [vfs_data+260], "INDO"
    mov dword [vfs_data+264], " AO "
    mov dword [vfs_data+268], "SKG!"
    mov byte [vfs_data+272], 0
    popa
    ret

print_prompt:
    mov esi, msg_newline
    call print_vga
    mov esi, msg_prompt
    call print_vga
    mov dword [cmd_len], 0
    mov byte [cmd_buffer], 0
    ret

clear_vga:
    mov edi, 0xB8000
    mov ecx, 2000
    mov ax, 0x0720
    rep stosw
    mov dword [cursor_pos], 0
    ret

print_vga:
    pusha
.p_loop:
    lodsb
    cmp al, 0
    je .p_done
    cmp al, 10
    je .p_newline

    mov edi, [cursor_pos]
    shl edi, 1
    add edi, 0xB8000
    mov ah, 0x0F
    mov [edi], ax
    inc dword [cursor_pos]
    jmp .p_loop

.p_newline:
    mov eax, [cursor_pos]
    mov ebx, 80
    xor edx, edx
    div ebx
    inc eax
    mul ebx
    mov [cursor_pos], eax
    jmp .p_loop

.p_done:
    popa
    ret

poll_keyboard:
    pusha
    in al, 0x64
    test al, 1
    jz .k_done

    test al, 0x20              ; Ignora se forem dados do mouse na porta aux
    jnz .k_flush

    in al, 0x60
    cmp al, 0xE0               ; Ignora bytes de extensao (setas, etc)
    je .k_done

    test al, 0x80              ; Ignora tecla ao ser solta (Key Release)
    jnz .k_done

    movzx eax, al
    cmp eax, 0x39
    jg .k_done

    mov bl, [scancode_map + eax]
    cmp bl, 0
    je .k_done

    cmp bl, 0x08
    je .k_bs
    cmp bl, 0x0D
    je .k_enter

    mov edx, [cmd_len]
    cmp edx, 60
    jge .k_done

    mov [cmd_buffer + edx], bl
    inc dword [cmd_len]
    mov byte [cmd_buffer + edx + 1], 0

    mov edi, [cursor_pos]
    shl edi, 1
    add edi, 0xB8000
    mov ah, 0x0E
    mov al, bl
    mov [edi], ax
    inc dword [cursor_pos]
    jmp .k_done

.k_bs:
    mov edx, [cmd_len]
    cmp edx, 0
    jle .k_done
    dec dword [cmd_len]
    mov edx, [cmd_len]
    mov byte [cmd_buffer + edx], 0
    dec dword [cursor_pos]
    mov edi, [cursor_pos]
    shl edi, 1
    add edi, 0xB8000
    mov word [edi], 0x0720
    jmp .k_done

.k_enter:
    call process_command
    call print_prompt
    jmp .k_done

.k_flush:
    in al, 0x60

.k_done:
    popa
    ret

process_command:
    pusha
    cmp dword [cmd_len], 0
    je .cmd_done

    mov esi, cmd_buffer

    ; --- HELP ---
    cmp byte [esi], "H"
    jne .chk_ver
    cmp byte [esi+1], "E"
    jne .chk_ver
    mov esi, msg_cmd_help
    call print_vga
    jmp .cmd_done

; --- VER ---
.chk_ver:
    cmp byte [esi], "V"
    jne .chk_sys
    cmp byte [esi+1], "E"
    jne .chk_sys
    mov esi, msg_cmd_ver
    call print_vga
    jmp .cmd_done

; --- SYSINFO ---
.chk_sys:
    cmp byte [esi], "S"
    jne .chk_drv
    cmp byte [esi+1], "Y"
    jne .chk_drv
    mov esi, msg_cmd_sys
    call print_vga
    jmp .cmd_done

; --- DRIVERS ---
.chk_drv:
    cmp byte [esi], "D"
    jne .chk_mse
    cmp byte [esi+1], "R"
    jne .chk_mse
    mov esi, msg_cmd_drv
    call print_vga
    jmp .cmd_done

; --- MOUSE ---
.chk_mse:
    cmp byte [esi], "M"
    jne .chk_vbe
    cmp byte [esi+1], "O"
    jne .chk_vbe
    mov esi, msg_cmd_mse
    call print_vga
    jmp .cmd_done

; --- VBEINFO ---
.chk_vbe:
    cmp byte [esi], "V"
    jne .chk_ls
    cmp byte [esi+1], "B"
    jne .chk_ls
    mov esi, msg_cmd_vbe
    call print_vga
    jmp .cmd_done

; --- LS ---
.chk_ls:
    cmp byte [esi], "L"
    jne .chk_write
    cmp byte [esi+1], "S"
    jne .chk_write
    call cmd_ls
    jmp .cmd_done

; --- WRITE ---
.chk_write:
    cmp byte [esi], "W"
    jne .chk_cat
    cmp byte [esi+1], "R"
    jne .chk_cat
    call cmd_write
    jmp .cmd_done

; --- CAT ---
.chk_cat:
    cmp byte [esi], "C"
    jne .chk_del
    cmp byte [esi+1], "A"
    jne .chk_del
    call cmd_cat
    jmp .cmd_done

; --- DELETE / RM ---
.chk_del:
    cmp byte [esi], "D"
    je .do_del
    cmp byte [esi], "R"
    jne .chk_clr
    cmp byte [esi+1], "M"
    jne .chk_clr
.do_del:
    call cmd_delete
    jmp .cmd_done

; --- CLEAR ---
.chk_clr:
    cmp byte [esi], "C"
    jne .chk_reb
    cmp byte [esi+1], "L"
    jne .chk_reb
    call clear_vga
    jmp .cmd_done

; --- REBOOT ---
.chk_reb:
    cmp byte [esi], "R"
    jne .unk
    cmp byte [esi+1], "E"
    jne .unk
    mov al, 0xFE
    out 0x64, al
    jmp .cmd_done

.unk:
    mov esi, msg_unknown
    call print_vga

.cmd_done:
    popa
    ret

cmd_ls:
    pusha
    mov ecx, 0
.ls_loop:
    cmp ecx, 8
    jge .ls_done
    mov al, [vfs_used + ecx]
    cmp al, 1
    jne .ls_next

    mov esi, msg_newline
    call print_vga

    mov eax, ecx
    shl eax, 6
    add eax, vfs_names
    mov esi, eax
    call print_vga
.ls_next:
    inc ecx
    jmp .ls_loop
.ls_done:
    popa
    ret

cmd_write:
    pusha
    mov ecx, 1
.find_slot:
    cmp ecx, 8
    jge .w_done
    mov al, [vfs_used + ecx]
    cmp al, 0
    je .slot_found
    inc ecx
    jmp .find_slot

.slot_found:
    mov byte [vfs_used + ecx], 1

    mov edi, ecx
    shl edi, 6
    add edi, vfs_names
    mov dword [edi], "DOC1"
    mov dword [edi+4], ".TXT"
    mov byte [edi+8], 0

    mov edi, ecx
    shl edi, 8
    add edi, vfs_data
    mov dword [edi], "TEXT"
    mov dword [edi+4], "O RO"
    mov dword [edi+8], "DAND"
    mov dword [edi+12], "O SK"
    mov dword [edi+16], "G!"
    mov byte [edi+20], 0

    mov esi, msg_write_ok
    call print_vga
.w_done:
    popa
    ret

cmd_cat:
    pusha
    mov ecx, 0
.cat_loop:
    cmp ecx, 8
    jge .cat_not_found
    mov al, [vfs_used + ecx]
    cmp al, 1
    jne .cat_next

    mov eax, ecx
    shl eax, 6
    add eax, vfs_names
    mov esi, eax

    mov edi, cmd_buffer
    add edi, 4

.cmp_name:
    mov bl, [esi]
    mov bh, [edi]
    cmp bl, 0
    je .check_end
    cmp bl, bh
    jne .cat_next
    inc esi
    inc edi
    jmp .cmp_name

.check_end:
    cmp bh, 0
    je .cat_found
    cmp bh, " "
    je .cat_found
    jmp .cat_next

.cat_found:
    mov esi, msg_newline
    call print_vga
    mov eax, ecx
    shl eax, 8
    add eax, vfs_data
    mov esi, eax
    call print_vga
    popa
    ret

.cat_next:
    inc ecx
    jmp .cat_loop

.cat_not_found:
    mov esi, msg_not_found
    call print_vga
    popa
    ret

cmd_delete:
    pusha
    mov esi, cmd_buffer
    add esi, 4
.check_panic:
    cmp byte [esi], "S"
    je .trigger_panic
    cmp byte [esi], "."
    je .trigger_panic

    mov byte [vfs_used + 1], 0
    mov esi, msg_del_ok
    call print_vga
    popa
    ret

.trigger_panic:
    mov byte [vfs_used], 0
    call clear_vga

    mov edi, 0xB8000
    mov ecx, 2000
    mov ax, 0x4F20
    rep stosw

    mov dword [cursor_pos], 0
    mov esi, msg_panic_1
    call print_vga
    mov esi, msg_panic_2
    call print_vga
    mov esi, msg_panic_3
    call print_vga

    mov ecx, 0x0FFFFFFF
.delay:
    loop .delay

    mov al, 0xFE
    out 0x64, al
    popa
    ret