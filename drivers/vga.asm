[BITS 32]
db "GMD1"
dd vga_init
dd vga_dispatch
dd 0x00010000

vga_init: ret
vga_dispatch: ret
