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

;
;	Spectrum Diagnostics - Spectranet ROM Module Part 1 of 2
;
;	v0.1 by Dylan 'Winston' Smith
;	v0.2 modifications and 128K testing by Brendan Alford.
;
;	This is the main module for the diagnostics program. It is run at
;	boot and installs a BASIC extension with version information then
;	locates the second module (containing most of the tests) to be
;	paged in at 0x1000.

	include "vars.asm"
	include "..\defines.asm"
	include "..\version.asm"
	include "spectranet.asm"
	
	LUA ALLPASS
	sj.insert_define("BUILD_TIMESTAMP", '"' .. os.date("%d/%m/%Y %H:%M:%S") .. '"');
	ENDLUA
	
	org 0x2000

;	Spectranet ROM Module table

	defb 0xAA			; Code module
	defb 0x00			; No ROM ID
	defw initroutine	; Address of reset vector
	defw 0xffff			; Mount vector - unused
	defw 0xffff			; Reserved
	defw 0xffff			; Address of NMI Routine
	defw 0xffff			; Address of NMI Menu string
	defw 0xffff			; Reserved
	defw str_identity	; Identity string

ident_string_check
	; compare start of ident string with ours
	push bc
	ld bc, 22			; bytes to compare
	ld hl, str_identity	; the ident string in this rom
	ld de, (0x100E)		; module's string address when in page B
	ld a,d
	sub 0x10
	ld d,a				; subtract 0x1000 because it is in page A
cp_loop
	ld a, (de)
	inc de
	cpi
	jr nz, break		; if z not set break out and return
	jp po, check_number	; if bc overflowed we matched all the bytes
	jr cp_loop

check_number
	ld a,(de)			; read next byte of ident string
	cp '2'				; is this "ZX Diagnostics Module 2"
break
	pop bc
	ret


find_tests_module
	ld b,1				; start with page 2
findmoduleloop
	inc b
	ld a, 0x1F
	cp b				; last ROM?
	jr z, module_not_found
	
	ld a,b
	call SETPAGEA		; page module into bank A
	ld a, (0x1000)
	cp 0xAA				; is a code module?
	jr nz, findmoduleloop
	
	call ident_string_check

	jr nz, findmoduleloop
	
	or 1                ; clear z flag
	ret
	
module_not_found
	ld hl, str_zx_diagnostics
	call PRINT42
	ld hl, str_no_tests_module
	call PRINT42
	xor a
	ret

initroutine
	call test_cmd		; install basic extension
	
	call find_tests_module
	ret z				; missing
	
;	tests module is now paged in page A

;	see if the user's pressing 't' to initiate testing

	ld hl, str_zx_diagnostics
	call PRINT42
	ld hl, str_press_t
	call PRINT42
	
	ld bc, 0xffff
	
press_t_loop

	push bc
	ld bc, 0xfbfe
	in a, (c)
	pop bc
	bit 4, a
	jr z, run_tests
	dec bc
	ld a, b
	or c
	jr nz, press_t_loop
	
;	T not pressed, exit and allow other ROMs to init

	ld hl, str_not_testing
	call PRINT42
	ret

run_tests

;	Sound a brief tone to indicate tests are starting.
;	This also verifies that the CPU and ULA are working.

	ld l, 1				; Border colour to preserve
	BEEP 0x48, 0x0300

	ld hl, str_waiting
	call PRINT42
	call waitforconnection
	ret c				; fatal error
	
	ld hl, str_start_tests
	call outputstring
	
start_beep

	;	Blank the screen, (and all lower RAM)
	BLANKMEM 16384, 16384, 0

	ld l, 1				; Border colour to preserve
	BEEP 0x23, 0x0150

start_testing
	
	ld iy, 0
	add iy, sp
	
	ld ix, 0
	
;	Blue border - signal no errors (yet)

	ld a, BORDERGRN
	out (ULA_PORT), a

;	Same for LED's - all off signifies no errors

	xor a
	out (LED_PORT), a

;	Set all RAM to zero.

	BLANKMEM 16384, 49152, 0

;	Start lower RAM 'walking bit' test

lowerram_walk

    WALKLOOP 16384,16384

;	Then the inversion test

lowerram_inversion

    ALTPATA 16384, 16384, 0
    ALTPATA 16384, 16384, 255
    ALTPATB 16384, 16384, 0
    ALTPATB 16384, 16384, 255

