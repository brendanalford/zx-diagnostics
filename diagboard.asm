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
;	diagboard.asm
;



;
;	Handler for diagboard paging operations.
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
	cp 3
	jr z, romhw_pagein_zxc
	ld a, 0xff
	ret

romhw_pagein_diagboard

	ld a, %00000000
	out (ROMPAGE_PORT), a
	ret

romhw_pagein_smart

	ld bc, SMART_ROM_PORT
	ld a, (v_hw_page)
	out (c), a
	ret

romhw_pagein_zxc

	ld hl, 0x3fc0
	ld a, (v_hw_page)
	and 0x7
	and l
	ld l, a
	ld a, (hl)
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
	cp 3
	jr z, romhw_pageout_zxc
	ret

romhw_pageout_diagboard

	ld a, %00100000
	out (ROMPAGE_PORT), a
	ld a, b
	cp 0x12
	ret nz
	ld a, c
	cp 0x34
	ret nz
	jp 0

romhw_pageout_smart
	push bc
	ld bc, SMART_ROM_PORT
	ld a, (v_hw_page)
	or 0x80
	out (c), a
	pop bc
	ld a, b
	cp 0x12
	ret nz
	ld a, c
	cp 0x34
	ret nz
	jp 0

romhw_pageout_zxc

	ld hl, 0x3fd0
	ld a, (v_hw_page)
	and 0x7
	and l
	ld l, a
	ld a, (hl)
	ret

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

;	Save the starting page so we can restore it later
;	Allows running this ROM from other slots than slot B

	in a, (c)
	and 0x0f
	ld (v_hw_page), a

	ld a, %10000001
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
	jr z, romhw_test_zxc

romhw_found_smart

	ld a, 2
	ld (v_testhwtype), a
	ld a, (v_hw_page)
	ld bc, SMART_ROM_PORT
	out (c), a
	ret

romhw_test_zxc

;	First see if we can page ourselves out.

	ld hl, 0x3fd0
	ld a, (hl)

	ld hl, str_rommagicstring
	ld a, (hl)
	cp 'T'
	jr nz, romhw_found_zxc
	inc hl
	ld a, (hl)
	cp 'R'
	jr nz, romhw_found_zxc
	inc hl
	ld a, (hl)
	cp 'O'
	jr nz, romhw_found_zxc
	inc hl
	ld a, (hl)
	cp 'M'
	jr z, romhw_not_found

;	Paged out successfully. Now we need to page each bank
; back in turn to find our diags rom again.

	ld de, 0x3fc0

test_zxc_loop

	ld hl, de
	ld a, (hl)

	ld hl, str_rommagicstring
	ld a, (hl)
	cp 'T'
	jr nz, test_zxc_next
	inc hl
	ld a, (hl)
	cp 'R'
	jr nz, test_zxc_next
	inc hl
	ld a, (hl)
	cp 'O'
	jr nz, test_zxc_next
	inc hl
	ld a, (hl)
	cp 'M'
	jr nz, test_zxc_next

	jr romhw_found_zxc

test_zxc_next

	inc de
	bit 3, e
	jr z, test_zxc_loop

test_zxc_error

;	Bugger. We paged out but couldn't page ourselves back in.
;	Error time.

	ld a, 250
	out (ULA_PORT), a
	ld a, 2
	out (ULA_PORT), a
	jr test_zxc_error

romhw_found_zxc

	ld a, 3
	ld (v_testhwtype), a
	ld a, e
	and 0x7
	ld (v_hw_page), a
	ld hl, 0x3fc0
	and l
	ld l, a
	ld a, (hl)
	ret

romhw_not_found

	xor a
	ld (v_testhwtype), a
	ld (v_hw_page), a
	ret

end_rompage_reloc
