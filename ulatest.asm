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

ULATEST_ROW	equ 0x58a0
	
ulatest

;	Assume RAM is working, this isn't going to end well if not.
; 	Initialize stack to top of lower RAM

	ld sp, 0x7fff

;
;	Write some data to Screen 1.
;	This'll just write to the C000 area on a 48K machine,
;	which isn't being used anyway.
;

	ld a, 7
	call pagein
	
	BLANKMEM 0xc000, 0x1800, 0x00
	BLANKMEM 0xd800, 0x300, 0x20
	
	ld a, 0
	call pagein

;	Init system variables

	xor a
	
	ld (v_fail_ic), a
	ld (v_fail_ic_contend), a
	ld (v_fail_ic_uncontend), a

	ld (v_column), a
    	ld (v_row), a
	ld (v_bold), a
	ld (v_ulatest_pos), a
	cpl
	ld (v_ulatest_dir), a
	
	ld a, 56
	ld (v_attr), a
	ld a, 6
	ld (v_width), a
		
	ld hl, ulatest_scan
	ld (v_userint), hl

	ld hl, 0
	ld (v_intcount), hl
	ld (v_intcount + 2), hl
	
	
;	IX will be used as the last recorded interrupt counter value
;	IY will be the number of cycles that IX was the same
;	If IY exceeds 100 cycles then interrupts are considered to have
;	failed

	ld ix, hl
	ld iy, hl
	
;	Copy ROM paging routines to RAM

	ld hl, rompage_reloc
	ld de, do_rompage_reloc
	ld bc, end_rompage_reloc-rompage_reloc
	ldir
	
;	Detect diagnostic board type

	ld a, 0x00
	call do_rompage_reloc
	
	call cls
	ld a, BORDERWHT
	out (0xfe), a
	
	ld hl, str_ulabanner
	call print_header
	
	ld hl, str_ulainresult
	call print

	ld a, 8
	ld (v_width), a
	ld hl, str_ulain_row
	call print
	ld a, 6
	ld (v_width), a

	ld hl, str_ulaint_test
	call print
	
	ld hl, str_ulaselecttest
	call print
	ld hl, str_ulaexit
	call print
	
	call print_footer
	
;	Start the interrupt service routine

	ld a, intvec2 / 256
	ld i, a
	im 2
	ei
	
ulatest_loop
	
; 	Display the status of the bits from a read
;	of port 0xFE. Black on white - 0, 
;	White on black - 1.

	xor a
	in a, (0xfe)
	ld c, a
	ld hl, 0x5858 	; Start of 76543210 on screen
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
	
;	Check how we're doing with the interrupt count
	
	ld hl, (v_intcount)
	ld de, ix
	sub hl, de
	ld a, h
	or l
	jr nz, interrupt_detected


;	Uh-oh, no increase, bump IY and see if the high
;	byte is non zero

	inc iy
	ld a, iyh
	cp 0
	jp z, check_input
	
;	More than 100 cycles have occurred since an interrupt,
;	something's failed to do with interrupt generation. Flag it.

	ld hl, str_ulaintfail
	call print
	jp check_input
	
interrupt_detected

;	Check how many interrupts have passed - we wouldn't ever
;	expect more than one - so flag a fail if we've detected
;	multiples.

	ld a, l
	cp 1
	jr z, interrupt_ok
	
	ld hl, str_ulaintfail
	call print
	
;	Counter's ok, reset the counters and print the latest

interrupt_ok

	ld ix, (v_intcount)
	ld iy, 0
	
check_input
		
;	Check input for keys 1, 2, 3 or 4.

	ld bc, 0xf7fe
	in a, (c)
	bit 0, a
	jr z, out_mictone
	bit 1, a
	jr z, out_eartone
	bit 2, a
	jr z, test_border
	bit 3, a
	jp z, test_screen
	
