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
;	testroutines.asm
;


;
;	Test routines used when lower memory is verified ok.
;	Ported from the macros in defines.asm to save space.
;


;
;	Run a RAM walk test
;	Inputs:
;	HL: Start address
;	DE: Length of memory to test
;

walkloop

.walk.loop

	ld a, 1
	ld b, 8     ; test 8 bits
	or a        ; ensure carry is cleared

.walk.checkbits

	ld (hl), a
	ld c, a     ; for compare
	ld a, (hl)
	cp c
	jr nz, .walk.borked
	rla
	djnz .walk.checkbits
	inc hl
	dec de
	ld a, d     ; does de=0?
	or e
	jp z, .walk.done
	jr .walk.loop

.walk.borked

; 	Store dodgy bit in ixh

	xor c

; 	And temporarily in d for BORKEDFLASH

	ld d, a
	ld bc, ix
	or b

	ld b, a
	ld a, 1	; Bit 0 of ixl: walk test fail
	or c
	ld c, a
	ld ix, bc
	ld a, BORDERRED
	out (ULA_PORT), a
	jr .walk.exit

.walk.done
.walk.exit

	ret

;
;	Routine to blank (or fill) an area of memory
;	Inputs:
;	HL: Start memory location
;	DE: Length of memory to blank
;	B:  Pattern to fill with
;

;
;	Inversion testing - pattern A.
;	Inputs:
;	HL: Start memory location
;	BC: Length of memory to blank
;	D:  Pattern to fill with
;
altpata

	push hl
	push de
	push bc

	ld a, d
	ld (hl), a
	ld de, hl
	inc de
	ldir

	pop bc
	pop de
	pop hl
	push hl
	push bc

.altpat1.wrloop1

	ld a, d
	cpl
	ld (hl), a
	inc hl
	inc hl
	dec bc
	dec bc
	ld a, b
	or c
	jr nz, .altpat1.wrloop1

	pop bc
	pop hl

.altpat1.rd

.altpat1.rdloop1

	ld a, d
	cpl
	cp (hl)
	jr nz, .altpat1.borked
	inc hl
	dec bc
	cpl
	cp (hl)
	jr nz, .altpat1.borked
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .altpat1.rdloop1
	jr .altpat1.done

.altpat1.borked

; 	Store dodgy bit in ixh

	xor (hl)
	ld bc, ix
	ld d, a

; 	And also in d for ALTBORKED

	or b

	ld b, a
	ld a, 2	; Bit 1 of ixl: inversion test fail
	or c
	ld c, a
	ld ix, bc

	ld a, BORDERRED
	out (ULA_PORT), a
	jr .altpat1.exit

.altpat1.done
.altpat1.exit

	ret

;
;	Inversion testing - pattern B.
;	Inputs:
;	HL: Start memory location
;	BC: Length of memory to blank
;	D:  Pattern to fill with
;

altpatb

	push hl
	push de
	push bc

	ld a, d
	ld (hl), a
	ld de, hl
	inc de
	ldir

	pop bc
	pop de
	pop hl
	push hl
	push bc

.altpat2.wrloop1

	ld a, d
	cpl
	inc hl
	ld (hl), a
	inc hl
	dec bc
	dec bc
	ld a, b
	or c
	jr nz, .altpat2.wrloop1

.altpat2.rd

	pop bc
	pop hl

.altpat2.rdloop1

	ld a, d
	cp (hl)
	jr nz, .altpat2.borked
	inc hl
	dec bc
	cpl
	cp (hl)
	jr nz, .altpat2.borked
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .altpat2.rdloop1
	jr .altpat2.done

.altpat2.borked

; 	Store dodgy bit in ixh

	xor (hl)
	ld bc, ix

; 	And also in d for ALTBORKED

	ld d, a
	or b

	ld b, a
	ld a, 2	; Bit 1 of l': inversion test fail
	or c
	ld c, a
	ld ix, bc
	ld a, BORDERRED
	out (ULA_PORT), a
	jr .altpat2.exit

.altpat2.done
.altpat2.exit

	ret

;
;	Algorithm March X
;	Step1: write 0 with up addressing order;
;	Step2: read 0 and write 1 with up addressing order;
;	Step3: read 1 and write 0 with down addressing order;
;	Step4: read 0 with down addressing order.
;
; 	Credit - Karl (PokeMon) on WoS for the algorithm description
;
;	Inputs:
;	HL: Start address
;	BC: Range to test

