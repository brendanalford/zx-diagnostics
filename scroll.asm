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
;	scroll.asm
;	

;
;	Scrolls the screen according to the values in v_scroll and v_scrl_lines.
;
prt_scroll

	ld a, (v_scroll)
	ld h, a
	ld a, (v_scrl_lines)
	ld l, a
	
scroll_up
;
;	Scrolls the screen upwards starting from 
;	the line in H for L lines.
;

	push ix
	push hl
	push de
	push bc

	ld ix, hl
	
.scroll_calc

;	Calc destination line
;	Store it in DE

	ld a, ixh
	and 0x18
	or 0x40
	ld d, a
	ld a, ixh
	and 0x7
	rla
	rla
	rla
	rla
	rla
	ld e, a

;	Is this the last line?

	ld a, ixl
	cp 1
	jr nz, .scroll_lines
	
;	Yes, set up to blank last line

	ld hl, de
	inc de
	
	ld b, 8
	
.scroll_last_line

	push hl
	push de
	push bc

	xor a
	ld bc, 31
	ld (hl), a
	ldir

	pop bc
	pop de
	pop hl
	inc h
	inc d
	djnz .scroll_last_line

	jr .scroll_attrs
	
.scroll_lines

;	Calculate source line (line + 1)
;	Store it in HL
	
	inc ixh
	ld a, ixh
	and 0x18
	or 0x40
	ld h, a
	ld a, ixh
	and 0x7
	rla
	rla
	rla
	rla
	rla
	ld l, a
	dec ixh
	
	ld b, 8
	
.scroll_line

	push hl
	push de
	push bc
	ld bc, 32
	ldir
	
	pop bc
	pop de
	pop hl

;	Move to next pixel row

	inc h
	inc d
	djnz .scroll_line

.scroll_attrs

;	Now scroll attributes
;	First calculate attribute destination
		
	ld a, ixh
	srl a
	srl a
	srl a
	and 3
	or 0x58
	ld h, a
	ld a, ixh
	sla a
	sla a
	sla a
	sla a
	sla a
	ld l, a
	inc ixh

	ld a, ixl
	cp 1
	jr nz, .scroll_attr

;	Last line, blank last line of attrs with
;	current attribute v_attr value

	ld de, hl
	inc de
	ld a, (v_attr)
	ld (hl), a
	ld bc, 31
	ldir
	jp .scroll_next
	
.scroll_attr

;	Add 32 to this to get attribute source
;	then copy
	
	push hl	
	ld de, 32
	add hl, de
	pop de
	ld bc, 31
	ldir
	
.scroll_next
	
	dec ixl
	ld a, ixl
	cp 0
	jp nz, .scroll_calc
		
	pop bc
	pop de
	pop hl
	pop ix
	ret



scroll_down
;
;	Scrolls the screen downwards starting from 
;	the line in H for L lines.
;

	push ix
	push hl
	push de
	push bc

	ld ix, hl
	
.scroll_calc

;	Calc destination line
;	Store it in DE

	ld a, ixh
	and 0x18
	or 0x40
	ld d, a
	ld a, ixh
	and 0x7
	rla
	rla
	rla
	rla
	rla
	ld e, a

;	Is this the last line?

	ld a, ixl
	cp 1
	jr nz, .scroll_lines
	
;	Yes, set up to blank last line

	ld hl, de
	inc de
	
	ld b, 8
	
.scroll_last_line

	push hl
	push de
	push bc

	xor a
	ld bc, 31
	ld (hl), a
	ldir

	pop bc
	pop de
	pop hl
	inc h
	inc d
	djnz .scroll_last_line

	jr .scroll_attrs
	
.scroll_lines

;	Calculate source line (line - 1)
;	Store it in HL
	
	dec ixh
	ld a, ixh
	and 0x18
	or 0x40
	ld h, a
	ld a, ixh
	and 0x7
	rla
	rla
	rla
	rla
	rla
	ld l, a
	inc ixh
	
	ld b, 8
	
.scroll_line

	push hl
	push de
	push bc
	ld bc, 32
	ldir
	
	pop bc
	pop de
	pop hl

;	Move to next pixel row

	inc h
	inc d
	djnz .scroll_line

.scroll_attrs

;	Now scroll attributes
;	First calculate attribute destination
		
	ld a, ixh
	srl a
	srl a
	srl a
	and 3
	or 0x58
	ld h, a
	ld a, ixh
	sla a
	sla a
	sla a
	sla a
	sla a
	ld l, a
	dec ixh

	ld a, ixl
	cp 1
	jr nz, .scroll_attr

;	Last line, blank last line of attrs with
;	current attribute v_attr value

	ld de, hl
	inc de
	ld a, (v_attr)
	ld (hl), a
	ld bc, 31
	ldir
	jp .scroll_next
	
.scroll_attr

;	Subtract 32 to this to get attribute source
;	then copy
	
	push hl
	ld de, 32
	and a 
	sbc hl, de
	pop de
	ld bc, 32
	ldir
	
.scroll_next
	
	dec ixl
	ld a, ixl
	cp 0
	jp nz, .scroll_calc
		
	pop bc
	pop de
	pop hl
	pop ix
	ret
