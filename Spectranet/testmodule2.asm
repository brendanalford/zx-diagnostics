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
;	Spectrum Diagnostics - Spectranet ROM Module 2 of 2
;
;	v0.1 by Dylan 'Winston' Smith
;	v0.2 modifications and 128K testing by Brendan Alford.
;
;	Despite being the second module, this is actually the primary point of 
;	entry for the diagnostics - reason being that module 1 must have been 
;	loaded successfully before module 2 can access anything in it.
;	If we lead from the first module and start executing tests, we cannot
;	call anything in the second module via MODULECALL as it hasn't been
;	loaded yet!

	include "..\defines.asm"
	include "..\version.asm"
	include "spectranet.asm"

	LUA ALLPASS
	sj.insert_define("BUILD_TIMESTAMP", '"' .. os.date("%d/%m/%Y %H:%M:%S") .. '"');
	ENDLUA
	
	org 0x2000

;	Spectranet ROM Module table

	defb 0xAA			; Code module
	defb 0xBB			; ROM identity - needs to change
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
	
	
;
;	Paint RAM FAIL message. This routine is borrowed from the 
;	main diagnostics ROM.
;	

	ld hl, 0x5880
	ld de, 0x5881
	ld bc, 0x1ff
	ld (hl), 9
	ldir

	ld hl, fail_ram_bitmap
	ld de, 0x5880
	ld b, 0x40

fail_msg_loop

	ld c, 8
	ld a, (hl)

fail_msg_byte

	bit 7, a
	jr z, fail_msg_next

	ex de, hl
	ld (hl), 0x7f
	ex de, hl

fail_msg_next

	inc de
	rla
	dec c
	jr nz, fail_msg_byte

	inc hl
	dec b
	jr nz, fail_msg_loop
	
	
;	Blank out the working RAM digits

	ld hl, 0x5980
	ld c, ixh

	ld d, 8
	
fail_bits_outer_loop

	ld b, 8
	
fail_bits_loop

	bit 0, c
	jr nz, fail_bits_ok
	ld a, 8
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	jr fail_bits_next
	
fail_bits_ok

	inc hl
	inc hl
	inc hl
	inc hl
	
fail_bits_next

	rrc c
	djnz fail_bits_loop
	
	dec d
	ld a, d
	cp 0
	jr nz, fail_bits_outer_loop
	
;	Wait for a key, then exit.

	ld hl, str_pressanykey
	call PRINT42
	call GETKEY
	ret

tests_done
	
	ld hl, str_16kpassed
	call PRINT42
	ld hl, 0xBA00
	rst MODULECALL_NOPAGE
	
;	Not sure we should ever get back here - check the MODULECALL 
;	result just in case

	ret nc
	cp 0xff
	ret nz

;	Module 2 was not called successfully.

	ld hl, str_modulefail
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
	call test_cmd
	ret

run_tests

	call modulecall
	ret

;
;	Implementation of the '.test' command
;	
test_cmd

	ld hl, parsetable
	call ADDBASICEXT
	ret nc
	ld hl, str_cmd_fail
	call PRINT42
	ret
	
parsetable

	defb 0x0b
	defw test_cmd_string
	defb 0xff
	defw print_version
	
print_version

	call STATEMENT_END
	
	call CLEAR42
	ld hl, str_version
	call PRINT42

	jp EXIT_SUCCESS
	
test_cmd_string

	defb "%zxdiags", 0
	
fail_ram_bitmap

	defb %00000000, %00000000, %00000000, %00000000
	defb %01100010, %01010000, %11100100, %11101000
	defb %01010101, %01110000, %10001010, %01001000
	defb %01010101, %01110000, %11001010, %01001000
	defb %01100111, %01010000, %10001110, %01001000
	defb %01010101, %01010000, %10001010, %01001000
	defb %01010101, %01010000, %10001010, %11101110
	defb %00000000, %00000000, %00000000, %00000000
	
	defb %00000000, %00000000, %00000000, %00000000
	defb %01000100, %01001110, %00101110, %01101110
	defb %10101100, %10100010, %10101000, %10000010
	defb %10100100, %00100100, %10100100, %11000100
	defb %10100100, %01000010, %11100010, %10100100
	defb %10100100, %10001010, %00101010, %10101000
	defb %01001110, %11100100, %00100100, %01001000
	defb %00000000, %00000000, %00000000, %00000000	

;
;	Text strings
;

str_cmd_fail

	defb "Failed to add BASIC extension\n", 0
	
str_identity

	defb "ZX Diagnostics ", VERSION, " [2/2]", 0 
	
str_version

	defb "ZX Diagnostics ", VERSION, "  B. Alford, D. Smith\n"
	defb "Build: ", BUILD_TIMESTAMP, "\n"
	defb "http://github.io/vkf1o\n", 0
	
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
	
str_modulefail

	defb "FATAL: Error calling ROM module", 0
	
	
	BLOCK 0x2fff-$, 0xff
