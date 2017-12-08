;
; Lab2.asm
;
; Created: 2017-11-22 23:54:04
; Author : Carl
;


; Replace with your application code


.def Char = r16
.def MorseChar = r17
.def SignalCount = r18
.def Periods = r24
.def CurrentBit = r25

.equ timeunit = 15

ldi r16, 1				; Ladda den port som ska vara output i port a
out DDRA, r16			; Sätt den första  porten i port a till output

ldi r16, low(RAMEND)	; Initiera stack pekare
out spl, r16
ldi r16, high(RAMEND)
out sph, r16

ldi ZH, high(MESSAGE*2)
ldi ZL, low(MESSAGE*2)

MORSE:
	call GET_CHAR
	cpi Char, 0			; Skip if Char !=0 
	breq END
	cpi Char, $20
	breq SPACE
	call LOOKUP			; Tills NUL
	call SEND
	//call LONGDELAY
	ldi SignalCount, 3
	call NOBEEP
	jmp MORSE

END:
	jmp END

GET_CHAR:
	call GET_CHAR_INNER
	ret
GET_CHAR_INNER:
	lpm Char, Z+
	ret

LOOKUP:
	push ZH
	push ZL
	subi Char, $41
	ldi ZH, high(BTAB*2)
	ldi ZL, low(BTAB*2)
	ldi	r20, 0
	add ZL, Char
	adc ZH, r20
	lpm MorseChar, Z
	pop ZL
	pop ZH
	ret

SPACE:
	ldi SignalCount, 7
	call NOBEEP
	jmp MORSE
	
SEND:
	call GET_BIT			; Hämta nasta bit
	ldi Periods, timeunit 
	cpi MorseChar, 0		; tills hela sänt
	brne SEND_INNER
	ret

SEND_INNER:
	ldi SignalCount, 1
	cpi CurrentBit, 1
	breq BEEP				; 1N ljud, dit

	ldi SignalCount, 3
	cpi CurrentBit, 0		; tills hela sänt;
	breq BEEP				; 3N ljud

	ldi SignalCount, 1
	call NOBEEP				; 1N tystnad

	jmp SEND
	ret

GET_BIT:
	lsl MorseChar
	brcs SET_BIT
	ret

SET_BIT:
	ldi CurrentBit, 1
	ret

BEEP:
	cpi SignalCount, 0
	brne BEEP_INNER
	ret
BEEP_INNER:
	cpi Periods, 0
	brne BEEP_SEND
	ret
BEEP_SEND:
	sbi PORTA, 0
	call DELAY
	cbi PORTA, 0
	call DELAY
	dec SignalCount
	dec Periods
	jmp BEEP


NOBEEP:
	cbi PORTA, 0
	cpi SignalCount, 0
	brne NOBEEP_INNER
	ret
NOBEEP_INNER:
	cpi Periods, 0
	brne NOBEEP_SEND
	ret
NOBEEP_SEND:
	call DELAY
	call DELAY
	dec SignalCount
	dec Periods
	jmp NOBEEP

DELAY:				;
	ldi     r21,5   ; Decimal bas
delayYttreLoop:
	ldi     r22,250
delayInreLoop:
	dec     r22
	brne    delayInreLoop
	dec     r21
	brne    delayYttreLoop
	ret

MESSAGE:
	.db "DATORTEKNIK", $00;

BTAB:
	.db $60, $88, $A8, $90, $40, $28, $D0, $08, $20, $78, $B0, $48, $E0, $A0, $F0, $68, $D8, $50, $10, $C0, $30, $18, $70, $98, $B8, $C8;