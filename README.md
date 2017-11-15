;
; AssemblerApplication2.asm
;
; Created: 2017-11-13 14:25:37
; Author : Carl & Frans
;

	clr	r16			; Rensa registeret r16
	out	DDRA,r16	; Sätt alla DDRA bitar i port a till r16 = tomma
	ldi r16, $8f	; Ladda de portar som behöver vara output i port b
	out DDRB, r16	; Sätt r16 portar i DDRB

	ldi r16, low(RAMEND) ; Sätt stackpekaren, RAMEND är 16 bit så vi måste splitta det
	out spl, r16
	ldi r16, high(RAMEND)
	out spl, r16

IDLE:
	sbi PINA, 0		; Simulera aktiv signal från ir utsändare
	sbic PINA, 0	; Skip readSignal 
	call readSignal	; om A0 är satt
	jmp IDLE		; Loopa oändligt
	 
readSignal:
	clr	r16			;
	out PORTB,r16	;

	call HALFDELAY	; Vänta t/2 för nästa bit
	sbis PINA, 0	; Kolla om startsignalen fortfarande finns
	ret		; Om startsignalen inte finns avsulta subrutin

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

	ret

DELAY:
	call HALFDELAY
	call HALFDELAY
	ret

// DELAY T från uppgiftpapperet
HALFDELAY:
	sbi PORTB,7 ; Sätter biten för oscilloskopet
	ldi r17,5 ; Första värde som bestämmer antal loops

delayYttreLoop:
	ldi r18,255 ; Andra värde som bestämmer antal loops

delayInreLoop:
	dec r18
	brne delayInreLoop
	dec r17
	brne delayYttreLoop ; Delay är klar när den har gått r17 * r18 antal loopar
	cbi PORTB,7 ; Tar bort biten för oscilloskopet
	ret