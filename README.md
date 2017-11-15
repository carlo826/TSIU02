;
; AssemblerApplication2.asm
;
; Created: 2017-11-13 14:25:37
; Author : Carl & Frans
;

	clr	r16
	out	DDRA,r16
	ldi r16, $8f	;
	out DDRB, r16	;

	; sätt stacken!
	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16

IDLE:
	//sbi PORTA, 0	; Fake simulation

	sbic PINA, 0	; Skip readSignal 
	jmp readSignal	; om A0 inte är satt

	jmp IDLE		; Loopa oändligt
	 
readSignal:
	clr	r16			;
	out PORTB,r16	;

	call HALFDELAY	; Vänta t/2 för nästa bit
	sbis PINA, 0	; Kolla om startsignalen fortfarande finns
	jmp IDLE		; Om startsignalen inte finns gå till IDLE

	call DELAY		
	sbic PINA, 0	; Kolla om A0 är satt
	sbi PORTB, 0	; Om A0 är satt sätt B0

	call DELAY		; Vänta t för nästa bit
	sbic PINA, 0	; Kolla om A0 är satt
	sbi PORTB, 1	; Om A0 är satt sätt B1

	call DELAY		; Vänta t för nästa bit
	sbic PINA, 0	; Kolla om A0 är satt
	sbi PORTB, 2	; Om A0 är satt sätt B2

	call DELAY		; Vänta t för nästa bit	
	sbic PINA, 0	; Kolla om A0 är satt
	sbi PORTB, 3	; Om A0 är satt sätt B3

	jmp	IDLE

DELAY:
	call HALFDELAY
	call HALFDELAY
	ret

// DELAY T från uppgiftpapperet
HALFDELAY:
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