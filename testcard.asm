testcard

; Relocate the test card attribute string

	ld hl, str_testcardattr
	ld de, v_testcard
	ld bc, 5
	ldir

	ld a, BORDERWHT
	out (ULA_PORT), a

	call cls
	xor a
	ld (v_row), a
	ld (v_column), a
	ld (v_attr), a

	ld b, 24

testcard_print


; Draw top third of testcard

	ld b, 8

testcard_row

	ld a, b
	dec a
	ld (v_testcard + 3), a
	push bc
	ld b, 8

testcard_col

	ld a, b
	dec a
	ld (v_testcard + 1), a

	push bc
	ld hl, v_testcard
	call print
	ld hl, str_year
	call print

	pop bc
	djnz testcard_col

	pop bc
	djnz testcard_row

	; Top third done, copy the attributes down

	ld hl, 0x5800
	ld de, 0x5900
	ld bc, 0x100
	ldir
	ld hl, 0x5900
	ld de, 0x5a00
	ld bc, 0x100
	ldir

	; Do the Diagnostics banner
	ld hl, str_testcard_banner
	call print
	ld hl, str_pageout_msg
	call print

	; Start the tone

tone_start

	call brk_check
	ld b, 1
	call tvt_tone
	jp tone_start


;
;	end of main program
;	local subroutines
;

brk_check

	ld a, 0x7f
	in a, (0xfe)
	rra
	ret c					; Space not pressed
	ld a, 0xfe
	in a, (0xfe)
	rra
	ret c					; Caps shift not pressed

	ld hl, brk_page_reloc
	ld de, 0x7f00				; Won't need system vars again at this point
	ld bc, end_brk_page_reloc - brk_page_reloc
	ldir
	jp 0x7f00

; This bit will be relocated so that we can page in the BASIC ROM

brk_page_reloc
	ld a, %00100000			; Bit 5 - release /ROMCS
	out (ROMPAGE_PORT), a
	jp 0
end_brk_page_reloc	

; Sounds a tone followed by a pause
; Number of tone/pause repetitions in B register
; This *may* have been lifted from the +2 ROM (cough)

tvt_tone	
	push bc
	ld a, 0xff
	out (LED_PORT), a
	ld de, 0x0370			; de= twice tone freq in Hz
	ld l, 0x7				; Border colour = white

tvt_tone_duration
	ld bc, 0x0049			; delay for 950us

tvt_tone_period
	dec bc
	ld a, b
	or c
	jr nz, tvt_tone_period

	ld a, l
	xor 0x10				; Toggle speaker output, preserve border
	ld l, a 
	out (0xfe), a

	dec de					; Generate tone for 1 sec
	ld a, d
	or e
	jr nz, tvt_tone_duration

; At this point the speaker is turned off, so delay for 1 second.
	
	ld a, 0
	out (LED_PORT), a
    	ld bc, 0x8000         ; Delay for 480.4us

tvt_tone_delay1
	dec bc
	ld a, b
	or c
	jr nz, tvt_tone_delay1

tvt_tone_delay2
	; delay for 480us
	dec bc		
	ld a, b
	or c
	jr nz, tvt_tone_delay2

	pop bc
	djnz tvt_tone
	ret 

tvt_sweep
	push bc

tvt_sweep_period
	dec bc
	ld a, b
	or c
	jr nz, tvt_sweep_period

	ld a, l
	xor 0x10				; Toggle speaker output, preserve border
	ld l, a 
	out (0xfe), a

	pop bc
	ld a, c
	out (LED_PORT), a
	dec bc					; Generate tone for 1 sec
	ld a, b
	or c
	jr nz, tvt_sweep
	ret
	  
;	The ZX Spectrum Diagnostics Banner 

str_testcardattr
	defb	PAPER, 0, INK, 0, 0
str_year
	defb	BRIGHT, 0, "20", BRIGHT, 1, "14", 0

str_testcard
	defb	PAPER, 0, "    ", PAPER, 1, "    ", PAPER, 2, "    ", PAPER, 3, "    "
	defb	PAPER, 4, "    ", PAPER, 5, "    ", PAPER, 6, "    ", PAPER, 7, "    ", 0
str_pageout_msg
	defb	AT, 22, 6, PAPER, 0, INK, 7, BRIGHT, 1, " Hold BREAK to exit ", 0
str_testcard_banner
	defb	AT, 18, 0, PAPER, 0, INK, 7, BRIGHT, 1
	defb    "                          " 
	defb	TEXTNORM, PAPER, 0, INK, 2, "~", PAPER, 2, INK, 6, "~", PAPER, 6, INK, 4, "~"
	defb	PAPER, 4, INK, 5, "~", PAPER, 5, INK, 0, "~", PAPER, 0, INK, 7, " "
	defb    TEXTBOLD, " ZX Spectrum Diagnostics "
	defb	TEXTNORM, PAPER, 0, INK, 2, "~", PAPER, 2, INK, 6, "~", PAPER, 6, INK, 4, "~"
	defb	PAPER, 4, INK, 5, "~", PAPER, 5, INK, 0, "~", PAPER, 0,"  "
	defb    "                        "
	defb	TEXTNORM, PAPER, 0, INK, 2, "~", PAPER, 2, INK, 6, "~", PAPER, 6, INK, 4, "~"
	defb	PAPER, 4, INK, 5, "~", PAPER, 5, INK, 0, "~", PAPER, 0,"   "

	defb	ATTR, 56, 0
      