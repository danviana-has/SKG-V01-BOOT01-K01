[BITS 32]
db "GMD1"
dd gmfs_init
dd gmfs_dispatch
dd 0x00010000

gmfs_init: ret
gmfs_dispatch: ret
