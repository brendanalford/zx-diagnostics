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
;	testrammain.asm
;	

;
;	Spectrum Diagnostics Test Program
;
;	Derived from Spectrum Diagnostics Test ROM code, which is...
;
;	v0.1 by Dylan 'Winston' Smith
;	v0.2 modifications and 128K testing by Brendan Alford.
;

	include "..\defines.asm"
	include "..\version.asm"

	org 24600

;
;	Be extra stingy with the memory. At one point we
;	only had 2 bytes free.
;
	DEFINE SAVEMEM 

start

; Initialize system variables

	di
	xor a
	ld ix, 0
	ld (v_fail_ic), a
	ld (v_fail_ic_contend), a
	ld (v_fail_ic_uncontend), a

	ld (v_column), a
    	ld (v_row), a
	ld (v_pr_ops), a
	ld a, 56
	ld (v_attr), a
	ld a,6 
	ld (v_width), a

	ld b, 5
	ld hl, v_hexstr

;	Soak test indicator: non zero = soak test active.

	ld iy, 0
	
; 	Perform some rudimentary lower RAM / page 5 tests.
;	We'll only be able to test RAM from 16384-24999, or 
;	8615 bytes - this utility takes up the other 7k (7767 bytes).

lowermem_test

	ld a, BORDERGRN
	out (ULA_PORT), a

	BLANKMEM 22528, 768, 0
	
;	Just do the random tests

    	RANDFILLUP 16384, 4057, 0
    	RANDFILLDOWN 24498, 4057, 255
    	
;	Establish a stack

	ld sp, 0x7bff

;	Check if lower ram tests passed
	
	ld a, ixh
	cp 0
	jr z, use_uppermem

;	Lower memory error detected.
;	We won't be able to test anything else effectively.
;	Finish with painting border with bad bits: black border
;	with red stripes for failed IC's, green for good ones.
;	Topmost stripe is bit 0, lowermost is bit 7.

;	First blank the screen but with white paper/black ink.
;	This gives the opportunity to visually see what's happening in
;	lower memory. This'll also give us a pattern to lock onto with 
;	the floating bus to sync the border (no room for an IM2 vector table).

    	BLANKMEM 16384, 6144, 0

;	Attributes - white screen, blank ink.

	BLANKMEM 22528, 768, 56

;	Enable interrupts. Hopefully the system is working to an 
;	extent that we can handle interrupts and use them to sync to the
;	screen refresh. Let's face it, we wouldn't have got this far if
;	not :)
	
	ei
	
fail_border

;	Starting border black until we need stripes
	
	halt
	ld a, 0
	out (ULA_PORT), a

;	Add a small delay so that the stripes begin when
;	paper begins

	ld a, 0x00
	ld c, a
	ld a, 0x2
	ld b, a


fail_border_wait:
	dec bc
	ld a, b
	or c
	jr nz, fail_border_wait

fail_border_1
	
	ld de, ix
	xor a
	ld c, a

; Change border to green or red depending on whether the current
; bit has been determined bad or not

fail_border_2

	ld a, 4
	bit 0, d
	jr z, fail_border_3
	ld a, 2

; Output the status colour for this bit

fail_border_3

	out (ULA_PORT), a
	ld a, 0xd0
	ld b, a

fail_border_4

	djnz fail_border_4

; Change back to black for gap between stripes

	ld a, 0
	out (ULA_PORT), a
	ld a, 0x80
	ld b, a

fail_border_5

	djnz fail_border_5
	rr d
	inc c
	ld a, c
	cp 8
	jr nz, fail_border_2

; Done, now delay a little

	ld bc, 0x40

fail_border_6

	dec bc
	ld a, c
	or b
	jr nz, fail_border_6

;	Delay until we're off the screen

	ld a, 0x8a
	ld b, a

fail_border_8

	djnz fail_border_8
	ld a, 0
	out (ULA_PORT), a

; And repeat for next frame - enable ints and wait for and interrupt
; to carry us back

fail_border_end

	jr fail_border


