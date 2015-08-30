;
;	ZX Diagnostics - fixing ZX Spectrums in the 21st Century
;	https://github.com/brendanalford/zx-diagnostics
;
;	Original code by Dylan Smith
;	Modifications and 128K support by Brendan Alford
;
;	This code is free software; you can redistribute it and/or
;	modify it under the terms of the GNU Lesser General Public
;	License as published by the Free Software Foundation;
;	version 2.1 of the License.
;
;	This code is distributed in the hope that it will be useful,
;	but WITHOUT ANY WARRANTY; without even the implied warranty of
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;	Lesser General Public License for more details.
;
;	crc16.asm
;	

;
;	This code came from http://map.tni.nl/sources/external/z80bits.html#5.1
;	Slightly modified by Dylan Smith for the tester.
;	'romcrc' code needs to be shifted into RAM to be run since we're going
;	to page out the testing rom while doing it.
;	Returns carry flag set if ROM could not be paged out, reset otherwise.
;	

romcrc

	ld a, 2
	call sys_rompaging
	
startcrc

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
	
;	Ordinarily we'd check for the end of ROM:
;	0x4000. However the ZXC3/ZXC4 carts use
;	memory mapped paging in the 3FC0-3FFF range
;	which means we can't touch that. So let's just
;	avoid it altogether.

	ld a, d
	cp 0x3f     
	jr	nz, Read
	ld a, e
	cp 0xc0
	jr nz, Read

;	Page our ROM back in
	
	ld a, 1
	call sys_rompaging
	ret
	   
romcrc_end   

