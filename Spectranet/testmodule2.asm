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
;	testrom.asm
;

;
;	Spectrum Diagnostics - Spectranet ROM Module 2 of 2
;
;	v0.1 by Dylan 'Winston' Smith
;	v0.2 modifications and 128K testing by Brendan Alford.
;
;	Despite being the second module, this is actually the primary point of 
;	entry for the diagnostics - reason being that module 1 must have been 
;	loaded successfully before module 2 can access anything in it.
;	If we lead from the first module and start executing tests, we cannot
;	call anything in the second module via MODULECALL as it hasn't been
;	loaded yet!

	include "..\defines.asm"
	include "..\version.asm"
	include "spectranet.asm"
	
CALLBAS equ 0x0010
ZXNEWLINE equ 0x0D	; ZX print routine newline
	
; store variables within spectranet's buf_workspace area
stringbuffer equ 0x3D00	; reserve 256 bytes for a buffer
v_sockfd equ 0x3E00
v_connfd equ 0x3E01
netflag equ 0x3E02

	LUA ALLPASS
	sj.insert_define("BUILD_TIMESTAMP", '"' .. os.date("%d/%m/%Y %H:%M:%S") .. '"');
	ENDLUA
	
	org 0x2000

;	Spectranet ROM Module table

	defb 0xAA			; Code module
	defb 0xBB			; ROM identity - needs to change
	defw initroutine	; Address of reset vector
	defw 0xffff			; Mount vector - unused
	defw 0xffff			; Reserved
	defw 0xffff			; Address of NMI Routine
	defw 0xffff			; Address of NMI Menu string
	defw 0xffff			; Reserved
	defw str_identity	; Identity string

	ret                 ; this module doesn't need to service modulecalls

initroutine

	call test_cmd		; install basic extension

; 	see if the user's pressing 't' to initiate testing

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
	ret

;
;	Lower RAM tests completed successfully.
;
tests_done
	
	ld hl, str_16kpassed
	call outputstring

;	Perform some ROM checksum testing to determine what
;	model we're running on

; 	Assume 128K toastrack (so far)

	xor a 
	ld (v_128type), a    
	
	ld hl, str_romcrc
    call outputstring

;	Copy the checksum code into RAM

	ld hl, start_romcrc
	ld de, do_romcrc
	ld bc, end_romcrc-start_romcrc
	ldir
	
;	Checksum the ROM

	call do_romcrc

;	Save it in DE temporarily
	
	ld de, hl
	ld hl, rom_signature_table
		
; 	Check for a matching ROM

rom_check_loop

;	Check for 0000 end marker

	ld bc, (hl)
	ld a, b
	or c
	jr z, rom_unknown
	
;	Check saved ROM CRC in DE against value in table
	
	ld a, d
	xor b
	jr nz, rom_check_next
	ld a, e
	xor c
	
	jr z, rom_check_found

rom_check_next

	ld bc, 6
	add hl, bc
	jr rom_check_loop

; Unknown ROM, say so and prompt the user for manual selection

rom_unknown

	push de
	ld hl, str_romunknown
	call outputstring
	pop hl
    ld de, v_hexstr
    call Num2Hex
    xor a
    ld (v_hexstr+4), a
    ld hl, v_hexstr
    call outputstring

;	Run 48K tests by default
	ld hl, test_48k
	jr call_test_routine
	
rom_check_found

;	Print the appropriate ROM type to screen

	push hl
	inc hl
	inc hl
	ld de, (hl)
	ld hl, de

	call outputstring
	ld hl, str_testpass
	call outputstring
	pop hl

;	Call the appropriate testing routine

	ld de, 4
	add hl, de
	
call_test_routine

	ld (v_test_rtn), hl
	
	ld hl, 0xBA00
	rst MODULECALL_NOPAGE
	
;	return to here from modulecall
	jr c, modulecallerror
	
	ld a, (v_connfd)
	call CLOSE			; close the connection
	jp closesocket		; close our socket and return
	
modulecallerror
;	Module 2 was not called successfully.
	ld hl, str_modulefail
	call outputstring
	call waitkey
	ret

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
	ret

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

outputstring
	ld a,(netflag)
	cp 0
	jr nz, outputstringnet
	call PRINT42
	ret
outputstringnet
	call strlen
	ld b,0
	ld c,a		; bc = length of string
dosendstring
	ex hl,de	; de = string address
	ld a, (v_connfd)
	call SEND
	;todo: error checking
	ret

outputchar
	ld b,a
	ld a,(netflag)
	cp 0
	jr nz, outputcharnet
	ld a,b
	call PUTCHAR42
	ret
outputcharnet
	ld hl, stringbuffer+1
	ld (hl),0
	dec hl
	ld (hl),b
	ld bc, 2
	jr dosendstring