;	Lower tests passed.
;	Page in ROM 0 (if running on 128 hardware) in preparation
;	for ROM test.

use_uppermem

	xor a 
	ld bc, 0x1ffd
	out (c), a
	ld bc, 0x7ffd
	out (c), a

uppermem_test

	ld hl, v_hexstr
	
hexstr_init

	ld (hl), a
	inc hl
	djnz uppermem_test
	
	ld b, 6
	ld hl, v_decstr
	xor a
	
decstr_init

	ld (hl), a
	inc hl
	djnz decstr_init
	
    	ld a, BORDERWHT
    	out (ULA_PORT), a

;	Clear the screen and print the top and bottom banners

	call cls
    	ld hl, str_banner
    	call print_header

	call print_footer

	ld hl, str_lowerramok
	call print
	
	ld a, iyh
	or iyl
	jr nz, check_soak_test
	
	ld hl, str_runsoak
	call print

get_soak_input
	
	call get_key
	cp 'Y'
	jr z, soak_test_on
	cp 'N'
	jr z, check_soak_test
	jr get_soak_input
	
soak_test_on

	ld iy, 1
	jr rom_test
	
check_soak_test

;
;	Check if a soak test is active 
;	output the iteration if so
;
	ld a, iyh
	or iyl
	jr z, rom_test
	
	ld hl, str_soaktest
	call print
	ld hl, iy
	ld de, v_decstr
	call Num2Dec
	ld hl, v_decstr
	call print

rom_test

;	Perform some ROM checksum testing to determine what
;	model we're running on

; 	Assume 128K toastrack (so far)

	xor a 
	ld (v_128type), a    
	
	ld hl, str_romcrc
    	call print

;	Checksum the ROM

    	call romcrc

;	Save it in DE temporarily
	
	ld de, hl
	ld hl, rom_signature_table
		
; 	Check for a matching ROM

rom_check_loop

;	Check for 0000 end marker

	ld bc, (hl)
	ld a, b
	or c
	jr z, rom_unknown
	
;	Check saved ROM CRC in DE against value in table
	
	ld a, d
	xor b
	jr nz, rom_check_next
	ld a, e
	xor c
	jr nz, rom_check_next

rom_check_found

;	Print the appropriate ROM type to screen

	push hl
	inc hl
	inc hl
	ld de, (hl)
	ld hl, de
	xor a
	ld (v_column), a
	call print
	ld hl, str_testpass
	call print
	pop hl

;	Call the appropriate testing routine

	ld de, 4
	add hl, de
	
;	Set up return address to be the testinterrupts label

	ld de, tests_complete
	push de
	
	ld de, (hl)
	ld hl, de
	jp hl
	
test_routine_return

	jp tests_complete

rom_check_next

	ld bc, 8
	add hl, bc
	jr rom_check_loop

; Unknown ROM, say so and prompt the user for manual selection

rom_unknown

	push de
	ld hl, str_romunknown
	call print
	pop hl
      	ld de, v_hexstr
      	call Num2Hex
      	xor a
      	ld (v_hexstr+4), a
      	ld hl, v_hexstr
      	call print

; 	Allow user to choose model if ROM version can't be determined

	ld hl, str_testselect
	call print

select_test
	  
	ld bc, 0xf7fe
	in a, (c)

; 	Only interested in keys 1,2,3 and 4

	and 0xf
	cp 0xf
	jr z, select_test

;	Scan the test vector table and call the appropriate routine

	ld hl, test_vector_table
	ld b, a
	
select_test_1

	ld de, (hl)
	ld a, d
	or e
	jr z, select_test
	
	bit 0, b
	jr nz, select_test_2
	
	push hl
	ld de, (hl)
	ld hl, de
	call print
	
	pop hl
	inc hl
	inc hl
	ld de, (hl)
	ld hl, de
	ld de, tests_complete
	push de
	jp hl
	
select_test_2

	ld de, 4
	add hl, de
	rr b
	jr select_test_1
	
	
tests_complete

