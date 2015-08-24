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
;	testrom.asm
;

;
;	Spectrum Diagnostics - Spectranet ROM Module Part 2 - 48 and 128 tests
;
;	v0.1 by Dylan 'Winston' Smith
;	v0.2 modifications and 128K testing by Brendan Alford.
;
	
	include "..\defines.asm"
	include "..\version.asm"
	include "spectranet.asm"
	
	org 0x2000

;	Spectranet ROM Module table

	defb 0xAA			; Code module
	defb 0xba			; ROM identity - needs to change
	defw 0xffff			; No init routine 
	defw 0xffff			; Mount vector - unused
	defw 0xffff			; Reserved
	defw 0xffff			; Address of NMI Routine
	defw 0xffff			; Address of NMI Menu string
	defw 0xffff			; Reserved
	defw str_identity	; Identity string

modulecall

;	Module 2 will call us here.	
;	Lower tests passed.
;	Page in ROM 0 (if running on 128 hardware) in preparation
;	for ROM test.

	ld hl, str_callok
	call PRINT42
	call GETKEY
	
	ret
	include "..\paging.asm"
	include "testroutines.asm"
	include "48tests.asm"
	include "128tests.asm"
;	include "..\romtables.asm"
	

str_callok

	defb "Now running from ROM image 0xBA!\n",0

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
print

	call PRINT42
	ret
	
newline

	ld a, '\n'
	call PUTCHAR42
	ret

str_identity

	defb "ZX-Diagnostics ", VERSION, " [1/2]", 0 
	
str_testpass

	defb "PASS", 0
	
str_testfail

	defb "FAIL", 0
	
str_newline

	defb "\n", 0
	
str_test4

	defb	"\nUpper RAM Walk test...      ", 0 

str_test5

	defb	"Upper RAM Inversion test... ", 0 

str_test6

	defb	"Upper RAM March test...     ", 0

str_test7

	defb	"Upper RAM Random test...    ", 0 

str_48ktestspass

	defb	"\n48K RAM Tests Passed", 0

str_48ktestsfail

	defb	"\n48K tests FAILED\n", 0

str_isthis16k

	defb	"This appears to be a 16K Spectrum\n"
	defb    "If 48K, check IC23-IC26 (74LS157, 32, 00)",0

str_check_ic

	defb	"Check the following IC's:\n", 0

str_ic

	defb "IC", 0
	
str_testingbank

	defb	"\nTesting RAM bank  ", 0

str_testingpaging

	defb	"Testing paging    ", 0 

str_bankm

	defb	"x ", 0

	
str_128ktestspass

	defb	"\n128K RAM Tests Passed", 0
	
str_128ktestsfail

	defb	"\n128K tests FAILED\n\n", 0

str_128kpagingfail

	defb	"\n128K Paging tests FAILED\n\n", 0

str_check_128_hal

	defb	"Check IC29 (PAL10H8CN) and IC31 (74LS174N)", 0

str_check_plus2_hal

	defb	"Check IC7 (HAL10H8ACN) and IC6 (74LS174N)", 0

str_check_js128_hal

	defb	"Check HAL (GAL16V8) and U6 (74LS174N)", 0

str_check_plus3_ula

	defb	"Check IC1 (ULA 40077)", 0
	
;	Page align the IC strings to make calcs easier
;	Each string block needs to be aligned to 32 bytes

	BLOCK #2ee0-$, #FF

str_bit_ref
	
	defb "0 ", 0, 0,  "1 ", 0, 0, "2 ", 0, 0, "3 ", 0, 0, "4 ", 0, 0, "5 ", 0, 0, "6 ", 0, 0, "7 ", 0, 0

str_48_ic

	defb "15 ",0, "16 ",0, "17 ",0, "18 ",0, "19 ",0, "20 ",0, "21 ",0, "22 ", 0	

str_128k_ic_contend

	defb "6  ",0, "7  ",0, "8  ",0, "9  ",0, "10 ",0, "11 ",0, "12 ",0, "13 ", 0

str_128k_ic_uncontend

	defb "15 ",0, "16 ",0, "17 ",0, "18 ",0, "19 ",0, "20 ",0, "21 ",0, "22 ", 0	

str_plus2_ic_contend

	defb "32 ",0, "31 ",0, "30 ",0, "29 ",0, "28 ",0, "27 ",0, "26 ",0, "25 ", 0

str_plus2_ic_uncontend

	defb "17 ",0, "18 ",0, "19 ",0, "20 ",0, "21 ",0, "22 ",0, "23 ",0, "24 ", 0

str_plus3_ic_contend

	defb "3  ", 0, "4  ", 0
	
str_plus3_ic_uncontend

	defb "5  ", 0, "6  ", 0	

str_js128_ic_contend

	defb "20 ",0, "21 ",0, "22 ",0, "23 ",0, "24 ",0, "25 ",0, "26 ",0, "27 ", 0

str_js128_ic_uncontend

	defb "29 ",0, "28 ",0, "10 ",0, "9  ",0, "30 ",0, "31 ",0, "32 ",0, "33 ", 0

	BLOCK 0x2fff-$, 0xff
	
	
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
v_rand_addr		equ #7fbe;	Random fill test base addr
v_rand_seed		equ #7fc0;	Random fill test rand seed
v_rand_reps		equ #7fc2;	Random fill test repetitions
