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
;	testram.asm
;

;
; ZX Diagnostics ROM Checker Program
;
;	Checksums the ROM(s) and identifies the specific Spectrum model being used.
; If the checksums aren't recognized, prints them for user to note.
;

	define ULA_PORT		0xfe

	define BANK_M 		0x5b5c
	define BANK678		0x5b67
	define BORDCR			0x5c48
	define ATTR_P			0x5c8d
	define PROG				0x5c53
	define VARS				0X5c4b
	define E_LINE			0x5c59
	define WORKSP			0x5c61

	org 25000

start

	di
	ld a, (BANK_M)
	ld (v_bankm), a
	ld a, (BANK678)
	ld (v_bank678), a

	call initialize

; Loading BASIC sysvars here also to make sure screen colour changes persist
	ld a, 56
	ld (v_attr), a
	ld (BORDCR), a
	ld (ATTR_P), a
	call cls
	ld a, 7
	out (ULA_PORT), a

	ld hl, str_romcheckbanner
	call print_header

	ld hl, str_running_checksum
	call print

;	Start checksumming the ROMs. Use the main zx-diagnostics lookup table for this.

rom_test_1

; Checksum all 4 possible ROM's - even if we're on a 48K system.

	xor a
	ld (v_curpage), a
	ld hl, v_romchksum

rom_checksum_loop

	push hl
	ld hl, str_dot
	call print
	ld a, (v_curpage)
	call pagein_rom
 	call romcrc
	ld de, hl
	pop hl
	ld (hl), de
	inc hl
	inc hl
	ld a, (v_curpage)
	inc a
	ld (v_curpage), a
	cp 4
	jr nz, rom_checksum_loop
	xor a
	call pagein_rom

; v_romchksum now contains all 4 checksums.

	ld hl, str_checking
	call print

	ld ix, rom_signature_table
	ld hl, v_romchksum
	ld de, (hl)
	inc hl
	inc hl

; 	Check for a matching ROM.
;		DE holds the current ROM checksum, HL holds the pointer to
; 	the computed ROM checksum table, and IX holds the pointer
;		to the master ROM signature table.

rom_check_loop

;	Check for 0000 end marker

	ld bc, (ix)
	ld a, b
	or c
	jp z, rom_unknown

;	Check saved ROM CRC in DE against value in table

	ld a, d
	xor b
	jr nz, rom_check_next
	ld a, e
	xor c
	jr z, rom_check_found

rom_check_next

	ld bc, 8
	add ix, bc
	jr rom_check_loop

rom_check_found

;	Save the appropriate ROM type string pointer

	ld de, (ix + 2)
	ld (v_romtype), de

;	Skip the address of the testing routine (not used here)

	ld de, 6
	add ix, de

;	Check if additional ROMs need to be checked (128 machines)

	ld bc, (ix)
	ld a, b
	or c
	jr z, rom_test_pass

;	Repoint IX at the address of the specific ROM table

	ld ix, bc

additional_rom_check_loop

;	Grab the next computed checksum from pointer at HL

	ld de, (hl)

;	Check against the value at IX

;	ld bc, (ix)
;	di
;	halt

	ld a, (ix)
	cp e
	jr nz, additional_rom_fail
	ld a, (ix + 1)
	cp d
	jr nz, additional_rom_fail

;	This ROM passed, skip ROM fail string pointer
;	and increment computed checksum pointer too

	inc ix
	inc ix
	inc ix
	inc ix
	inc hl
	inc hl

;	Any more ROM checksums?

	ld b, (ix)
	ld a, (ix + 1)
	or b
	jr nz, additional_rom_check_loop

;	All passed, say so and continue with a call to the routine at v_test_rtn

	jr rom_test_pass

additional_rom_fail

	ld hl, str_rombroken
	call print
	ld hl, (v_romtype)
	call print_rom_type
	call newline
	call newline
	ld hl, str_contact
	call print
	call print_checksums
	jp exit


rom_unknown

	ld hl, str_romnotfound
	call print
	ld hl, str_contact
	call print
	call print_checksums
	jp exit

; Unknown ROM printout here

rom_test_pass

	ld hl, str_romdetected
	call print
	ld hl, (v_romtype)
	call print_rom_type
	jp exit

exit

	ld hl, str_completed
	call print

