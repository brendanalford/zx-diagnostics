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
	di                ; we're paging roms in and out at random
 	ld a, 7           ; White border
 	out (ULA_PORT), a

;	Set up the system variables

     	ld a, 56        ; Black text on white paper
     	ld (v_attr), a
      	call cls

      	xor a
      	ld (v_column), a
      	ld (v_row), a
      	ld (v_bold), a
      
;	Main Menu screen

	ld hl, str_banner
      	call print
      	ld hl, str_run
      	call print

      	ld hl, str_p1
      	call print
      	ld hl, str_others
      	call print

;	Wait for a user selection

get_option	
      	call get_key
      
	cp "W"
      	jp z, .progpage
      	cp "X"
      	jp z, .erasesector
      	cp "Y"
      	jp z, .copypage
      	cp "Z"
      	jr z, .reset

;	Was this a ROM selection keypress?
     
     	cp "0"
     	jr nc, get_option
      
; 	If we get here we've selected a ROM to boot
      	or 32          	; bit 5 = /ROMCS line - bit 5 should be high
                     	; to assert it with the jumper in 'SPECTRUM' pos
      	out (ROMPAGE_PORT), a
      	jp 0

;
;	Pages out diagnostic ROM and returns control to BASIC ROM
;
.reset
      
      xor a
      out (ROMPAGE_PORT), a   ; page in Speccy ROM
      ei
      ret

;
;	Programs a flash page.
;
.progpage

; 	Display banner and page selection options.

      	call cls
      	ld hl, str_banner
      	call print

      	ld hl, str_prog
      	call print
	ld hl, str_progopt 
	call print
      	ld hl, str_p1
      	call print
      	ld hl, str_back
      	call print
      	
;	Wait for the user to pick a page or option.

      	call get_key

;	Did the user want to exit?
	cp "Z"
	jp z, start	

; 	Now try to program the page - first do some checks
     	or 32       ; set /ROMCS flag
      	out (ROMPAGE_PORT), a
      	ld (v_page), a    ; save the flash page number

;	Check first byte of page (NOTE: Check first 256 bytes?)

      	ld a, (0)
      	cp #ff      ; unused flash memory is set to all 1s
      	jr nz, .progpage.inuse

;	Page is blank, say we're writing and continue

      	ld hl, str_writing
      	call print

.progpage.program

;	Writing 16384 bytes from 32768 to the flash
	
	ld hl, 0x8000
      	ld de, 0
      	ld bc, 16384

.progpage.loop

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
      	jr nz, .progpage.loop

;	All done

	ld hl, str_done
	call print
     	ld hl, str_anykey
      	call print
      	call get_key
      	jp start

.progpage.borked

;	A failure occurred during writing. Say so, wait for a 
;	keypress, and go back to main menu.

     	ld hl, str_borked
      	call print
      	ld hl, str_anykey
      	call print
      	call get_key
      	jp start

.progpage.inuse

;	The page appeared to be in use, first byte was not 0xff.
;	Ask the user what they want to do.

     	ld hl, str_inuse
      	call print
      	call get_key
      	cp "Y"    
      	jp nz, .progpage

;	User doesn't seem to care. Try programming anyway.

      	ld hl, str_prog_anyway
	call print
	jr .progpage.program

;
;	Erases a sector of flash memory.
;
.erasesector

;	Display erase menu and options.
      
      	call cls
      	ld hl, str_erasehdr
      	call print
      	ld hl, str_chooseerase
      	call print
.repoll
      
      	call get_key

;	User can hit X to return to the main menu.

      	cp "X"    
      	jp z, start
      
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
      	jp start

.eraseborked

;	An error occurred, say so, wait for a key then main menu.
      
      	ld hl, str_borked
      	call print
      	ld hl, str_anykey
      	call print
      	call get_key
      	jp start

.yourekillingme

;	User's trying to kill the sector containing 
;	the flash utility. Warn them first and give
;	them options

      	push af     ; save intended sector
      	call cls
      	ld hl, str_delp4
      	call print
      	call get_key
      	
;	Y = keep me
      	
      	cp "Y"      
      	jr z, .keep

;	N = kill off this sector
      	
      	cp "N"       
      	jr z, .killme
      
; 	any other key = abort
      	
      	pop af
      	jp .erasesector

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
      	jp .progpage.loop

;
;	Copies a given flash page to RAM
;
.copypage

;	Print the copy menu and wait for a selection

	call cls
     	ld hl, str_copyhdr
     	call print
	ld hl, str_p1
	call print
      	ld hl, str_back
      	call print
      
      	call get_key

      	cp "Z"      
      	jp z, start
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
      	jp start

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
;	Translates a pressed key to a page number
;

map_key_to_page
	
	sub '0'
	cp '9'
	ret c
	sub 9
	ret
	
     	include "../charset.asm"
 	include "../print.asm"
	include "input.asm"

str_banner
	defb	AT, 0, 0, PAPER, 0, INK, 7, BRIGHT, 1, TEXTBOLD, " Diag Board Flash Utility "
	defb	TEXTNORM, PAPER, 0, INK, 2, "~", PAPER, 2, INK, 6, "~", PAPER, 6, INK, 4, "~"
	defb	PAPER, 4, INK, 5, "~", PAPER, 5, INK, 0, "~", PAPER, 0," ", ATTR, 56, 0

