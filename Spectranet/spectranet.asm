;The MIT License
;
;Copyright (c) 2008 Dylan Smith
;
;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in
;all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;THE SOFTWARE.

; This file can be included in assembly language programs to give
; symbolic access to the public jump table entry points.

; Hardware page-in entry points
MODULECALL      equ 0x3FF8
MODULECALL_NOPAGE       equ 0x28
PAGEIN          equ 0x3FF9
PAGEOUT         equ 0x007C
HLCALL          equ 0x3FFA
IXCALL          equ 0x3FFD

; Port defines
CTRLREG         equ 0x033B
CPLDINFO        equ 0x023B

; Jump table entry points
SOCKET          equ 0x3E00      ; Allocate a socket
CLOSE           equ 0x3E03      ; Close a socket
LISTEN          equ 0x3E06      ; Listen for incoming connections
ACCEPT          equ 0x3E09      ; Accept an incoming connection
BIND            equ 0x3E0C      ; Bind a local address to a socket
CONNECT         equ 0x3E0F      ; Connect to a remote host
SEND            equ 0x3E12      ; Send data 
RECV            equ 0x3E15      ; Receive data 
SENDTO          equ 0x3E18      ; Send data to an address
RECVFROM        equ 0x3E1B      ; Receive data from an address
POLL            equ 0x3E1E      ; Poll a list of sockets
POLLALL         equ 0x3E21      ; Poll all open sockets
POLLFD          equ 0x3E24      ; Poll a single socket
GETHOSTBYNAME   equ 0x3E27      ; Look up a hostname
PUTCHAR42       equ 0x3E2A      ; 42 column print write a character
PRINT42         equ 0x3E2D      ; 42 column print a null terminated string
CLEAR42         equ 0x3E30      ; Clear the screen and reset 42-col print
SETPAGEA        equ 0x3E33      ; Sets page area A
SETPAGEB        equ 0x3E36      ; Sets page area B
LONG2IPSTRING   equ 0x3E39      ; Convert a 4 byte big endian long to an IP
IPSTRING2LONG   equ 0x3E3C      ; Convert an IP to a 4 byte big endian long
ITOA8           equ 0x3E3F      ; Convert a byte to ascii
RAND16          equ 0x3E42      ; 16 bit PRNG
REMOTEADDRESS   equ 0x3E45      ; Fill struct sockaddr_in
IFCONFIG_INET   equ 0x3E48      ; Set IPv4 address
IFCONFIG_NETMASK equ 0x3E4B     ; Set netmask
IFCONFIG_GW     equ 0x3E4E      ; Set gateway
INITHW          equ 0x3E51      ; Set the MAC address and initial hw registers
GETHWADDR       equ 0x3E54      ; Read the MAC address
DECONFIG        equ 0x3E57      ; Deconfigure inet, netmask and gateway
MAC2STRING      equ 0x3E5A      ; Convert 6 byte MAC address to a string
STRING2MAC      equ 0x3E5D      ; Convert a hex string to a 6 byte MAC address
ITOH8           equ 0x3E60      ; Convert accumulator to hex string
HTOI8           equ 0x3E63      ; Convert hex string to byte in A
GETKEY          equ 0x3E66      ; Get a key from the keyboard, and put it in A
KEYUP           equ 0x3E69      ; Wait for key release
INPUTSTRING     equ 0x3E6C      ; Read a string into buffer at DE
GET_IFCONFIG_INET equ 0x3E6F    ; Gets the current IPv4 address
GET_IFCONFIG_NETMASK equ 0x3E72 ; Gets the current netmask
GET_IFCONFIG_GW equ 0x3E75      ; Gets the current gateway address
SETTRAP         equ 0x3E78      ; Sets the programmable trap
DISABLETRAP     equ 0x3E7B      ; Disables the programmable trap
ENABLETRAP      equ 0x3E7E      ; Enables the programmable trap
PUSHPAGEA       equ 0x3E81      ; Pages a page into area A, pushing the old one
POPPAGEA        equ 0x3E84      ; Restores the previous page in area A
PUSHPAGEB       equ 0x3E87      ; Pages into area B pushing the old one
POPPAGEB        equ 0x3E8A      ; Restores the previous page in area B
PAGETRAPRETURN  equ 0x3E8D      ; Returns from a trap to page area B
TRAPRETURN      equ 0x3E90      ; Returns from a trap that didn't page area B
ADDBASICEXT     equ 0x3E93      ; Adds a BASIC command
STATEMENT_END   equ 0x3E96      ; Check for statement end, exit at syntax time
EXIT_SUCCESS    equ 0x3E99      ; Use this to exit successfully after cmd
PARSE_ERROR     equ 0x3E9C      ; Use this to exit to BASIC with a parse error
RESERVEPAGE     equ 0x3E9F      ; Reserve a page of static RAM
FREEPAGE        equ 0x3EA2      ; Free a page of static RAM
REPORTERR       equ 0x3EA5      ; report an error via BASIC

; Filesystem functions
MOUNT           equ 0x3EA8
UMOUNT          equ 0x3EAB
OPENDIR         equ 0x3EAE
OPEN            equ 0x3EB1
UNLINK          equ 0x3EB4
MKDIR           equ 0x3EB7
RMDIR           equ 0x3EBA
SIZE            equ 0x3EBD
FREE            equ 0x3EC0
STAT            equ 0x3EC3
CHMOD           equ 0x3EC6
READ            equ 0x3EC9
WRITE           equ 0x3ECC
LSEEK           equ 0x3ECF
VCLOSE          equ 0x3ED2
VPOLL           equ 0x3ED5
READDIR         equ 0x3ED8
CLOSEDIR        equ 0x3EDB
CHDIR           equ 0x3EDE
GETCWD          equ 0x3EE1
RENAME          equ 0x3EE4
SETMOUNTPOINT   equ 0x3EE7
FREEMOUNTPOINT  equ 0x3EEA
RESALLOC        equ 0x3EED


; Definitions
ALLOCFD         equ 1
FREEFD          equ 0
ALLOCDIRHND     equ 3
FREEDIRHND      equ 2

; POLL status bits
BIT_RECV        equ 2
BIT_DISCON      equ 1
BIT_CONN        equ 0
