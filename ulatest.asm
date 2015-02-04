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
	
	ld a, 56
	ld (v_attr), a
	
	ld a, 1
	ld (v_rtcenable), a
	
	ld hl, 0
	ld (v_intcount), hl
	ld (v_intcount + 2), hl
	ld (v_rtc), hl
	ld (v_rtc + 2), hl
	
;	IX will be used as the last recorded interrupt counter value
;	IY will be the number of cycles that IX was the same
;	If IY exceeds 100 cycles then interrupts are considered to have
;	failed

	ld ix, hl
	ld iy, hl
	
	call cls
	ld a, BORDERWHT
	out (0xfe), a
	
	ld hl, str_banner
	call print
	ld hl, str_ulatest
	call print
	
	ld hl, str_ulainresult
	call print

	ld hl, str_ulainterrupt
	call print
	
	ld hl, str_ulaselecttest
	call print
	ld hl, str_ulaexit
	call print
	
;	Start the interrupt clock

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
	ld hl, 0x5898 	; Start of 76543210 on screen
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

	ld hl, str_ulacounter
	call print

;	Print the 32-bit counter

	ld hl, (v_intcount + 2)
	ld de, v_hexstr
	call Num2Hex
	ld hl, v_hexstr
	call print
	
	ld hl, (v_intcount)
	ld de, v_hexstr
	call Num2Hex	
	ld hl, v_hexstr
	call print

; 	Do the real time counter print

	ld hl, str_rtccounter
	call print

;	Print hours

	xor a
	ld h, a
	ld a, (v_rtc)
	ld l, a
	ld de, v_decstr
	call Num2Dec
	ld hl, v_decstr + 3
	call print
	ld hl, str_colon
	call print
	
;	Print minutes

	xor a
	ld h, a
	ld a, (v_rtc + 1)
	ld l, a	
	ld de, v_decstr
	call Num2Dec
	ld hl, v_decstr + 3
	call print

	ld hl, str_colon
	ld a, (v_rtc + 3)
	cp 25
	jr c, blink_colon
	ld hl, str_nocolon
	
blink_colon

	call print

;	Print seconds

	xor a
	ld h, a
	ld a, (v_rtc + 2)
	ld l, a
	ld de, v_decstr
	call Num2Dec
	ld hl, v_decstr + 3
	call print

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

	jp restart			; Page out and restart the machine	

	
out_mictone
	
;	Test effectiveness of outputting sound via bit 3 (MIC).

	di	
	ld hl, str_ulacounterblank
	call print
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
	ld hl, str_ulacounterblank
	call print
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
	ld hl, str_ulacounterblank
	call print
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
	ld hl, str_ulacounterblank
	call print

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
	
str_ulatest

	defb AT, 2, 9, TEXTBOLD, "* ULA TEST *", TEXTNORM, 0
	
str_ulainresult

	defb AT, 4, 0, "ULA Read............... 76543210", 0
	
str_ulainterrupt

	defb AT, 6, 0, "Interrupt counter......", AT, 7, 0, "Real time elapsed......", 0
	
str_ulacounter

	defb AT, 6, 24, 0
	
str_ulacounterblank

	defb AT, 6, 24, "--------"
	defb AT, 7, 24, "--------", 0
	
str_rtccounter

	defb AT, 7, 24, 0
		
str_colon
	
	defb ":", 0

str_nocolon
	
	defb " ", 0
	
str_ulaintfail

	defb AT, 6, 18, INK, 2, TEXTBOLD, " FAIL", TEXTNORM, ATTR, 56, 0
	
str_ulaselecttest

	defb AT, 9, 0, "Select:"
	defb AT, 11, 0, "1) Output tone to MIC port"
	defb AT, 12, 0, "2) Output tone to EAR port"
	defb AT, 13, 0, "3) Test border generation"
	defb AT, 14, 0, "4) Test screen switching (128K)", 0

str_ulaexit

	defb AT, 16, 7, "Hold BREAK to exit", 0