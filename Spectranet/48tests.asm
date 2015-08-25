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
;	48tests.asm
;	

;
;	48K Specific Tests
;
;	Perform the standard inversion, fill and random tests
;   on the top 32K of RAM.
;
	
;	Start the Upper RAM walk test.
		
test_48k

;	Test if we can read/write 0x00 to the lowest byte
; 	in upper RAM. If we get all bits set over time, then there's no RAM
; 	present there at all, and we shouldn't test it.

	ld b, 0xff
	ld hl, 0x8000
	ld (hl), 0
	xor a
	
is_upper_ram_present

	ld c, (hl)
	or c
	djnz is_upper_ram_present

	cp 0xff
	jr nz, upper_ram_present

;	No upper ram, reset the error bitmap in ix
	
	xor a
	ld ixh, 0
	
	call newline
	ld hl, str_isthis16k
	call outputstring
	
;	Don't flag errors if all upper RAM failed

	xor a 
	ld (v_fail_ic), a
	ret

upper_ram_present

	call upperram_test

;	Contents of v_fail_ic system variable will be 
;	non-zero if we have any failures.
	  
print_upperresult

	ld a, (v_fail_ic)
   	cp 0
	jr z, print_upperpass
	ld hl, str_48ktestsfail
	call outputstring
	
; If possible, output the failing IC's to the screen

print_upper_ic

	ld hl, str_check_ic
	call outputstring

	ld a, (v_fail_ic)
	ld d, a
	ld ix, str_48_ic

	call print_fail_ic

	ld hl, RETURN
	call outputstring
	ret 

;	Upper RAM tests passed, give the user the good news

print_upperpass

	ld hl, str_48ktestspass
	call outputstring
	
;	48K tests passed at this point

	ret	
	
	
;
;	48K Specific Tests
;
;	Perform the standard inversion, fill and random tests
;   	on the top 32K of RAM.
;
	
;	Start the Upper RAM walk test for generic machines
		
test_48kgeneric

	call upperram_test

;	Contents of v_fail_ic system variable will be 
;	non-zero if we have any failures.
	  

	ld a, (v_fail_ic)
    	cp 0
	jr z, print_upperpass_gen
	ld hl, str_48ktestsfail
	call outputstring

;	If all upper RAM IC's tested faulty, then
;	chances are we're a 16K Spectrum

	cp 0xff
	jr nz, print_upper_ic_gen

;	Reset the error bitmap in ix
	
	xor a
	ld ixh, 0
	
	ld hl, str_isthis16k
	call outputstring
	
;	Don't flag errors if all upper RAM failed

	xor a 
	ld (v_fail_ic), a
	ret
	
; If possible, output the failing IC's to the screen

print_upper_ic_gen

	ld hl, str_check_bits
	call outputstring

	ld a, (v_fail_ic)
	ld d, a
	ld ix, str_bit_ref
	ld b, 0

fail_print_bit_loop

	bit 0, d
	jr z, bit_ok

;	Bad IC, print out the corresponding location for a 48K machine

	ld hl, str_bit
	call outputstring
	ld hl, ix

;	Strings are aligned to nearest 32 bytes, so we can just replace
;	this much the LSB

	ld a, b
	rlca
	rlca
	or l
	ld l, a

	call outputstring
	ld a, 5

bit_ok

;	Rotate D register right to line up the next IC result
;	for checking in bit 0

	rr d

;	Loop round if we've got more bits to check

	inc b
	ld a, b
	cp 8
	jr nz, fail_print_bit_loop
	
	call newline
	ret 

;	Upper RAM tests passed, give the user the good news

print_upperpass_gen

	ld hl, str_48ktestspass
	call outputstring
	
;	48K tests passed at this point

	ret	
	
	
	
upperram_test

;	Called to test upper 32K of ram for both 48K spectrums 
;   and related clones.

	xor a
	ld (v_fail_ic), a
	
	ld hl, str_test4
	call outputstring

	call preparehreg
	ld hl, 32768
	ld de, 32768
	call walkloop
	call testresult
	
;	Do the upper RAM inversion test
	    
upperram_inversion

	ld hl, str_test5
	call outputstring

	call preparehreg

	ld hl, 32768
	ld bc, 32768
	ld d, 0
	call altpata

	ld hl, 32768
	ld bc, 32768
	ld d, 255
	call altpata

	ld hl, 32768
	ld bc, 32768
	ld d, 0
	call altpatb

	ld hl, 32768
	ld bc, 32768
	ld d, 255
	call altpatb

	call testresult
	
;	Do the upper RAM March test

upperram_march

	ld hl, str_test6
	call outputstring

	call preparehreg

	ld hl, 32768
	ld bc, 32768
	call marchtest
	call testresult
	
;	And lastly the upper RAM Random fill test.
	  
upperram_random

	ld hl, str_test7
	call outputstring
	  
	call preparehreg

	ld hl, 32768
	ld de, 16384
	ld bc, 11
	call randfillup
	
	ld hl, 65534
	ld de, 16383
	ld bc, 17
	call randfilldown
	
	call testresult
	ret
	
str_check_bits

	defb	"Failures found in bits:\n", 0

str_bit

	defb 	"Bit ", 0