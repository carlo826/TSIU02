;
; Lab2.asm
;
; Created: 2017-11-22 23:54:04
; Author : Carl
;


; Replace with your application code

ldi r16, low(RAMEND);
out spl, r16;
ldi r16, high(RAMEND);
out sph, r16;

.def char = r16;
.def index = r17;
.def message_tmp = r18;
ldi index, 0;
.equ tidsenhet = 15;

MESSAGE:
	.db "DATORTEKNIK", $00

BTAB:
	.db "A", $41, "B", $42, "C", $43, "D", $44, "E", $45, "F", $46, "G", $47, "H", $48, "I", $49, "J", $4A, "K", $4B, "L", $4C, "M", $4D, "N", $4E, "O", $4F, "P", $50, "Q", $51, "R", $52, "S", $53, "T", $54, "U", $55, "V", $56, "W", $57, "X", $58, "Y", $59, "Z", $5A

lpm messagetmp, $00;

GET_CHAR:
	lsl messagetmp;
	ret char;
	

MORSE:
	call GET_CHAR;
	sbrc char;				//Skip if char != 0
	jmp MORSE;			    // Tills NUL
	call LOOKUP;
	call SEND;
	call NOBEEP(2N);
	jmp MORSE;

SEND:
	call GET_BIT;           // Hämta nasta bit
	sbrs Z;					// tills hela sänt
	ret;
	sbis bit;
	call BEEP(N);			// 1N ljud, dit
	sbic bit				// tills hela sänt;
	call BEEP(3N);			// 3N ljud, dah
	call NOBEEP(N);			// 1N tystnad
	call GET_BIT;
	