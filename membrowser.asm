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
;	membrowser.asm
;

	define KEY_DELAY 10

mem_browser

    ld sp, sys_stack

	call initialize

	ld hl, ld_a_hl
	ld de, sys_ld_a_hl
	ld bc, ld_a_hl_end-ld_a_hl
	ldir

;	Set the correct interrupt service routine

	ld hl, membrowser_isr
	ld (v_userint), hl

    	ld a, BORDERWHT
    	out (ULA_PORT), a

	call cls

	ld hl, str_mem_browser_header
	call print_header
	ld hl, str_mem_browser_footer
	call print

;	Paint initial memory locations
;	HL is our starting address.

	ld hl, 0x4000

;	IX is our cursor location.
;	IXh = row, IXl = column * 2, e.g. IXl=3 is low nibble of
;	byte 1.

	ld ix, 0x0000

	call refresh_mem_display

;	Set up the keyboard delay

	ex af, af'
	ld a, 0
	ex af, af'

	ld c, a
	call print_cursor

	ei

mem_loop

	ex af, af'
	ld b, a
	ex af, af'

;	Delay repeat key presses

	ld a, b
	cp 0
	jr nz, key_delay
	ld a, 1
	ld b, a

key_delay

	halt
	djnz key_delay

;	Scan the keyboard

	xor a
	call scan_keys
	jr c, mem_key_pressed

;	No key pressed, reset the delay timer

	ex af, af'
	ld a, 0
	ex af, af'

	jr mem_loop


mem_key_pressed

;	A key was pressed, set the timer to the initial delay,
;	or reduce the delay by one if not already = 1.

	ex af, af'
	cp 0
	jr z, delay_timer_start
	cp 1
	jr z, delay_timer_end
	dec a
	jr delay_timer_end

delay_timer_start

	ld a, KEY_DELAY

delay_timer_end

	ex af, af'

check_keys

;	Movement keys.

	cp 'W'
	jp z, page_up
	cp 'X'
	jp z, page_down
	cp 'Q'
	jp z, cur_up
	cp 'Z'
	jp z, cur_down
	cp 'O'
	jp z, cur_left
	cp 'P'
	jp z, cur_right

;	Option keys

	cp 'T'
	jp z, ram_page
	cp 'R'
	jp z, rom_page
	cp 'G'
	jp z, goto_addr
	cp BREAK
	jr z, exit

;	Test for Hex characters

	cp 'F' + 1
	jr nc, mem_loop
	cp '0'
	jr c, mem_loop

	cp '9' + 1
	jr c, hex_digit
	cp 'A'
	jr nc, hex_digit


hex_digit

;	Normalise it

	sub '0'
	cp 10
	jr c, hex_digit_2
	sub 0x7

hex_digit_2

;	Work out the target byte

	push hl
	push af

	call get_hl_cursor_addr

;	Now work out the high or low
; 	nibble to write, and write it

	ld a, ixl
	bit 0, a
	jr z, write_high_nibble

write_low_nibble

	call ld_a_hl
	and 0xf0
	ld b, a
	pop af
	and 0x0f
	jr write_end

write_high_nibble

	call sys_ld_a_hl
	and 0x0f
	ld b, a
	pop af
	rla
	rla
	rla
	rla
	and 0xf0

write_end
	or b
	ld (hl), a

	pop hl
	call refresh_mem_display
	call cur_right
	jp mem_loop

exit

	call diagrom_exit


;	Routine to allow the user to enter a 4 digit
;	hexadecimal memory address to go to
goto_addr

;	We're replacing the value of HL (memory pointer)
; so it's okay to trash it

	ld hl, str_goto_addr_prompt
	call print
	ld hl, str_cursor
	call print

	ld bc, 0x0000

	call get_hex_digit
	sla a
	sla a
	sla a
	sla a
	or b
	ld b, a
	call get_hex_digit
	or b
	ld b, a

	call get_hex_digit
	sla a
	sla a
	sla a
	sla a
	or c
	ld c, a
	call get_hex_digit
	or c
	ld ixl, a
	and 0xf8
	ld c, a

	ld hl, str_goto_addr_default
	call print

	push bc
	pop hl

	ld ixh, 0
	ld a, ixl
	and 0x07
	sla a
	ld ixl, a

	set 0, c
	call refresh_mem_display
	call print_cursor
	jp mem_loop

