; This curious looking file basically aligns a routine to
; copy in the flash utility when BASIC 'OUT 31, 36' is executed.
; The routine lives at the address the RET from the BASIC ROM for
; the OUT command would live (since the OUT (C), A switches page,
; the next fetched instruction will be from this file, not the Speccy ROM)

         org 0
         jp copyflashutil
         block #38-$,0
         ; just in case an interrupt occurs before we can DI
interrupt
         reti
flashutil
         incbin "flashutil.bin"
flashutilend

         block #1E7F-$, 0
copyflashutil
         di
         ld hl, flashutil
         ld de, #E000   ; Decimal 57344
         ld bc, flashutilend-flashutil
         ldir
         jp #E000

fillspare
         block #4000-$,0
         
