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
;	vars.asm
;	
	
;	System variables for the Flash utility.

	define v_attr     		0xff00
	define v_column   		0xff01
	define v_row      		0xff02
; 	v_pr_ops - bit 0: bold on/off, bit 1: inverse on/off
	define v_pr_ops     	0xff03
	define v_width			0xff04
	define v_scroll			0xff05
	define v_scroll_lines		0xff06
	define v_page     		0xff10
	define v_printbuf 		0xff11
	define v_tapehdr  		0xff20 
	define v_keybuffer		0xff30
