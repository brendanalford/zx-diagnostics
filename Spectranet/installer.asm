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
;	installer.asm
;	
;	Installer for Spectranet test modules.
;

;	Min/Maximum Spectranet ROM pages we can touch.

	define MIN_PAGE 0x04
	define MAX_PAGE 0x1F
	
	include "spectranet.asm"
	include "..\version.asm"
	
	org 0x8000
	
	call PAGEIN
	call CLEAR42
	
	ld hl, str_title
	call PRINT42
	
	call scan_flash
	ld a, (v_ok)
	cp 0
	jp nz, exit

	ld hl, v_freepages

checkmodule1

	ld a, (v_module1page)
	cp 0xff
	jr nz, module1found
	
	ld a, (hl)
	cp 0xff
	jp z, no_free_pages
	inc hl
	push hl
	push af
	ld (v_module1page), a
	ld hl, str_new_module1
	call PRINT42
	pop af
	ld hl, v_workspace
	call ITOH8
	ld hl, v_workspace
	call PRINT42
	ld hl, str_found_module_end
	call PRINT42
	pop hl	
	jr checkmodule2
	
module1found

	push hl
	ld hl, str_found_module1
	call PRINT42
	ld hl, v_workspace
	ld a, (v_module1page)
	call ITOH8
	ld hl, v_workspace
	call PRINT42
	ld hl, str_found_module_end
	call PRINT42
	pop hl

checkmodule2

	ld a, (v_module2page)
	cp 0xff
	jr nz, module2found
	
	ld a, (hl)
	cp 0xff
	jp z, no_free_pages
	inc hl
	push hl
	push af
	ld (v_module2page), a
	ld hl, str_new_module2
	call PRINT42
	pop af
	ld hl, v_workspace
	call ITOH8
	ld hl, v_workspace
	call PRINT42
	ld hl, str_found_module_end
	call PRINT42
	pop hl	
	jr continue

module2found

	push hl
	ld hl, str_found_module2
	call PRINT42
	ld hl, v_workspace
	ld a, (v_module2page)
	call ITOH8
	ld hl, v_workspace
	call PRINT42
	ld hl, str_found_module_end
	call PRINT42
	pop hl	

;	Start erasing/programming pages according to the contents of
;	v_module1page and v_module2page.

continue
	
;	Give the user one last chance to bail out

	ld hl, str_confirm
	call PRINT42
	call GETKEY
	cp 'p'
	jp nz, exit
	
	di
	
;	Lock off 128 paging. TODO: Revisit this
;	in a future release to allow the user
;	carry on as normal after an upgrade.

	ld bc, 0x7ffd
	ld a, 0x30
	out (c), a

	ld hl, str_writing1
	call PRINT42
	ld a, (v_module1page)
	ld (v_modindex), a
	ld hl, bin_module1
	ld (v_modaddr), hl
	call write_rom_page
	jr c, exit
	
	di
	ld hl, str_writing2
	call PRINT42
	ld a, (v_module2page)
	ld (v_modindex), a
	ld hl, bin_module2
	ld (v_modaddr), hl
	call write_rom_page
	jr c, exit
	
complete

	ld hl, str_done
	call PRINT42
	di
	halt
	
no_free_pages

	ld hl, str_no_free_pages
	call PRINT42
	
exit

	ei
	call PAGEOUT
	ret
	
;
;	Scans Flash ROM memory looking for module 1 and module 2 of 
;	the diagnostics, and also looks for any free pages should
;	they be needed if the diags aren't already installed
;
scan_flash

	ld hl, 0xffff
	exx
	ld de, v_freepages
	exx
	ld (v_module1page), hl
	ld (v_freepages), hl
	ld a, 0xff
	ld (v_ok), a
	ld a, MIN_PAGE
	
scan_flash_loop
	
	push af
	
;	Page in the ROM and see if it's blank (first byte 0xff)

	call SETPAGEB
	ld a, (0x2000)
	cp 0xFF
	jr z, scan_flash_blank
	
;	Not blank, see if the identity string matches module 1

match_mod1

	ld hl, (0x200E)
	ld de, str_identity1
	call string_hl_startswith_de
	jr nz, match_mod2

;	Found module 1, check if we already saw one
	ld a, (v_module1page)
	cp 0xff
	jr nz, scan_flash_duplicate
	
	pop af
	ld (v_module1page), a
	push af
	jr scan_flash_next

;	No match, see if the identity string matches module 2
	
match_mod2

	ld hl, (0x200E)
	ld de, str_identity2
	call string_hl_startswith_de
	jr nz, scan_flash_next
	
;	Found module 2, check if we already saw one
	ld a, (v_module2page)
	cp 0xff
	jr nz, scan_flash_duplicate
	
	pop af
	ld (v_module2page), a
	push af
	jr scan_flash_next
	
;	ROM page is blank, mark it as available if we need to install from scratch

scan_flash_blank

	exx
	pop af
	ld (de), a
	inc de
	push af
	exx

;	Keep checking until last page is reached
;	Page 1F is reserved so exit when that's hit.

scan_flash_next

	pop af
	inc a
	cp MAX_PAGE
	jr nz, scan_flash_loop
	
	xor a
	ld (v_ok), a
	
	ret

;	More than one of a particular module was found.
;	Tell the user to clean up their mess before 
;	rerunning.
scan_flash_duplicate
	
	pop af
	ld hl, str_duplicate
	call PRINT42
	ret
	
string_hl_startswith_de

	ld a, (de)
	cp (hl)
	ret nz
	inc de
	inc hl
	ld a, (de)
	cp 0
	ret z

	jr string_hl_startswith_de
	
str_title

	defb "ZX Diagnostics ", VERSION, " Spectranet Installer\n\n", 0
	
str_confirm

	defb "\nPress P to install, any other key aborts\n\n", 0
	
str_identity1

	defb "ZX Diagnostics Module 1", 0 

str_identity2

	defb "ZX Diagnostics Module 2", 0 
	
str_found_module1

	defb "Module 1: present, slot:    [", 0
	
str_found_module2

	defb "Module 2: present, slot:    [", 0
	
str_new_module1
	
	defb "Module 1: new, target slot: [", 0

str_new_module2

	defb "Module 2: new, target slot: [", 0

str_found_module_end

	defb "]\n", 0

str_writing1

	defb "Writing module 1...\n", 0

str_writing2

	defb "Writing module 2...\n", 0

str_no_free_pages

	defb "ERROR: Not enough free pages to complete\nthe install, exiting.", 0 
	
str_duplicate

	defb "ERROR: Duplicate modules found. Delete\nthese duplicates via the ROM manager\nbefore retrying. Exiting.\n", 0

str_done

	defb "\nComplete. Please reset your machine.", 0
	
	include "flash_functions.asm"
	
bin_module1

	incbin "testmodule1.module"

bin_module2

	incbin "testmodule2.module"
	
v_module1page	equ 0xff00		; Address of module 1 in flash or 0xFF if not found
v_module2page	equ 0xff01		; Address of module 2 in flash of 0xFF if not found
v_ok			equ 0xff02		; Module check pass if 0
v_modaddr		equ 0xff03		; Address of module to copy
v_modindex		equ 0xff05		; ROM index of module to write to
v_freepages		equ 0xff06		; Indexes of first free page or 0xFF if non
v_workspace		equ 0xff80		; General workspace
