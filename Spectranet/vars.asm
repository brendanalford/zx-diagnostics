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
;	Variables and defines.
;

CALLBAS		equ 0x0010
ZXNEWLINE 	equ 0x0D	; ZX print routine newline
	
; store variables within spectranet's buf_workspace area
v_sockfd	equ 0x3D00
v_connfd 	equ 0x3D01
netflag		equ 0x3D02

; use spectrant's buf_message for somewhere to put a string
stringbuffer equ 0x3B00	; reserve 256 bytes for a buffer

tempstack		equ #7dfe;	Temporary stack location with running ROM CRC
do_romcrc		equ #7e00;	Location in RAM to run ROM CRC test routine from

;	Testing variables

v_stacktmp		equ #7fb0; Temporary stack location when calling routines that assume no lower ram
v_curpage		equ #7fb2; Currently paged location
v_paging		equ #7fb3; Bank Paging status (output)
v_fail_ic		equ #7fb6; Failed IC bitmap (48K)
v_fail_ic_uncontend	equ #7fb7; Failed IC bitmap, uncontended memory banks 0,2,4,8 (128k)
v_fail_ic_contend	equ #7fb8; Failed IC bitmap, contended memory banks 1,3,5,7 (128k)
v_128type		equ #7fb9; 0 - 128K toastrack, 1 - grey +2, 2 - +2A or +3
v_test_rtn		equ #7fba;	Test type to run
v_keybuffer		equ #7fbc; Keyboard bitmap (8 bytes)
v_rand_addr		equ #7fbe;	Random fill test base addr
v_rand_seed		equ #7fc0;	Random fill test rand seed
v_rand_reps		equ #7fc2;	Random fill test repetitions
v_hexstr		equ #7fc4; Workspace for Num2Hex routine
v_decstr		equ #7fca; Workspace for Num2Dec routine