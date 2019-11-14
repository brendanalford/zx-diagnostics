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
;	flashutil.asm
;

	org 0xE000

	include "vars.asm"

	define ULA_PORT       0xfe
	define ROMPAGE_PORT   31

start

; 	We're paging roms in and out at random

	di

; 	Quick check to see if user has lowered SP below 32768 as requested

	ld hl, 0
	add hl, sp
	ld a, h
	cp 0x80

	jr c, start_2

;	Nope, Print a message and generate
;	M RAMTOP no good error

	xor a
	out (ROMPAGE_PORT), a   ; page in Speccy ROM

	ld hl, str_bad_ramtop
	call print_rom

	ei

	rst 0x08
	defb 0x15

start_2

;	Set up the system variables

     	ld a, 56        ; Black text on white paper
     	ld (v_attr), a
	ld a, 6
	ld (v_width), a

      	xor a
      	ld (v_column), a
      	ld (v_row), a

      	ld (v_pr_ops), a
      	ld (v_printbuf), a
	ld hl, v_printbuf
	ld de, v_printbuf + 1
	ld bc, 6
	ldir

	ld a, 0x2
	ld (v_scroll), a
	ld a, 0x15
	ld (v_scrl_lines), a


	ld a, 2
	ld (v_scroll), a
	ld a, 21
	ld (v_scrl_lines), a

;	Main Menu screen

main_menu

 	ld a, 7           ; White border
 	out (ULA_PORT), a

	call cls

	    ld hl, str_banner
      	call print_header

      	ld hl, str_run
      	call print

      	ld hl, str_p1
      	call print
      	ld hl, str_others
      	call print

      	ld hl, str_mfrdevice
      	call print

      	call F_FlashReadId
      	call map_device_id
      	jr nc, flash_not_identified

      	ld l, (ix+2)
      	ld h, (ix+3)
      	call print

      	jr get_option

flash_not_identified

      	push hl
      	ld hl, chip_unknown
      	call print
      	pop hl
      	ld de, v_printbuf
      	call Num2Hex
      	ld hl, v_printbuf
      	call print
	ld hl, chip_unknown2
	call print

;	Wait for a user selection

get_option
	call beep
    call get_key

	cp " "
	jr z, return_to_basic
	cp 0x13
	jr z, options_menu
	cp "W"
	jr nc, get_option

	call is_alphanumeric
	jr nc, get_option

; 	If we get here we've selected a ROM to boot

	call map_key_to_page

  or 32          	; bit 5 = /ROMCS line - bit 5 should be high
                 	; to assert it with the jumper in 'SPECTRUM' pos
  out (ROMPAGE_PORT), a
  jp 0

;
;	The options menu.
;
options_menu

	call cls
	ld hl, str_options_menu
	call print_header
	ld hl, str_options
	call print

options_1
	call beep
	call get_key

		cp "P"
      	jp z, program_page
      	cp "X"
      	jp z, erase_sector
      	cp "C"
      	jp z, copy_page
      	cp "L"
      	jr z, tape_load
		cp " "
		jp z, main_menu
		jp options_1

;
;	Pages out diagnostic ROM and returns control to BASIC ROM
;

return_to_basic

    ld a, (0x5c48)
	and 0x38
	rrca
	rrca
	rrca
	out (0xfe), a

	ld a, (0x5c8d)
	ld (v_attr), a

      	call cls
     	xor a
     	out (ROMPAGE_PORT), a   ; page in Speccy ROM
     	ei
     	ret

;
;	Loads a CODE block of 16K into memory at 32768
;
tape_load

	call cls
	ld hl, str_tapehdr
	call print_header
	ld hl, str_loadmsg
	call print

	xor a
	out (ROMPAGE_PORT), a   ; page in Speccy ROM

	ld hl, .tapeerror

.tapeloop

	xor a
	scf
	ld ix, v_tapehdr
	ld de, 17
	call load_bytes
	call check_break
	ld a, d
	or e
	jr nz, .tapeloop

;	Check header type

	ld a, (v_tapehdr)
	cp 3
	jr z, .tapeloop1

	ld hl, str_headertype
	call print
	call .fixtapename
	call print
	ld a, 56
	ld (v_attr), a
	call newline
	jr .tapeloop

.tapeloop1

