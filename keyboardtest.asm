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
;	keyboardtest.asm
;

	define	KBROW 	5

keyboard_test

  ld sp, sys_stack

	ld iy, 0

	ld a, h
	cp 190
	jr nz, keyb_test_init
	ld a, l
	cp 238
	jr nz, keyb_test_init

	ld l, 7
	ld bc, 0x0023
	ld de, 0x0150
	call beep

keyb_test_init

	call initialize

  ld a, BORDERWHT
  out (ULA_PORT), a

	call cls

	ld hl, str_keyb_header
	call print_header
	call print_footer
	ld hl, str_exit
	call print

;	Paint keyboard

	xor a
	ld hl, 0x5800 + (KBROW * 32)
	ld (hl), a
	ld de, 0x5801 + (KBROW * 32)
	ld bc, 0x1df
	ldir

	ld hl, str_keyboard
	call print

;	Paint the keys

	ld ix, keyboard_vect
	ld a, 8
	ld (v_attr), a
	ld a, 1
	ld (v_pr_ops), a
	ld a, 8
	ld (v_width), a

	ld hl, (ix)

key_print

	call print
	inc ix
	inc ix
	ld hl, (ix)
	ld a, h
	or l
	jr nz, key_print

	ld a, 0x4f
	ld (v_attr), a

;	Store 'key read' flags in H'

	exx
	ld h, 00
	exx

keyb_loop

	ld b, 8
	ld d, 0xfe
	ld ix, keyboard_vect

keyb_loop_row

	ld a, d
	in a, (0xfe)
	ld e, a
	ld c, 5

keyb_loop_col

	bit 0, e
	jr nz, keyb_next_col

	ld hl, (ix)
	call print
	exx

;	Set bit 0 of H' - key pressed

	set 0, h
	exx

keyb_next_col

	inc ix
	inc ix
	rrc e
	dec c
	ld a, c
	cp 0
	jr nz, keyb_loop_col

	rlc d
	djnz keyb_loop_row

check_key_press

	exx
	ld a, h
	exx

;	Bit 1 of H' is set if a key was pressed or held during the last scan

	bit 0, a
	jr z, check_key_release

; 	Beep only if bit 1 of H' is reset, otherwise we've already beeped without key release

	bit 1, a
	jr nz, check_key_release
	ld l, 7
	ld bc, 0x0023
	ld de, 0x0015
	call beep
	exx
	set 1, h
	exx

check_key_release

	xor a
	in a, (0xfe)
	and 0x1f
	cp 0x1f
	jr nz, check_break

;	No keys now pressed, set H' to 0
	exx
	ld h, 0
	exx

check_break

	ld a, 0x7f
	in a, (0xfe)
	rra
	jr c, no_break					; Space not pressed
	ld a, 0xfe
	in a, (0xfe)
	rra
	jr c, no_break					; Caps shift not pressed

;	BREAK pressed, don't exit until its been held for
;	a certain amount of time (IY=0x3f)

	inc iy
	ld a, iyl
	cp 0x3f
	jr nz, keyb_loop

;	OK, now exit

	call diagrom_exit

no_break

	ld iy, 0
	jp keyb_loop


str_keyb_header

	defb TEXTBOLD, "Keyboard Test", TEXTNORM, 0

str_exit

	defb AT, 2, 0, "Press all keys to test, hold BREAK to exit", 0

str_keyboard

	defb AT, KBROW, 0, WIDTH, 8, ATTR, 7
	defb 0x8b, TAB, 248, 0x8c
	defb AT, KBROW + 4, 0
	defb 0x8d, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f
	defb 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f
	defb 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8e

	defb AT, KBROW + 8, 248, ATTR, 0x42, 0x80, ATTR, 7
	defb AT, KBROW + 9, 240, ATTR, 0x42, 0x80, ATTR, 0x56, 0x80, ATTR, 7
	defb AT, KBROW + 10, 232, ATTR, 0x42, 0x80, ATTR, 0x56, 0x80, ATTR, 0x74, 0x80, ATTR, 7
	defb AT, KBROW + 11, 224, ATTR, 0x42, 0x80, ATTR, 0x56, 0x80, ATTR, 0x74, 0x80, ATTR, 0x65, 0x80, ATTR, 7
	defb AT, KBROW + 12, 216, ATTR, 0x42, 0x80, ATTR, 0x56, 0x80, ATTR, 0x74, 0x80, ATTR, 0x65, 0x80, ATTR, 0x68, 0x80
	defb ATTR, 7

	defb 0x8d, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f
	defb 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f
	defb 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8e

	defb 0x90, TAB, 248, 0x91

	defb WIDTH, 6
	defb AT, KBROW + 1, 6, TEXTBOLD, BRIGHT, 1, "ZX Spectrum", TEXTNORM, ATTR, 56, 0

