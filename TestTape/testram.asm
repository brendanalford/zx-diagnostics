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
;	memtest.asm
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

	org 26000

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
	ld (v_bold), a
	ld a, 56
	ld (v_attr), a

	ld b, 5
	ld hl, v_hexstr
	
; 	Perform some rudimentary lower RAM / page 5 tests.
;	We'll only be able to test RAM from 16384-25999, or 
;	9615 bytes - this utility takes up the other 6k (6767 bytes).

	ld a, BORDERGRN
	out (ULA_PORT), a

	BLANKMEM 22528, 768, 0
	
;	Just do the random tests

    	RANDFILLUP 16384, 4806, 0
    	RANDFILLDOWN 25998, 4806, 255
    	
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

hexstr_init

	ld (hl), a
	inc hl
	djnz hexstr_init
	
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
    	call print

	ld hl, str_footer
	call print

	ld hl, str_lowerramok
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

	ld bc, 6
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

  
	include "..\print.asm"
	include "..\paging.asm"
	
;
;	Table to define ROM signatures
;

rom_signature_table

	defw 0xfd5e, str_rom48k, test_48k
	defw 0xeffc, str_rom128k, test_128k
	defw 0x3a1f, str_rom128esp, test_128k
	defw 0x2aa3, str_romplus2, test_plus2
	defw 0x3567, str_romplus2esp, test_plus2
	defw 0xd3b4, str_romplus2fra, test_plus2
	defw 0x3998, str_romplus2a, test_plus3
	defw 0x88f9, str_romplus3, test_plus3
	defw 0x5a18, str_romplus3esp, test_plus3
;	Some +3E ROM sets that might be out there
	defw 0x8dfe, str_romplus3e_v1_38, test_plus3
	defw 0xcaf2, str_romplus3e_v1_38esp, test_plus3
	defw 0x0000

str_rom48k

	defb	"Spectrum 16/48K ROM...      ", 0

str_rom128k

	defb	"Spectrum 128K ROM...        ", 0

str_rom128esp

	defb	"Spectrum 128K (Esp) ROM...  ", 0
	
str_romplus2

	defb	"Spectrum +2 (Grey) ROM...   ", 0

str_romplus2esp

	defb	"Spectrum +2 (Esp) ROM...    ", 0

str_romplus2fra

	defb	"Spectrum +2 (Fra) ROM...    ", 0
	
str_romplus3

	defb	"Spectrum +3 (v4.0) ROM...   ", 0
	
str_romplus2a

	defb    "Spectrum +2A (v4.1) ROM...  ", 0
	
str_romplus3esp

	defb	"Spectrum +2A/+3 (Esp) ROM.. ", 0

str_romplus3e_v1_38

	defb 	"Spectrum +3E v1.38 ROM...   ", 0
	
str_romplus3e_v1_38esp

	defb	"Spec +3E v1.38 ROM (Esp)... ", 0

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

	defb	AT, 0, 0, PAPER, 0, INK, 7, BRIGHT, 1, TEXTBOLD, " ZX Spectrum Diagnostics  "
	defb	TEXTNORM, PAPER, 0, INK, 2, "~", PAPER, 2, INK, 6, "~", PAPER, 6, INK, 4, "~"
	defb	PAPER, 4, INK, 5, "~", PAPER, 5, INK, 0, "~", PAPER, 0," ", ATTR, 56, 0

str_footer			
	
	defb	AT, 23, 0, "    v0.2 D. Smith, B. Alford    ", 0
	
str_lowerramok

	defb 	AT, 2, 0, "Lower RAM (partial test)... ", TEXTBOLD, INK, 4, "PASS", TEXTNORM, INK, 0, 0
	
str_test4

	defb	"\nUpper RAM Walk test...      ", 0 

str_test5

	defb	"Upper RAM Inversion test... ", 0 

str_test6

	defb	"Upper RAM March test...     ", 0

str_test7

	defb	"Upper RAM Random test...    ", 0 


str_48ktestsfail

	defb	"\n", TEXTBOLD, PAPER, 2, INK, 7,"        48K tests FAILED        \n", TEXTNORM, ATTR, 56, 0

str_isthis16k	

	defb	"   This may be a 16K Spectrum   ", 0	
	
str_128ktestsfail

	defb	"\n", TEXTBOLD, PAPER, 2, INK, 7,"       128K tests FAILED        \n", TEXTNORM, ATTR, 56, 0