;	Check block length

	ld a, (v_tapehdr+0xd)
	cp 0
	jr nz, .tapelength
	ld a, (v_tapehdr+0xc)
	cp 0x40
	jr z, .tapeloop2

.tapelength
	ld  hl, str_headerlength
	call print
	call .fixtapename
	call print
	ld a, 56
	ld (v_attr), a
	call newline
	jr .tapeloop

.tapeloop2

	ld hl, str_headerok
	call print
	call .fixtapename
	call print
	ld a, 56
	ld (v_attr), a
	call newline

	scf
	ld a, 255
	ld ix, 0x8000
	ld de, 0x4000
	call load_bytes
	call check_break
	ld a, d
	or e
	jr nz, .tapeerror

	ld hl, str_loadok
	ld a, 7
	out (ULA_PORT), a
	call print
	ld hl, str_anykey
	call print
	call get_key

	jp main_menu

.tapeerror

	ld a, 7
	out (ULA_PORT), a
	ld hl, str_tapeerror
	call print
	ld hl, str_anykey
	call print
	call get_key
	jp main_menu

.fixtapename

	ld hl, v_tapehdr+1
	ld a, (hl)
	cp 0xff
	jr nz, .tapenamepresent
	xor a
	ret

.tapenamepresent

	xor a
	ld (v_tapehdr+0x0b), a
	ret

check_break

	ld a, 0x7f
	in a, (0xfe)
	rra
	ret c
	pop hl
	jp main_menu

;
;	Does some initial setup and then calls the ROM routine LD-BYTES past the point
;	where it sets SA/LD-RET as the return, allowing us to trap BREAK pressed properly.
;
load_bytes

	inc d
	ex af, af'
	dec d
	di
	ld a, 0x0f
	out (ULA_PORT), a

	; Jump to point in ROM past the change of return address
	jp 0x0562

;
;	Programs a flash page.
;
program_page

; 	Display banner and page selection options.

      	call cls
      	ld hl, str_proghdr
      	call print_header

	ld hl, str_progopt
	call print
      	ld hl, str_p1
      	call print
      	ld hl, str_back
      	call print

;	Wait for the user to pick a page or option.

.progpage_getpage
	call beep
      	call get_key

;	Did the user want to exit?
	cp "Z"
	jp z, main_menu

	call is_alphanumeric
	jr nc, .progpage_getpage

	call map_key_to_page

; 	Now try to program the page - first do some checks

     	or 32       ; set /ROMCS flag
      	out (ROMPAGE_PORT), a
      	ld (v_page), a    ; save the flash page number

;	Check first byte of page (NOTE: Check first 256 bytes?)

      	ld a, (0)
      	cp #ff      ; unused flash memory is set to all 1s
      	jr nz, program_page_in_use

;	Page is blank, say we're writing and continue

      	ld hl, str_writing
      	call print

program_page_program

;	Writing 16384 bytes from 32768 to the flash

	ld hl, 0x8000
      	ld de, 0
      	ld bc, 16384

program_page_loop

;	Grab a byte at a time and send to the flash program routing

     	ld a, (hl)
      	call F_FlashWriteByte

;	Carry flag set means an error occurred

  	jr c, .progpage.borked
      	inc hl
      	inc de
      	dec bc
      	ld a, b
      	or c
      	jr nz, program_page_loop

;	All done

	ld hl, str_done
	call print
     	ld hl, str_anykey
      	call print
      	call get_key
      	jp main_menu

.progpage.borked

;	A failure occurred during writing. Say so, wait for a
;	keypress, and go back to main menu.

     	ld hl, str_borked
      	call print
      	ld hl, str_anykey
      	call print
      	call get_key
      	jp main_menu

program_page_in_use

;	The page appeared to be in use, first byte was not 0xff.
;	Ask the user what they want to do.

     	ld hl, str_inuse
      	call print
      	call get_key
      	cp "Y"
      	jp nz, program_page

;	User doesn't seem to care. Try programming anyway.

      	ld hl, str_prog_anyway
	call print
	jr program_page_program

;
;	Erases a sector of flash memory.
;
erase_sector

;	Display erase menu and options.

      	call cls
      	ld hl, str_erasehdr
      	call print_header
      	ld hl, str_chooseerase
      	call print