;	Did we encounter any failures?

	xor a
	ld b, a
	ld a, (v_fail_ic)
	or b
	ld b, a
	ld a, (v_fail_ic_contend)
	or b
	ld b, a
	ld a, (v_fail_ic_uncontend)
	or b
	jr z, tests_passed

;	Yes we did - say so and halt
	
	ld hl, str_halted_fail
	call print

	di 
	halt

tests_passed

;	All tests passed.

	ld a, iyh
	or iyl
	jp z, tests_done
	
;	Soak test.
;	A short delay before recommencing testing

	ld hl, 0x08
innerdelay_1
	ld bc, 0xffff
innerdelay_2
	dec bc
	ld a, b
	or c
	jr nz, innerdelay_2

	dec hl
	ld a, h
	or l
	jr nz, innerdelay_1

	inc iy
	jp lowermem_test

	
tests_done
	ld hl, str_halted
	call print
	di
	halt

;
;	Testing Routines
;

	include "..\48tests.asm"
	include "..\128tests.asm"

;
;	Subroutine to print a list of failing IC's.
;   	Inputs: D=bitmap of failed IC's, IX=start of IC number list
;

print_fail_ic

	ld b, 0

fail_print_ic_loop

	bit 0, d
	jr z, ic_ok

;	Bad IC, print out the correspoding location for a 48K machine

	ld hl, str_ic
	call print
	ld hl, ix

;	Strings are aligned to nearest 32 bytes, so we can just replace
;	this much the LSB

	ld a, b
	rlca
	rlca
	or l
	ld l, a
	
	call print
	ld a, 5
	call check_end_of_line

ic_ok

;	Rotate D register right to line up the next IC result 
;	for checking in bit 0

	rr d

;	Loop round if we've got more bits to check

	inc b
	ld a, b
	cp 8
	jr nz, fail_print_ic_loop

	ret

;
;	Subroutines to print a list of failing IC's for 4 bit wide
;	memories (+2A/+3).
;   	Inputs: D=bitmap of failed IC's, IX=start of IC number list
;

print_fail_ic_4bit


	ld a, d
	and 0x0f
	jr z, next_4_bits

;	Bad IC, print out the correspoding location 

	ld hl, str_ic
	call print
	ld hl, ix
	call print
	
next_4_bits
	
	ld bc, 4
	add ix, bc
	
	ld a, d
	and 0xf0
	jr z, bit4_check_done

	ld hl, str_ic
	call print
	ld hl, ix
	call print
	
bit4_check_done

	ret

;
;	Checks to see if the SPACE key was pressed.
;	Result: Z set if pressed, reset otherwise
;
	
check_spc_key

	ld a, 0x7f
	in a, (0xfe)
	bit 0, a
	ret 

;
;	ROM CRC generation code.
;

romcrc

	ld de, 0

;	Note: byte counter is modified compared to orginal code.

Crc16	

	ld hl,0xFFFF

Read

	ld a, (de)
	inc	de
	xor	h
	ld	h,a
	ld	b,8

CrcByte
    
	add	hl, hl
	jr	nc, Next
	ld	a,h
	xor	10h
	ld	h,a
	ld	a,l
	xor	21h
	ld	l,a

Next	

	djnz	CrcByte
	ld a, d
	cp 0x40     ; 0x4000 = end of rom
	jr	nz,Read

	ret

;
;	Define a no-op scroll routine since we're not including
;	scroll.asm
;
prt_scroll
 	
 	ret
 
	include "..\print.asm"
	include "..\paging.asm"
	include "..\input.asm"
	include "..\romtables.asm"
	
;
;	Table to define pointers to test routines
;

test_vector_table

	defw str_select48k, test_48k
	defw str_select128k, test_128k
	defw str_selectplus2, test_plus2
	defw str_selectplus3, test_plus3
	defw 0x0000

;
;	String tables
;

; the ZX Spectrum Diagnostics Banner 

str_banner

	defb	TEXTBOLD, "ZX Spectrum Diagnostics", TEXTNORM, 0

