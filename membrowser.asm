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

mem_browser

    	ld sp, 0x7cff

	call initialize

;	Start the interrupt service routine

	ld a, intvec2 / 256
	ld i, a
	im 2

	ld hl, membrowser_isr 
	ld (v_userint), hl
	ei
	
    	ld a, BORDERWHT
    	out (ULA_PORT), a

	call cls

	ld hl, str_mem_browser_header
	call print_header
	call print_footer
	
;	Paint initial memory locations

	ld a, 2
	ld (v_row), a
	xor a
	ld (v_column), a
	
	ld hl, 0x0000
	ld b, 0x12

	push hl
	
;	IX is our cursor location.
;	IXh = row, IXl = column * 2, e.g. IXl=3 is low nibble of
;	byte 1.

	ld ix, 0x0000
	
init_mem_loop

	call print_mem_line
	call newline		
	djnz init_mem_loop

	pop hl
	
	ld a, 1
	ld c, a
	call print_cursor
	
	ei
	
mem_loop
	
	halt
	call scan_keys
	cp '1'
	call z, scroll_mem_up
	cp '0'
	call z, scroll_mem_down
	cp 'Q'
	call z, cur_up
	cp 'A'
	call z, cur_down
	cp 'O'
	call z, cur_left
	cp 'P'
	call z, cur_right
	jr mem_loop

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
	ret
	
cur_left_normal

	dec ixl
	call print_cursor
	ret
	
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
	ret
	
cur_right_normal

	inc ixl
	call print_cursor
	ret


cur_up

	ld c, 0
	call print_cursor
	ld c, 1
	ld a, ixh
	cp 0
	jr nz, cur_up_normal
	
	call scroll_mem_down
	call print_cursor
	ret
	
cur_up_normal

	dec ixh
	call print_cursor
	ret

cur_down

	ld c, 0
	call print_cursor
	ld c, 1
	ld a, ixh
	cp 0x11
	jr nz, cur_down_normal
	
	call scroll_mem_up
	call print_cursor
	ret
	
cur_down_normal

	inc ixh
	call print_cursor
	ret
	
scroll_mem_up
	
	ld de, 8
	add hl, de
	push hl
	ld de, 88
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
;	Prints a single memory line
;	Start address is in HL
;	Print position is presumed to be set
;
print_mem_line

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

	ld a, (hl)
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

	ld a, (hl)
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
	
;	HL now contains the memory address. Grab it
;	and store it in B register

	ld a, (hl)
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

;	TODO - proper cursor by nibble

	call set_print_pos
	
	ld l, b
	ld h, 0
	ld de, v_hexstr + 2
	call Byte2Hex
	ld hl, v_hexstr + 2
	ld a, c
	cp 0
	jr z, skip_inverse
	ld a, 2
	ld (v_pr_ops), a

skip_inverse

	call print
	xor a
	ld (v_pr_ops), a
	
	pop hl
	ret

membrowser_isr

	ret
	
str_mem_browser_header

	defb	TEXTBOLD, "Memory Browser", TEXTNORM, 0
	
str_colon

	defb ":  ", 0