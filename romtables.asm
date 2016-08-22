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
;	romtables.asm
;

;
;	Table to define ROM signatures.
;	Format is initial ROM checksum (ROM 0 in 128 machines),
;	identification string, upper RAM test routine location
;	and address of further ROM test table (0000 if 48K machine)
;

rom_signature_table

	defw 0x44e2, str_rom48k, test_48k, 0x0000
	defw 0x5eb1, str_rom48kesp, test_48k, 0x0000
	defw 0x62c7, str_rom128k, test_128k, rom_table_rom128k
	defw 0xdbaa, str_romplus2, test_plus2, rom_table_romplus2
	defw 0x26f5, str_romplus2a, test_plus3,	rom_table_romplus2a
	defw 0x1f83, str_romplus3, test_plus3, rom_table_romplus3

	defw 0xe157, str_rom128espv1, test_128k, rom_table_rom128espv1
	defw 0x7a1f, str_rom128espv2, test_128k, rom_table_rom128espv2
	defw 0xc563, str_romplus2esp, test_plus2, rom_table_romplus2esp
	defw 0xda64, str_romplus2fra, test_plus2, rom_table_romplus2fra

	defw 0x95b8, str_romplus3espv40, test_plus3, rom_table_romplus3espv40
	defw 0x29c0, str_romplus3espv41, test_plus3, rom_table_romplus3espv41

	IFNDEF SAVEMEM

; Spectrum 128 Derby 1.4 ROM (Development machine)

  defw 0x5129, str_rom128derby14, test_128k, rom_table_rom128derby14

;	Some +3E ROM sets that might be out there

	defw 0xdba9, str_romplus3e_v1_38, test_plus3, rom_table_romplus3e_v1_38
	defw 0x3710, str_romplus3e_v1_38esp, test_plus3, rom_table_romplus3e_v1_38esp

;	Soviet clones that some people are inexplicably fond of :)

	defw 0x26f0, str_orelbk08, test_48kgeneric, 0x0000

;	Just Speccy 128 clone

	defw 0xee67, str_js128, test_js128, rom_table_js128

;	Harlequin Rev F

	defw 0xe56c, str_harlequin_f, test_48kgeneric, 0x0000

;	Beckman 48K

	defw 0x870c, str_rom48kbeckman, test_48k, 0x0000

; 	Gosh Wonderful ROM (assume 48K)

	defw 0x8116, str_rom48gw03, test_48k, 0x0000

	ENDIF

;	End of ROM table
	defw 0x0000

;
;	Tables specifying rest of checksums for a particular machine.
;	Format starts with checksum for ROM 1, fail IC designation,
;	and continues with checksum for further ROMS, or 0000 if no
;	more ROMs are expected.
;

rom_table_rom128k

	defw	0xbe09, str_rom128_fail, 0x0000

rom_table_romplus2

	defw	0x27f9, str_romplus2_fail, 0x0000

rom_table_romplus2a

	defw	0x4d5b, str_romplus3_a_fail, 0xb3e4, str_romplus3_b_fail, 0x5d75, str_romplus3_b_fail, 0x0000

rom_table_romplus3

	defw	0x4e7b, str_romplus3_a_fail, 0x3388, str_romplus3_b_fail, 0x4f34, str_romplus3_b_fail, 0x0000

rom_table_rom128espv1

	defw	0x8413, str_rom128_fail, 0x0000

rom_table_rom128espv2

	defw	0x8413, str_rom128_fail, 0x0000

rom_table_romplus2esp

	defw	0xadbb, str_romplus2_fail, 0x0000

rom_table_romplus2fra

	defw	0x9a23, str_romplus2_fail, 0x0000

rom_table_romplus3espv40

	defw	0xba48, str_romplus3_a_fail, 0x05c5, str_romplus3_b_fail, 0xd49d, str_romplus3_b_fail, 0x0000

rom_table_romplus3espv41

	defw	0x89c8, str_romplus3_a_fail, 0xf579, str_romplus3_b_fail, 0x8a84, str_romplus3_b_fail, 0x0000

	IFNDEF SAVEMEM

rom_table_rom128derby14

  defw 0x8c11, str_rom128_fail, 0x0000

rom_table_romplus3e_v1_38

	defw	0xa8e8, str_romplus3_a_fail, 0xe579, str_romplus3_b_fail, 0x4f34, str_romplus3_b_fail, 0x0000

rom_table_romplus3e_v1_38esp

	defw	0xa6d0, str_romplus3_a_fail, 0xff63, str_romplus3_b_fail, 0x8a84, str_romplus3_b_fail, 0x0000

rom_table_js128

	defw	0x8616, str_romjs128_fail, 0x0000

	ENDIF

str_rom128_fail

	defb 	"IC5", 0

str_romplus2_fail

	defb	"IC8", 0

str_romplus3_a_fail

	defb	"IC7", 0

str_romplus3_b_fail

	defb 	"IC8", 0

str_romjs128_fail

	defb	"U18", 0

;
;	ROM ID Strings
;

str_rom48k

	defb	"Spectrum 16/48K ROM...      ", 0

str_rom48kesp

	defb	"Spectrum 48K (Spanish) ROM...", 0

str_rom128k

	defb	"Spectrum 128K ROM...        ", 0

str_romplus2

	defb	"Spectrum +2 (Grey) ROM...   ", 0

str_romplus3

	defb	"Spectrum +3 (v4.0) ROM...   ", 0

str_romplus2a

	defb    "Spectrum +2A (v4.1) ROM...  ", 0

str_rom128espv1

	defb	"Spectrum 128K (Spanish v1) ROM...  ", 0

str_rom128espv2

	defb	"Spectrum 128K (Spanish v2) ROM...  ", 0


str_romplus2esp

	defb	"Spectrum +2 (Spanish) ROM...    ", 0

str_romplus2fra

	defb	"Spectrum +2 (French) ROM...    ", 0

str_romplus3espv40

	defb	"Spectrum +2A/+3 (Spanish v4.0) ROM... ", 0

str_romplus3espv41

	defb	"Spectrum +2A/+3 (Spanish v4.1) ROM... ", 0

	IFNDEF SAVEMEM

str_rom128derby14

  defb "Spectrum 128 Dev, Derby 1.4 ROM... ", 0

str_romplus3e_v1_38

	defb 	"Spectrum +3E v1.38 ROM...   ", 0

str_romplus3e_v1_38esp

	defb	"Spectrum +3E v1.38 (Spanish) ROM... ", 0

str_orelbk08

	defb	"Orel BK-08 ROM...           ", 0

str_harlequin_f

	defb	"Harlequin Rev. F...         ", 0

str_js128

	defb	"Just Speccy 128 ROM...          ", 0

str_rom48kbeckman

	defb 	"Beckman Spectrum 48K ROM... ", 0

str_rom48gw03

	defb	"Gosh Wonderful 48K ROM...   ", 0

	ENDIF
