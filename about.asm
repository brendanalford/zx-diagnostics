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
;	about.asm
;	

about

	ld sp, sys_stack
	call initialize
	
	ld a, BORDERWHT
	out (0xfe), a
	call cls
	
	ld hl, str_creditsbanner
	call print_header
	
	ld hl, str_hardware
	call print
	
	ld a, (v_testhwtype)
	
	cp 1
	jr nz, .checkhw_1
	
	ld hl, str_diagboard
	jr print_hw
	
.checkhw_1

	cp 2
	jr nz, .checkhw_2
	
	ld hl, str_smart
	jr print_hw
	
.checkhw_2

	cp 3
	jr nz, .checkhw_3
	
	ld hl, str_zxc
	jr print_hw
	
.checkhw_3

	ld hl, str_no_hardware
	
print_hw

	call print
	
	ld hl, str_version
	call print
	
	ld hl, str_build
	call print
	
	di
	halt
	
str_creditsbanner

	defb	TEXTBOLD, "About ZX Diagnostics", TEXTNORM, 0	
	
str_hardware

	defb 	AT, 2, 0, "Hardware: ", 0

str_diagboard

	defb "Alioth Diagboard\n\n", 0
	
str_smart

	defb "Retroleum SMART Card\n\n", 0
	
str_zxc

	defb "Fruitcake ZXC3/ZXC4\n\n", 0
	
str_no_hardware

	defb "None detected\n\n", 0
	
str_version

	defb "Build/version information:\n\n", 0