
;
;	Pages the given RAM page into memory. 
;	Inputs: A=desired RAM page.
;

pagein

	push bc
	push af
	ld bc, 0x7ffd

;	Ensure nothing else apart from paging gets touched
	
	and 0x7	
	out (c), a
	pop af
	pop bc 
	ret