str_lowerramok

	defb	AT, 2, 0, "Diagnostics integrity check...", TAB, 38 * 6, TAB, 38 * 6, TEXTBOLD, INK, 4, "PASS", TEXTNORM, INK, 0
	defb	AT, 3, 0, "Lower 16K RAM tests (partial test)...", TAB, 38 * 6, TEXTBOLD, INK, 4, "PASS", TEXTNORM, INK, 0, 0

str_runsoak

	defb	AT, 5, 0, "Run in soak test mode? (Press Y or N)", 0
	
str_soaktest

	defb 	AT, 5, 0, "Soak test running, iteration ", 0
	
str_test4

	defb	"\nUpper RAM Walk test...      ", 0 

str_test5

	defb	"Upper RAM Inversion test... ", 0 

str_test6

	defb	"Upper RAM March test...     ", 0

str_test7

	defb	"Upper RAM Random test...    ", 0 

str_48ktestsfail

	defb	"\n", TEXTBOLD, PAPER, 2, INK, 7, "             48K tests FAILED             \n", TEXTNORM, ATTR, 56, 0

str_isthis16k

	defb	"This appears to be a 16K Spectrum\n"
	defb    "If 48K, check IC23-IC26 (74LS157, 32, 00)",0

str_128ktestsfail

	defb	"\n", TEXTBOLD, PAPER, 2, INK, 7, "            128K tests FAILED             \n\n", TEXTNORM, ATTR, 56, 0


str_128kpagingfail

	defb	"\n", TEXTBOLD, PAPER, 2, INK, 7, "         128K Paging tests FAILED         \n\n", TEXTNORM, ATTR, 56, 0

str_romcrc	

	defb	"\n\nChecking ROM version...     ", 0

str_romunknown

	defb	AT, 5, 0, INK, 2, TEXTBOLD, "Unknown or corrupt ROM... ", TEXTNORM, INK, 0, "            ", ATTR, 56, 0

str_testselect

	defb	AT, 6, 0, "Press: 1..48K  2..128K  3..+2  4..+2A/+3", 0

str_select48k

	defb	AT, 6, 7 * 6, BRIGHT, 1, "1..48K\n", TEXTNORM, ATTR, 56, 0

str_select128k

	defb	AT, 6, 15 * 6, BRIGHT, 1, "2..128K\n", TEXTNORM, ATTR, 56, 0

str_selectplus2

	defb	AT, 6, 24 * 6, BRIGHT, 1, "3..+2\n", TEXTNORM, ATTR, 56, 0

str_selectplus3

	defb	AT, 6, 31 * 6, BRIGHT, 1, "4..+2A/+3\n", TEXTNORM, ATTR, 56, 0

str_dblbackspace

	defb	LEFT, LEFT, 0

str_testpass

	defb	INK, 4, TAB, 38 * 6, TEXTBOLD, "PASS", TEXTNORM, INK, 0, 0

str_testfail

	defb	INK, 2, TAB, 38 * 6, TEXTBOLD, "FAIL", TEXTNORM, INK, 0, 0

str_testwait

	defb	"WAIT", 0

str_newline

	defb	"\n",	0

str_testingbank

	defb	"\nTesting RAM bank  ", 0

str_testingpaging

	defb	"Testing paging    ", 0 

str_bankm

	defb	"x ", 0

str_48ktestspass

	defb	"\n", PAPER, 4, INK, 7, BRIGHT, 1, TEXTBOLD, "           48K RAM Tests Passed           ", TEXTNORM, ATTR, 56, 0

str_128ktestspass

	defb	"\n", PAPER, 4, INK, 7, BRIGHT, 1, TEXTBOLD, "          128K RAM Tests Passed           ", TEXTNORM, ATTR, 56, 0
	
str_halted

	defb	TEXTBOLD, "\n\n", TAB, 48, "*** Testing Completed ***", TEXTNORM, 0

str_halted_fail

	defb	TEXTBOLD, "\n", TAB, 36,"Failures found, system halted ", TEXTNORM, 0

