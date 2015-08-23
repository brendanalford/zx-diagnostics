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

	DEFINE SAVEMEM 
	
	include "..\defines.asm"
	include "..\version.asm"
	include "spectranet.asm"
	
	org 0x2000

;	Spectranet ROM Module table

	defb 0xAA			; Code module
	defb 0xbb			; ROM identity - needs to change
	defw initroutine	; Address of reset vector
	defw 0xffff			; Mount vector - unused
	defw 0xffff			; Reserved
	defw 0xffff			; Address of NMI Routine
	defw 0xffff			; Address of NMI Menu string
	defw 0xffff			; Reserved
	defw str_identity	; Identity string

modulecall

;	Module 1 will call us here.	
;	Lower tests passed.
;	Page in ROM 0 (if running on 128 hardware) in preparation
;	for ROM test.

	ld hl, str_callok
	call PRINT42
	call GETKEY
	
loop
	jr loop
	
;
;	No init routine - this ROM should not respond to reset or any other events
;

initroutine

	ret

;
;	Text strings
;

str_callok

	defb "Now running from second ROM image!",0


str_ic

	defb "IC", 0
	
str_identity

	defb "ZX-Diagnostics ", VERSION, " [2/2]", 0 
	
	BLOCK 0x2fff-$, 0xff
