[BITS 32]
global shell_start

extern vga_print
extern vga_putc
extern vga_backspace
extern vga_clear
extern keyboard_getchar
extern gmfs_list
extern gmfs_read
extern pit_get_ticks
extern gme_load_and_run

section .data
prompt_str:     db "SKG> ", 0

; Tabela de Comandos
cmd_help:       db "help", 0
cmd_dir:        db "dir", 0
cmd_ls:         db "ls", 0
cmd_cls:        db "cls", 0
cmd_echo:       db "echo", 0
cmd_type:       db "type", 0
cmd_run:        db "run", 0
cmd_mem:        db "mem", 0
cmd_ver:        db "ver", 0
cmd_time:       db "time", 0
cmd_date:       db "date", 0
cmd_reboot:     db "reboot", 0
cmd_shutdown:   db "shutdown", 0

help_menu:
    db "Comandos do SKG Shell:", 0x0A
    db "  help, dir, ls, cls, echo, type, run, mem, ver, time, date, reboot, shutdown", 0x0A, 0

version_msg:    db "Source Kernel GM (SKG) [Versao 5.1 Stable] 32-bit", 0x0A, 0
memory_msg:     db "RAM Total: 128 MB | Heap: 16 MB | Paginacao: ATIVA", 0x0A, 0
date_msg:       db "Data Atual do Sistema: 27/07/2026", 0x0A, 0
time_prefix:    db "Ticks PIT (100Hz): ", 0
unknown_cmd:    db "Comando invalido! Digite 'help'.", 0x0A, 0
file_err_msg:   db "Erro: Arquivo nao encontrado.", 0x0A, 0
shutdown_msg:   db 0x0A, "Sistema desligado. CPU Halted.", 0x0A, 0

section .bss
cmd_buffer:     resb 128
arg_buffer:     resb 128

section .text
shell_start:
.shell_loop:
    mov esi, prompt_str
    call vga_print

    call clear_buffers
    call read_line_input
    call execute_command
    jmp .shell_loop

clear_buffers:
    pusha
    mov edi, cmd_buffer
    mov ecx, 128
    xor eax, eax
    rep stosb
    mov edi, arg_buffer
    mov ecx, 128
    xor eax, eax
    rep stosb
    popa
    ret

read_line_input:
    mov edi, cmd_buffer
    mov ecx, 0

.key_loop:
    call keyboard_getchar
    cmp al, 13                  ; Enter (\r)
    je .input_finished
    cmp al, 10                  ; Enter (\n)
    je .input_finished
    cmp al, 8                   ; Backspace
    je .input_backspace

    cmp ecx, 120
    jae .key_loop

    mov [edi + ecx], al
    inc ecx
    call vga_putc
    jmp .key_loop

.input_backspace:
    test ecx, ecx
    jz .key_loop
    dec ecx
    call vga_backspace
    jmp .key_loop

.input_finished:
    mov byte [edi + ecx], 0
    mov al, 0x0A
    call vga_putc
    ret

execute_command:
    mov esi, cmd_buffer
    cmp byte [esi], 0
    je .exec_done

    call parse_arguments

    mov esi, cmd_buffer
    mov edi, cmd_help
    call compare_strings
    jz .run_help

    mov edi, cmd_dir
    call compare_strings
    jz .run_dir

    mov edi, cmd_ls
    call compare_strings
    jz .run_dir

    mov edi, cmd_cls
    call compare_strings
    jz .run_cls

    mov edi, cmd_echo
    call compare_strings
    jz .run_echo

    mov edi, cmd_type
    call compare_strings
    jz .run_type

    mov edi, cmd_run
    call compare_strings
    jz .run_run

    mov edi, cmd_mem
    call compare_strings
    jz .run_mem

    mov edi, cmd_ver
    call compare_strings
    jz .run_ver

    mov edi, cmd_time
    call compare_strings
    jz .run_time

    mov edi, cmd_date
    call compare_strings
    jz .run_date

    mov edi, cmd_reboot
    call compare_strings
    jz .run_reboot

    mov edi, cmd_shutdown
    call compare_strings
    jz .run_shutdown

    mov esi, unknown_cmd
    call vga_print
.exec_done:
    ret

.run_help:
    mov esi, help_menu
    call vga_print
    ret

.run_dir:
    call gmfs_list
    ret

.run_cls:
    call vga_clear
    ret

.run_echo:
    mov esi, arg_buffer
    call vga_print
    mov al, 0x0A
    call vga_putc
    ret

.run_type:
    mov esi, arg_buffer
    call gmfs_read
    test eax, eax
    jz .type_err
    mov esi, eax
    call vga_print
    mov al, 0x0A
    call vga_putc
    ret
.type_err:
    mov esi, file_err_msg
    call vga_print
    ret

.run_run:
    mov esi, arg_buffer
    call gme_load_and_run
    ret

.run_mem:
    mov esi, memory_msg
    call vga_print
    ret

.run_ver:
    mov esi, version_msg
    call vga_print
    ret

.run_time:
    mov esi, time_prefix
    call vga_print
    call pit_get_ticks
    call print_dec_num
    mov al, 0x0A
    call vga_putc
    ret

.run_date:
    mov esi, date_msg
    call vga_print
    ret

.run_reboot:
    mov al, 0xFE
    out 0x64, al
    ret

.run_shutdown:
    mov esi, shutdown_msg
    call vga_print
    cli
.hlt_loop:
    hlt
    jmp .hlt_loop

parse_arguments:
    pusha
    mov esi, cmd_buffer
    mov edi, arg_buffer

.find_space:
    mov al, [esi]
    test al, al
    jz .no_args
    cmp al, ' '
    je .split
    inc esi
    jmp .find_space

.split:
    mov byte [esi], 0
    inc esi

.copy_arg:
    mov al, [esi]
    mov [edi], al
    test al, al
    jz .no_args
    inc esi
    inc edi
    jmp .copy_arg

.no_args:
    popa
    ret

compare_strings:
    push esi
    push edi
.c_loop:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne .c_diff
    test al, al
    jz .c_match
    inc esi
    inc edi
    jmp .c_loop
.c_diff:
    pop edi
    pop esi
    mov eax, 1
    ret
.c_match:
    pop edi
    pop esi
    xor eax, eax
    ret

print_dec_num:
    pusha
    mov ecx, 0
    mov ebx, 10
.p_div:
    xor edx, edx
    div ebx
    push edx
    inc ecx
    test eax, eax
    jnz .p_div
.p_print:
    pop eax
    add al, '0'
    call vga_putc
    loop .p_print
    popa
    ret
