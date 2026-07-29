[BITS 32]
db "GMD1"
dd pit_init
dd pit_dispatch
dd 0x00010000

pit_init: ret
pit_dispatch: ret
