;
; Lab2.asm
;
; Created: 2017-11-22 23:54:04
; Author : Carl
;


; Replace with your application code

ldi r16, 1;		//Ladda den port som ska vara output i port a
out DDRA, r16	//Sätt den första  porten i port a till output

ldi r16, low(RAMEND);
out spl, r16;
ldi r16, high(RAMEND);
out sph, r16;

.def char = r16;
.def tablevalue = r17;
.def morsechar = r18;
.def currbit = r19;
.def temp = r20;
.def antalsignaler = r21;


MESSAGE:
	.db "DATORTEKNIK", $00;

BTAB:
	.db "A", 0x60, "B", 0x88, "C", 0xA8//, "D", 0x90, "E", 0x40, "F", 0x28, "G", 0xD0, "H", 0x08, "I", 0x20, "J", 0x78, "K", 0xB0, "L", 0x48, "M", 0xE0, "N", 0xA0, "O", 0xF0, "P", 0x68, "Q", 0xD8, "R", 0x50, "S", 0x10, "T", 0xC0, "U", 0x30, "V", 0x18, "W", 0x70, "X", 0x98, "Y", 0xB8, "Z", 0xC8
    //.db "A", $41, "B", $42, "C", $43, "D", $44, "E", $45, "F", $46, "G", $47, "H", $48, "I", $49, "J", $4A, "K", $4B, "L", $4C, "M", $4D, "N", $4E, "O", $4F, "P", $50, "Q", $51, "R", $52, "S", $53, "T", $54, "U", $55, "V", $56, "W", $57, "X", $58, "Y", $59, "Z", $5A

ldi ZH, high(MESSAGE);
ldi ZL, low(MESSAGE);


MORSE:
	ldi char, 0;
	call GET_CHAR;
	cpi char, 0;			//Skip if char != 0
	brlo MORSE;				
	call LOOKUP;			// Tills NUL
	call SEND;
	//call NOBEEP(2N);
	jmp MORSE;


GET_CHAR:
	lpm char, Z+;
	ret;

LOOKUP:
	ldi ZL, low(BTAB);
	ldi ZH, high(BTAB);
	lpm tablevalue, Z+;
	cp char, tablevalue;
	brne LOOKUP;
	lpm morsechar, Z;
	ret;
	
SEND:
	call GET_BIT;           // Hämta nasta bit
	lpm temp, Z;
	sbrs temp, 0;				// tills hela sänt
	ret;
	sbis PORTA, 0;
	ldi antalsignaler, 1;
	call BEEP;			// 1N ljud, dit
	ldi antalsignaler, 3;
	sbic PORTA, 0				// tills hela sänt;
	call BEEP;				// 3N ljud
	ldi antalsignaler, 1;
	call NOBEEP;			// 1N tystnad
	call GET_BIT;
	ret;

GET_BIT:
	cbi PORTA, 0;
	lsl morsechar;
	brcs SET_BIT;
	ret;

SET_BIT:
	sbi PORTA, 0;
	ret

BEEP:
	ldi temp, 0
	cp antalsignaler, temp;
	breq BEEPRETURN;
	call DELAY;
	dec antalsignaler;
	call BEEP;
	ret;

BEEPRETURN:
	ret;

NOBEEP:
	cbi PORTA, 0;
	call BEEP;
	ret;

DELAY:		//20ms @ 4MHz
	ldi     r16,100   ; Decimal bas
delayYttreLoop:
	ldi     r17,$FF
delayInreLoop:
	dec     r17
	brne    delayInreLoop
	dec     r16
	brne    delayYttreLoop
	ret


