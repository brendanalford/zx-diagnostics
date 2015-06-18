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
		
init_mem_loop

	call print_mem_line
	call newline		
	djnz init_mem_loop

	pop hl
	
mem_loop
	
	call scan_keys
	cp 'Q'
	call z, mem_up
	cp 'A'
	call z, mem_down
	jr mem_loop

mem_up
	
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
	
mem_down

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

	
str_mem_browser_header

	defb	TEXTBOLD, "Memory Browser", TEXTNORM, 0
	
str_colon

	defb ":  ", 0