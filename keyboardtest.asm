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

keyboard_test
    	
    	ld sp, 0x7cff
	ld iy, 0
	
	call init_vars
	
;	Copy ROM paging routines to RAM

	ld hl, rompage_reloc
	ld de, do_rompage_reloc
	ld bc, end_rompage_reloc-rompage_reloc
	ldir
	ld a, 0
	call do_rompage_reloc
	
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
	ld hl, 0x58a0
	ld (hl), a
	ld de, 0x58a1
	ld bc, 0x1df
	ldir
	
	ld hl, str_keyboard
	call print

;	Paint the keys

	ld ix, keyboard_vect
	ld a, 8
	ld (v_attr), a
	ld a, 1
	ld (v_bold), a
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

;	Just do a simple reset if diagboard hardware isn't detected
	
	ld a, (v_testhwtype)
	cp 0
	jp z, 0000

;	Else page the diagnostic ROM out and start the machine's own ROM

	ld bc, 0x1234
	ld a, 2
	call do_rompage_reloc	; Page out and restart the machine	

no_break

	ld iy, 0
	jp keyb_loop
	
	
str_keyb_header

	defb TEXTBOLD, "Keyboard Test", TEXTNORM, 0

str_exit

	defb AT, 2, 0, "Press all keys to test, hold BREAK to exit", 0
	
str_keyboard

	defb AT, 5, 0, WIDTH, 8, ATTR, 7
	defb 0x8b, TAB, 248, 0x8c
	defb AT, 9, 0
	defb 0x8d, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f
	defb 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f
	defb 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8e

	defb AT, 13, 248, ATTR, 0x42, 0x80, ATTR, 7
	defb AT, 14, 240, ATTR, 0x42, 0x80, ATTR, 0x56, 0x80, ATTR, 7
	defb AT, 15, 232, ATTR, 0x42, 0x80, ATTR, 0x56, 0x80, ATTR, 0x74, 0x80, ATTR, 7
	defb AT, 16, 224, ATTR, 0x42, 0x80, ATTR, 0x56, 0x80, ATTR, 0x74, 0x80, ATTR, 0x65, 0x80, ATTR, 7
	defb AT, 17, 216, ATTR, 0x42, 0x80, ATTR, 0x56, 0x80, ATTR, 0x74, 0x80, ATTR, 0x65, 0x80, ATTR, 0x68, 0x80
	defb ATTR, 7

	defb 0x8d, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f
	defb 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f
	defb 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8f, 0x8e
	
	defb 0x90, TAB, 248, 0x91
	
	defb WIDTH, 6
	defb AT, 6, 6, TEXTBOLD, BRIGHT, 1, "ZX Spectrum", TEXTNORM, ATTR, 56, 0
	
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
	defb AT, 10, 8, "1", 0
tk_2
	defb AT, 10, 32, "2", 0
tk_3
	defb AT, 10, 56, "3", 0
tk_4
	defb AT, 10, 80, "4", 0
tk_5
	defb AT, 10, 104, "5", 0
tk_6
	defb AT, 10, 128, "6", 0
tk_7
	defb AT, 10, 152, "7", 0
tk_8
	defb AT, 10, 176, "8", 0
tk_9
	defb AT, 10, 200, "9", 0
tk_0
	defb AT, 10, 224, "0", 0

tk_q
	defb AT, 12, 16, "Q", 0
tk_w
	defb AT, 12, 40, "W", 0
tk_e
	defb AT, 12, 64, "E", 0
tk_r
	defb AT, 12, 88, "R", 0
tk_t
	defb AT, 12, 112, "T", 0
tk_y
	defb AT, 12, 136, "Y", 0
tk_u
	defb AT, 12, 160, "U", 0
tk_i
	defb AT, 12, 184, "I", 0
tk_o
	defb AT, 12, 208, "O", 0
tk_p
	defb AT, 12, 232, "P", 0

tk_a
	defb AT, 14, 24, "A", 0
tk_s
	defb AT, 14, 48, "S", 0
tk_d
	defb AT, 14, 72, "D", 0
tk_f
	defb AT, 14, 96, "F", 0
tk_g
	defb AT, 14, 120, "G", 0
tk_h
	defb AT, 14, 144, "H", 0
tk_j
	defb AT, 14, 168, "J", 0
tk_k
	defb AT, 14, 192, "K", 0
tk_l
	defb AT, 14, 216, "L", 0
tk_ent
	defb AT, 14, 240, "e", 0

tk_cs
	defb AT, 16, 8, "cs", 0
tk_z
	defb AT, 16, 40, "Z", 0
tk_x
	defb AT, 16, 64, "X", 0
tk_c
	defb AT, 16, 88, "C", 0
tk_v
	defb AT, 16, 112, "V", 0
tk_b
	defb AT, 16, 136, "B", 0
tk_n
	defb AT, 16, 160, "N", 0
tk_m
	defb AT, 16, 184, "M", 0
tk_ss
	defb AT, 16, 208, "s", 0
tk_spc
	defb AT, 16, 232, "sp", 0
