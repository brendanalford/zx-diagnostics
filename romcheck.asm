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
;	romcheck.asm
;	

;
;	A standalone ROM crc calculator designed to be loaded and run from 
;	tape, so that known ROMS can be added to the test tool.
;
	org 0xfd00	; 64768
	
	di
	ld de, 0
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
	
	push hl
	pop bc
	ei
	ret	   
	
;	Known checksums:
;	48K Spectrum		FD5E
;	128K Spectrum		EFFC
;	Grey +2 Eng		2AA3
;	Grey +2 Spa		
;	Grey +2 Fra	
;
;
;
;
;

	