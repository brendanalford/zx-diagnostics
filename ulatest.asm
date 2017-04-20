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

ULATEST_ROW	equ 0x5900
FETEST_POS	equ 0x58B8

ulatest

	ld sp, sys_stack
	call initialize

write_shadow_screen

;	Write some data to Screen 1.
;	This'll just write to the C000 area on a 48K machine,
;	which isn't being used anyway.
;

	ld a, 7
	call pagein

	ld hl, 0xc000
	ld bc, 0x1800
	xor a
	call blankmem

	ld hl, 0xd800
	ld bc, 0x300
	ld a, 0x20
	call blankmem

	xor a
	call pagein

;	Detect frame length. Once HALT is issued, we start counting until the
;	second interrupt is reached.
;	NOTE: This routine doesn't produce exact lengths, but close enough
;	for us to be able to identify specific ULA types (48/128/NTSC).

	ld hl, ulatest_get_frame_length
	ld (v_userint), hl
	ld hl, 0
	ld (v_ulacycles), hl
	ld a, 0
	ei
	halt

;	Loop counting T states
;	ISR set above will break us out of this.
ulatest_count_loop

	inc hl
	nop
	nop
	nop
	nop
	nop
	nop
	jp ulatest_count_loop

ulatest_count_loop_done

	xor a
	ld (v_ulafloatbus), a
	ld hl, 0xfff
	ld a, 0xff
	ld b, a

ulatest_check_floating_bus

	in a, (0xff)
	and b
	ld b, a
	dec hl
	ld a, h
	or l
	jr nz, ulatest_check_floating_bus

	ld a, b
	cp 0xff
	jr z, checks_done

	ld a, 1
	ld (v_ulafloatbus), a

checks_done

;	IX will be used as the last recorded interrupt counter value
;	IY will be the number of cycles that IX was the same
;	If IY exceeds 100 cycles then interrupts are considered to have
;	failed

	ld hl, 0
	ld ix, hl
	ld iy, hl

	call cls

	ld a, BORDERWHT
	out (0xfe), a

	ld hl, str_ulabanner
	call print_header

	ld hl, str_ulatype
	call print

	ld hl, (v_ulacycles)
	ld de, hl
	ld ix, ula_type_table_contend

	ld a, (v_ulafloatbus)
	cp 0
	jr nz, ula_type_find

	ld ix, ula_type_table_uncontend

;	Given the ULA cycles in DE, and an index to the ULA type table
;	in IX, find and print the ULA type.

ula_type_find

	ld a, (ix)
	xor e
	jr nz, ula_type_next
	ld a, (ix+1)
	xor d
	jr nz, ula_type_next

;	Found ULA type

	ld hl, (ix+2)
	call print
	jr ula_type_done

ula_type_next

	ld bc, 4
	add ix, bc
	ld a, (ix)
	or (ix+1)
	jr nz, ula_type_find

;	ULA type unknown

	ld hl, str_ulaunknown
	call print

	ld hl, (v_ulacycles)
	ld de, v_hexstr
	call Num2Hex
	ld hl, v_hexstr
	call print
	ld a, ')'
	call putchar

ula_type_done

	ld hl, str_floatingbus
	call print

	ld hl, str_fb_detected
	ld a, (v_ulafloatbus)
	cp 0
	jr nz, ula_print_floatbus_type
	ld hl, str_fb_absent

ula_print_floatbus_type

	call print

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
	exx

;	'Have we printed the FAIL message' flag
;	stored in B' register

	xor a
	ld b, a

; 	Set the initial border colour
;	Gets stored in L'

	ld h, a
	in a, (0xfe)
	and 0xe0
	bit 6, a
	jr z, store_bord
	or 0x07

store_bord

	ld l, a
	exx

;	Set up ISR for interrupt test sweep

	ld hl, 0
	ld ix, hl
	ld (v_intcount), hl
	ld hl, ulatest_scan
	ld (v_userint), hl

;	Start the interrupt service routine

	ei

ulatest_loop

; 	Display the status of the bits from a read
;	of port 0xFE. Black on white - 0,
;	White on black - 1.

	xor a
	in a, (0xfe)
	ld c, a

	ld hl, FETEST_POS 	; Start of 76543210 on screen
	ld de, 0x4778		; D = B/W attrs, E = W/B
	ld b, 8


inval_print

;	Check and set the correct colour for the current
;	bit being checked

	call read_ear_bit

	ld a, d
	bit 7, c
	jr z, inval_print2
	ld a, e

inval_print2

	ld (hl), a
	inc hl
	sll c
	djnz inval_print

	call read_ear_bit

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
	jp nz, interrupt_fail

;	High byte zero, check if low byte is less than 30

	ld a, iyl
	cp 0x40
	jp c, check_input

;	More than 30 cycles have occurred since an interrupt,
;	something's failed to do with interrupt generation. Flag it.

interrupt_fail

	exx
	ld a, b
	exx

	cp 0
	jr nz, check_input

	ld hl, str_ulaintfail
	call print

	exx
	ld a, 1
	ld b, a
	exx

	jp check_input