.repoll
      	call beep
      	call get_key

;	User can hit X to return to the main menu.

      	cp "X"
      	jp z, main_menu

     	call map_key_to_page

;	Return for more input if 0-7 wasn't pressed.

      	cp 8
      	jp p, .repoll

;	Warn if the user's trying to overwrite sector
;	1 (pages 4-7), page 4 contains this flash utility.

      	cp 1
      	jr z, .yourekillingme

.doerase

;	Go ahead and erase the chosen sector

     	ld hl, str_erasing
      	call print
      	call F_FlashEraseSector

;	Carry flag set indicates failure

      	jr c, .eraseborked

.erasedone

;	All done, say so, wait for a key, then return to main
;	menu.

      	ld hl, str_done
      	call print
      	ld hl, str_anykey
      	call print
      	call get_key
      	jp main_menu

.eraseborked

;	An error occurred, say so, wait for a key then main menu.

      	ld hl, str_borked
      	call print
      	ld hl, str_anykey
      	call print
      	call get_key
      	jp main_menu

.yourekillingme

;	User's trying to kill the sector containing
;	the flash utility. Warn them first and give
;	them options

      	push af     ; save intended sector
      	call cls

      	ld hl, str_delp4_hdr
      	call print_header

      	ld hl, str_delp4
      	call print

;	Emit a long beep
	ld b, 10
.killbeep
	call beep
	djnz .killbeep

      	call get_key

;	Y = keep me

      	cp "Y"
      	jr z, .keep

;	N = kill off this sector

      	cp "N"
      	jr z, .killme

; 	any other key = abort

      	pop af
      	jp erase_sector

.killme

;	Jump back and erase the chosen sector

     	pop af
      	jr .doerase

.keep

;	User wants to keep the flash utility, so erase
;	and reprogram.

;	Page in the existing utility from page 4first

     	ld a, #24   ; bit 5 set + page 4
      	out (ROMPAGE_PORT), a

;	Copy it to RAM at 32768

      	ld hl, 0
      	ld de, 32768
      	ld bc, 16384
      	ldir

;	Start erasing the sector

      	ld hl, str_erasing
      	call print
      	pop af
      	call F_FlashEraseSector

;	Oops, something went wrong, warn the user

      	jr c, .eraseborked

;	Erased, now reprogram to page 4

      	ld hl, str_reprogramming
      	call print
      	ld a, #24   ; page 4 with bit 5 set for /romcs
      	ld (v_page), a

;	Set up parameters and jump straight into the programming loop

      	ld hl, 32768
      	ld de, 0
      	ld bc, 16384
      	jp program_page_loop

;
;	Copies a given flash page to RAM
;
copy_page

;	Print the copy menu and wait for a selection

	call cls
     	ld hl, str_copyhdr_banner
     	call print_header
     	ld hl, str_copyhdr
     	call print

	ld hl, str_p1
	call print
      	ld hl, str_back
      	call print

.copypage_getpage
      	call beep
      	call get_key

      	cp "Z"
      	jp z, main_menu
      	call is_alphanumeric
      	jr nc, .copypage_getpage

	call map_key_to_page

; 	Page number now in A

	or 32       ; set /ROMCS bit
	out (ROMPAGE_PORT), a

;	Paged in, copy the contents

	ld hl, str_copying
     	call print
      	ld hl, 0
      	ld de, 32768
      	ld bc, 16384
      	ldir

 ; Page copied, say so, wait for a key, then back to main menu

      	ld hl, str_done
      	call print
      	ld hl, str_anykey
      	call print
      	call get_key
      	jp main_menu

F_FlashReadId
;
;	Read manufacturer id/device id from Flash.
;	Returns H = Mfr ID, L = Device ID.
;

	push af
	ld a, 32
	out (ROMPAGE_PORT), a

;	Initiate autoselect command sequence

	ld a, 0xaa
	ld (0x555), a
	ld a, 0x55
	ld (0x2aa), a
	ld a, 0x90
	ld (0x555), a

;	Read Manufacturer ID

	ld a, (0x0)
	ld h, a

;	Read Device ID

	ld a, (0x1)
	ld l,a

;	Issue reset command to exit autoselect mode

	ld a, 0xf0
	ld (0x00), a

	pop af
	ret