; Check if we're in 48K mode and paging's unlocked (DivMMC mode)

	bit 4, (iy+1)
	jr nz, exit_2

; We are in USR 0/DivMMC mode, force ROM 1/ROM3 mode (128 / +3 mode)
	ld hl, v_bankm
	set 4, (hl)
	ld hl, v_bank678
	set 2, (hl)

;	Restore paging registers from system variables

exit_2

	ld a, (v_bank678)
	ld bc, 0x1ffd
	out (c), a
	ld a, (v_bankm)
	ld bc, 0x7ffd
	out (c), a

;	Wipe out the BASIC program, 'cos we're tidy around here.

	ld hl, (PROG)
	ld (VARS), hl					; Set VARS = PROG
	ld (hl), 0x80					; Set vars end marker
	inc hl
	ld (E_LINE), hl				; Set edit line location

	ei
	ret

;
;	External dependencies.
;

;	Defines to keep romtables.asm happy.

	define test_48k 				0x0000
	define test_128k				0x0000
	define test_plus2 			0x0000
	define test_plus3 			0x0000
	define test_48kgeneric	0x0000

	include "vars.asm"
	include "..\version.asm"
	include "..\print.asm"
	include "..\charset.asm"
	include "..\scroll.asm"
	include "..\romtables.asm"
	include "..\crc16.asm"
	include "..\paging.asm"

;
;	The standard strings from romtables.asm include trailing dots and spaces.
; This routine takes such a string and truncates these, then prints the string.
;
print_rom_type

	push hl

print_rom_type_1

	inc hl
	ld a, (hl)
	cp 0
	jr nz, print_rom_type_1

print_rom_type_2

	dec hl
	ld a, (hl)
	cp TKN_ROM
	jr nz, print_rom_type_2

; Found the 'ROM...' token, null-terminate from there

	xor a
	ld (hl), a

	pop hl
	call print
	ret

print_checksums

	call newline
	ld ix, v_romchksum
	ld b, 4

print_checksum_loop

	push bc
	push ix
	ld hl, str_rom_no
	call print
	ld hl, str_rom_no+4
	inc (hl)
	ld hl, (ix)
	ld de, v_hexstr
	call Num2Hex
	xor a
	ld (v_hexstr+4), a
	ld hl, v_hexstr
	call print
	call newline
	pop ix
	inc ix
	inc ix
	pop bc
	djnz print_checksum_loop

	ret


initialize

	xor a
	ld hl, 0x5800
	ld de, 0x5801
	ld bc, 0x2ff
	ld (hl), a
	ldir
	ld hl, 0x4000
	ld de, 0x4001
	ld bc, 0x17ff
	ld (hl), a
	ldir
	out (ULA_PORT), a

	xor a

	ld (v_column), a
  ld (v_row), a
	ld (v_pr_ops), a
	ld (v_curpage), a
	ld a, 56
	ld (v_attr), a
	ld a, 2
	ld (v_scroll), a
	ld a, 21
	ld (v_scroll_lines), a

	ld a, 6
	ld (v_width), a
	ld a, 0xff
	ld (v_scroll), a
	cpl
	ld (v_scroll_lines), a


	ld b, 5
	xor a
	ld hl, v_hexstr

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

	ret

;
;	Dummy routine to keep crc16.asm happy
;
sys_rompaging

	ret

str_romcheckbanner

	defb TEXTBOLD, "ZX Diagnostics ROM Checker", TEXTNORM, 0

str_running_checksum

	defb AT, 2, 0, "Running ROM checksum", 0

str_dot

	defb ".", 0

str_checking

	defb AT, 4, 0, "Checking...", 0

str_romnotfound

	defb AT, 6, 0, "The ROM checksum(s) are unrecognized.\n", 0

str_rombroken

	defb AT, 6, 0, "The ROM was recognized but seems corrupt:\n", 0

str_contact

	defb "Please contact Brendan Alford\n(brendanalford@eircom.net) with the ROM\n"
	defb "checksums detailed below, along with a\n"
	defb "description of your hardware.\n", 0

str_romdetected

	defb AT, 6, 0, "ROM type detected:\n", 0

str_rom_no

	defb "ROM 0: ", 0

str_completed

	defb "\n\nTesting complete.", 0

	BLOCK (32768+5000)-$, 0x00