get_hex_digit

;	Get a keypress and see if it's a valid hex digit
	xor a
	call scan_keys
	jr nc, get_hex_digit

	cp 'F' + 1
	jr nc, get_hex_digit
	cp '0'
	jr c, get_hex_digit

	cp '9' + 1
	jr c, got_hex_digit
	cp 'A'
	jr c, get_hex_digit

got_hex_digit

	push af

;	Debounce the keypress

get_hex_digit_2

	xor a
	call scan_keys
	jr c, get_hex_digit_2
	pop af

; Print the digit

	push af
	call putchar
	ld d, 6
	ld a, (v_column)
	add a, d
	ld (v_column), a
	ld hl, str_cursor
	call print
	pop af

;	Normalise the ASCII keypress to a hex digit 0-F

	sub '0'
	cp 10
	ret c
	sub 0x7
	ret


; Page in whatever ROM the user wants
rom_page

	push hl
	ld hl, str_selrompage
	call print_header

rom_page_sel

	xor a
	call scan_keys
	jr nc, rom_page_sel

	cp ' '
	jp nz, rom_page_sel_chk

	ld hl, str_mem_browser_header
	call print_header
	pop hl
	jp mem_loop

rom_page_sel_chk

	cp '0'
	jr c, rom_page_sel
	cp '4'
	jr nc, rom_page_sel

;	Normalise to 0-3

	sub '0'
	push af

;	Write 0x1ffd part

	and 0x2
	rla
	ld b, a
	ld a, (v_paging_2)
	and 0xfb
	or b
	ld bc, 0x1ffd
	out (c), a
	ld (v_paging_2), a

;	Write 0x7ffd part

	pop af
	and 0x1
	rla
	rla
	rla
	rla
	ld b, a
	ld a, (v_paging)
	and 0xef
	or b
	ld bc, 0x7ffd
	out (c), a
	ld (v_paging), a

;	Restore header and refresh memory display

	ld hl, str_mem_browser_header
	call print_header
	pop hl
	call refresh_mem_display
	jp mem_loop

ram_page

	push hl
	ld hl, str_selrampage
	call print_header

ram_page_sel

	xor a
	call scan_keys
	jr nc, ram_page_sel

	cp ' '
	jp nz, ram_page_sel_chk

	ld hl, str_mem_browser_header
	call print_header
	pop hl
	jp mem_loop

ram_page_sel_chk

	cp '0'
	jr c, ram_page_sel
	cp '8'
	jr nc, ram_page_sel

;	Page in required RAM bank

	sub '0'
	and 0x7

	ld b, a
	ld a, (v_paging)
	and 0xf8
	or b
	ld bc, 0x7ffd
	out (c), a
	ld (v_paging), a

	ld hl, str_mem_browser_header
	call print_header
	pop hl
	call refresh_mem_display
	jp mem_loop

page_up
	and a
	ld de, 0x90
	sbc hl, de
	call refresh_mem_display
	call print_cursor
	jp mem_loop

page_down

	ld de, 0x90
	add hl, de
	call refresh_mem_display
	call print_cursor
	jp mem_loop

cur_left

	ld c, 0
	call print_cursor
	ld c, 1
	ld a, ixl
	cp 0
	jr nz, cur_left_normal

	ld a, 15
	ld ixl, a

	ld a, ixh
	cp 0
	jr nz, cur_left_nopage

	call scroll_mem_down
	inc ixh

cur_left_nopage

	dec ixh
	call print_cursor
	jp mem_loop

cur_left_normal

	dec ixl
	call print_cursor
	jp mem_loop

cur_right

	ld c, 0
	call print_cursor
	ld c, 1
	ld a, ixl
	cp 15
	jr nz, cur_right_normal

	ld a, 0
	ld ixl, a

	ld a, ixh
	cp 0x11
	jr nz, cur_right_nopage

	call scroll_mem_up
	dec ixh

