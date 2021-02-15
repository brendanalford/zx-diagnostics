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

;	Initialise stack and system variables

	ld sp, sys_stack
	call initialize

;	White screen and border

	ld a, BORDERWHT
	out (0xfe), a
	call cls

;	Print top and bottom banners/footers

	ld hl, str_creditsbanner
	call print_header

	call print_footer

;	Print the diagnostic hardware type we're running
;	on (if any)

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

	cp 4
	jr nz, .checkhw_4

	ld hl, str_dand
	jr print_hw

.checkhw_4

	cp 5
	jr nz, .checkhw_5
	ld hl, str_css
	jr print_hw

.checkhw_5

	cp 6
	jr nz, .checkhw_6
	ld hl, str_vtx 
	jr print_hw	

.checkhw_6

	ld hl, str_no_hardware

print_hw

	call print

;	Print version and build information

	ld hl, str_version
	call print

	ld hl, str_build
	call print
	call newline
	ld hl, str_gitbranch
	call print
	call newline
	ld hl, str_gitcommit
	call print
	call newline
	ld hl, str_buildmachine
	call print

;	Output the amount of free space left in the ROM image

	ld hl, str_free_sp
	call print

	ld hl, free_space_end - free_space
	ld de, v_decstr
	call Num2Dec
	ld hl, v_decstr
	call print

	ld hl, str_free_sp_2
	call print

	ld a, (v_testhwtype)
	cp 0
	jr nz, wait_for_key

;	No diagnostic hardware means no means of exit - just halt

	di
	halt

wait_for_key

;	Prompt and wait for a key press

	ld hl, str_anykey
	call print

	call get_key

;	Passing 0x1234 to the pageout routine forces a jump to
;	the system ROM when done

	ld a, 2
	ld bc, 0x1234

;	We won't ever return from this call

	call sys_rompaging

str_creditsbanner

	defb	TEXTBOLD, "About ZX Diagnostics", TEXTNORM, 0

str_hardware

	defb 	AT, 2, 0, "Hardware: ", 0

str_diagboard

	IFNDEF SLAMTEST
	defb "Alioth Diagboard\n\n", 0
	ENDIF

	IFDEF SLAMTEST
	defb "SLAM48/128 ULA Replacement\n\n", 0
	ENDIF

str_smart

	defb "Retroleum SMART Card\n\n", 0

str_zxc

	defb "Paul Farrow ZXC3/ZXC4\n\n", 0

str_dand

	defb "ZX Dandanator! Mini\n\n", 0

str_css

	defb "CSS 128K ROM Board\n\n", 0

str_vtx

	defb "Prism VTX5000\n\n", 0

str_no_hardware

	defb "None detected\n\n", 0

str_version

	defb "Build/version information:\n\n", 0

str_free_sp

	defb "\n\nFree ROM space: ", 0

str_anykey

	defb "Press any key to exit.", 0

str_free_sp_2

	defb " bytes \n\n", 0
