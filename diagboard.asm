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

	include "defines.asm"
	include "vars.asm"

	org sys_rompaging
;
;	Handler for diagboard paging operations.
;	Inputs; A=command type, BC=operands.
;

	cp 0
	jp z, romhw_test
	cp 1
	jr z, romhw_pagein
	cp 2
	jr z, romhw_pageout


;	Command not understood, return with error in A

	ld a, 0xff
	ret

; Command 1: Page in external ROM

romhw_pagein

	ld a, (v_testhwtype)
	cp 1
	jr z, romhw_pagein_diagboard
	cp 2
	jr z, romhw_pagein_smart
	cp 3
	jr z, romhw_pagein_zxc
	cp 4
	jr z, romhw_pagein_dand
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

	push hl
	ld hl, 0x3fc0
	ld a, (v_hw_page)
	and 0x7
	or l
	ld l, a
	ld a, (hl)
	pop hl
	ret

romhw_pagein_dand

	ld a, 32
	call issue_dandanator_command
	ret

;	Command 2: Page out external ROM
;	BC = 0x1234: Jump to start of internal ROM

romhw_pageout

	ld a, (v_testhwtype)
	cp 1
	jr z, romhw_pageout_diagboard
	cp 2
	jr z, romhw_pageout_smart
	cp 3
	jr z, romhw_pageout_zxc
	cp 4
	jr z, romhw_pageout_dand
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

	push hl
	ld hl, 0x3fd0
	ld a, (hl)
	pop hl

	ld a, b
	cp 0x12
	ret nz
	ld a, c
	cp 0x34
	ret nz
	jp 0

romhw_pageout_dand

; Are we jumping to ROM at the end of this routine?

	ld a, b
	cp 0x12
	jr nz, romhw_pageout_dand_2
	ld a, c
	cp 0x34
	jr nz, romhw_pageout_dand_2

; Yes, issue command 34 instead of 33 to page out and lock further commands

	ld a, 34
	jr romhw_pageout_dand_3

romhw_pageout_dand_2

	ld a, 33

romhw_pageout_dand_3

	ld hl, 1
	call issue_dandanator_command

	cp 34		; Was this a page out with further commands locked?
	ret nz
	ld a, b		; If so, does BC=0x1234?
	cp 0x12
	ret nz
	ld a, c
	cp 0x34
	ret nz
	jp 0			; Yes - restart the machine


;	Command 3: Test for diagnostic devices
;	Stores result in system variable v_testhwtype

romhw_test

; 	First try diagboard hardware

	ld a, %00100000
	out (ROMPAGE_PORT), a

	call check_magic_string
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
	call check_magic_string
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

	call check_magic_string
	jr z, romhw_test_dandanator

;	Paged out successfully. Now we need to page each bank
; back in turn to find our diags rom again.

romhw_found_zxc

	ld de, 0x3fc0

test_zxc_loop

	call check_magic_string
	jr nz, test_zxc_next

	jr zxc_paged_in

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

zxc_paged_in

	ld a, e
	and 0x7
	ld (v_hw_page), a
	ld a, 3
	ld (v_testhwtype), a

	ret

romhw_test_dandanator

; Before testing for the Dandanator hardware,
; we need to issue a special command sequence to the
; Dandanator board: 46 16 16 1.

	ld hl, 1
	ld a, 46
	call issue_dandanator_command
	inc hl

	ld a, 16
	call issue_dandanator_command
	inc hl
	call issue_dandanator_command

	ld (0), a

;	Set up for disable of test ROM

	ld hl, 1
	ld a, 33
	call issue_dandanator_command

;	Now check for the TROM magic string

	ld hl, de
	ld a, (hl)

	call check_magic_string
	jr z, romhw_not_found

dandanator_paging_test_success

;	Successfully paged out the test ROM, set flags and page ourselves
; back in.

	ld a, 4
	ld (v_testhwtype), a

	ld hl, 1
	ld a, 32
	call issue_dandanator_command
	ret

romhw_not_found

	xor a
	ld (v_testhwtype), a
	ld (v_hw_page), a
	ret

;	Issues a command held in the A register to the
; Dandanator board. Preserves all registers used.
;
issue_dandanator_command

	push bc
	push af

;	Issue Dandanator command/data exchange

	ld b, a

dandanator_cmdloop ; Add extra 110 t-states for ~50us pulse cycle (109 for 48k, 111,34 for 128k)

	ex (sp), hl
	ex (sp), hl
	ld (hl), a
	djnz dandanator_cmdloop

	ld b, 40

dandanator_waitxcmd

	djnz dandanator_waitxcmd

;	Need to waste about 300ms here to allow paging to settle down

	ld bc, 0x100

dandanator_waitforpaging

	dec bc
	ld a, b
	or c
	jr nz, dandanator_waitforpaging

	pop af
	pop bc
	ret

;	Checks to see if the magic string is present in ROM
;

check_magic_string

	ld hl, de
	ld a, (hl)

	ld hl, v_rom_magic_loc
	ld a, (hl)
	cp 'T'
	ret nz
	inc hl
	ld a, (hl)
	cp 'R'
	ret nz
	inc hl
	ld a, (hl)
	cp 'O'
	ret nz
	inc hl
	ld a, (hl)
	cp 'M'
	ret nz

;	Match all the way, zero flag will be set

	ret

;	Magic string to tell if we can page out our ROM (so that we can
;	tell the difference between Diagboard hardware and generic external
;	ROM boards)
