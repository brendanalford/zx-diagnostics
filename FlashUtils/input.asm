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
;	input.asm
;	

	define CAPS_SHIFT	0xaa
	define SYMBOL_SHIFT	0x88
	define ENTER		0x13
	
keylookup
	defb " ", SYMBOL_SHIFT, "MNB", ENTER ,"LKJHPOIUY09876"
	defb "12345QWERTASDFG", CAPS_SHIFT, "ZXCV"
	
;
;	Scans the keyboard for a single keypress. 
;	Returns with carry flag set and key in accumulator if 
;	found, or carry flag clear if no key pressed.
;

scan_keys
	push hl
	push bc
	ld hl, keylookup
	ld bc, 0x7ffe

key_row_read

	in a, (c)
	push bc
	ld b, 5

key_loop

	bit 0, a
	jr nz, key_next

;	Key found, lookup from table and store in A
	ld a, (hl)
	pop bc
	pop bc
	pop hl
	scf
	ret

key_next	
	inc hl
	srl a
	djnz key_loop	
	
	pop bc
	rrc b
	ld a, b
	cp 0x7f
	jr nz, key_row_read
	
	pop bc
	pop hl
	ccf
	ret
	
;
;	Waits for a key press (and release)
;	Returns the key pressed in A
;

get_key
	push bc
	call scan_keys
	jr c, get_key
	ld b, a

debounce_key
	
	call scan_keys
	jr nc, debounce_key
	ld a, b
	pop bc
	ret