cur_right_nopage

	inc ixh
	call print_cursor
	jp mem_loop

cur_right_normal

	inc ixl
	call print_cursor
	jp mem_loop

cur_up

	ld c, 0
	call print_cursor
	ld c, 1
	ld a, ixh
	cp 0
	jr nz, cur_up_normal

	call scroll_mem_down
	call print_cursor
	jp mem_loop

cur_up_normal

	dec ixh
	call print_cursor
	jp mem_loop

cur_down

	ld c, 0
	call print_cursor
	ld c, 1
	ld a, ixh
	cp 0x11
	jr nz, cur_down_normal

	call scroll_mem_up
	call print_cursor
	jp mem_loop

cur_down_normal

	inc ixh
	call print_cursor
	jp mem_loop

scroll_mem_up

	ld de, 8
	add hl, de
	push hl
	ld de, 0x88
	add hl, de
	push hl
	ld hl, 0x1300
	call set_print_pos
	ld hl, 0x0212
	call scroll_up
	pop hl
	call print_mem_line
	pop hl
	ret

scroll_mem_down

	ld de, 8
	and a
	sbc hl, de
	push hl
	push hl
	ld hl, 0x1312
	call scroll_down
	ld hl, 0x0200
	call set_print_pos
	pop hl
	call print_mem_line
	pop hl
	ret

;
;	Refreshes the entire memory display.
;
refresh_mem_display

	push af
	push bc
	ld a, 2
	ld (v_row), a
	xor a
	ld (v_column), a

	ld b, 0x12

	push hl

init_mem_loop

	call print_mem_line
	call newline
	djnz init_mem_loop

	pop hl
	pop bc
	pop af
	ret

;
;	Sets ink colour appropriately for the
;	memory region being displayed. Red=
;	read only, black=read/write.
;
set_mem_line_colour

	ld a, h
	cp 0x40
	ret nc

	ld a, 58
	ld (v_attr),a
	ret

;
;	Prints a single memory line
;	Start address is in HL
;	Print position is presumed to be set
;
print_mem_line

;	Set red ink if we're in ROM address space

	call set_mem_line_colour

	ld de, v_hexstr
	call Num2Hex
	push hl
	ld hl, v_hexstr
	call print

	ld hl, str_colon
	call print
	pop hl
	push bc
	ld b, 8

mem_loop_hex

	call sys_ld_a_hl
	push hl
	push bc
	ld l, a
	ld h, 0
	ld de, v_hexstr + 2
	call Byte2Hex
	ld hl, v_hexstr + 2
	call print
	ld a, (v_column)
	ld d, 6
	add d
	ld (v_column), a

	pop bc
	pop hl
	inc hl
	djnz mem_loop_hex

;	Step back 8 bytes , time to output in ASCII

	ld de, 8
	and a
	sbc hl, de

	ld a, (v_column)
	ld d, 12
	add d
	ld (v_column), a

	ld b, 8

mem_loop_ascii

	call sys_ld_a_hl
	cp 32
	jr c, control_char
	cp 127
	jr nc, control_char
	call putchar
	jr mem_loop_ascii_next

control_char

	ld a, '?'
	call putchar

mem_loop_ascii_next

	ld d, 6
	ld a, (v_column)
	add d
	ld (v_column), a
	inc hl
	djnz mem_loop_ascii
	pop bc

	ld a, 56
	ld (v_attr), a
	ret

;
;	Prints cursor and memory value associated with it.
;	HL = memory location of top line/leftmost byte
;	IX = cursor position (IXH = row, IXL & 0xfe = column,
;	IXL bit 0 = nibble within byte)
;	C = nonzero, inverse. Zero = normal video
;
print_cursor

	push hl
	call get_hl_cursor_addr
	call set_mem_line_colour

;	HL now contains the memory address. Grab it
;	and store it in B register

	call sys_ld_a_hl
	ld b, a

;	Now calculate the actual screen address to print
;	Offset from top left is 2,7

	ld a, 2
	ld e, ixh
	add e
	ld h, a


;	IXL = cursor position (8 bytes * 2 nibbles)

	ld a, ixl

