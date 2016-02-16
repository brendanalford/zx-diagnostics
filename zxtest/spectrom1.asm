	org 0

; 	Ints must be disabled as we don't have
; 	anywhere reliable to put a stack yet

	di
	
	ld hl, 0x4000
	ld de, 0x4001
	ld bc, 6912
	ld (hl), 0
	ldir
	
start
	
	ld a, 2
	out (0xfe), a
	ld a, 16
	ld hl, 0x5800
	ld de, 0x5801
	ld bc, 0x300
	ld (hl), a
	ldir
	
	jr start
	
	BLOCK 0x4000-$, 0xff

	