waitkey
	ld a,(netflag)
	cp 0
	jr nz, waitkeynet
	call GETKEY
	ret
waitkeynet
	;todo: implement this
	ret

; String length returned in A for the string at HL
; don't call this on really long or unterminated strings...
strlen
	push hl
	xor a
	ld bc, 0x100
	cpir
	ld a, c
	cpl
	pop hl
	ret

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

	
;
;	Prints a 16-bit hex number to the buffer pointed to by DE.
;	Inputs: HL=number to print.
;

Num2Hex

	ld	a,h
	call	Num1
	ld	a,h
	call	Num2

;	Call here for a single byte conversion to hex

Byte2Hex

	ld	a,l
	call	Num1
	ld	a,l
	jr	Num2

Num1

	rra
	rra
	rra
	rra

Num2

	or	0xF0
	daa
	add	a,#A0
	adc	a,#40

	ld	(de),a
	inc	de
	ret

;
;	Routine to calculate the checksum of the 
;	currently installed ROM.
;
start_romcrc

;	Unpage the Spectranet
	call 0x007c
	
	ld de, 0
	ld hl,0xFFFF
	
Read
	
	ld a, (de)
	inc	de
	xor	h
	ld	h,a
	ld	b,8
	
CrcByte
    
	add	hl, hl
	jr	nc, Next
	ld	a,h
	xor	10h
	ld	h,a
	ld	a,l
	xor	21h
	ld	l,a
	
Next	
	
	djnz	CrcByte
	ld a, d
	cp 0x40     ; 0x4000 = end of rom
	jr	nz,Read
	
	push hl
	pop bc
	
;	Restore Spectranet ROM/RAM

	call 0x3ff9
	ret	   
	
end_romcrc
	
	include "..\romtables.asm"

test_48k
test_128k
test_plus2
test_plus3
test_48kgeneric
test_js128
	
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

str_cmd_fail

	defb "Failed to add BASIC extension\n", 0
	
str_identity

	defb "ZX Diagnostics ", VERSION, " [2/2]", 0 
	
str_version

	defb "ZX Diagnostics ", VERSION, ZXNEWLINE
	defb "B. Alford, D. Smith", ZXNEWLINE
	defb "http://git.io/vkf1o", ZXNEWLINE, ZXNEWLINE
	defb "Installer and Spectranet code", ZXNEWLINE
	defb "by ZXGuesser", ZXNEWLINE, ZXNEWLINE
	defb "Build: ", BUILD_TIMESTAMP, ZXNEWLINE, 0
	
str_press_t

	defb "\nZX-Diagnostics: Press T to initiate tests\n", 0
	
str_not_testing

	defb "Not running tests.\n\n", 0
	
str_testpass

	defb "PASS", 0
	
str_testfail

	defb "FAIL", 0
	
str_16kpassed

	defb "Lower/Page 5 RAM tests passed.\n", 0
	
str_16kfailed

	defb "Lower/Page 5 RAM tests failed!\n", 0
	
str_romcrc	

	defb	"\nChecking ROM version...", 0

str_romunknown

	defb "Unknown or corrupt ROM\n", 0

str_failedbits

	defb "Failed bit locations: ", 0

str_waiting

	defb "Waiting for connection\nPress L for local output\n", 0
	
str_pressanykey

	defb "Press any key to continue.\n\n", 0
	
str_modulefail

	defb "FATAL: Error calling ROM module", 0

str_sockerror

	defb "FATAL: Socket error",0
	
	BLOCK 0x2fff-$, 0xff
	
do_romcrc		equ #7e00;	Location in RAM to run ROM CRC test routine from

;	Testing variables

v_stacktmp		equ #7fb0; Temporary stack location when calling routines that assume no lower ram
v_curpage		equ #7fb2; Currently paged location
v_paging		equ #7fb3; Bank Paging status (output)
v_fail_ic		equ #7fb6; Failed IC bitmap (48K)
v_fail_ic_uncontend	equ #7fb7; Failed IC bitmap, uncontended memory banks 0,2,4,8 (128k)
v_fail_ic_contend	equ #7fb8; Failed IC bitmap, contended memory banks 1,3,5,7 (128k)
v_128type		equ #7fb9; 0 - 128K toastrack, 1 - grey +2, 2 - +2A or +3
v_test_rtn		equ #7fba;	Address of test routine for extra memory (48/128)
v_keybuffer		equ #7fbc; Keyboard bitmap (8 bytes)
v_rand_addr		equ #7fbe;	Random fill test base addr
v_rand_seed		equ #7fc0;	Random fill test rand seed
v_rand_reps		equ #7fc2;	Random fill test repetitions
v_hexstr		equ #7fc4; Workspace for Num2Hex routine
