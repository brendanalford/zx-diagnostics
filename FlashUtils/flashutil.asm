      org #E000

      include "vars.asm"

      define ULA_PORT       0xfe
      define ROMPAGE_PORT   31

      jp start

start
      di                ; we're paging roms in and out at random
      ld a, 7           ; White border
      out (ULA_PORT), a

      ld a, 56        ; Black text on white paper
      ld (v_attr), a
      call cls

      xor a
      ld (v_column), a
      ld (v_row), a
      ld (v_bold), a
      ld hl, str_banner
      call print
      ld hl, STR_run
      call print

      ld hl, STR_p1
      call print
      ld hl, STR_others
      call print

      call F_pollkeys

      ; check for options
      cp 31
      jp p, .options
      or 32          ; bit 5 = /ROMCS line - bit 5 should be high
                     ; to assert it with the jumper in 'SPECTRUM' pos
      out (ROMPAGE_PORT), a
      jp 0
.options
      cp 32
      jp z, .progpage
      cp 33
      jp z, .erasesector
      cp 34
      jp z, .copypage

      ; if we get here Z was pressed
      xor a
      out (ROMPAGE_PORT), a   ; page in Speccy ROM
      ei
      ret

.progpage
      call cls
      ld hl, STR_prog
      call print
      ld hl, STR_p1
      call print
      ld hl, STR_back
      call print
      call F_pollkeys
      cp 31
      jp p, start

      ; now try to program the page - first do some checks
      or 32       ; set /ROMCS flag
      out (ROMPAGE_PORT), a
      ld (v_page), a    ; save the flash page number
      ld a, (0)
      cp #ff      ; unused flash memory is set to all 1s
      jr nz, .progpage.inuse
      ld hl, STR_writing
      call print

.progpage.program
      ld hl, #8000
      ld de, 0
      ld bc, 16384
.progpage.loop
      ld a, (hl)
      call F_FlashWriteByte
      jr c, .progpage.borked
      inc hl
      inc de
      dec bc
      ld a, b
      or c
      jr nz, .progpage.loop

      ld hl, STR_done
      call print
      ld hl, STR_anykey
      call print
      call F_pollkeys
      jp start
.progpage.borked
      ld hl, STR_borked
      call print
      ld hl, STR_anykey
      call print
      call F_pollkeys
      jp start
.progpage.inuse
      ld hl, STR_inuse
      call print
      call F_pollkeys
      cp 34    ; 'y'
      jr nz, .progpage
      ld hl, STR_hgn
      call print
      jr .progpage.program


.erasesector
      call cls
      ld hl, STR_erasetxt
      call print
.repoll
      call F_pollkeys
      cp 33    ; X
      jp z, start
      cp 8
      jp p, .repoll
      cp 1
      jr z, .yourekillingme
.doerase
      ld hl, STR_erasing
      call print
      call F_FlashEraseSector
      jr c, .eraseborked
.erasedone
      ld hl, STR_done
      call print
      ld hl, STR_anykey
      call print
      call F_pollkeys
      jp start
.eraseborked
      ld hl, STR_borked
      call print
      ld hl, STR_anykey
      call print
      call F_pollkeys
      jp start
.yourekillingme
      push af     ; save intended sector
      call cls
      ld hl, STR_delp4
      call print
      call F_pollkeys
      cp 34       ; Y = keep me
      jr z, .keep
      cp 23       ; N = delete me
      jr z, .killme
      ; any other key = abort
      pop af
      jp .erasesector
.killme
      pop af
      jr .doerase
.keep
      ld a, #24   ; bit 5 set + page 4
      out (ROMPAGE_PORT), a
      ld hl, 0
      ld de, 32768
      ld bc, 16384
      ldir
      ld hl, STR_erasing
      call print
      pop af
      call F_FlashEraseSector
      jr c, .eraseborked
      ld hl, STR_reprogramming
      call print
      ld a, #24   ; page 4 with bit 5 set for /romcs
      ld (v_page), a
      ld hl, 32768
      ld de, 0
      ld bc, 16384
      jp .progpage.loop

.copypage
      call cls
      ld hl, STR_copyhdr
      call print
      ld hl, STR_p1
      call print
      call F_pollkeys

      cp 33       ; 'X'
      jp z, start

      ; A = page
      or 32       ; set /ROMCS bit
      out (ROMPAGE_PORT), a
      ld hl, STR_copying
      call print
      ld hl, 0
      ld de, 32768
      ld bc, 16384
      ldir
      ld hl, STR_done
      call print
      ld hl, STR_anykey
      call print
      call F_pollkeys
      jp start