interrupt_detected

	call read_ear_bit

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

	call read_ear_bit

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
	bit 4, a
	jp z, test_ula_addressing

;	Check for Break (Caps Shift+Space)

	ld bc, 0x7ffe
	in a, (c)
	bit 0, a
	jp nz, ulatest_loop		; Space not pressed
	ld bc, 0xfefe
	in a, (c)
	bit 0, a
	jp nz, ulatest_loop		; Caps shift not pressed

	call diagrom_exit

;
;	Reads bit 6 of port 0xFE (EAR bit) and
;	reflects its status by changing the border colour.
;
read_ear_bit

	push af
	exx
	ld h, l

	in a, (0xfe)
	bit 6, a
	jr nz, read_ear_bit_2

	ld a, h
	xor 0x07
	ld h, a

read_ear_bit_2

	ld a, h
	out (0xfe), a

	exx
	pop af
	ret

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


test_ula_addressing

	di

	ld b, 0
	ld hl, 0x0204

test_ula_addr_loop

	push bc
	ld bc, 0x3fff

test_ula_addr_delay

	dec bc
	ld a, b
	or c
	jr nz, test_ula_addr_delay

	pop bc

	ld a, 7
	bit 0, b
	jr z, test_ula_addr_border

	out (0xfe), a
	out (0xff), a
	jr test_ula_addr_next

test_ula_addr_border

	ld a, l
	out (0xfe), a
	ld a, h
	out (0xff), a

test_ula_addr_next

	inc b
	in a, (0xfe)
	and 0x1f
	cp 0x1f
	jr nz, test_ula_addr_loop

	xor a
	out (0xff), a
	ei
	jp ulatest_loop

;
;	Interrupt routine to run the ula test visual indication.
;
ulatest_scan

	exx
	ld a, l
	exx
	and 0xe0
	or 0x02

	out (0xfe), a
	ld hl, ULATEST_ROW
	ld b, 0x20
	ld a, 0x7
	ld c, a

ulatest_scan_fade

	ld a, (hl)
	cp 0x38
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

;
;	ISR to approximate the frame length of the machine under test.
;
ulatest_get_frame_length

	ld hl, (v_ulacycles)
	ld a, h
	or l
	jr nz, ulatest_get_frame_length_done
	ld hl, 0xffff
	ld (v_ulacycles), hl
	ret

ulatest_get_frame_length_done

;	Disable our ISR

	ld hl, 0
	ld (v_userint), hl

;	Unwind the stack, grabbing the pre-interrupt value of HL as we go

	pop bc
	pop bc
	pop bc
	pop hl
	pop bc
	pop bc

	ld (v_ulacycles), hl

	jp ulatest_count_loop_done

str_ulabanner

	defb	TEXTBOLD, "ULA Test", TEXTNORM, 0

str_ulainresult

	defb AT, 5, 0, "ULA port 0xFE read............. ", 0

str_ulain_row

	defb AT, 5, 24 * 8, 0x88, 0x87, 0x86, 0x85, 0x84, 0x83, 0x82, 0x81, 0

str_ulaint_test

	defb AT, 7, 0, "Interrupt test (movement should be smooth)", 0

str_ulaintfail

	defb AT, 8, 13 * 6, ATTR, ATTR_TRANS, TEXTBOLD, "FAIL FAIL FAIL", TEXTNORM, ATTR, 56, 0

str_ulaselecttest

	defb AT, 10, 0, "Select:"
	defb AT, 12, 0, "1) Output tone to MIC port"
	defb AT, 13, 0, "2) Output tone to EAR port"
	defb AT, 14, 0, "3) Test border generation"
	defb AT, 15, 0, "4) Test screen switching (128K)"
	defb AT, 16, 0, "5) Test ULA port addressing"
	defb AT, 17, 18, "(Flashing green border: pass,"
	defb AT, 18, 18, "anything else: fail)", 0

str_ulaexit

	defb AT, 20, 12 * 6, "Hold BREAK to exit", 0

str_ulatype

	defb AT, 2, 0, "ULA type: ", 0

;	Tables defining ULA timings to type strings.
;	Contended ULA's first
ula_type_table_contend

	defw 0x06CB, str_ula48pal
	defw 0x06E4, str_ula128
	defw 0x05BE, str_ula48ntsc
	defw 0x05B3, str_ts2068
	defw 0x0000

;	Uncontended ULA's
ula_type_table_uncontend

	defw 0x06CB, str_ula48notr6
	defw 0x06E4, str_ulaplus3
	defw 0x0000

str_ula48pal

	defb "Spectrum 48K", 0

str_ula48ntsc

	defb "Spectrum 48K (NTSC)", 0

str_ula128

	defb "Spectrum 128K or +2", 0

str_ulaplus3

	defb "Spectrum +2A/+3 ASIC", 0

str_ts2068

	defb "TS2048/TS2068 ASIC", 0

str_ula48notr6

	defb "48K Issue 1 or TR6 missing", 0

str_ulaunknown

	defb "Unknown (", 0

str_floatingbus

	defb AT, 3, 0, "Floating bus ", 0

str_fb_detected

	defb "detected", 0

str_fb_absent

	defb "absent", 0
