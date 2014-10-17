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
;	ulatest.asm
;	

ulatest

;	Assume RAM is working, this isn't going to end well if not.

; 	Initialize system variables

	xor a
	ld (v_fail_ic), a
	ld (v_fail_ic_contend), a
	ld (v_fail_ic_uncontend), a

	ld (v_column), a
    	ld (v_row), a
	ld (v_bold), a
	ld a, 56
	ld (v_attr), a
	
	call cls
	ld a, BORDERWHT
	out (0xfe), a
	
	ld hl, str_banner
	call print
	ld hl, str_ulatest
	call print
	
	ld hl, str_ulainresult
	call print
	ld hl, str_loadingstripe
	call print
	ld hl, str_ulaselecttest
	call print
	ld hl, str_ulaexit
	call print
	
ulatest_loop
	
; 	Display the status of the bits from a read
;	of port 0xFE. Black on white - 0, 
;	White on black - 1.

	xor a
	in a, (0xfe)
	ld c, a
	ld hl, 0x588a 	; Start of 76543210 on screen
	ld de, 0x4778	; D = B/W attrs, E = W/B
	ld b, 8
	
inval_print

;	Check and set the correct colour for the current
;	bit being checked

	ld a, d
	bit 7, c
	jr z, inval_print2
	ld a, e
	
inval_print2

	ld (hl), a
	inc hl
	sll c
	djnz inval_print
	
;	Check and specifically output EAR port as if
;	it were striped in the paper region.
	
	ld c, 0x08
	xor a
	in a, (0xfe)
	bit 6, a
	jr z, ear_notset
	ld c, 0x30

ear_notset

;	Write to a 2x3 block of attributes as quickly as possible

	ld a, c
	ld hl, 0x587c
	LDHL4TIMES
	ld hl, 0x589c
	LDHL4TIMES
	ld hl, 0x58bc
	LDHL4TIMES
	
;	Check input for keys 1, 2 or 3.

	ld bc, 0xf7fe
	in a, (c)
	bit 0, a
	jr z, out_mictone
	bit 1, a
	jr z, out_eartone
	bit 2, a
	jr z, test_border
	
	
;	Check for Break (Caps Shift+Space)

	ld bc, 0x7ffe
	in a, (c)
	bit 0, a
	jr nz, ulatest_loop		; Space not pressed
	ld bc, 0xfefe
	in a, (c)
	bit 0, a
	jr nz, ulatest_loop		; Caps shift not pressed

	jp restart			; Page out and restart the machine	

	
out_mictone
	
;	Test effectiveness of outputting sound via bit 3 (MIC).
	
	ld c, 0x0a

out_mictone1

	ld a, c
	out (0xfe), a
	xor 0x0f
	ld c, a
	ld b, 0x30

out_mictone2
	djnz out_mictone2
	
;	Check if we're holding any keys down, keep going if so

	xor a
	in a, (0xfe)
	and 0x1f
	cp 0x1f
	jr nz, out_mictone1
	
;	Restore border to white and return

	ld a, BORDERWHT	
	out (0xfe), a
	jp ulatest_loop
	
out_eartone
	
;	Test effectiveness of outputting sound via bit 4 (EAR).
	
	ld c, 0x11

out_eartone1

	ld a, c
	out (0xfe), a
	xor 0x17
	ld c, a
	
	ld b, 0x30

out_eartone2
	djnz out_eartone2
	
;	Check if we're holding any keys down, keep going if so

	xor a
	in a, (0xfe)
	and 0x1f
	cp 0x1f
	jr nz, out_eartone1
	
;	Restore border to white and return

	ld a, BORDERWHT	
	out (0xfe), a
	jp ulatest_loop

test_border

;	Test that the border colour can be changed successfully.

	ld c, 0

test_border1

;	Set and cycle border colour

	ld a, c
	out (0xfe), a
	inc a
	and 0x7
	ld c, a
	
	ld b, 0xa2

test_border2

	djnz test_border2
	
;	Check if we're holding any keys down, keep going if so

	xor a
	in a, (0xfe)
	and 0x1f
	cp 0x1f
	jr nz, test_border1
	
;	Restore border to white and return

	ld a, BORDERWHT	
	out (0xfe), a
	jp ulatest_loop
	
str_ulatest

	defb AT, 2, 9, TEXTBOLD, "* ULA TEST *", TEXTNORM, 0
	
str_ulainresult

	defb AT, 4, 0, "ULA READ: 76543210", 0
	
str_loadingstripe

	defb AT, 4, 20, "EAR IN:", 0

str_ulaselecttest

	defb AT, 6, 0, "Select:"
	defb AT, 8, 0, "1) Output tone to MIC port"
	defb AT, 9, 0, "2) Output tone to EAR port"
	defb AT, 10, 0, "3) Test border generation", 0

str_ulaexit

	defb AT, 13, 7, "Hold BREAK to exit", 0