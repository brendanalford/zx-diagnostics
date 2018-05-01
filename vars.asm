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

v_column					equ #7c00; 1
v_row						equ #7c01; 1
v_attr						equ #7c02; 1
v_pr_ops					equ #7c03; bit 0: bold on/off, bit 1: inverse on/off
v_width						equ #7c04; 1
v_scroll					equ #7c05; 1
v_scroll_lines  			equ #7c06; 1

;	Miscellaneous

v_intcount					equ #7c10; 4
v_userint					equ #7c14; 2
v_ulatest_pos				equ #7c16; 1
v_ulatest_dir				equ #7c17; 1

v_hexstr					equ #7c20; 5
v_decstr					equ #7c28; 6

;	Testing variables

v_stacktmp					equ #7c30; Temporary stack location when calling routines that assume no lower ram
v_curpage					equ #7c32; Currently paged location
v_paging					equ #7c33; 7ffd Bank Paging status (output)
v_paging_2					equ #7c34; +2A/+3 1ffd Bank Paging status
v_fail_ic					equ #7c36; Failed IC bitmap (48K)
v_fail_ic_uncontend			equ #7c37; Failed IC bitmap, uncontended memory banks 0,2,4,8 (128k)
v_fail_ic_contend			equ #7c38; Failed IC bitmap, contended memory banks 1,3,5,7 (128k)
v_fail_rom					equ #7c39; Failed ROM indication
v_128type					equ #7c3a; 0 - 128K toastrack, 1 - grey +2, 2 - +2A or +3
v_testcard_flags			equ #7c3b; bit 0 - AY present. bit 1 - quiet mode
v_ulacycles					equ #7c3c; ULA cycles x 6 since last interrupt
v_ulafloatbus				equ #7c3e; ULA floating bus detected (0 no, 1 yes)
v_ulapluspresent			equ #7c3f; ULAPLus hardware detected (0 no, 1 yes)
v_cmoscpupresent			equ #7c40; CMOS CPU detected (0 no, 1 yes)
v_testhwtype				equ #7c41; Type of interface we're running on. 0-none found,
							 	 	 ; 1-Diagboard, 2-Retroleum SMART card, 3-ZXC3/ZXC4
v_hw_page					equ #7c42; Paged ROM index on startup (SMART and ZXC4 hardware)
v_test_rtn					equ #7c43; Address of RAM test routine to run after ROM check
v_keybuffer					equ #7c45; keyboard bitmap (8 bytes)
v_testcard					equ #7c50; Workspace for testcard string
v_rand_addr					equ #7c60; Random fill test base addr
v_rand_seed					equ #7c62; Random fill test rand seed
v_rand_reps					equ #7c64; Random fill test repetitions
v_kempston					equ #7c70; Bit 7 - Kempston I/F present
									 ; Bits 5-0: Kempston values after call to read_kempston
v_membrowser_buffer			equ #7c71; 8 byte buffer for memory browser

;	Relocation addresses for routines that need the original ROM paged

sys_romcrc					equ #7d00
sys_ld_a_hl					equ #7d30
sys_ld_buffer_8_bytes_hl	equ #7d70
sys_rompaging				equ #7dc0

; Location of magic string for testing Diag ROM presence

v_rom_magic_loc			equ #00f0

;	Default stack location

sys_stack				equ #7bff
