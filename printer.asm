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
;	printer.asm
;

;
; Routines for printing to the ZX Printer and compatibles.
;

    define PRINTER_PORT   0xfb

lprint_screen

; Copy 192 lines, starting from start of display

    ld b, 192
    ld hl, 0x4000

;
; Entry point lprint_line - call with address of start line in HL,
; number of rows to print in B
;
lprint_line

    di
    in a, (PRINTER_PORT)

; Check for printer present

    bit 6, a
    jp nz, lpcopy_error

    bit 7, a
    jp nz, lpcopy_error

lprint_loop;  copy-1

    push hl
    push bc       ; Save screen address and line counter

; now enter a loop to handle each pixel line.

    call lprint_row

    pop bc
    pop hl

    inc h
    ld a, h

    ; Have we left the current third of the screen

    and 0x7
    jr nz, lprint_loop_2;  (copy-2)

    ; Yes, readjust for next third

    ld a, l
    add a, 0x20
    ld l, a
    ccf
    sbc a
    and 0xf8
    add a, h
    ld h, a

lprint_loop_2

    djnz lprint_loop

    ld a, 0x04
    out (PRINTER_PORT), a
    ei
    ret

;
; Prints a 256x1 line from the printer buffer pointed to by HL.
;
lprint_row

    ld a, b
    cp 0x03
    sbc a
    and 0x20
    out (PRINTER_PORT), a
    ld d, a

lprint_row_1

    in a, (PRINTER_PORT)
    add a, a
    jr nc, lprint_row_1          ; Loop if stylus isn't in position

    ld c, 0x20                    ; 32 bytes in line

lprint_row_2

    ld e, (hl)
    inc hl
    ld b, 0x8

lprint_row_3

    rl d
    rl e
    rr d

lprint_row_4

    in a, (PRINTER_PORT)
    rra
    jr nc, lprint_row_4          ; Loop if stylus not in position

    ld a, d
    out (PRINTER_PORT), a
    djnz lprint_row_3

    dec c
    jr nz, lprint_row_2
    ret

;
; Called if printer is not present, or is out of paper.
; Beeps, then exits.
;
lpcopy_error

    ld l, 7
    ld bc, 0x0100
    ld de, 0x0100
    call beep
    ei
    ret