marchtest

	; Step 1 - write 0 with up addressing order
	; No errors expected with this part :)

	push hl
	push bc

.marchtest1.loop

	ld (hl), 0
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .marchtest1.loop

	; Step 2 - read 0 and write 1 with up addressing order

	pop bc
	pop hl
	push hl
	push bc

.marchtest2.loop
	ld a, (hl)
	cp 0
	jr z, .marchtest2.next

	call marchborked

.marchtest2.next
	ld a, 0xff
	ld (hl), a
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .marchtest2.loop

.marchtest3.start

	pop bc
	pop hl
	push hl
	push bc

	; Step 3 - read 1 and write 0 with down addressing order
	dec bc
	add hl, bc

.marchtest3.loop

	ld a, (hl)
	cp 0xff
	jr z, .marchtest3.next

	xor a
	call marchborked

.marchtest3.next

	xor a
	ld (hl), a
	dec hl
	dec bc
	ld a, b
	or c
	jr nz, .marchtest3.loop

.marchtest4.start
	; Step 4 - read 0 with down addressing order

	pop bc
	pop hl

	dec bc
	add hl, bc

.marchtest4.loop

	ld a, (hl)
	cp 0
	jr z, .marchtest4.next

	call marchborked

.marchtest4.next

	dec hl
	dec bc
	ld a, b
	or c
	jr nz, .marchtest4.loop

.marchtest.done

	ret


marchborked

	exx
	ld b, a
	ld a, ixh
	or b
	ld ixh, a

	ld a, 4			; Set bit 2 of IXL - march test fail
	ld c, a
	ld a, ixl
	or c
	ld ixl, a

	ld a, BORDERRED
	out (ULA_PORT), a
	exx
	ret

;
;	Generate a pseudo random 16-bit number.
; 	see http://map.tni.nl/sources/external/z80bits.html#3.2 for the
; 	basis of the random fill
;
;	Inputs:
; 	BC: seed
;

rand16

	ld d, b
	ld e, c
	ld a, d
	ld h, e
	ld l, 253
	or a
	sbc hl, de
	sbc a, 0
	sbc hl, de
	ld d, 0
	sbc a, d
	ld e, a
	sbc hl, de
	jr nc, .rand16.done
	inc hl

.rand16.done

	ld b, h
	ld c, l

	ret

;
;	Random fill test in increasing order
;	Inputs:
;	HL: Base address
;	DE: Half memory size being tested
;	BC: PRNG seed to use

randfillup

	ld (v_stacktmp), sp
	ld (v_rand_addr), hl
	ld (v_rand_reps), de
	ld (v_rand_seed), bc

	ld sp, (v_rand_addr)
	exx
	ld bc, (v_rand_seed)
	ld hl, 0
	exx
	ld bc, (v_rand_reps)

.randfill.up.loop

	exx
	RAND16
	ld de, hl
	ld hl, 0
	add hl, sp
	ld (hl), de
	inc sp
	inc sp
	exx
	dec bc
	ld a, b
	or c
	jp nz, .randfill.up.loop

;	Delay for a second or so if we are soak testing.
; This will hopefully reveal any memory refresh issues.
.randfill.up.soak

	ld a, iyl
	or iyh
	jr z, .randfill.up.test

	ld bc, 0xffff

.randfill.up.delay

	dec bc
	ld a, c
	or b
	jr nz, .randfill.up.delay

.randfill.up.test

	ld sp, (v_rand_addr)
	exx
	ld bc, (v_rand_seed)
	exx
	ld bc, (v_rand_reps)
	ld l, 0

.randfill.up.testloop

	exx
	RAND16	; byte pair to test now in HL
	pop de	; Pop memory off the stack to test into DE
	ld a, h
	xor d
	jr nz, .randfill.up.borked
	ld a, l
	xor e
	jr nz, .randfill.up.borked
	jr .randfill.up.next

.randfill.up.borked

	exx
	or l
	ld l, a
	exx

.randfill.up.next

	exx
	dec bc
	ld a, b
	or c
	jr nz, .randfill.up.testloop

	ld a, l
	cp 0
	jp z, .randfill.up.done

.randfill.up.borkedreport

; Store dodgy bit in ixh

	ld bc, ix

; And in D for borkedloop

	ld d, a
	or b

	ld b, a
	ld a, 8	; Bit 3 IXL': random test fail
	or c
	ld c, a
	ld ix, bc
	ld c, a   ; save good byte
	ld a, BORDERRED
	out (ULA_PORT), a
	jp .randfill.up.exit