; EraseSector subroutine erases a 64K Flash ROM sector. It's designed
; for 4 megabit chips like the Am29F040.
; This function will page in the sector and erase it.
; Pass the page in A
; On error, carry flag set.
F_FlashEraseSector
		push AF

		; select page 0
		ld a, 32
		out (ROMPAGE_PORT), A

		ld a, #AA	; unlock code 1
		ld (#555), a	; unlock addr 1
		ld a, #55	; unlock code 2
		ld (#2AA), a	; unlock addr 2
		ld a, #80	; erase cmd 1
		ld (#555), a	; erase cmd addr 1
		ld a, #AA	; erase cmd 2
		ld (#555), a	; erase cmd addr 2
		ld a, #55	; erase cmd 3
		ld (#2AA), a	; erase cmd addr 3

		; select sector to erase
		pop AF

      ; multiply by 4
      rla
      rla
      or 32       ; set /romcs high
		out (ROMPAGE_PORT), A

		ld a, #30	; erase cmd 4
		ld (0), a	; erase sector address is set by flip-flop, just use addr 0

		ld HL, #0
EraseSector.wait
		bit 7, (hl)	; test DQ7 - should be 1 when complete
		jr nz, EraseSector.complete
		bit 5, (hl)	; test DQ5 - should be 1 to continue
		jr z, EraseSector.wait
		bit 7, (hl)	; test DQ7 again
		jr z, EraseSector.borked

EraseSector.complete
		or 0		; clear carry flag
		ret

EraseSector.borked
		scf		; carry flag = error
		ret


; Writebyte: A = byte to write, DE = address to write
; This code was taken from my ALIAC-2 single board computer flash burner
; since this is pretty well tested, and just tweaked for Speccy use.
; This is designed for the Am29F040B flash chip, but should work with
; anything that's JEDEC standard
F_FlashWriteByte
      push bc
      ld c, a     ; save byte to write

      ; try to program the requested page
      ld a, 32    ; page 0 to write unlock code
      out (ROMPAGE_PORT), a

      ; Tell the flash chip we are writing a byte to it.
      ld a, #aa
      ld (#555), a
      ld a, #55
      ld (#2AA), a
      ld a, #a0
      ld (#555), a

      ; page in the page we're actually writing
      ld a, (v_page)
      out (ROMPAGE_PORT), a

      ld a, c     ; get the byte back
      ld (de), a  ; write it

WriteData.wait
		ld a, (de)	; read programmed address
		ld b, a		; save status
		xor c
		bit 7, a	; If bit 7 = 0 then bit 7 = data
		jr z, writeData.byteComplete

		bit 5, b	; test DQ5
		jr z, WriteData.wait

		ld a, (de)	; read programmed address
		xor c
		bit 7, a	; Does DQ7 = programmed data? 0 if true
		jr nz, writeData.borked

writeData.byteComplete
		pop bc
		or 0		; clear carry flag
		ret

writeData.borked
		pop bc
		scf		; error = set carry flag
		ret


; Use the Speccy rom plus a lookup table to turn a keypress (0-z)
; into an option.
F_pollkeys
      xor a
      out (ROMPAGE_PORT), a   ; page in Spectrum ROM (deassert /ROMCS)
.poll
      call #28e      ; Spectrum ROM key poll routine
      ld a, e        ; result is in E, move to A to test
      cp #ff         ; No key pressed
      jr z, .poll
      push de        ; save for later
.pollkeyup
      call #28e
      ld a, e
      cp #ff
      jr nz, .pollkeyup
      pop de
      ld hl, LK_keys ; Look up the key that was pressed
      ld d, 0
      add hl, de
      ld a, (hl)
      ret

      include "../charset.asm"
      include "../print.asm"

str_banner

  defb	AT, 0, 0, PAPER, 0, INK, 7, BRIGHT, 1, TEXTBOLD, " Diag Board Flash Utility "
  defb	TEXTNORM, PAPER, 0, INK, 2, "~", PAPER, 2, INK, 6, "~", PAPER, 6, INK, 4, "~"
  defb	PAPER, 4, INK, 5, "~", PAPER, 5, INK, 0, "~", PAPER, 0," ", ATTR, 56, 0

STR_run
  defb  AT, 2, 0, "Select ROM page to boot:", 0

STR_p1   defb "0...Page 0     1...Page 1    2...Page 2\n"
STR_p2   defb "3...Page 3     4...Page 4    5...Page 5\n"
STR_p3   defb "6...Page 6     7...Page 7    8...Page 8\n"
STR_p4   defb "9...Page 9     a...Page 10   b...Page 11\n"
STR_p5   defb "c...Page 12    d...Page 13   e...Page 14\n"
STR_p6   defb "f...Page 15    g...Page 16   h...Page 17\n"
STR_p7   defb "i...Page 18    j...Page 19   k...Page 20\n"
STR_p8   defb "l...Page 21    m...Page 22   n...Page 23\n"
STR_p9   defb "o...Page 24    p...Page 25   q...Page 26\n"
STR_p10  defb "r...Page 27    s...Page 28   t...Page 29\n"
STR_p11  defb "u...Page 30    v...Page 31\n\n",0
STR_others  defb "Other options:\n"
STR_burn defb "w...Program a 16K flash page\n"
STR_erase   defb "x...Erase a 64K flash sector\n"
;STR_cerase  defb "y...Erase entire chip\n"
STR_copy    defb "y...Copy a 16K page to RAM at 32768\n"
STR_reboot  defb "z...Exit to ZX BASIC\n", 0

STR_prog    defb "      PROGRAM A 16K FLASH PAGE\n\n"
STR_progopt defb "Press a key to program the following page:\n", 0
STR_writing defb "Writing flash chip...\n", 0

STR_copyhdr defb "      COPY A 16K FLASH PAGE TO RAM\n\n"
            defb "Press a key to copy the following page:\n", 0
STR_copying defb "Copying ROM image to address 32768...\n", 0

STR_borked  defb "Sorry, the operation failed.\n", 0
STR_done    defb "Done!\n", 0
STR_back    defb "Press z to go back\n", 0
STR_anykey  defb "Press 0-9 or a-z to exit", 0

STR_erasetxt   defb "       ERASE A 64K FLASH SECTOR\n\n"
STR_chooseerase   defb "Press 0 to 7 to choose the sector to\n"
            defb "erase, or press X to exit\n\n"
STR_eraseinfo  defb "Information: Sectors map to pages as \nfollows:\n\n"
STR_sectors defb "Sector 0  ->  Pages  0 to 3\n"
         defb  "Sector 1  ->  Pages  4 to 7\n"
         defb  "Sector 2  ->  Pages  8 to 11\n"
         defb  "Sector 3  ->  Pages 12 to 15\n"
         defb  "Sector 4  ->  Pages 16 to 19\n"
         defb  "Sector 5  ->  Pages 20 to 23\n"
         defb  "Sector 6  ->  Pages 24 to 27\n"
         defb  "Sector 7  ->  Pages 28 to 31\n\n", 0
STR_erasing defb "Erasing...\n", 0
STR_reprogramming defb "Reprogramming flash util to page 4\n", 0

STR_delp4   defb "     ERASING SECTOR 1 (PAGES 4 -> 7)\n\n"
            defb "You will delete me by deleting sector 1\n"
            defb "since I live in page 4. Press Y if you\n"
            defb "want to re-write the utility back into\n"
            defb "page 4 or N if you want to kill off the\n"
            defb "flash utility.\n"
            defb "Any other key aborts.\n\n", 0

STR_warning defb "         WARNING!\n\n", 0
STR_unused  defb "This flash page looks unused... are you really\n"
            defb "sure you want to select it? (Y/N)\n\n", 0
STR_hgn     defb "Well, OK...here goes nothing...\n",0
STR_inuse   defb "This flash page looks to be used. Trying\n"
            defb "to program it will probably fail (and may\n"
            defb "corrupt the first few bytes of the page).\n"
            defb "Continue anyway? (Y/N)\n", 0

         ; Key value lookup table. Key 0 = 0, Key Z = 35
LK_keys  defb 11, 17, 34, 6, 5, 29, 16, 31    ; 0-7
         defb 23, 19, 30, 7, 4, 27, 15, 12    ; 8-15
         defb 22, 20, 18, 8, 3, 14, 13, 33     ; 16-23
         defb 255, 21, 24, 9, 2, 32, 28, 35   ; 24-31
         defb 255, 255, 25, 0, 1, 26, 10         ; 32-38
         block $+32-$, #ff