str_check_128_hal

	defb	"Check IC29 (PAL10H8CN) and IC31 (74LS174N)", 0

str_check_plus2_hal

	defb	"Check IC7 (HAL10H8ACN) and IC6 (74LS174N)", 0

str_check_js128_hal

	defb	"Check HAL (GAL16V8) and U6 (74LS174N)", 0

str_check_plus3_ula

	defb	"Check IC1 (ULA 40077)", 0
	
str_check_ic

	defb	"Check the following IC's:\n", 0

str_ic

	defb "IC", 0

;	Page align the IC strings to make calcs easier
;	Each string block needs to be aligned to 32 bytes

	BLOCK #7A80-$, #FF

str_bit_ref
	
	defb "0 ", 0, 0,  "1 ", 0, 0, "2 ", 0, 0, "3 ", 0, 0, "4 ", 0, 0, "5 ", 0, 0, "6 ", 0, 0, "7 ", 0, 0

str_48_ic

	defb "15 ",0, "16 ",0, "17 ",0, "18 ",0, "19 ",0, "20 ",0, "21 ",0, "22 ", 0	

str_128k_ic_contend

	defb "6  ",0, "7  ",0, "8  ",0, "9  ",0, "10 ",0, "11 ",0, "12 ",0, "13 ", 0

str_128k_ic_uncontend

	defb "15 ",0, "16 ",0, "17 ",0, "18 ",0, "19 ",0, "20 ",0, "21 ",0, "22 ", 0	

str_js128_ic_contend

	defb "20 ",0, "21 ",0, "22 ",0, "23 ",0, "24 ",0, "25 ",0, "26 ",0, "27 ", 0

str_js128_ic_uncontend

	defb "29 ",0, "28 ",0, "10 ",0, "9  ",0, "30 ",0, "31 ",0, "32 ",0, "33 ", 0

str_plus2_ic_contend

	defb "32 ",0, "31 ",0, "30 ",0, "29 ",0, "28 ",0, "27 ",0, "26 ",0, "25 ", 0

str_plus2_ic_uncontend

	defb "17 ",0, "18 ",0, "19 ",0, "20 ",0, "21 ",0, "22 ",0, "23 ",0, "24 ", 0

str_plus3_ic_contend

	defb "3  ", 0, "4  ", 0
	
str_plus3_ic_uncontend

	defb "5  ", 0, "6  ", 0

	BLOCK #7C00-$, #FF

;	Character set at 0x7C00
      
	include "..\charset.asm"

;	Fill ROM space up to 0x7FFF with FF's

;	BLOCK #8000-$,#FF

;
;	System Variable locations in lower ram 
;

;	Printing system variables

v_column		equ #7f80; 1
v_row			equ #7f81; 1
v_attr			equ #7f82; 1
; v_pr_ops - bit 0: bold on/off, bit 1: inverse on/off
v_pr_ops		equ #7f83; 1
v_width			equ #7f84; 1
v_scroll		equ #7f85; 1
v_scroll_lines  	equ #7d86; 1

;	Miscellaneous

v_hexstr		equ #7f90; 5
v_intcount		equ #7f9a; 4
v_decstr		equ #7fa0; 6

;	Testing variables

v_stacktmp		equ #7fb0; Temporary stack location when calling routines that assume no lower ram
v_curpage		equ #7fb2; Currently paged location
v_paging		equ #7fb3; Bank Paging status (output)
v_fail_ic		equ #7fb6; Failed IC bitmap (48K)
v_fail_ic_uncontend	equ #7fb7; Failed IC bitmap, uncontended memory banks 0,2,4,8 (128k)
v_fail_ic_contend	equ #7fb8; Failed IC bitmap, contended memory banks 1,3,5,7 (128k)
v_128type		equ #7fb9; 0 - 128K toastrack, 1 - grey +2, 2 - +2A or +3
v_test_rtn		equ #7fba;	Address of test routine for extra memory (48/128)
v_keybuffer		equ #7fbc; Keyboard bitmap (8 bytes)