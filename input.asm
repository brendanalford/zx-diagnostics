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

	define CAPS_SHIFT	0x01
	define SYMBOL_SHIFT	0x02

	define KEY_LEFT		0x05
	define KEY_RIGHT	0x06
	define KEY_UP		0x07
	define KEY_DOWN		0x08
	define BREAK		0x09
	define DELETE		0x10
	define ENTER		0x13


keylookup_norm

	defb " ", SYMBOL_SHIFT, "MNB", ENTER ,"LKJHPOIUY09876"
	defb "12345QWERTASDFG", CAPS_SHIFT, "ZXCV"

keylookup_lower

	defb " ", SYMBOL_SHIFT, "mnb", ENTER ,"lkjhpoiuy09876"
	defb "12345qwertasdfg", CAPS_SHIFT, "zxcv"

keylookup_caps

	defb BREAK, SYMBOL_SHIFT, "MNB", ENTER ,"LKJHPOIUY"
	defb DELETE, "9", KEY_RIGHT, KEY_UP, KEY_DOWN
	defb "1234", KEY_LEFT, "QWERTASDFG", CAPS_SHIFT, "ZXCV"

keylookup_symshift

	defb " ", SYMBOL_SHIFT, ".,*", ENTER ,"=+-^", 0x22, ";i][_)('&"
	defb "!@#$%qwe<>~|\\{}", CAPS_SHIFT, ":", 0x60, "?/"


;
;	Scans the keyboard for a single keypress.
;	A set to 1 on entry implies full upper/lower case.
;	Returns with carry flag set and key in accumulator if
;	found, or carry flag clear if no key pressed.
;

scan_keys

	push ix
	push hl
	push bc
	push af

	ld bc, 0x7ffe
	ld ix, v_keybuffer

key_row_read

	in a, (c)
	and 0x1f
	ld (ix), a
	inc ix

	rrc b
	ld a, b
	cp 0x7f
	jr nz, key_row_read

; 	Rows read into bitmap

	pop af

 	ld ix, v_keybuffer
	ld hl, keylookup_lower

	cp 1
	jr z, no_force_upcase

	ld hl, keylookup_norm

no_force_upcase

	bit 0, (ix+7)
	jr nz, no_caps_pressed

	ld hl, keylookup_caps

no_caps_pressed

	bit 1, (ix)
	jr nz, no_sym_pressed

	ld hl, keylookup_symshift

no_sym_pressed

	ld b, 8

map_row_read

	ld a, 0xff
	ld c, b
	ld b, 5

key_loop

	bit 0, (ix)
	jr nz, key_next

;	Key found, lookup from table

	ld a, (hl)
	cp 0x03

;	If it's Caps or Symbol shift, continue scanning

	jr c, key_next

;	Else return with key in A

	pop bc
	pop hl
	pop ix
	scf
	ret

key_next

	inc hl
	srl (ix)
	djnz key_loop

map_row_next

	inc ix
	ld b, c
	djnz map_row_read

	pop bc
	cp 0xff
	jr z, no_key
	pop hl
	pop ix
	scf
	ret

no_key

	pop hl
	pop ix
	and a 	; reset carry flag
	ret

;
;	Waits for a key press (and release)
;	Returns the key pressed in A
;

get_key

	push bc

get_key_scan

	call scan_keys
	jr nc, get_key_scan
	ld b, a

debounce_key

	xor a
	in a, (0xfe)
	and 0x1f
	cp 0x1f
	jr nz, debounce_key
	ld a, b
	pop bc
	ret

	IFDEF TESTROM

;	Check to see if the upper three bits of the Kempston port are
; at any time non-zero - this would indicate a faulty interface or
; one that's not present.
; Bit 7 of v_kempston reflects result.
detect_kempston

	ld hl, v_kempston
	xor a
	ld (hl), a

detect_kemp_loop

	in a, (0x1f)
	ld c, a
	and 0xe0

;	Are any of the top bits set?

	cp 0
	ret nz

; Loop a bit to make sure

	djnz detect_kemp_loop

; Kempston appears to be present

	set  7, (hl)
	ret

; Reads Kempston I/F values (if present) and stores them
; in system variable v_kempston.
read_kempston

	ld hl, v_kempston
	bit 7, (hl)
	ret z

	in a, (0x1f)
	and 0x1f
	or 0x80
	ld (hl), a
	ret

	ENDIF
