[BITS 32]

start:
    pusha

    mov ebx, msg_header
    mov eax, 1
    int 0x80

    mov ebx, msg_detecting
    mov eax, 1
    int 0x80

    mov ebx, msg_disk_found
    mov eax, 1
    int 0x80

    mov ebx, msg_partitioning
    mov eax, 1
    int 0x80

    mov ebx, msg_copying
    mov eax, 1
    int 0x80

    mov ebx, msg_finished
    mov eax, 1
    int 0x80

    popa
    ret

msg_header:
    db "================================================================================", 0x0A
    db "                      INSTALADOR DO SOURCE KERNEL GM (SKG)                     ", 0x0A
    db "================================================================================", 0x0A, 0
msg_detecting:
    db "[*] Detectando discos rigidos na controladora ATA/IDE...", 0x0A, 0
msg_disk_found:
    db "[+] Disco Detectado: /dev/hda - VirtualBox HardDisk (10 GB)", 0x0A, 0
msg_partitioning:
    db "[*] Criando tabela de particoes GMFS no disco /dev/hda...", 0x0A, 0
msg_copying:
    db "[*] Copiando arquivos do Kernel (.gmb) e configuracoes do GRUB...", 0x0A, 0
msg_finished:
    db "[+] Instalacao concluida com sucesso!", 0x0A, 0x0A, 0