;	Check for Break (Caps Shift+Space)

	ld bc, 0x7ffe
	in a, (c)
	bit 0, a
	jp nz, ulatest_loop		; Space not pressed
	ld bc, 0xfefe
	in a, (c)
	bit 0, a
	jp nz, ulatest_loop		; Caps shift not pressed

;	Just do a simple reset if diagboard hardware isn't detected

	ld a, (v_testhwtype)
	cp 0
	jp z, 0000

;	Else page the diagnostic ROM out and start the machine's own ROM
	
	ld bc, 0x1234
	ld a, 2
	call do_rompage_reloc 	; Page out and restart the machine	

	
out_mictone
	
;	Test effectiveness of outputting sound via bit 3 (MIC).

	di	
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
	ei
	jp ulatest_loop
	
out_eartone
	
;	Test effectiveness of outputting sound via bit 4 (EAR).
	
	di
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
	ei
	jp ulatest_loop

test_border

;	Test that the border colour can be changed successfully.
	
	di
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
	ei
	jp ulatest_loop

test_screen

	di

	ld a, 0x9b
	ld h, a
	
test_screen_loop

	ld a, 4
	out (0xfe), a
	ld bc, 0x7ffd
	ld a, 0x08
	out (c), a
	
	ld b, h
	
test_screen_loop1
	
	djnz test_screen_loop1

	ld a, 7
	out (0xfe), a
	ld bc, 0x7ffd
	ld a, 0x00
	out (c), a

	ld b, h
	
test_screen_loop2
	
	djnz test_screen_loop2
	
	in a, (0xfe)
	and 0x1f
	cp 0x1f
	jr nz, test_screen_loop
	
	ei
	jp ulatest_loop

;
;	Interrupt routine to run the ula test visual indication.
;
ulatest_scan

	ld hl, ULATEST_ROW
	ld b, 0x20
	ld a, 0x7
	ld c, a
	
ulatest_scan_fade

	ld a, (hl)
	cp 0x3f
	jr nc, ulatest_scan_fade_2
	add c

ulatest_scan_fade_2

	ld (hl), a
	inc hl
	djnz ulatest_scan_fade
	
	
;	Draw current scan dot

	ld hl, ULATEST_ROW
	ld a, (v_ulatest_pos)
	or l
	ld l, a
	ld a, 7
	ld (hl), a

; 	Move scan dot left or right	

	ld a, (v_ulatest_dir)
	cp 0
	jr z, ulatest_scan_right
	
	ld a, (v_ulatest_pos)
	inc a
	ld (v_ulatest_pos), a
	cp 0x1f
	ret nz
	jr ulatest_scan_changedir
	
ulatest_scan_right

	ld a, (v_ulatest_pos)
	dec a
	ld (v_ulatest_pos), a
	cp 0
	ret nz
	
ulatest_scan_changedir

	ld a, (v_ulatest_dir)
	cpl
	ld (v_ulatest_dir), a
	
	ret

str_ulabanner

	defb	TEXTBOLD, "ULA Test", TEXTNORM, 0	
	
str_ulainresult

	defb AT, 2, 0, "ULA Read....................... ", 0
	
str_ulain_row

	defb AT, 2, 24 * 8, "76543210", 0

str_ulaint_test
	
	defb AT, 4, 0, "Interrupt test (movement should be smooth)", 0
	
str_ulaintfail

	defb AT, 5, 13 * 6, ATTR, ATTR_TRANS, TEXTBOLD, "FAIL FAIL FAIL", TEXTNORM, ATTR, 56, 0
	
str_ulaselecttest

	defb AT, 7, 0, "Select:"
	defb AT, 9, 0, "1) Output tone to MIC port"
	defb AT, 10, 0, "2) Output tone to EAR port"
	defb AT, 11, 0, "3) Test border generation"
	defb AT, 12, 0, "4) Test screen switching (128K)", 0

str_ulaexit

	defb AT, 14, 12 * 6, "Hold BREAK to exit", 0