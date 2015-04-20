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
;	paging.asm
;	

;
;	Pages the given RAM page into memory. 
;	Inputs: A=desired RAM page.
;

pagein

	push bc
	push af
	ld bc, 0x7ffd

;	Ensure nothing else apart from paging gets touched
	
	and 0x7	
	out (c), a
	pop af
	pop bc 
	ret

;
;	Pages out the diagnostics ROM and restarts the computer
;
restart

	ld bc, 0x1234
	ld a, 1
	ld hl, brk_page_reloc
	ld de, 0x7f00				; Won't need system vars again at this point
	ld bc, end_brk_page_reloc - brk_page_reloc
	ldir
	jp 0x7f00

; This bit will be relocated so that we can page in the BASIC ROM

brk_page_reloc
	ld a, %00100000			; Bit 5 - release /ROMCS
	out (ROMPAGE_PORT), a
	jp 0
end_brk_page_reloc


;
;	Handler for external paging operations.
;	Inputs; A=command type, BC=operands.
;

rompage_reloc

	cp 0
	jr z, romhw_test
	cp 1
	jr z, romhw_pagein
	cp 2
	jr z, romhw_pageout

;	Command not understood, return with error in A

	ld a, 0xff
	ret

; 	Command 1: Page in external ROM

romhw_pagein

	ld a, (v_testhwtype)
	cp 1
	jr z, romhw_pagein_diagboard
	cp 2
	jr z, romhw_pagein_smart
	ld a, 0xff
	ret
	
romhw_pagein_diagboard

	ld a, %00000000
	out (ROMPAGE_PORT), a
	ret

romhw_pagein_smart
	
	ld bc, SMART_ROM_PORT
	ld a, 0x00
	out (c), a
	ret
	
;	Command 2: Page out external ROM
;	BC = 0x1234: Jump to start of internal ROM

romhw_pageout
	
	ld a, (v_testhwtype)
	cp 1
	jr z, romhw_pageout_diagboard
	cp 2
	jr z, romhw_pageout_smart
	ld a, 0xff
	ret
	
romhw_pageout_diagboard
	
	ld a, %00100000
	out (ROMPAGE_PORT), a
	ld a, b
	cp 0x12
	ret nz
	ld a, c
	cp 0x34
	jp 0

romhw_pageout_smart
	ld bc, SMART_ROM_PORT
	ld a, %10000000
	out (c), a
	ld a, b
	cp 0x12
	ret nz
	ld a, c
	cp 0x34
	ret nz
	jp 0
	
;	Command 3: Test for diagnostic devices
;	Stores result in system variable v_testhwtype

romhw_test

; 	First try diagboard hardware

	ld a, %00100000
	out (ROMPAGE_PORT), a
	ld hl, str_rommagicstring
	ld a, (hl)
	cp 'T'
	jr nz, romhw_found_diagboard
	inc hl
	ld a, (hl)
	cp 'R'
	jr nz, romhw_found_diagboard
	inc hl
	ld a, (hl)
	cp 'O'
	jr nz, romhw_found_diagboard
	inc hl
	ld a, (hl)
	cp 'M'
	jr z, romhw_test_smart
	
romhw_found_diagboard

	ld a, 1
	ld (v_testhwtype), a
	ld a, 0
	out (ROMPAGE_PORT), a
	ret
	
romhw_test_smart

	ld bc, SMART_ROM_PORT
	ld a, %10000000
	out (c), a
	ld hl, str_rommagicstring
	ld a, (hl)
	cp 'T'
	jr nz, romhw_found_smart
	inc hl
	ld a, (hl)
	cp 'R'
	jr nz, romhw_found_smart
	inc hl
	ld a, (hl)
	cp 'O'
	jr nz, romhw_found_smart
	inc hl
	ld a, (hl)
	cp 'M'
	jr z, romhw_not_found
	
romhw_found_smart
	
	ld a, 2
	ld (v_testhwtype), a
	ld a, 0
	ld bc, SMART_ROM_PORT
	out (c), a
	ret
	
romhw_not_found

	xor a
	ld (v_testhwtype), a
	ret

end_rompage_reloc
	
