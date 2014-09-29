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
