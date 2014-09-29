;
;	This code came from http://map.tni.nl/sources/external/z80bits.html#5.1
;	Slightly modified by Dylan Smith for the tester.
;	'romcrc' code needs to be shifted into RAM to be run since we're going
;	to page out the testing rom while doing it.
;	

romcrc

	ld a, %00100000 ; bit 5 controls /ROMCS
	out (ROMPAGE_PORT), a
	ld de, 0

;	Note: byte counter is modified compared to orginal code.

Crc16	

	ld hl,0xFFFF

Read

	ld a, (de)
	inc	de
	xor	h
	ld	h,a
	ld	b,8

CrcByte
    
	add	hl, hl
	jr	nc, Next
	ld	a,h
	xor	10h
	ld	h,a
	ld	a,l
	xor	21h
	ld	l,a

Next	

	djnz	CrcByte
	ld a, d
	cp 0x40     ; 0x4000 = end of rom
	jr	nz,Read

;	Page our ROM back in
	
	xor a
	out (ROMPAGE_PORT), a
	ret
	   
endromcrc   

