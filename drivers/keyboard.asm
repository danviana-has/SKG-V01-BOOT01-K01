[BITS 32]
db "GMD1"
dd kbd_init
dd kbd_dispatch
dd 0x00010000

kbd_init: ret
kbd_dispatch: ret
