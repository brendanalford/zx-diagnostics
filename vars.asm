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

v_column						equ #7d00; 1
v_row								equ #7d01; 1
v_attr							equ #7d02; 1
v_pr_ops						equ #7d03; bit 0: bold on/off, bit 1: inverse on/off
v_width							equ #7d04; 1
v_scroll						equ #7d05; 1
v_scroll_lines  		equ #7d06; 1

;	Miscellaneous

v_intcount					equ #7d10; 4
v_userint						equ #7d14; 2
v_ulatest_pos				equ #7d16; 1
v_ulatest_dir				equ #7d17; 1

v_hexstr						equ #7d20; 5
v_decstr						equ #7d28; 6

;	Testing variables

v_stacktmp					equ #7d30; Temporary stack location when calling routines that assume no lower ram
v_curpage						equ #7d32; Currently paged location
v_paging						equ #7d33; 7ffd Bank Paging status (output)
v_paging_2					equ #7d34; +2A/+3 1ffd Bank Paging status
v_fail_ic						equ #7d36; Failed IC bitmap (48K)
v_fail_ic_uncontend	equ #7d37; Failed IC bitmap, uncontended memory banks 0,2,4,8 (128k)
v_fail_ic_contend		equ #7d38; Failed IC bitmap, contended memory banks 1,3,5,7 (128k)
v_fail_rom					equ #7d39; Failed ROM indication
v_128type						equ #7d3a; 0 - 128K toastrack, 1 - grey +2, 2 - +2A or +3
v_testcard_flags		equ #7d3b; bit 0 - AY present. bit 1 - quiet mode
v_ulacycles					equ #7d3c; ULA cycles x 6 since last interrupt
v_ulafloatbus				equ #7d3e; ULA floating bus detected (0 no, 1 yes)
v_testhwtype				equ #7d40; Type of interface we're running on. 0-none found,
							 							 ; 1-Diagboard, 2-Retroleum SMART card, 3-ZXC3/ZXC4
v_hw_page					 	equ #7d41; Paged ROM index on startup (SMART and ZXC4 hardware)
v_test_rtn					equ #7d42;	Address of RAM test routine to run after ROM check
v_keybuffer					equ #7d44; keyboard bitmap (8 bytes)
v_testcard					equ #7d50; Workspace for testcard string
v_rand_addr					equ #7d60;	Random fill test base addr
v_rand_seed					equ #7d62;	Random fill test rand seed
v_rand_reps					equ #7d64;	Random fill test repetitions

;	Relocation addresses for routines that need the original ROM paged

sys_romcrc					equ #7d80
sys_ld_a_hl					equ #7e00
sys_rompaging				equ #7e40

;	Default stack location

sys_stack						equ #7cff
