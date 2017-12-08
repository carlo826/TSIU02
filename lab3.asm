;
; Lab3.asm
;
; Created: 12/6/2017 10:23:33 AM
; Author : Carl
;

.equ TIME = $60
.def Zero = r17

.def Index = r18
.def BCDTmp = r19
.def MUXIndex = r21
.def MUXDigit = r22
.def MUXAddr = r23

.org $0000
jmp COLD

.org INT0addr
jmp INTERRUPT_0

.org INT1addr
jmp INTERRUPT_1

	; --- Cold start
COLD:
	; --- Initiera stack pekare
	ldi r16, low(RAMEND)	
	out spl, r16
	ldi r16, high(RAMEND)
	out sph, r16

	; --- Konfigurerar "trigger settings" för INT0 och INT1 till fallande flank.
	ldi r16, (1 << ISC01) | (0 << ISC00) | (1 << ISC11) | (0 << ISC10)
	out MCUCR, r16
	
	; --- Aktiverar INT0 och INT1
	ldi r16, (1 << INT0) | (1 << INT1) 
	out GICR, r16 

	sei						; Aktiverar global interrupt

	ldi r16, $03			; Ladda de port som ska vara output i port a
	out DDRA, r16			; Sätt den alla  portar i port a till output
	ldi r16, $FF			; Ladda de port som ska vara output i port a
	out DDRB, r16			; Sätt den alla  portar i port a till output

	; --- Nollställer
	clr Index
	clr BCDTmp
	clr Zero
	clr MUXDigit
	clr MUXIndex
	clr MUXAddr

	push YH
	push YL
	ldi YL, low(TIME)
	ldi YH, high(TIME)
	std Y+0, Zero
	std Y+1, Zero
	std Y+2, Zero
	std Y+3, Zero
	pop YL
	pop YH

WAIT:
	jmp WAIT

	; --- Interrupts
INTERRUPT_0:
	push r16
	in r16, SREG
	push r16
	call BCD
	pop r16
	out SREG, r16
	pop r16
	reti

INTERRUPT_1:
	push r16
	in r16, SREG
	push r16
	call MUX
	pop r16
	out SREG, r16
	pop r16
	reti

	; --- BCD
BCD:
	clr Index
BCD_INNER:
	push YH
	push YL
	ldi YL, low(TIME)
	ldi YH, high(TIME)
	add YL, Index
	adc YH, Zero

	; Increment TIME at Index
	ld BCDTmp, Y
	inc BCDTmp
	st Y, BCDTmp
	; ---

	; Skippa om index är jämnt
	sbrc Index, 0			
	call BCD_ODD

	; Skippa om index är udda
	sbrs Index, 0			
	call BCD_EVEN

	pop YL
	pop YH
	
	ret
BCD_ODD:
	cpi BCDTmp, 6
	brsh OVERFLOW
	ret
BCD_EVEN:
	cpi BCDTmp, 10
	brsh OVERFLOW
	ret

OVERFLOW:
	st Y, Zero ; reset
	cpi Index, 3
	brne OVERFLOW_INNER
	ret
OVERFLOW_INNER:
	inc Index
	call BCD_INNER
	ret

	; --- MUX
MUX:
	cpi MUXIndex, 4
	breq MUX_RESET
	brne MUX_INNER
MUX_INNER:
	push ZH
	push ZL
	push YH
	push YL

	ldi ZL, low(BIT_PATTERN*2)
	ldi ZH, high(BIT_PATTERN*2)
	ldi YL, low(TIME)
	ldi YH, high(TIME)

	add YL, MUXIndex
	adc YH, Zero
	ld MUXAddr, Y

	add ZL, MUXAddr
	adc ZH, Zero
	lpm MUXDigit, Z

	pop YL
	pop YH
	pop ZL
	pop ZH

	out PORTB, MUXDigit
	out PORTA, MUXIndex

	inc MUXIndex
	ret

MUX_RESET:
	clr MUXIndex
	ret

BIT_PATTERN:
	.db $3F, $6, $5B, $4F, $66, $6D, $7D, $27, $7F, $67


/*  

	MUX {
		if (MUXIndex == 3) {
			reset()
		}
		else {
			inner()
		}
	}

	inner(){
		PORTA.set(MUXIndex)
		digit = BIT_PATTERN[TIME[MUXIndex]]
		PORTB.set(digit)
		MUXIndex++
	}

	reset() {
		MUXIndex = 0
	}

*/

/*  
	BCD {
		INDEX = 0
	}
	BCD_INNER {
		TIME[INDEX]++
		when{
			INDEX == EVEN {
				if(TIME[INDEX] == 10)
					overflow()
			}
			INDEX == ODD {
				if(TIME[INDEX] == 6)
					overflow()
			}
		}
	}
	overflow() {
		TIME[INDEX] = 0;
		INDEX++
		BCD_INNER()
	}
*/