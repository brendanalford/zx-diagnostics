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
;	Spectrum Diagnostics - Spectranet ROM Module
;
;	v0.1 by Dylan 'Winston' Smith
;	v0.2 modifications and 128K testing by Brendan Alford.
;

	include "..\defines.asm"
	include "..\version.asm"
	include "spectranet.asm"

v_border	equ 0x3fef
	
	org 0x2000

;	Spectranet ROM Module table

	defb 0xAA			; Code module
	defb 0xba			; ROM identity - needs to change
	defw initroutine	; Address of reset vector
	defw 0xffff			; Mount vector - unused
	defw 0xffff			; Reserved
	defw 0xffff			; Address of NMI Routine
	defw 0xffff			; Address of NMI Menu string
	defw 0xffff			; Reserved
	defw str_identity	; Identity string

modulecall

	;	Blank the screen, (and all lower RAM)

	BLANKMEM 16384, 16384, 0

;	Sound a brief tone to indicate tests are starting.
;	This also verifies that the CPU and ULA are working.

	ld l, 1				; Border colour to preserve
	BEEP 0x48, 0x0300
	BEEP 0x23, 0x0150

start_testing

	ld iy, 0
	add iy, sp
	
	ld ix, 0
	
;	Blue border - signal no errors (yet)

	ld a, BORDERGRN
	out (ULA_PORT), a

;	Same for LED's - all off signifies no errors

	xor a
	out (LED_PORT), a

;	Set all RAM to zero.

	BLANKMEM 16384, 49152, 0

;	Start lower RAM 'walking bit' test

lowerram_walk

    WALKLOOP 16384,16384

;	Then the inversion test

lowerram_inversion

    ALTPATA 16384, 16384, 0
    ALTPATA 16384, 16384, 255
    ALTPATB 16384, 16384, 0
    ALTPATB 16384, 16384, 255

lowerram_march

	MARCHTEST 16384, 16384

;	Lastly the Random fill test

lowerram_random

    RANDFILLUP 16384, 8192, 11
    RANDFILLDOWN 32766, 8191, 17

;	This gives the opportunity to visually see what's happening in
;	lower memory in case there is a problem with it.
;	Conveniently, if there's some lower RAM, then this'll give us
;	a pattern to lock onto with the floating bus sync test.

    BLANKMEM 16384, 6144, 0

;	Attributes - white screen, blank ink.

	BLANKMEM 22528, 768, 56

; 	Restore machine stack, and clear screen

	ld sp, iy
	call CLEAR42
	
;	Check if lower ram tests passed

    ld a, ixh
    cp 0
    jp z, tests_done

;	Lower memory is no good, give up now.

	ld hl, str_16kfailed
	call PRINT42
	ld hl, str_failedbits
	call PRINT42
	
	ld c, ixh
	ld b, 0
	
fail_loop
	bit 0, c
	jr z, fail_next
	
	ld a, b
	add '0'
	push bc
	call PUTCHAR42
	ld a, ' '
	call PUTCHAR42
	pop bc
	
fail_next

	rr c
	inc b
	ld a, b
	cp 8
	jr nz, fail_loop
	
	ld a, '\n'
	call PUTCHAR42
	
	jp exit

tests_done
	
	ld hl, str_16kpassed
	call PRINT42
	
exit
	
	ld hl, str_pressanykey
	call PRINT42
	call GETKEY
	ret
	
initroutine

; 	First see if the user's pressing 'r' to initiate testing

	ld hl, str_press_r
	call PRINT42
	
	ld bc, 0xffff
	
press_r_loop

	push bc
	ld bc, 0xfbfe
	in a, (c)
	pop bc
	bit 4, a
	jr z, run_tests
	dec bc
	ld a, b
	or c
	jr nz, press_r_loop
	
;	R not pressed, exit and allow other ROMs to init

	ld hl, str_not_testing
	call PRINT42
	ret

run_tests

	call modulecall
	ret
	
;
;	Text strings
;

str_identity

	defb "ZX-Diagnostics ", VERSION, 0 
	
str_press_r

	defb "\nZX-Diagnostics: Press T to initiate tests\n", 0
	
str_not_testing

	defb "Not running tests.\n\n", 0
	
str_16kpassed

	defb "Lower/Page 5 RAM tests passed.\n", 0
	
str_16kfailed

	defb "Lower/Page 5 RAM tests failed!\n", 0
	
str_failedbits

	defb "Failed bit locations: ", 0
	
str_pressanykey

	defb "Press any key to continue.\n\n", 0
	
	BLOCK 0x2fff-$, 0xff
