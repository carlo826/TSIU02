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
.def Periods = r19
.def CurrentBit = r20
.def Zero = r21
.def One = r22

.equ timeunit = 15
.equ space = $20
.equ charStartIndex = $41

START:
	ldi r16, 1				; Ladda den port som ska vara output i port a
	out DDRA, r16			; Sätt den första  porten i port a till output

	ldi r16, low(RAMEND)	; Initiera stack pekare
	out spl, r16
	ldi r16, high(RAMEND)
	out sph, r16

	ldi ZH, high(MESSAGE*2)
	ldi ZL, low(MESSAGE*2)

	; Nollställ
	clr Char
	clr MorseChar
	clr SignalCount
	clr Periods
	clr CurrentBit
	clr Zero
	ldi One, 1

MORSE:
	call GET_CHAR
	cpi Char, 0			; Skip if Char !=0 
	breq END
	cpi Char, space
	breq DO_SPACE

	call LOOKUP			; Tills NUL
	call SEND
	ldi SignalCount, 3
	call NOBEEP
	jmp MORSE

END:
	jmp END

GET_CHAR:
	lpm Char, Z+
	ret

LOOKUP:
	push ZH
	push ZL
	subi Char, charStartIndex
	ldi ZH, high(BTAB*2)
	ldi ZL, low(BTAB*2)
	add ZL, Char
	adc ZH, Zero
	lpm MorseChar, Z
	pop ZL
	pop ZH
	ret

DO_SPACE:
	ldi SignalCount, 7
	call NOBEEP
	jmp MORSE
	
SEND:
	clr CurrentBit
	call GET_BIT			; Hämta nasta bit
	cpi MorseChar, 0		; tills hela sänt
	brne SEND_INNER
SEND_DONE:
	ret
SEND_INNER:
	ldi SignalCount, 3
	cpse CurrentBit, One
	ldi SignalCount, 1
	call BEEP
	ldi SignalCount, 1
	call NOBEEP
	jmp SEND

GET_BIT:
	lsl MorseChar
	brcs SET_BIT
RETURN_BIT:
	ret
SET_BIT:
	ldi CurrentBit, 1
	jmp RETURN_BIT


BEEP:
	ldi Periods, timeunit
BEEP_SEND:
	sbi PORTA, 0
	call DELAY
	cbi PORTA, 0
	call DELAY
	dec Periods
	cpse Periods, Zero
	jmp BEEP_SEND
	dec SignalCount
	cpse SignalCount, Zero
	jmp BEEP_END
	jmp BEEP_SEND
BEEP_END:
	ret

NOBEEP:
	ldi Periods, timeunit
NOBEEP_SEND:
	call DELAY
	call DELAY
	dec Periods
	cpse Periods, Zero
	jmp NOBEEP_SEND
	dec SignalCount
	cpse SignalCount, Zero
	jmp NOBEEP_END
	jmp NOBEEP_SEND
NOBEEP_END:
	ret

DELAY:				;
	ldi     r23,2   ; Decimal bas
delayYttreLoop:
	ldi     r24,3
delayInreLoop:
	dec     r24
	brne    delayInreLoop
	dec     r23
	brne    delayYttreLoop
	ret
MESSAGE:
	.db "C", $00;
BTAB:
	.db $60, $88, $A8, $90, $40, $28, $D0, $08, $20, $78, $B0, $48, $E0, $A0, $F0, $68, $D8, $50, $10, $C0, $30, $18, $70, $98, $B8, $C8;