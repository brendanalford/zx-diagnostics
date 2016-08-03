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
	jr z, romhw_test_jump
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

	push bc
	push de
	push hl
	ld a, 80
	ld e, a
	ld a, 32
	ld hl, 0
	ld d, a
	jr dandinator_paging

;
;	Just here so we can maintain fully relocatable code
romhw_test_jump

	jr romhw_test_jump_2


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

	push bc
	push de
	push hl
	push af
	ld a, 80
	ld e, a
	ld a, 33
	ld hl, 0
	ld d, a
	jr dandinator_paging

;
;	Just here so we can maintain fully relocatable code
romhw_test_jump_2

		jr romhw_test

dandinator_paging

	ld (v_dand_iy_save), iy

	ld c, a; Save A, 4 ts
	ld b, 100 ; First number of pulses : Command, 7 ts (pulse @50us -> PIC Window = ~5ms)

dandinator_cmdloop ; Add extra 110 t-states for ~50us pulse cycle (109 for 48k, 111,34 for 128k)

	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states

	; Branch Send NZ = 4+4+12+(7+6)+4+4+12+13=66 ts
	; Branch NoSend Z = 4+4+7+13+13+12+13=66 ts

	ld a, c 	; Restore A, 4 ts
	or a			; Get when A=0  , 4 ts
	jr nz, dandinator_sppulse ; Jump if pulses left to send 12ts if jumps, 7 otherwise

	ld a, (1) ; Load Dummy Value to A, 13 ts
	ld a, (1) ; Load Dummy Value to A, 13 ts
	jr dandinator_afterpul ; Jump to end pulse cycle, 12 ts

dandinator_sppulse

	ld (hl), d ; Send Pulse 7 ts (ZESARUX)
	dec de ; Dummy instruction 6 t-states
	dec c ; Countdown pulses 4ts
	inc e ; 4ts Dummy instruction that restores E to previous value
	jr dandinator_afterpul ; Jump to end pulse cycle, 12 ts

dandinator_afterpul

	djnz dandinator_cmdloop ; Cycle all pulses: 13ts if cycle 8 if no cycle
	nop ; 4ts Last cycle takes 1ts less
	ld b, 28 ; Drift ~100us actual measured drift=~160us)

dandinator_drift

	djnz dandinator_drift ; Drift will allow for variances in PIC clock Speed and Spectrum type.
	ld iy, (v_dand_iy_save)
	pop af
	pop hl
	pop de
	pop bc
	cp 0x33		; Was this a page out?
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
	jr z, romhw_test_dandinator

;	Paged out successfully. Now we need to page each bank
; 	back in turn to find our diags rom again.

romhw_found_zxc

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

romhw_test_dandinator

;	Set up for disable of test ROM

	ld a, 80
	ld e, a
	ld a, 33
	ld d, a
	ld hl, 0
	ld (v_dand_iy_save), iy

	ld c, a; Save A, 4 ts
	ld b, 100 ; First number of pulses : Command, 7 ts (pulse @50us -> PIC Window = ~5ms)

test_dandinator_cmdloop ; Add extra 110 t-states for ~50us pulse cycle (109 for 48k, 111,34 for 128k)

	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states

	; Branch Send NZ = 4+4+12+(7+6)+4+4+12+13=66 ts
	; Branch NoSend Z = 4+4+7+13+13+12+13=66 ts

	ld a, c 	; Restore A, 4 ts
	or a			; Get when A=0  , 4 ts
	jr nz, test_dandinator_sppulse ; Jump if pulses left to send 12ts if jumps, 7 otherwise

	ld a, (1) ; Load Dummy Value to A, 13 ts
	ld a, (1) ; Load Dummy Value to A, 13 ts
	jr test_dandinator_afterpul ; Jump to end pulse cycle, 12 ts

test_dandinator_sppulse

	ld (hl), d ; Send Pulse 7 ts (ZESARUX)
  dec de ; Dummy instruction 6 t-states
	dec c ; Countdown pulses 4ts
	inc e ; 4ts Dummy instruction that restores E to previous value
	jr test_dandinator_afterpul ; Jump to end pulse cycle, 12 ts

test_dandinator_afterpul

	djnz test_dandinator_cmdloop ; Cycle all pulses: 13ts if cycle 8 if no cycle
	nop ; 4ts Last cycle takes 1ts less
	ld b, 28 ; Drift ~100us actual measured drift=~160us)

test_dandinator_drift

	djnz test_dandinator_drift ; Drift will allow for variances in PIC clock Speed and Spectrum type.
	ld iy, (v_dand_iy_save)

;	Now check for the TROM magic string

	ld hl, de
	ld a, (hl)

	ld hl, str_rommagicstring
	ld a, (hl)
	cp 'T'
	jr nz, dandinator_paging_test_success
	inc hl
	ld a, (hl)
	cp 'R'
	jr nz, dandinator_paging_test_success
	inc hl
	ld a, (hl)
	cp 'O'
	jr nz, dandinator_paging_test_success
	inc hl
	ld a, (hl)
	cp 'M'
	jr nz, dandinator_paging_test_success

	jr romhw_not_found

dandinator_paging_test_success

;	Successfully paged out the test ROM, set flags and page ourselves
; back in.

	ld a, 4
	ld (v_testhwtype), a

	ld a, 80
	ld e, a
	ld a, 32
	ld d, a
	ld hl, 0
	ld (v_dand_iy_save), iy

	ld c, a; Save A, 4 ts
	ld b, 100 ; First number of pulses : Command, 7 ts (pulse @50us -> PIC Window = ~5ms)

after_test_dandinator_cmdloop ; Add extra 110 t-states for ~50us pulse cycle (109 for 48k, 111,34 for 128k)

	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states
	inc iy ; 10 t-states

	; Branch Send NZ = 4+4+12+(7+6)+4+4+12+13=66 ts
	; Branch NoSend Z = 4+4+7+13+13+12+13=66 ts

	ld a, c 	; Restore A, 4 ts
	or a			; Get when A=0  , 4 ts
	jr nz, after_test_dandinator_sppulse ; Jump if pulses left to send 12ts if jumps, 7 otherwise

	ld a, (1) ; Load Dummy Value to A, 13 ts
	ld a, (1) ; Load Dummy Value to A, 13 ts
	jr after_test_dandinator_afterpul ; Jump to end pulse cycle, 12 ts

after_test_dandinator_sppulse

	ld (hl), d ; Send Pulse 7 ts (ZESARUX)
  dec de ; Dummy instruction 6 t-states
	dec c ; Countdown pulses 4ts
	inc e ; 4ts Dummy instruction that restores E to previous value
	jr after_test_dandinator_afterpul ; Jump to end pulse cycle, 12 ts

after_test_dandinator_afterpul

	djnz after_test_dandinator_cmdloop ; Cycle all pulses: 13ts if cycle 8 if no cycle
	nop ; 4ts Last cycle takes 1ts less
	ld b, 28 ; Drift ~100us actual measured drift=~160us)

after_test_dandinator_drift

	djnz after_test_dandinator_drift ; Drift will allow for variances in PIC clock Speed and Spectrum type.
	ld iy, (v_dand_iy_save)
	ret

romhw_not_found

	xor a
	ld (v_testhwtype), a
	ld (v_hw_page), a
	ret

end_rompage_reloc
