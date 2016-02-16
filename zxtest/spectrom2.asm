	org 0
	
	di
	
	ld hl, 0x4000
	ld de, 0x4001
	ld bc, 6912
	ld (hl), 0
	ldir
	
start2
	
	ld a, 4
	out (0xfe), a
	ld a, 32
	ld hl, 0x5800
	ld de, 0x5801
	ld bc, 0x300
	ld (hl), a
	ldir
	
	jr start2
	
	BLOCK 0x4000-$, 0xff