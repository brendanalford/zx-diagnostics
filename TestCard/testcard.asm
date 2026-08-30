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

	include "../defines.asm"
	include "../version.asm"

	org 32768

;
;	Be extra stingy with the memory. At one point we
;	only had 2 bytes free.
;
	DEFINE SAVEMEM

;	This will enable extra code in the testcard routines to call back to us to 
;	do the vertical text.

	DEFINE TESTCARD_TAPE

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

	ld a, BORDERWHT
	out (ULA_PORT), a

;	Clear the screen and print the top and bottom banners

	call ay_reset
	call testcard

;	Reset the machine on return 

	jp 0

;
;	Define some stubs for routines that are not part of this package
;
prt_scroll

 	ret

initialize 

	ret 

read_kempston

	ret 


diagrom_exit 

	jp 0

beep

	push bc

.tone.duration

	pop bc
	push bc

.tone.period

	dec bc
	ld a, b
	or c
	jr nz, .tone.period

;	Toggle speaker output, preserve border

	ld a, l
	xor 0x10
	ld l, a
	out (0xfe), a

;	Generate tone for desired duration

	dec de
	ld a, d
	or e
	jr nz, .tone.duration

	pop bc
	ret

;	Prints vertical text using the sideways font. Supports A-Z only.

test_card_vertical_text

;	Before we do the text, create some proper attributes for the text to land on
	ld hl, tc_attributes
	ld de, 0x5900
	ld bc, 0x20
	ldir 

	ld hl, 0x5900 
	ld de, 0x5920
	ld bc, 0x40 
	ldir 

	ld hl, 0x5900 
	ld de, 0x5940
	ld bc, 0x80 
	ldir 

	ld hl, 0x5900 
	ld de, 0x5980
	ld bc, 0x100 
	ldir 


	ld hl, tc_white
	call test_card_print_vert_text
	ld hl, tc_yellow
	call test_card_print_vert_text
	ld hl, tc_cyan
	call test_card_print_vert_text
	ld hl, tc_green
	call test_card_print_vert_text
	ld hl, tc_magenta
	call test_card_print_vert_text
	ld hl, tc_red
	call test_card_print_vert_text
	ld hl, tc_blue
	call test_card_print_vert_text
	ld hl, tc_black
	call test_card_print_vert_text

	ret 

test_card_print_vert_text

	push hl
	pop ix
	ld hl, (ix)
	inc ix 
	inc ix

; 	HL contains the screen location, IX points to the character location. 

test_card_print_vert_char_loop

	ld de, vertcharset
	ld a, (ix)
	sub 'A'

;	Multiply by 8

	add a, a 
	add a, a 
	add a, a 
	ld e, a 

	ld b, 8

;	Now DE contains the location of the character data. 

	push hl 

test_card_print_v_t_loop

	ld a, (de)
	push af 

;	Do 1st half 
	and 0xf0 
	rrca
	rrca
	rrca 
	rrca 
	ld (hl), a 
	inc hl 

;	Do 2nd half 
	pop af 
	and 0x0f 
	rlca 
	rlca 
	rlca 
	rlca 
	ld (hl), a 
	dec hl 

;	Move print position to next line 
	inc h

;	Update character data location
	inc de 

	djnz test_card_print_v_t_loop 

	pop hl

; 	Next character line and next charset data byte.

	inc e 

	ld a, 32 
	add l 
	ld l, a 

	inc ix
	ld a, (ix)
	cp 0
	jr nz, test_card_print_vert_char_loop

;	All done
	ret 

;	We're going to make some assumptions here.
;	1) This routine will only print characters A-Z
;	2) It will only ever print on the middle third of the screen, without attributes
;	3) It will be hardcoded to split the character across the 2nd and 3rd character.
;
;	So, we can define tables for each string, beginning with the display file offset
;	at which the character should begin, the text, and a marker byte.

test_card_text_data

tc_white

	defw	0x4821
	defb	"WHITE", 0

tc_yellow

	defw	0x4825
	defb	"YELLOW", 0

tc_cyan 

	defw	0x4829
	defb	"CYAN", 0

tc_green  

	defw	0x482D
	defb	"GREEN", 0

tc_magenta 

	defw	0x4831
	defb	"MAGENTA", 0

tc_red 

	defw	0x4835
	defb	"RED", 0

tc_blue 

	defw	0x4839
	defb	"BLUE", 0

tc_black 

	defw	0x483D
	defb	"BLACK", 0

	include "../print.asm"
	include "../input.asm"
	include "../testcard.asm"

tc_attributes 

	defb 0x38, 0x38, 0x78, 0x78, 0x30, 0x30, 0x70, 0x70, 0x28, 0x28, 0x68, 0x68, 0x20, 0x20, 0x60, 0x60
	defb 0x1f, 0x1f, 0x5f, 0x5f, 0x17, 0x17, 0x57, 0x57, 0x0f, 0x0f, 0x4f, 0x4f, 0x07, 0x07, 0x47, 0x47

;
;	String tables
;

; the ZX Spectrum Diagnostics Banner

str_banner

	defb	TEXTBOLD, "ZX Spectrum Diagnostics", TEXTNORM, 0

	BLOCK 0x8d00-$, 0xFF

;	Character set at 0x8b00

	include "../charset.asm"

	BLOCK 0x9100-$, 0xFF

; 	Vertical character set at 0x8F00. Chars A-Z only

	include "../vertcharset.asm"

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
v_scrl_lines  	equ #7d86; 1

;	Miscellaneous

v_hexstr		equ #7f90; 5
v_intcount		equ #7f9a; 4
v_decstr		equ #7fa0; 6

;	Testing variables

v_stacktmp			equ #7fb0; Temporary stack location when calling routines that assume no lower ram
v_curpage			equ #7fb2; Currently paged location
v_paging			equ #7fb3; Bank Paging status (output)
v_fail_ic			equ #7fb6; Failed IC bitmap (48K)
v_fail_ic_uncontend	equ #7fb7; Failed IC bitmap, uncontended memory banks 0,2,4,8 (128k)
v_fail_ic_contend	equ #7fb8; Failed IC bitmap, contended memory banks 1,3,5,7 (128k)
v_128type			equ #7fb9; 0 - 128K toastrack, 1 - grey +2, 2 - +2A or +3
v_test_rtn			equ #7fba;	Address of test routine for extra memory (48/128)
v_keybuffer			equ #7fbc; Keyboard bitmap (8 bytes)
v_rand_addr			equ #7fc4;	Random fill test base addr
v_rand_seed			equ #7fc6;	Random fill test rand seed
v_rand_reps			equ #7fc8;	Random fill test repetitions
v_cmoscpupresent 	equ	#7fca;	Stores CPU type - 0=NMOS, 1=CMOS

;	defines that need duplication from the main test tools

sys_stack 			equ 24499
v_testcard_flags	equ #7fcb; bit 0 - AY present. bit 1 - quiet mode
v_kempston			equ #7fcc; Bit 7 - Kempston I/F present
									 ; Bits 5-0: Kempston values after call to read_kempston
v_testcard			equ #7fd0; Workspace for testcard string
