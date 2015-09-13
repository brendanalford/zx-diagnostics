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
;	flash_functions.asm
;	
;	Flash utilities for Spectranet test modules.
;	Heavily borrowed from ZXGuesser and Winston's code.
;

;
;	Writes a given ROM page. This is entered as follows:
;	v_modaddr contains the start address in main RAM of the module to write
;	v_modindex contains its desired index
;	This routine loops through all sectors (32 / 4 = 8) and
;	detects if it needs to write a module to this specific sector.
;	If so, it backs up the sectors to Spectranet SRAM (replacing the target)
;	page as it goes, then erases the sector, and rewrites the lot.
;	I imagine I'll be using the restore functionality a lot :)
;
write_rom_page

;	We need to write to this page within this sector.
;	Step back to v_modindex mod 4 for a full sector,
;	then back it up page by page to SRAM, except if 
; 	the current page matches our target, then take it instead.

	ld a, (v_modindex)
	and 0xfc
	ld b, a
	
;	Start with page 0xDC of SRAM

	ld c, 0xdc

copy_to_sram_loop

	ld a, c
	push bc
	call SETPAGEB
	pop bc
	ld a, b
	push bc
	call SETPAGEA
	pop bc
	
;	Is our page current?

	ld a, (v_modindex)
	cp b
	jr nz, copy_rom_to_sram
	
;	Yes, copy the 4K block at v_modaddr to SRAM

	push hl
	push de
	push bc
	ld hl, (v_modaddr)
	ld de, 0x2000
	ld bc, 0x1000
	ldir
	pop bc
	pop de
	pop hl
	jr copy_to_sram_next

;	No, just copy this page from Flash to SRAM

copy_rom_to_sram
	
	push hl
	push de
	push bc
	ld hl, 0x1000
	ld de, 0x2000
	ld bc, 0x1000
	ldir
	pop bc
	pop de
	pop hl
	
copy_to_sram_next

	inc b
	inc c
	ld a, c
	cp 0xe0
	jr nz, copy_to_sram_loop
	
;	At this point, we have a full sector backed up to SRAM.
;	Now erase its target sector.

	ld a, 2
	out (0xfe), a
	
	ld a, (v_modindex)
	and 0xfc
	
	push bc
	di
	call F_FlashEraseSector
	pop bc
	jr c, write_page_erase_error

	ld a, (v_modindex)
	and 0xfc

	di
	call F_writesector
	jr c, write_page_write_error
	
	ld a, 1
	out (0xfe), a
	
;	Our work here is done.
	ret
	
write_page_erase_error

	ld hl, str_eraseerror
	jr write_page_giveup
	
write_page_write_error
	
	ld hl, str_writeerror
	
write_page_giveup
		
	ld a, 1
	out (0xfe), a
	CALL PRINT42
	scf
	ret
	
	
;---------------------------------------------------------------------------
; F_FlashEraseSector
; Simple flash writer for the Am29F010 (and probably any 1 megabit flash
; with 16kbyte sectors)
;
; Parameters: A = page to erase (based on 4k Spectranet pages, but
; erases a 16k sector)
; Carry flag is set if an error occurs.
F_FlashEraseSector: 

        ; Page in the appropriate sector first 4k into page area B.
        ; Page to start the erase from is in A.
        call SETPAGEA 	; page into page area B

        ld a, 0xAA      ; unlock code 1
        ld (0x555), a   ; unlock addr 1
        ld a, 0x55      ; unlock code 2
        ld (0x2AA), a   ; unlock addr 2
        ld a, 0x80      ; erase cmd 1
        ld (0x555), a   ; erase cmd addr 1
        ld a, 0xAA      ; erase cmd 2
        ld (0x555), a   ; erase cmd addr 2
        ld a, 0x55      ; erase cmd 3
        ld (0x2AA), a   ; erase cmd addr 3
        ld a, 0x30      ; erase cmd 4
        ld (0x1000), a  ; erase sector address

        ld hl, 0x1000
.wait1: 
        bit 7, (hl)     ; test DQ7 - should be 1 when complete
        jr nz,  .complete1
        bit 5, (hl)     ; test DQ5 - should be 1 to continue
        jr z,  .wait1
        bit 7, (hl)     ; test DQ7 again
        jr z,  .borked1

.complete1: 
        or 0            ; clear carry flag
        ret

