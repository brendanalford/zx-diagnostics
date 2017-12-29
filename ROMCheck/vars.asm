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
;	vars.asm
;

;
;	System Variable locations in lower ram
;

;	Printing system variables

v_column						equ #bf00; 1
v_row								equ #bf01; 1
v_attr							equ #bf02; 1
v_pr_ops						equ #bf03; bit 0: bold on/off, bit 1: inverse on/off
v_width							equ #bf04; 1
v_scroll						equ #bf05; 1
v_scroll_lines  		equ #bf06; 1

;	Miscellaneous

v_hexstr						equ #bf20; 5
v_decstr						equ #bf28; 6

;	Testing variables

v_curpage						equ #bf32; Currently paged location
v_romtype           equ #bf35; String pointer to ROM type
v_romchksum         equ #bf37; 8 bytes - ROM checksums for ROMs 0-3
v_bankm             equ #bf40; Copy of BANK_M system variable
v_bank678           equ #bf42; Copy of BANK678 system variable
