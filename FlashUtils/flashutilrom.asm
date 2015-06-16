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
;	flashutilrom.asm
;	

; 	This curious looking file basically aligns a routine to
; 	copy in the flash utility when BASIC 'OUT 31, 36' is executed.
; 	The routine lives at the address the RET from the BASIC ROM for
; 	the OUT command would live (since the OUT (C), A switches page,
; 	the next fetched instruction will be from this file, not the Speccy ROM)

	include "../defines.asm"
	
        org 0
		ld sp, 0x7fff
        jp copyflashutil
        block #38-$,0

; 	Just in case an interrupt occurs before we can DI

interrupt
         
         reti

flashutil

;	Flash utility code to be relocated.

        incbin "flashutil.bin"

flashutilend

        block #1E80-$, 0

;
;	Relocate the flash utility to RAM, then run from there
;
copyflashutil
 
	di
 
 ;	First check if we have any upper memory.
 ;	This utility won't work on 16K machines.
 
 	ld hl, 0
 	ld (0xfffe), hl
 	ld hl, (0xfffe)
 	ld a, h
 	or l
 	jr nz, ramfail
 	
docopy
 
 	ld hl, flashutil
        ld de, #E000   ; Decimal 57344
        ld bc, flashutilend-flashutil
        ldir
        jp #E000

 ;	Uh-oh, we weren't able to read and write 0000 to
 ;	locations 32768/32769. Either we're running on a 
 ;	16K Spectrum, or upper memory's faulty.
 ;	(The flash utility could run in the lower 16K, but
 ;	then there's no spare memory to copy ROM images to
 ;	or from.)

ramfail 

 	xor a
 	ld hl, 0x4000
 	ld (hl), a
 	ld de, 0x4001
 	ld bc, 0x1800
 	ldir
	ld ixl, 4
	
ramfail_1
 	
	ld a, 0x10
 	ld hl, 0x5800
 	ld (hl), a
 	ld de, 0x5801
 	ld bc, 0x300
 	ldir
 	ld a, 2
 	out (0xfe), a
 	
 	ld hl, 0xffff
 
ramfail_2
 
 	dec hl
 	ld a, h
 	or l
 	jr nz, ramfail_2
 	 	
 	ld hl, 0x5800
	ld (hl), a
	ld de, 0x5801
	ld bc, 0x300
	ldir
 	ld a, 0
 	out (0xfe), a

 	ld hl, 0xffff

ramfail_3

	dec hl
	ld a, h
	or l
	jr nz, ramfail_3
	dec ixl
	or ixl
	jr nz, ramfail_1
	
ret_basic

;	Clear screen to previously set border and paper colour
;	as stored in system variables

	ld a, (0x5c48)
	and 0x38
	rrca
	rrca
	rrca
	out (0xfe), a 
	
	ld a, (0x5c8d)
	ld hl, 0x5800
	ld de, 0x5801
	ld bc, 0x0300
	ld (hl), a
	ldir

;	Copy last bits of setup code to RAM	
;	This is a 16K or a faulty 48K Spectrum, it's ok
;	to use the printer buffer here.

	ld hl, report4
	ld de, 0x5b00
	ld bc, report4end-report4
	ldir
	jp 0x5b00
	
report4

     	xor a
     	out (ROMPAGE_PORT), a   ; page in Speccy ROM

     	ei

     	ld l, 0x03		; Generate '4 Out of memory' report
     	jp 0x0055

report4end

fillspare
        block #4000-$,0
         