lowerram_march

	MARCHTEST 16384, 16384

;	Lastly the Random fill test

lowerram_random

    RANDFILLUP 16384, 8192, 11
    RANDFILLDOWN 32766, 8191, 17

;	This gives the opportunity to visually see what's happening in
;	lower memory in case there is a problem with it.
;	Conveniently, if there's some lower RAM, then this'll give us
;	a pattern to lock onto with the floating bus sync test.

    BLANKMEM 16384, 6144, 0

;	Attributes - white screen, blank ink.

	BLANKMEM 22528, 768, 56

; 	Restore machine stack, and clear screen

	ld sp, iy
	call CLEAR42
	
;	Check if lower ram tests passed

    ld a, ixh
    cp 0
    jp z, tests_done

;	Lower memory is no good, give up now.

	ld hl, str_16kfailed
	call outputstring
	ld hl, str_failedbits
	call outputstring
	
	ld c, ixh
	ld b, 0
	
fail_loop
	bit 0, c
	jr z, fail_next
	
	ld a, b
	add '0'
	push bc
	call outputchar
	ld a, ' '
	call outputchar
	pop bc
	
fail_next

	rr c
	inc b
	ld a, b
	cp 8
	jr nz, fail_loop
	
	ld a, '\r'
	call outputchar
	ld a, '\n'
	call outputchar
	
	
;
;	Paint RAM FAIL message. This routine is borrowed from the 
;	main diagnostics ROM.
;	

	ld hl, 0x5880
	ld de, 0x5881
	ld bc, 0x1ff
	ld (hl), 9
	ldir

	ld hl, fail_ram_bitmap
	ld de, 0x5880
	ld b, 0x40

fail_msg_loop

	ld c, 8
	ld a, (hl)

fail_msg_byte

	bit 7, a
	jr z, fail_msg_next

	ex de, hl
	ld (hl), 0x7f
	ex de, hl

fail_msg_next

	inc de
	rla
	dec c
	jr nz, fail_msg_byte

	inc hl
	dec b
	jr nz, fail_msg_loop
	
	
;	Blank out the working RAM digits

	ld hl, 0x5980
	ld c, ixh

	ld d, 8
	
fail_bits_outer_loop

	ld b, 8
	
fail_bits_loop

	bit 0, c
	jr nz, fail_bits_ok
	ld a, 8
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	jr fail_bits_next
	
fail_bits_ok

	inc hl
	inc hl
	inc hl
	inc hl
	
fail_bits_next

	rrc c
	djnz fail_bits_loop
	
	dec d
	ld a, d
	cp 0
	jr nz, fail_bits_outer_loop
	
;	Wait for a key, then exit.

	ld hl, str_pressanykey
	call outputstring
	call waitkey
	
	jp exitcleanly

;
;	Lower RAM tests completed successfully.
;
tests_done
	
	ld hl, str_16kpassed
	call outputstring

;
;	Module 1 will ID the ROM and perform the appropriate tests.
;	
	
	call 0x1010			; module_2_entrypoint
	
	ld hl, str_pressanykey
	call outputstring
	call waitkey
	
	jp exitcleanly

exitcleanly
	ld a,(netflag)
	cp 0
	ret z				; no sockets to close, return
	
	ld a, (v_connfd)
	call CLOSE			; close the connection
	jp closesocket		; close our socket and return

;
;	wait for an incoming connection or the user to press L
;
waitforconnection

;	Module 1 was not called successfully.
	ld c, SOCK_STREAM	; open a TCP socket
	call SOCKET
	jp c, sockerror
	ld (v_sockfd), a	; save the socket
	ld de, 23			; bind it to the telnet port
	call BIND
	jp c, sockerror
	ld a, (v_sockfd)
	call LISTEN
	jp c, sockerror
	
acceptloop
	ld bc, 0xBFFE
	in a,(c)
	bit 1, a
	jr z, uselocal		; user pressed L so forget network stuff
	ld a, (v_sockfd)
	call POLLFD			; poll our socket
	jr z, acceptloop	; socket is not ready
	ld a, (v_sockfd)
	call ACCEPT
	jp c, sockerrorclose
	ld (v_connfd),a		; save connection descriptor
	ld a,1
	ld (netflag), a		; use network ui
	ld hl, str_connected_1
	call outputstringnet
	ld hl, str_zx_diagnostics
	call outputstringnet
	ld hl, str_connected_2
	jp outputstringnet

