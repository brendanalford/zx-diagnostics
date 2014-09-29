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
v_intcount		equ #7d1a; 2

;	Testing variables

v_stacktmp		equ #7d20; Temporary stack location when calling routines that assume no lower ram
v_curpage		equ #7d22; Currently paged location
v_paging		equ #7d23; Bank Paging status (output)
v_fail_ic		equ #7d26; Failed IC bitmap (48K)
v_fail_ic_uncontend	equ #7d27; Failed IC bitmap, uncontended memory banks 0,2,4,8 (128k)
v_fail_ic_contend	equ #7d28; Failed IC bitmap, contended memory banks 1,3,5,7 (128k)
v_toastrack		equ #7d29; Non-zero if this is a 128K toastrack
v_testcard		equ #7d2a; Workspace for testcard string

;	Relocation addresses for routines that need the original ROM paged

do_romcrc		equ #7e00
do_pagein		equ #7e80
do_testdiaghw		equ #7f00