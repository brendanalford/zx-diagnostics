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
;	paging.asm
;	

;
;	Pages the given RAM page into memory. 
;	Inputs: A=desired RAM page.
;

pagein

	push bc
	push af
	ld bc, 0x7ffd

;	Ensure nothing else apart from paging gets touched
	
	and 0x7	
	out (c), a
	pop af
	pop bc 
	ret

;
;	Pages out the diagnostics ROM and restarts the computer
;
restart

	ld hl, brk_page_reloc
	ld de, 0x7f00				; Won't need system vars again at this point
	ld bc, end_brk_page_reloc - brk_page_reloc
	ldir
	jp 0x7f00

; This bit will be relocated so that we can page in the BASIC ROM

brk_page_reloc
	ld a, %00100000			; Bit 5 - release /ROMCS
	out (ROMPAGE_PORT), a
	jp 0
end_brk_page_reloc