str_128kpagingfail

	defb	"\n", TEXTBOLD, PAPER, 2, INK, 7,"    128K Paging tests FAILED    \n", TEXTNORM, ATTR, 56, 0

str_romcrc	

	defb	AT, 4, 0, "Checking ROM version...     ", 0

str_romunknown

	defb	AT, 4, 0, INK, 2, TEXTBOLD, "Unknown ROM", INK, 0, TEXTNORM, "                 ", ATTR, 56, 0

str_testselect

	defb	AT, 5, 0, "Press 1:48K 2:128K 3:+2 4:+2A/+3", 0 

str_assume48k

	defb 	AT, 5, 0, "Assuming 48K mode...\n", 0
	
str_select48k

	defb	AT, 5, 6, BRIGHT, 1, "1:48K\n", TEXTNORM, ATTR, 56, 0

str_select128k

	defb	AT, 5, 12, BRIGHT, 1, "2:128K\n", TEXTNORM, ATTR, 56, 0

str_selectplus2

	defb	AT, 5, 19, BRIGHT, 1, "3:+2\n", TEXTNORM, ATTR, 56, 0

str_selectplus3

	defb	AT, 5, 24, BRIGHT, 1, "4:+2A/+3", TEXTNORM, ATTR, 56, 0

str_dblbackspace

	defb	LEFT, LEFT, 0

str_testpass

	defb	INK, 4, TEXTBOLD, "PASS", TEXTNORM, INK, 0, 0

str_testfail

	defb	INK, 2, TEXTBOLD, "FAIL", TEXTNORM, INK, 0, 0

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

	defb	"\n", PAPER, 4, INK, 7, BRIGHT, 1, TEXTBOLD, "      48K RAM Tests Passed      ", TEXTNORM, ATTR, 56, 0

str_128ktestspass

	defb	"\n", PAPER, 4, INK, 7, BRIGHT, 1, TEXTBOLD, "     128K RAM Tests Passed      ", TEXTNORM, ATTR, 56, 0

	
str_halted

	defb	TEXTBOLD, "\n   *** Testing Completed ***    ", TEXTNORM, 0 

str_halted_fail

	defb	TEXTBOLD, "\n     *** Failures found ***     ", TEXTNORM, 0 

str_check_128_hal

	defb	"Check IC29 (PAL10H8CN) and IC31\n(74LS174N)\n", 0

str_check_plus2_hal

	defb	"Check IC7 (HAL10H8ACN) and IC6\n(74LS174N)\n", 0


str_check_plus3_ula

	defb	"Check IC1 (ULA 40077)\n", 0
	
str_check_ic

	defb	"Check the following IC's:\n", 0

str_ic

	defb "IC", 0

;	Page align the IC strings to make calcs easier
;	Each string block needs to be aligned to 32 bytes

	BLOCK #7B00-$, #FF

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

;	Magic string to tell if we can page out our ROM (so that we can
;	tell the difference between Diagboard hardware and generic external
;	ROM boards)

	BLOCK #7C00-$, #36

;	Character set at 0x7C00
      
	include "..\charset.asm"

;	Fill ROM space up to 0x7FFF with FF's

	BLOCK #8000-$,#FF

;
;	System Variable locations in lower ram 
;

;	Printing system variables

v_column		equ #7f00; 1
v_row			equ #7f01; 1
v_attr			equ #7f02; 1
v_bold			equ #7f03; 1

;	Miscellaneous

v_hexstr		equ #7f10; 5
v_intcount		equ #7f1a; 4
v_decstr		equ #7f20; 6
v_rtcenable		equ #7f28; 1
v_rtc			equ #7f29; 4 - h:m:s:50

;	Testing variables

v_stacktmp		equ #7f30; Temporary stack location when calling routines that assume no lower ram
v_curpage		equ #7f32; Currently paged location
v_paging		equ #7f33; Bank Paging status (output)
v_fail_ic		equ #7f36; Failed IC bitmap (48K)
v_fail_ic_uncontend	equ #7f37; Failed IC bitmap, uncontended memory banks 0,2,4,8 (128k)
v_fail_ic_contend	equ #7f38; Failed IC bitmap, contended memory banks 1,3,5,7 (128k)
v_128type		equ #7f39; 0 - 128K toastrack, 1 - grey +2, 2 - +2A or +3