str_run
  	defb  AT, 2, 0, "Select ROM page to boot:", 0

str_p1
	defb AT, 4, 0, "0:Page 0   1:Page 1   2:Page 2\n"
str_p2   
	defb "3:Page 3   4:Page 4   5:Page 5\n"
str_p3   
	defb "6:Page 6   7:Page 7   8:Page 8\n"
str_p4 
	defb "9:Page 9   a:Page 10  b:Page 11\n"
str_p5   
	defb "c:Page 12  d:Page 13  e:Page 14\n"
str_p6   
	defb "f:Page 15  g:Page 16  h:Page 17\n"
str_p7   
	defb "i:Page 18  j:Page 19  k:Page 20\n"
str_p8   
	defb "l:Page 21  m:Page 22  n:Page 23\n"
str_p9   
	defb "o:Page 24  p:Page 25  q:Page 26\n"
str_p10  
	defb "r:Page 27  s:Page 28  t:Page 29\n"
str_p11  
	defb "u:Page 30  v:Page 31\n\n",0

str_others  
	defb "Other options:\n"

str_burn 
	defb "w:Program a 16K flash page\n"
str_erase   
	defb "x:Erase a 64K flash sector\n"
str_copy    
	defb "y:Copy 16K page to RAM at 32768\n"
str_reboot  
	defb "z:Exit to ZX BASIC\n", 0

str_prog
 	defb	AT, 0, 0, PAPER, 0, INK, 7, BRIGHT, 1, TEXTBOLD, " Program 16K Flash Page   "
 	defb	TEXTNORM, PAPER, 0, INK, 2, "~", PAPER, 2, INK, 6, "~", PAPER, 6, INK, 4, "~"
 	defb	PAPER, 4, INK, 5, "~", PAPER, 5, INK, 0, "~", PAPER, 0," ", ATTR, 56, 0


str_progopt 
	defb AT, 2, 0, "Select a page to program:\n", 0

str_writing 
	defb "Writing flash chip...\n", 0

str_copyhdr

  	defb	AT, 0, 0, PAPER, 0, INK, 7, BRIGHT, 1, TEXTBOLD, " Copy 16K Page to RAM     "
  	defb	TEXTNORM, PAPER, 0, INK, 2, "~", PAPER, 2, INK, 6, "~", PAPER, 6, INK, 4, "~"
  	defb	PAPER, 4, INK, 5, "~", PAPER, 5, INK, 0, "~", PAPER, 0," ", ATTR, 56
  	defb AT, 2, 0, "Select a page to copy:\n", 0

str_copying 
	defb "Copying page to address 32768..\n", 0

str_borked  
	defb "Sorry, the operation failed.\n", 0
str_done    
	defb "Done!\n", 0

str_back    
	defb "Press ", TEXTBOLD, BRIGHT, 1, "Z", TEXTNORM, BRIGHT, 0," to go back\n", 0

str_anykey  
	defb "Press ", TEXTBOLD, BRIGHT, 1, "0-9", TEXTNORM, BRIGHT, 0
	defb " or ", TEXTBOLD, BRIGHT, 1, "A-Z", TEXTNORM, BRIGHT, 0," to exit", 0

str_erasehdr
	defb	AT, 0, 0, PAPER, 0, INK, 7, BRIGHT, 1, TEXTBOLD, " Erase 64K Flash Sector   "
 	defb	TEXTNORM, PAPER, 0, INK, 2, "~", PAPER, 2, INK, 6, "~", PAPER, 6, INK, 4, "~"
  	defb	PAPER, 4, INK, 5, "~", PAPER, 5, INK, 0, "~", PAPER, 0," ", ATTR, 56, 0

str_chooseerase   
	defb AT, 2, 0, "Press ", TEXTBOLD, BRIGHT, 1, "0", TEXTNORM, BRIGHT, 0," to "
	defb TEXTBOLD, BRIGHT, 1, "7", TEXTNORM, BRIGHT, 0, " to choose the\n" 
	defb "sector to erase, or ", TEXTBOLD, BRIGHT, 1, "X"
	defb TEXTNORM, BRIGHT, 0, " to exit."
	
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

str_delp4
 	defb	AT, 0, 0, PAPER, 0, INK, 7, BRIGHT, 1, TEXTBOLD, " *** WARNING ***          "
  	defb	TEXTNORM, PAPER, 0, INK, 2, "~", PAPER, 2, INK, 6, "~", PAPER, 6, INK, 4, "~"
  	defb	PAPER, 4, INK, 5, "~", PAPER, 5, INK, 0, "~", PAPER, 0," ", ATTR, 56
  
	defb AT, 2,0, "ERASING SECTOR 1 (PAGES 4 -> 7)\n\n"
        defb "You will delete me by deleting\n"
        defb "sector 1 since I live in page 4.\n"
        defb "Press ", TEXTBOLD, BRIGHT, 1, "Y"
        defb TEXTNORM, BRIGHT, 0," if you want to re-write\n"
        defb "the utility back into page 4.\n\n"
        defb "Press ", TEXTBOLD, BRIGHT, 1, "N" 
        defb TEXTNORM, BRIGHT, 0," if you want to kill\n" 
        defb "off the flash utility.\n\n"
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