.randfill.up.done
.randfill.up.exit

	ld sp, (v_stacktmp)
	ret

;
;	Random fill test in descendingvorder
;	Args: addr - base address, reps - half memory size being tested,
;	      seed - PRNG seed to use
;


;
;	Random fill test in descending order
;	Inputs:
;	HL:	 Base address
;	DE': Half memory size being tested
;	BC:  PRNG seed to use

randfilldown

	ld (v_stacktmp), sp
	ld (v_rand_addr), hl
	ld (v_rand_reps), de
	ld (v_rand_seed), bc

	ld sp, (v_rand_addr)
	exx
	ld bc, (v_rand_seed)
	exx
	ld bc, (v_rand_reps)

	; Adjust stack pointer as we won't be popping values off in
	; the normal sense when testing

	inc sp
	inc sp

.randfill.down.loop

	exx
	RAND16
	push hl
	exx
	dec bc
	ld a, b
	or c
	jp nz, .randfill.down.loop


;	Delay for a second or so if we are soak testing.
; This will hopefully reveal any memory refresh issues.
.randfill.down.soak

	ld a, iyl
	or iyh
	jr z, .randfill.down.test

	ld bc, 0xffff

.randfill.down.delay

	dec bc
	ld a, c
	or b
	jr nz, .randfill.down.delay

.randfill.down.test

	ld sp, (v_rand_addr)
	exx
	ld bc, (v_rand_seed)
	exx
	ld bc, (v_rand_reps)
	ld l, 0

.randfill.down.testloop

	exx
	RAND16		; byte pair to test now in HL
	pop de		; corresponding memory in DE
	dec sp
	dec sp		; Adjust stack pointer back downwards
	dec sp
	dec sp

	ld a, h
	xor d
	jr nz, .randfill.down.borked
	ld a, l
	xor e
	jr nz, .randfill.down.borked
	jr .randfill.down.next

.randfill.down.borked

	exx
	or l
	ld l, a
	exx

.randfill.down.next

	exx
	dec bc
	ld a, b
	or c
	jp nz, .randfill.down.testloop

	ld a, l
	cp 0
	jr nz, .randfill.down.borkedreport
	jp .randfill.down.done

.randfill.down.borkedreport

; Store dodgy bit in ixh

	ld bc, ix

; And in D for borkedloop

	ld d, a
	or b

	ld b, a
	ld a, 4	; Bit 0 of l': random test fail
	or c
	ld c, a
	ld ix, bc
	ld c, a   ; save good byte
	ld a, BORDERRED
	out (ULA_PORT), a
	jp .randfill.down.exit

.randfill.down.done
.randfill.down.exit

	ld sp, (v_stacktmp)
	ret


;
;	Routine to interpret the results of a 48k memory test
;	and store the result, write result to screen etc
;

testresult

	ld bc, ix
	ld a, b
	cp 0
	jr nz, .test.fail

.test.pass

	ld hl, str_testpass
	call print
	call newline

	jr .test.end

.test.fail

	ld a, (v_fail_ic)
	or b
	ld (v_fail_ic), a
	ld hl, str_testfail
	call print
	call newline

.test.end

	ret

;
;	Routine to interpret the results of a 128k memory test
;	and store the result
;

testresult128

	ld bc, ix
	ld a, (v_fail_ic)
	or b
	ld (v_fail_ic), a

	ret

;
;	Blanks the H register.
;

preparehreg

	exx
	ld a, 0
	ld h, a
	exx

	ret

;
;	Routine to sound a tone.
;	Inputs:
;	BC: frequence
;	DE: length
;	L:  border colour.
;

beep

	push bc

.tone.duration

	pop bc
	push bc

.tone.period

	dec bc
	ld a, b
	or c
	jr nz, .tone.period

;	Toggle speaker output, preserve border

	ld a, l
	xor 0x10
	ld l, a
	out (0xfe), a

;	Generate tone for desired duration

	dec de
	ld a, d
	or e
	jr nz, .tone.duration

	pop bc
	ret

;	A quick routine to write a value in a to four consecutive
;	memory locations starting at HL.

ldhl4times

	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a

	ret
;
;	Routine to blank (or fill) an area of memory
; HL=start, BC=length, A=pattern
;

blankmem

		ld de, hl
		inc de
		ld (hl), a
		ldir
		ret