;
; 	EraseSector subroutine erases a 64K Flash ROM sector. It's designed
; 	for 4 megabit chips like the Am29F040.
; 	This function will page in the sector and erase it.
; 	Pass the page in A
; 	On error, carry flag set.
;
F_FlashEraseSector

	push AF

; 	select page 0

	ld a, 32
	out (ROMPAGE_PORT), A

	ld a, #AA	; unlock code 1
	ld (#555), a	; unlock addr 1
	ld a, #55	; unlock code 2
	ld (#2AA), a	; unlock addr 2
	ld a, #80	; erase cmd 1
	ld (#555), a	; erase cmd addr 1
	ld a, #AA	; erase cmd 2
	ld (#555), a	; erase cmd addr 2
	ld a, #55	; erase cmd 3
	ld (#2AA), a	; erase cmd addr 3

; 	Select sector to erase
	pop af

; 	Multiply by 4 and set /ROMCS high

      	rla
      	rla
      	or 32
      	out (ROMPAGE_PORT), A

	ld a, #30	; erase cmd 4
	ld (0), a	; erase sector address is set by flip-flop, just use addr 0

	ld hl, #0

EraseSector.wait

	bit 7, (hl)	; test DQ7 - should be 1 when complete
	jr nz, EraseSector.complete
	bit 5, (hl)	; test DQ5 - should be 1 to continue
	jr z, EraseSector.wait
	bit 7, (hl)	; test DQ7 again
	jr z, EraseSector.borked

EraseSector.complete

	or 0		; clear carry flag
	ret

EraseSector.borked

	scf		; carry flag = error
	ret


;
; 	Writebyte: A = byte to write, DE = address to write
; 	This code was taken from my ALIAC-2 single board computer flash burner
; 	since this is pretty well tested, and just tweaked for Speccy use.
; 	This is designed for the Am29F040B flash chip, but should work with
; 	anything that's JEDEC standard
;
F_FlashWriteByte

     	push bc
      	ld c, a     ; save byte to write

; 	Try to program the requested page

      	ld a, 32    ; page 0 to write unlock code
      	out (ROMPAGE_PORT), a

; 	Tell the flash chip we are writing a byte to it.

      	ld a, #aa
      	ld (#555), a
      	ld a, #55
      	ld (#2AA), a
      	ld a, #a0
      	ld (#555), a

; 	page in the page we're actually writing

     	ld a, (v_page)
     	out (ROMPAGE_PORT), a

      	ld a, c     ; get the byte back
      	ld (de), a  ; write it

WriteData.wait

	ld a, (de)	; read programmed address
	ld b, a		; save status
	xor c
	bit 7, a	; If bit 7 = 0 then bit 7 = data
	jr z, writeData.byteComplete

	bit 5, b	; test DQ5
	jr z, WriteData.wait

	ld a, (de)	; read programmed address
	xor c
	bit 7, a	; Does DQ7 = programmed data? 0 if true
	jr nz, writeData.borked

writeData.byteComplete

;	Byte written succesfully

	pop bc
	or 0		; clear carry flag
	ret

writeData.borked

;	Something went wrong when writing the byte

	pop bc
	scf		; error = set carry flag
	ret

;
;	Emits a short beep.
;	Assumes a white border
;
beep
	push hl
	push de
	push bc

	ld a, 7
	ld l, a
	ld de, 0x50

.tone.duration

	ld bc, 0x20			; bc = twice tone freq in Hz

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
	pop de
	pop hl
	ret

;
;	Checks if the given ASCII value in A is alphanumeric
;	Carry flag set if true, reset otherwise.
;
is_alphanumeric
	cp '0'
	jr c, not_alphanum
	cp 'Z'
	jr nc, not_alphanum

	cp '9' + 1
	jr c, is_alpha
	cp 'A'
	jr nc, is_alpha
not_alphanum
	and a
	ret
is_alpha
	scf
	ret

;
;	Translates a pressed key to a page number
;
map_key_to_page

	sub '0'
	cp 0x10
	ret c
	sub 7
	ret


;
;	Maps the given device id to an information block describing
;	the flash capabilities.
;	Input: Device/Mfr ID in HL
;	Output: Info block in IX, carry set if found
;		Carry reset if no match
;
map_device_id
	ld ix, map_info_table
map_dev_loop
	ld a, (ix)
	cp h
	jr nz, map_dev_next
	ld a, (ix+1)
	cp l
	jr nz, map_dev_next

;	Found match, return with current value of ix

	scf
	ret

map_dev_next
	ld de, 6
	add ix, de
	ld a, (ix)
	ld b, (ix+1)
	or a
	jr nz, map_dev_loop

;	Not found a match
	and a
	ret

;
;	Chip string table
;
chip_amic_a29040b
	defb "AMIC A29040B", 0

chip_amd_am29f040b
	defb "AMD AM29F040B", 0

chip_amd_am29f040
	defb "AMD AM29F040", 0
	
;
;	Map info table - each entry is six bytes long
;	Bytes 0-1: Mfr Id/Device ID
;	Bytes 2-3: Pointer to device type string
;	Byte 4: Number of 16K pages supported by this device
;	Byte 5: Sector size in KB
;
map_info_table

;	AMIC A29040B - 32 pages, 64K sectors

	defb 0x37, 0x86
	defw chip_amic_a29040b
	defb 32, 64

;	AMD AM29F040B - 32 pages, 64K sectors

	defb 0xc2, 0xa4
	defw chip_amd_am29f040b
	defb 32,64

;	AMD AM29F040 - 32 pages, 64K sectors

	defb 0x01, 0xa4
	defw chip_amd_am29f040
	defb 32,64
	
;	Table end

	defb 0x00, 0x00, 0x00, 0x00, 0x00 ,0x00



	include "../version.asm"
     	include "../charset.asm"
 	include "../print.asm"
 	include "../scroll.asm"
	include "../input.asm"

chip_unknown
	defb "Unknown (", 0
chip_unknown2
	defb ")",0

str_bad_ramtop

	defb 0x0d, "Please set RAMTOP to 32767 or ", 0x0d
	defb "lower to use this utility, e.g.", 0x0d, 0x0d
	defb "CLEAR 32767", 0

str_banner

	defb TEXTBOLD, "Diagnostic Board Flash Utility", TEXTNORM, 0

str_run
  	defb  AT, 2, 0, "Select ROM page to boot:", 0

str_p1
	defb AT, 4, 0, "0: Page 0", TAB, 90, "1: Page 1", TAB, 180, "2: Page 2\n"
str_p2
	defb "3: Page 3", TAB, 90, "4: Page 4", TAB, 180, "5: Page 5\n"
str_p3
	defb "6: Page 6", TAB, 90, "7: Page 7", TAB, 180, "8: Page 8\n"
str_p4
	defb "9: Page 9", TAB, 90, "a: Page 10", TAB, 180, "b: Page 11\n"
str_p5
	defb "c: Page 12", TAB, 90, "d: Page 13", TAB, 180, "e: Page 14\n"
str_p6
	defb "f: Page 15", TAB, 90, "g: Page 16", TAB, 180, "h: Page 17\n"
str_p7
	defb "i: Page 18", TAB, 90, "j: Page 19", TAB, 180, "k: Page 20\n"
str_p8
	defb "l: Page 21", TAB, 90, "m: Page 22", TAB, 180, "n: Page 23\n"
str_p9
	defb "o: Page 24", TAB, 90, "p: Page 25", TAB, 180, "q: Page 26\n"
str_p10
	defb "r: Page 27", TAB, 90, "s: Page 28", TAB, 180, "t: Page 29\n"
str_p11
	defb "u: Page 30", TAB, 90, "v: Page 31\n\n",0

str_others
	defb "Press ", TEXTBOLD, INK, 2,"ENTER ", TEXTNORM, INK, 0, "for Other Options menu\n\n"
	defb "Press ", TEXTBOLD, INK, 2,"SPACE ", TEXTNORM, INK, 0, "to exit to ZX Basic",0

str_options_menu

	defb TEXTBOLD, "Other Options", TEXTNORM, 0

str_options
	defb AT, 2, 0, "Select option:\n\n"
	defb "P: Program a 16K flash page\n"
	defb "X: Erase a 64K flash sector\n"
	defb "C: Copy 16K page to RAM at 32768\n"
	defb "L: Load a 16K image from tape to\n"
	defb "   RAM at 32768\n\n"
	defb "Press ", TEXTBOLD, INK, 2, "SPACE ", TEXTNORM, INK, 0, "to return to main menu", 0

str_mfrdevice

	defb AT, 23, 0, "Flash type: ", 0

str_proghdr

	defb TEXTBOLD, "Program 16K Flash Page", TEXTNORM, 0

str_progopt

	defb AT, 2, 0, "Select a page to program:\n", 0

str_writing

	defb "Writing image to flash chip...\n", 0

str_copyhdr_banner

	defb TEXTBOLD, "Copy 16K Page to RAM", TEXTNORM, 0

str_copyhdr

  	defb AT, 2, 0, "Select a page to copy:\n", 0

str_copying

	defb "Copying page to address 32768..\n", 0

str_borked

	defb "Sorry, the operation failed.\n", 0

str_done

	defb "Done!\n", 0

str_back
	defb "Press ", TEXTBOLD, INK, 2, "Z ", TEXTNORM, INK, 0,"to go back\n", 0

str_anykey

	defb "Press any key to exit", 0

str_erasehdr

	defb TEXTBOLD, "Erase 64K Flash Sector", TEXTNORM, 0

str_chooseerase
	defb AT, 2, 0, "Press ", TEXTBOLD, INK, 2, "0 ", TEXTNORM, INK, 0,"to "
	defb TEXTBOLD, INK, 2, "7 ", TEXTNORM, INK, 0, "to choose the sector to \n"
	defb "erase, or ", TEXTBOLD, INK, 2, "X ", TEXTNORM, INK, 0, "to exit."

str_eraseinfo  defb AT, 5, 0, "Sectors map to pages as follows:"
str_sectors defb AT, 7, 0, "Sector 0  ->  Pages  0 to 3\n"
       	defb  "Sector 1  ->  Pages  4 to 7\n"
        defb  "Sector 2  ->  Pages  8 to 11\n"
        defb  "Sector 3  ->  Pages 12 to 15\n"
        defb  "Sector 4  ->  Pages 16 to 19\n"
        defb  "Sector 5  ->  Pages 20 to 23\n"
        defb  "Sector 6  ->  Pages 24 to 27\n"
        defb  "Sector 7  ->  Pages 28 to 31\n\n", 0

str_erasing
	defb "Erasing...\n", 0

str_reprogramming
	defb "Reprogramming utility to page 4\n", 0

str_delp4_hdr

	defb TEXTBOLD, "*** WARNING *** WARNING ***", TEXTNORM, 0

str_delp4

	defb AT, 2,0, TEXTBOLD, "ERASING SECTOR 1 (PAGES 4 -> 7)\n\n", TEXTNORM
        defb "You will delete me by deleting sector 1\n"
        defb "since I live in page 4.\n\n"
        defb "Press ", TEXTBOLD, INK, 2, "Y "
        defb TEXTNORM, INK, 0,"if you want to re-write the\n"
        defb "utility back into page 4.\n\n"
        defb "Press ", TEXTBOLD, INK, 2, "N "
        defb TEXTNORM, INK, 0,"if you want to kill off the flash\n"
        defb "utility.\n\n"
        defb "Any other key aborts.\n\n", 0

str_warning
	defb "WARNING!\n\n", 0

str_unused
	defb "This flash page seems to be\n"
  	defb "unused... are you really\n"
        defb "sure you want to select it? (Y/N)\n\n", 0

str_prog_anyway
	defb "Well, OK...here goes nothing...\n",0

str_inuse
	defb "This flash page seems used.\n"
        defb "Continue anyway? (Y/N)\n", 0

str_tapehdr
	defb TEXTBOLD, "Load ROM Image from Tape", TEXTNORM, 0

str_loadmsg

	defb AT, 2, 0, "Insert tape and press play.\n"
	defb "Press ", TEXTBOLD, INK, 2, "SPACE/BREAK ", TEXTNORM, INK, 0,"to abort.\n\n", 0

str_headerok

	defb "Loading image: ", 0

str_headerlength

	defb "Ignoring, wrong length: ", 0

str_headertype

	defb "Ignoring, wrong type: ", 0

str_tapeerror

	defb "Tape loading error!\n",0

str_loadok

	defb "\nImage loaded successfully.\n",0
