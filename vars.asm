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

v_column		equ #7d00; 1
v_row			equ #7d01; 1
v_attr			equ #7d02; 1
v_bold			equ #7d03; 1

;	Miscellaneous

v_hexstr		equ #7d10; 5
v_intcount		equ #7d1a; 4
v_decstr		equ #7d20; 6
v_rtcenable		equ #7d28; 1
v_rtc			equ #7d29; 4 - h:m:s:50

;	Testing variables

v_stacktmp		equ #7d30; Temporary stack location when calling routines that assume no lower ram
v_curpage		equ #7d32; Currently paged location
v_paging		equ #7d33; Bank Paging status (output)
v_fail_ic		equ #7d36; Failed IC bitmap (48K)
v_fail_ic_uncontend	equ #7d37; Failed IC bitmap, uncontended memory banks 0,2,4,8 (128k)
v_fail_ic_contend	equ #7d38; Failed IC bitmap, contended memory banks 1,3,5,7 (128k)
v_128type		equ #7d39; 0 - 128K toastrack, 1 - grey +2, 2 - +2A or +3
v_testcard		equ #7d3a; Workspace for testcard string

;	Relocation addresses for routines that need the original ROM paged

do_romcrc		equ #7e00
do_pagein		equ #7e80
do_testdiaghw		equ #7f00