uselocal
	xor a
	ld (netflag), a		; use local ui
closesocket
	ld a, (v_sockfd)
	call CLOSE
	jp c, sockerror
	ret
	
sockerrorclose
	ld a, (v_sockfd)
	call CLOSE
sockerror
	ld hl, str_sockerror
	call PRINT42
	call GETKEY
	scf
	ret

	include "output.asm"

;
;	Implementation of the '%zxdiags' basic extension
;	
test_cmd

	ld hl, parsetable
	call ADDBASICEXT
	ret nc
	ld hl, str_cmd_fail
	call PRINT42
	ret
	
parsetable

	defb 0x0b
	defw test_cmd_string
	defb 0xff
	defw print_version
	
print_version

	call STATEMENT_END
	
	rst CALLBAS
	defw 0x0D6B	; CLS
	
	rst CALLBAS
	defw 0x1642	; Channel S

	ld hl, str_zx_diagnostics
	call zx_print
	ld hl, str_version
	call zx_print

	jp EXIT_SUCCESS

zx_print
	ld a, (hl)
	and a
	ret z
	rst CALLBAS
	defw 0x10	; print character using ROM routine
	inc hl
	jr zx_print

		
test_cmd_string

	defb "%zxdiags", 0
	
fail_ram_bitmap

	defb %00000000, %00000000, %00000000, %00000000
	defb %01100010, %01010000, %11100100, %11101000
	defb %01010101, %01110000, %10001010, %01001000
	defb %01010101, %01110000, %11001010, %01001000
	defb %01100111, %01010000, %10001110, %01001000
	defb %01010101, %01010000, %10001010, %01001000
	defb %01010101, %01010000, %10001010, %11101110
	defb %00000000, %00000000, %00000000, %00000000
	
	defb %00000000, %00000000, %00000000, %00000000
	defb %01000100, %01001110, %00101110, %01101110
	defb %10101100, %10100010, %10101000, %10000010
	defb %10100100, %00100100, %10100100, %11000100
	defb %10100100, %01000010, %11100010, %10100100
	defb %10100100, %10001010, %00101010, %10101000
	defb %01001110, %11100100, %00100100, %01001000
	defb %00000000, %00000000, %00000000, %00000000	

;
;	Text strings
;

str_no_tests_module

	defb " Module 2 not found.\n", 0

str_cmd_fail

	defb "Failed to add BASIC extension\n", 0
	
str_zx_diagnostics
	defb "ZX Diagnostics", 0
	
str_identity

	defb "ZX Diagnostics Module 1 ", VERSION, 0 
	
str_version

	defb " ", VERSION, ZXNEWLINE
	defb "B. Alford, D. Smith", ZXNEWLINE
	defb "http://git.io/vkf1o", ZXNEWLINE, ZXNEWLINE
	defb "Installer and Spectranet code", ZXNEWLINE
	defb "by ZXGuesser", ZXNEWLINE, ZXNEWLINE
	defb "Build: ", BUILD_TIMESTAMP, ZXNEWLINE, 0
	
str_press_t

	defb ": Press T to initiate tests\n", 0
	
str_not_testing

	defb "Not running tests.\n", 0
	
str_testpass

	defb "PASS", 0
	
str_testfail

	defb "FAIL", 0
	
str_commence_tests

	defb "Press any key to commence RAM tests.\r\n", 0
	
str_16kpassed

	defb "Lower/Page 5 RAM tests passed.\r\n", 0
	
str_16kfailed

	defb "Lower/Page 5 RAM tests failed!\r\n", 0

str_failedbits

	defb "Failed bit locations: ", 0

str_waiting

	defb "Waiting for connection\nPress L for local output\n", 0

str_connected_1

	defb 0x1B,"[2J",0x1B,"[H",0
	
str_connected_2

	defb " ", VERSION, " "
	defb 0x1B, "[101m ", 0x1B, "[103m ", 0x1B, "[102m ", 0x1B, "[106m ", 0x1B, "[40m "
	defb "\r\nConnection established\r\n\r\n", 0
	
str_start_tests

	defb "Running Lower/Page 5 RAM tests\r\n",0

str_pressanykey

	defb "Press enter key to continue.\r\n", 0

str_sockerror

	defb "FATAL: Socket error",0
	
	BLOCK 0x2fff-$, 0xff

