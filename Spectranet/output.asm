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
;	output.asm
;	
;	Routines to output either to screen or to network
;

readnetstring
	ld hl, stringbuffer
	ld de, stringbuffer+1
	ld bc, 255
	ld (hl),0
	ldir			;zero out buffer
	
	ld de, stringbuffer
	ld bc, 256
	ld a, (v_connfd)
	call RECV
	; todo: error checking
	ret
	
outputstring
	ld a,(netflag)
	cp 0
	jr nz, outputstringnet
	call PRINT42
	ret
outputstringnet
	call strlen
	ld b,0
	ld c,a		; bc = length of string
dosendstring
	ex hl,de	; de = string address
	ld a, (v_connfd)
	call SEND
	;todo: error checking
	ret

outputchar
	ld b,a
	ld a,(netflag)
	cp 0
	jr nz, outputcharnet
	ld a,b
	call PUTCHAR42
	ret
outputcharnet
	ld hl, stringbuffer+1
	ld (hl),0
	dec hl
	ld (hl),b
	ld bc, 2
	jr dosendstring

getkey
	ld a,(netflag)
	cp 0
	jr nz, getkeynet
	call KEYUP
	call GETKEY
	ret
getkeynet
	call readnetstring
	ld a, (stringbuffer)
	ret
	
	; todo: error checking
	
	; right now this is reading a string while the local one gets a keypress
	ret

; String length returned in A for the string at HL
; don't call this on really long or unterminated strings...
strlen
	push hl
	xor a
	ld bc, 0x100
	cpir
	ld a, c
	cpl
	pop hl
	ret