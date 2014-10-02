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

        org 0
        jp copyflashutil
        block #38-$,0

; 	Just in case an interrupt occurs before we can DI

interrupt
         
         reti

flashutil

;	Flash utility code to be relocated.

        incbin "flashutil.bin"

flashutilend

        block #1E7F-$, 0

;
;	Relocate the flash utility to RAM, then run from there
;
copyflashutil
 
	di
        ld sp, 0xffff
        ld hl, flashutil
        ld de, #E000   ; Decimal 57344
        ld bc, flashutilend-flashutil
        ldir
        jp #E000

fillspare
        block #4000-$,0
         
