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
;	128tests.asm
;	

;
;	128K Specific Tests
;
;	Page 5 has already been tested lower RAM), so just do pages 0,1,2,3,4,6 and 7.
;   	Page each one into the top 16K of RAM and perform the standard fill, inversion
;   	and random tests.
;   	Finally, do a paging test (only if the RAM checks pass, otherwise it
;   	can't be reliable).
;

test_128k
	
	xor a
	ld (v_128type), a
	jr begin_128_tests
	
test_plus2
	
	ld a, 1
	ld (v_128type), a
	jr begin_128_tests

test_plus3

	ld a, 2
	ld (v_128type), a
	jr begin_128_tests
	
test_js128

	ld a, 3
	ld (v_128type), a

begin_128_tests

	ld hl, str_testingbank
	call outputstring

;	Copy paging string to RAM where we can write to it

	ld hl, str_bankm
	ld de, v_paging
	ld bc, 3
	ldir

	ld b, 0

;	Test an individual RAM page.

test_ram_page
	
	ld a, b

;	Don't touch page 5. That's where the screen and sysvars live.
;	Plus we've already tested it via the 48K lower RAM tests.

	cp 5
	jp z, test_ram_page_skip

;	Page the target page in and write its index to the screen.
;	Save BC beforehand as we're using that
;	to keep track of the current page being tested.

	push bc
	
	call pagein
	ld a, b
	or 0x30
	ld (v_paging), a
	ld hl, v_paging
	call outputstring

	xor a
	ld (v_fail_ic), a
	ld ixh, a

;	Run the walk, inversion and random fill tests on the 
;	target page. 
	
	ld hl, 49152
	ld de, 16384
	call walkloop
	call testresult128

	ld hl, 49152
	ld bc, 16384
	ld d, 0
	call altpata

	ld hl, 49152
	ld bc, 16384
	ld d, 255
	call altpata

	ld hl, 49152
	ld bc, 16384
	ld d, 0
	call altpatb

	ld hl, 49152
	ld bc, 16384
	ld d, 255
	call altpatb
	call testresult128

	ld hl, 49152
	ld bc, 16384
	call marchtest
	call testresult128
	
	
	ld hl, 49152
	ld de, 8192
	ld bc, 11
	call randfillup
	
	ld hl, 65534
	ld de, 8191
	ld bc, 17
	call randfilldown
	call testresult128

	pop bc

; Check if we got a failure for this bank

	push ix
	pop af
	cp 0

; 	Skip to test next page if not

	jr z, test_ram_page_next
	
	ld c, ixh

	ld a, (v_128type)
	cp 2
	jr nz, odd_contend
	cp 3
	jr nz, odd_contend
	
;	+2a/+3 - Was this in a contented bank (4,5,6,7)?

	ld a, b
	cp 4
	jr nc, test_ram_fail_contend
	jr test_ram_fail_uncontend
	
; 	128/+2 - Was this in a contended bank (1,3,5,7)?

odd_contend

	bit 0, b
	jr nz, test_ram_fail_contend

; 	Store result in appropriate sysvar

test_ram_fail_uncontend

	ld a, (v_fail_ic_uncontend)
	or ixh
	ld a, ixh
	ld (v_fail_ic_uncontend), a
	jr test_ram_page_next

; 	Contended bank fail (1,3,5,7)

test_ram_fail_contend

	ld a, (v_fail_ic_contend)
	or ixh
	ld a, ixh
	ld (v_fail_ic_contend), a

;	Check if we've any more pages to test

test_ram_page_next
	
test_ram_page_skip

	inc b
	ld a, b
	cp 8
	jp nz, test_ram_page

; 	Now check if any errors were detected

	ld a, (v_fail_ic_contend)
	ld b, a
	ld a, (v_fail_ic_uncontend)
	or b
	jp z, test_ram_bank_pass

; 	Test failed - say so and abort 128K tests.
; 	No point in testing paging if we don't have
; 	reliable RAM to do so.

	call newline
	ld hl, str_128ktestsfail
	call outputstring
	
; 	If possible, output the failing IC's to the screen

	ld hl, str_check_ic
	call outputstring

; 	Are we a +2 or +3?

	ld a, (v_128type)
	cp 1
	jr z, ic_fail_plus2
	cp 2
	jr z, ic_fail_plus3 
	cp 3
	jr z, ic_fail_js128

; 	Output failing IC's with Toastrack IC references

	ld a, (v_fail_ic_contend)
	ld d, a
	ld ix, str_128k_ic_contend
	call print_fail_ic

	ld a, (v_fail_ic_uncontend)
	ld d, a
	ld ix, str_128k_ic_uncontend
	call print_fail_ic
	jr test_ram_fail_end

; 	Output failing IC's with Grey +2 IC references

ic_fail_plus2

	ld a, (v_fail_ic_uncontend)
	ld d, a
	ld ix, str_plus2_ic_uncontend
	call print_fail_ic

	ld a, (v_fail_ic_contend)
	ld d, a
	ld ix, str_plus2_ic_contend
	call print_fail_ic
	jr test_ram_fail_end

ic_fail_js128

	ld a, (v_fail_ic_uncontend)
	ld d, a
	ld ix, str_js128_ic_uncontend
	call print_fail_ic

	ld a, (v_fail_ic_contend)
	ld d, a
	ld ix, str_js128_ic_contend
	call print_fail_ic
	jr test_ram_fail_end


ic_fail_plus3

	ld a, (v_fail_ic_uncontend)
	ld d, a
	ld ix, str_plus3_ic_uncontend
	call print_fail_ic_4bit

	ld a, (v_fail_ic_contend)
	ld d, a
	ld ix, str_plus3_ic_contend
	call print_fail_ic_4bit

;	Abandon test at this point

test_ram_fail_end

	call newline
	ret

;	RAM tests passed, now test the paging

test_ram_bank_pass

	call newline
	ld hl, str_testingpaging
	call outputstring
	
;	Fill all RAM pages (except page 5) with a pattern
;	that uniquely identifies the page
	
	ld b, 0

test_write_paging

	ld a, b
	cp 5
	jr z, skip_write_page5

;	Page target page in and write the pattern
	
	call pagein

	push bc
	ld hl, 0xc000
	ld de, 0xc001
	ld bc, 0x3fff

;	Ok, it's a really simple pattern (RAM page number) :)

	ld (hl), a
	ldir
	pop bc

skip_write_page5

	inc b
	ld a, b
	cp 8
	jr nz, test_write_paging

;	Pages all written, now page each one back in turn
;	and verify that the expected pattern is in each one.

	ld a, 0
	ld b, a

test_read_paging

;	Skip page 5 as per usual

	ld a, b
	cp 5
	jr z, skip_read_page5

;	Page in test page and write which one is being tested to the screen
	
	call pagein

	ld a, b
	or 0x30
	ld (v_paging), a
	ld hl, v_paging
	push bc
	call outputstring
	pop bc
	
; Test the full page to see if it matches what was written

	ld hl, 0xc000

test_read_loop

	ld a, (hl)
	cp b

;	Non zero comparison means we've not got what we expected.
;	RAM all checks out (as far as we know), so this must be
;	a paging issue.

	jr nz, test_paging_fail

;	Otherwise continue testing

	inc hl
	ld a, h
	or l
	jr nz, test_read_loop

skip_read_page5

;	Any more pages to test paging with?

	inc b
	ld a, b
	cp 8
	jr nz, test_read_paging

;	All tests pass, we're all good. Nothing else to test so return.

	call newline
	ld hl, str_128ktestspass
	call outputstring
	
	ret

test_paging_fail

;	Give the user the bad news

	ld a, 2
	out (ULA_PORT), a
	call newline
	ld hl, str_128kpagingfail
	call outputstring
	
;	A paging fault is most likely the PAL/HAL/ULA chip so identify
;	what type of machine we are running on, then use this info to
;	inform the user which IC to check

	ld a, (v_128type)
	cp 1
	jr z, plus2_pal_msg
	cp 2
	jr z, plus3_ula_msg
	cp 3
	jr z, js128_pal_msg
	
	ld hl, str_check_128_hal
	call outputstring
	call newline
	ret

js128_pal_msg

	ld hl, str_check_js128_hal
	call outputstring
	ret
	
plus2_pal_msg

	ld hl, str_check_plus2_hal
	call outputstring
	ret

plus3_ula_msg

	ld hl, str_check_plus3_ula
	call outputstring
	ret
