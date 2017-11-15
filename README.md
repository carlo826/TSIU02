;
; AssemblerApplication2.asm
;
; Created: 2017-11-13 14:25:37
; Author : Carl
;

.def completeSignal = r18

IDLE:
	//sbi PORTA, 0
	sbic PORTA, 0
	jmp readSignal
	jmp IDLE
	 
readSignal:
	jmp DELAY
	sbis PORTA, 0
	brne IDLE

	jmp DELAY
	sbic PORTA, 0
	sbi PORTB, 0

	jmp DELAY
	sbic PORTA, 0
	sbi PORTB, 1

	jmp DELAY
	sbic PORTA, 0
	sbi PORTB, 2

	jmp DELAY
	sbic PORTA, 0
	sbi PORTB, 3

	out DDRB, r19




DELAY:
	sbi PORTB,7
	ldi r16,5 ; Decimal bas
delayYttreLoop:
	ldi r17,$FF
delayInreLoop:
	dec r17
	brne delayInreLoop
	dec r16
	brne delayYttreLoop
	cbi PORTB,7
	ret