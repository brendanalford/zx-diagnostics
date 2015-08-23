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

	defw 0xfd5e, str_rom48k, test_48k, 0x0000
	defw 0xeffc, str_rom128k, test_128k, rom_table_rom128k
	defw 0x2aa3, str_romplus2, test_plus2, rom_table_romplus2
	defw 0x3998, str_romplus2a, test_plus3,	rom_table_romplus2a
	defw 0x88f9, str_romplus3, test_plus3, rom_table_romplus3

	IFNDEF SAVEMEM
	
	defw 0x3a1f, str_rom128esp, test_128k, rom_table_rom128esp
	defw 0x3567, str_romplus2esp, test_plus2, rom_table_romplus2esp
	defw 0xd3b4, str_romplus2fra, test_plus2, rom_table_romplus2fra
	defw 0x5a18, str_romplus3esp, test_plus3, rom_table_romplus3esp

;	Some +3E ROM sets that might be out there

	defw 0x8dfe, str_romplus3e_v1_38, test_plus3, rom_table_romplus3e_v1_38
	defw 0xcaf2, str_romplus3e_v1_38esp, test_plus3, rom_table_romplus3e_v1_38esp
	
;	Soviet clones that some people are inexplicably fond of :)

	defw 0xe2ec, str_orelbk08, test_48kgeneric, 0x0000

;	Just Speccy 128 clone

	defw 0xb023, str_js128, test_js128, rom_table_js128

;	Harlequin Rev F

	defw 0x669e, str_harlequin_f, test_48kgeneric, 0x0000

;	Beckman 48K 

	defw 0xafcf, str_rom48kbeckman, test_48k, 0x0000
	
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

	defw	0xdcec, str_rom128_fail, 0x0000

rom_table_romplus2

	defw	0xb0a2, str_romplus2_fail, 0x0000

rom_table_romplus2a

	defw	0xe797, str_romplus3_a_fail, 0xf991, str_romplus3_b_fail, 0xbeeb, str_romplus3_b_fail, 0x0000

rom_table_romplus3

	defw	0xa624, str_romplus3_a_fail, 0xea97, str_romplus3_b_fail, 0x8a9b, str_romplus3_b_fail, 0x0000

	IFNDEF SAVEMEM
	
rom_table_rom128esp

	defw	0xc154, str_rom128_fail, 0x0000

rom_table_romplus2esp

	defw	0x3dfd, str_romplus2_fail, 0x0000

rom_table_romplus2fra

	defw	0x1b07, str_romplus2_fail, 0x0000
	
rom_table_romplus3esp

	defw	0xfe38, str_romplus3_a_fail, 0x6f7d, str_romplus3_b_fail, 0xfb2c, str_romplus3_b_fail, 0x0000

rom_table_romplus3e_v1_38

	defw	0x5004, str_romplus3_a_fail, 0x49e7, str_romplus3_b_fail, 0x8a9b, str_romplus3_b_fail, 0x0000

rom_table_romplus3e_v1_38esp

	defw	0xf4be, str_romplus3_a_fail, 0xd440, str_romplus3_b_fail, 0xfb2c, str_romplus3_b_fail, 0x0000

rom_table_js128

	defw	0xd8d8, str_romjs128_fail, 0x0000

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

str_rom128k

	defb	"Spectrum 128K ROM...        ", 0

str_romplus2

	defb	"Spectrum +2 (Grey) ROM...   ", 0

str_romplus3

	defb	"Spectrum +3 (v4.0) ROM...   ", 0

str_romplus2a

	defb    "Spectrum +2A (v4.1) ROM...  ", 0

	IFNDEF SAVEMEM
	
str_rom128esp

	defb	"Spectrum 128K (Spanish) ROM...  ", 0

str_romplus2esp

	defb	"Spectrum +2 (Spanish) ROM...    ", 0

str_romplus2fra

	defb	"Spectrum +2 (French) ROM...    ", 0

str_romplus3esp

	defb	"Spectrum +2A/+3 (Spanish) ROM... ", 0

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

	ENDIF