keyboard_vect

	defw tk_cs, tk_z, tk_x, tk_c, tk_v
	defw tk_a, tk_s, tk_d, tk_f, tk_g
	defw tk_q, tk_w, tk_e, tk_r, tk_t
	defw tk_1, tk_2, tk_3, tk_4, tk_5
	defw tk_0, tk_9, tk_8, tk_7, tk_6
	defw tk_p, tk_o, tk_i, tk_u, tk_y
	defw tk_ent, tk_l, tk_k, tk_j, tk_h
	defw tk_spc, tk_ss, tk_m, tk_n, tk_b, 0, 0

tk_1
	defb AT, KBROW + 5, 8, "1", 0
tk_2
	defb AT, KBROW + 5, 32, "2", 0
tk_3
	defb AT, KBROW + 5, 56, "3", 0
tk_4
	defb AT, KBROW + 5, 80, "4", 0
tk_5
	defb AT, KBROW + 5, 104, "5", 0
tk_6
	defb AT, KBROW + 5, 128, "6", 0
tk_7
	defb AT, KBROW + 5, 152, "7", 0
tk_8
	defb AT, KBROW + 5, 176, "8", 0
tk_9
	defb AT, KBROW + 5, 200, "9", 0
tk_0
	defb AT, KBROW + 5, 224, "0", 0

tk_q
	defb AT, KBROW + 7, 16, "Q", 0
tk_w
	defb AT, KBROW + 7, 40, "W", 0
tk_e
	defb AT, KBROW + 7, 64, "E", 0
tk_r
	defb AT, KBROW + 7, 88, "R", 0
tk_t
	defb AT, KBROW + 7, 112, "T", 0
tk_y
	defb AT, KBROW + 7, 136, "Y", 0
tk_u
	defb AT, KBROW + 7, 160, "U", 0
tk_i
	defb AT, KBROW + 7, 184, "I", 0
tk_o
	defb AT, KBROW + 7, 208, "O", 0
tk_p
	defb AT, KBROW + 7, 232, "P", 0

tk_a
	defb AT, KBROW + 9, 24, "A", 0
tk_s
	defb AT, KBROW + 9, 48, "S", 0
tk_d
	defb AT, KBROW + 9, 72, "D", 0
tk_f
	defb AT, KBROW + 9, 96, "F", 0
tk_g
	defb AT, KBROW + 9, 120, "G", 0
tk_h
	defb AT, KBROW + 9, 144, "H", 0
tk_j
	defb AT, KBROW + 9, 168, "J", 0
tk_k
	defb AT, KBROW + 9, 192, "K", 0
tk_l
	defb AT, KBROW + 9, 216, "L", 0
tk_ent
	defb AT, KBROW + 9, 240, "e", 0

tk_cs
	defb AT, KBROW + 11, 8, "cs", 0
tk_z
	defb AT, KBROW + 11, 40, "Z", 0
tk_x
	defb AT, KBROW + 11, 64, "X", 0
tk_c
	defb AT, KBROW + 11, 88, "C", 0
tk_v
	defb AT, KBROW + 11, 112, "V", 0
tk_b
	defb AT, KBROW + 11, 136, "B", 0
tk_n
	defb AT, KBROW + 11, 160, "N", 0
tk_m
	defb AT, KBROW + 11, 184, "M", 0
tk_ss
	defb AT, KBROW + 11, 208, "s", 0
tk_spc
	defb AT, KBROW + 11, 232, "sp", 0