.borked1: 
        scf             ; carry flag = error
        ret

;---------------------------------------------------------------------------
; F_FlashWriteByte
; Writes a single byte to the flash memory.
; Parameters: DE = address to write
;              A = byte to write
; On return, carry flag set = error
; Page the appropriate flash area into one of the paging areas to write to
; it, and the address should be in that address space.
F_FlashWriteByte: 
        push bc
        ld c, a         ; save A

        ld a, 0xAA      ; unlock 1
        ld (0x555), a   ; unlock address 1
        ld a, 0x55      ; unlock 2
        ld (0x2AA), a   ; unlock address 2
        ld a, 0xA0      ; Program
        ld (0x555), a   ; Program address
        ld a, c         ; retrieve A
        ld (de), a      ; program it

;		Do border stripes depending on the content being written

		cpl
		and 0x7
		out (0xfe), a

.wait3: 
        ld a, (de)      ; read programmed address
        ld b, a         ; save status
        xor c           
        bit 7, a        ; If bit 7 = 0 then bit 7 = data        
        jr z,  .byteComplete3

        bit 5, b        ; test DQ5
        jr z,  .wait3

        ld a, (de)      ; read programmed address
        xor c           
        bit 7, a        ; Does DQ7 = programmed data? 0 if true
        jr nz,  .borked3

.byteComplete3: 
        pop bc
        or 0            ; clear carry flag
        ret

.borked3: 
	
	push de
	ld hl, str_byteverifyfail
	call PRINT42
	pop de
	push de
	ld a, d
	ld hl, v_workspace
	call ITOH8
	ld hl, v_workspace
	call PRINT42
	pop de
	push de
	ld a, e
	ld hl, v_workspace
	call ITOH8
	ld hl, v_workspace
	call PRINT42
	ld a, '\n'
	call PUTCHAR42
	pop de
    pop bc
    scf             ; error = set carry flag
    ret

;---------------------------------------------------------------------------
; F_FlashWriteBlock
; Copies a block of memory to flash. The flash should be mapped into
; page area B.
; Parameters: HL = source start address
;             DE = destination start address
;             BC = number of bytes to copy
; On error, the carry flag is set.
F_FlashWriteBlock: 
        ld a, (hl)      ; get byte to write
        call F_FlashWriteByte
        ret c           ; on error, return immediately
        inc hl          ; point at next source address
        inc de          ; point at next destination address
        dec bc          ; decrement byte count
        ld a, b
        or c            ; is it zero?
        jr nz, F_FlashWriteBlock
        ret

		
;---------------------------------------------------------------------------
; F_writesector
; Writes 4 pages from the last 4 pages of RAM to flash, starting at the
; page specified in A
F_writesector: 
        ex af, af'      ; swap with alternate set
        ld a, 0xDC      ; RAM page 0xDC
        ld b, 4         ; number of pages
.loop4: 
        push bc
        call SETPAGEB ; Page RAM into area B
        inc a           ; next page
        ex af, af'      ; get flash page to program
        call SETPAGEA	; into page A
        inc a           ; next page
        ex af, af'      ; back to ram page for next iteration
        ld hl, 0x2000
        ld de, 0x1000
        ld bc, 0x1000
        push af
        call F_FlashWriteBlock
        jr c,  .failed4 ; restore stack and exit
        pop af
        pop bc
        djnz  .loop4    ; next page
		or 0
        ret
.failed4:               ; restore stack, set carry flag
		ex af, af'
		ld hl, v_workspace
		call ITOH8
		ex af, af'
		ld hl, str_sectorfail
		call PRINT42
		ld hl, v_workspace
		call PRINT42
		ld a, '\n'
		CALL PUTCHAR42
		
        pop af
		ld hl, v_workspace
		call ITOH8
		ld hl, str_sectorramfail
		call PRINT42
		ld hl, v_workspace
		call PRINT42
		ld a, '\n'
		call PUTCHAR42
        pop bc
        scf
        ret
		
str_byteverifyfail

	defb "\nProgrammed byte failed verification\nat address: ", 0
	
str_sectorfail

	defb "\nFailed writing ROM page: ", 0

str_sectorramfail

	defb "\nSource SRAM page: ", 0
		
str_eraseerror

	defb "\nError erasing Flash sector, aborting.\n",0
	
str_writeerror

	defb "\nError writing Flash sector, aborting.\n",0
	