;	Divide by 2 to take account of nibbles

	srl a

;	Every byte takes 3 print positions ( * 6 )

	ld l, a
	add l
	add l
	add l
	add l
	add l

;	(byte * 6) * 3

	ld l, a
	xor a
	add l
	add l
	add l
	ld l, a

;	42 + (byte * 6) * 3

	ld a, 7 * 6
	add l
	ld l, a

;	Cursor is now in position to print byte.

	call set_print_pos

;	Do high nibble first

	ld a, b
	ld hl, v_pr_ops
	res 1, (hl)

	rra
	rra
	rra
	rra

	call num_2_hex
	ld d, ixl
	bit 0, d
	jr nz, no_inverse_1

	bit 0, c
	jr z, no_inverse_1

	set 1, (hl)

no_inverse_1

	call putchar

;	Now lower nibble.

	res 1, (hl)
	ld a, (v_column)
	inc a
	inc a
	inc a
	inc a
	inc a
	inc a
	ld (v_column), a

	ld a, b
	and 0x0f
	call num_2_hex
	ld d, ixl
	bit 0, d
	jr z, no_inverse_2

	bit 0, c
	jr z, no_inverse_2

	set 1, (hl)

no_inverse_2

	call putchar
	res 1, (hl)

	pop hl
	ld a, 56
	ld (v_attr), a
	ret

;
;	Gets the address of the byte in memory pointed
;	to by the cursor represented by IX.
;	HL = start screen address, IX=cursor
;	Output: HL is cursor byte.
;
get_hl_cursor_addr

;	First get memory byte in question in HL
;	Work out row position * 8

	ld a, ixh
	add a
	add a
	add a
	ld e, a
	ld d, 0
	add hl, de

;	Now get offset within row

	ld a, ixl
	srl a
	ld e, a
	add hl, de
	ret
;
;	Converts number in A to its ASCII hex equivalent.
;
num_2_hex

	or	0xF0
	daa
	add	a,#A0
	adc	a,#40
	ret

;
;	Waits until no keys are being pressed.
;	Designed to be jumped to from a subrouting
;	so it returns to the caller's caller.
;
release_key
	push af
rel_key_loop
	xor a
	in a, (0xfe)
	and 0x1f
	cp 0x1f
	jr nz, rel_key_loop
	pop af
	ret

membrowser_isr

	ret

;
;	Routine for relocation to RAM. Loads A with memory location in HL.
;	Pages out ROM to do it.
; Checks to see if ZXC4 is active, and if the location points to the
; area between 3FC0-3FFF. It'll return FF's in this case.
;
ld_a_hl

	ld a, (v_testhwtype)
	cp 3
	jr nz, ld_a_hl_2
	ld a, h
	cp 0x3f
	jr nz, ld_a_hl_2
	ld a, l
	cp 0xc0
	jr c, ld_a_hl_2
	ld a, 0xff
	ret

ld_a_hl_2

	di
	push bc
	ld a, 2
	call sys_rompaging
	ld a, (hl)
	push af
	ld a, 1
	call sys_rompaging
	pop af
	pop bc
	ei
	ret

ld_a_hl_end

str_mem_browser_header

	defb	TEXTBOLD, "Memory Browser  ", TEXTNORM, 0

str_mem_browser_footer

	defb	AT, 21, 0, "Q,Z,O,P: cursor, 0-9,A-F: enter data\n"
	defb	"W: PgUp X: PgDown R: Page ROM, T: Page RAM\n"

str_goto_addr_default

	defb	AT, 23, 0, "G: Goto Address. BREAK to exit. ",0

str_goto_addr_prompt

	defb  AT, 23, 15 * 6, ":               ", AT,23, 17 * 6, 0

str_cursor

	defb INVERSE, 1, ' ', INVERSE, 0, LEFT, 0

str_colon

	defb ":  ", 0

str_selrompage

	defb	TEXTBOLD, "ROM Page (0-3)?", TEXTNORM, 0

str_selrampage

	defb	TEXTBOLD, "RAM Page (0-7)?", TEXTNORM, 0
