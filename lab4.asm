;
; Lab4.asm
;
; Created: 12/12/2017 10:30:56 AM
; Author : Carl
;

		; --- lab4_skal . asm
		.equ VMEM_SZ = 5 ; # rows on display
		.equ AD_CHAN_X = 0 ; ADC0 = PA0 , PORTA bit 0 X - led
		.equ AD_CHAN_Y = 1 ; ADC1 = PA1 , PORTA bit 1 Y - led
		.equ GAME_SPEED = 70 ; inter - run delay ( millisecs )
		.equ PRESCALE = 7 ; AD - prescaler value
		.equ BEEP_PITCH = 20 ; Victory beep pitch
		.equ BEEP_LENGTH = 100 ; Victory beep length

		.def MUX_INDEX = r20
		; ---------------------------------------
		; --- Memory layout in SRAM
		.dseg
		.org SRAM_START
POSX  :	.byte 1 ; Own position
POSY  :	.byte 1
TPOSX : .byte 1 ; Target position
TPOSY : .byte 1
LINE  : .byte 1 ; Current line
VMEM  : .byte VMEM_SZ ; Video MEMory
SEED  : .byte 1 ; Seed for Random

		; ---------------------------------------
		; --- Macros for inc / dec - rementing
		; --- a byte in SRAM
		.macro INCSRAM ; inc byte in SRAM
				lds r16 , @0
				inc r16
				sts @0 , r16
		.endmacro

		.macro DECSRAM ; dec byte in SRAM
				lds r16 , @0
				dec r16
				sts @0 , r16
		.endmacro
		; ---------------------------------------
		; --- Code
		.cseg
		.org $0
		jmp START
		.org INT0addr
		jmp MUX
START :
		;*** Initiera stack pekare
		ldi r16, low(RAMEND)	
		out spl, r16
		ldi r16, high(RAMEND)
		out sph, r16
		; //KLART
		call HW_INIT
		call WARM
RUN :
		call JOYSTICK
		call ERASE
		call UPDATE
;*** Vanta en stund sa inte spelet gar for fort ***
;*** Avgor om traff ***
		call DELAY
		lds r16, POSX
		lds r17, TPOSX
		lds r18, POSY
		lds r19, TPOSY
		cpse r16, r17
		cp r18, r19
; //KLART
		brne NO_HIT
		ldi r16 , BEEP_LENGTH
		call BEEP
		call WARM
NO_HIT :
jmp RUN
		; ---------------------------------------
		; --- Multiplex display
		; --- Uses : r16
MUX :

;*** skriv rutin som handhar multiplexningen och ***
;*** utskriften till diodmatrisen . Oka SEED . ***
; // KLART
		cpi MUX_INDEX, VMEM_SZ
		brne MUX_INNER
MUX_RESET:
		clr MUX_INDEX
MUX_INNER:
		INCSRAM SEED ; 255 xd
		lsl MUX_INDEX
		lsl MUX_INDEX
		lsl MUX_INDEX
		andi MUX_INDEX, PORTA
		out PORTA, MUX_INDEX
		inc MUX_INDEX
		reti
		; ---------------------------------------
		; --- JOYSTICK Sense stick and update POSX , POSY
		; --- Uses :

JOYSTICK :
;*** skriv kod som okar eller minskar POSX beroende ***
;*** pa insignalen fran A/D - omvandlaren i X - led ... ***
;*** ... och samma for Y - led ***
; // KLART

		ldi r16, (1<<REFS1) | (1<<REFS0) ; 1100 0000
										 ; volt ADC0
		out ADMUX, r16
		ldi r16, (1<<ADEN) | (1<<ADSC) | (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0)
		out ADCSRA, r16
JOY_LISTEN_X:
		in r16, ADCH
		andi r16, $03 ; clear register "but" last bits
		cpi r16, $03 ; if 0000 0011 (inc)
		breq JOY_INC_POSX
		cpi r16, $00  ; if 0000 0000 (decr)
		breq JOY_DEC_POSX
		jmp JOY_LISTEN_Y
JOY_INC_POSX:
	INCSRAM POSX
	jmp JOY_LISTEN_Y
JOY_DEC_POSX:
	DECSRAM POSX
	jmp JOY_LISTEN_Y
JOY_LISTEN_Y:
		ldi r16, (1<<REFS1) | (1<<REFS0) | (1<<MUX0) ; 1100 0001
													 ; volt ADC1
		out ADMUX, r16
		ldi r16, (1<<ADEN) | (1<<ADSC) | (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0)
		out ADCSRA, r16
		in r16, ADCH
		andi r16, $03 ; clear register "but" last bits
		cpi r16, $03 ; if 0000 0011 (inc)
		breq JOY_INC_POSY
		cpi r16, $00  ; if 0000 0000 (decr)
		breq JOY_DEC_POSY
		jmp JOY_LIM
JOY_INC_POSY:
	INCSRAM POSY
	jmp JOY_LIM
JOY_DEC_POSY:
	DECSRAM POSY
	jmp JOY_LIM
JOY_LIM :
		call LIMITS ; don  t fall off world !
		ret
		; ---------------------------------------
		; --- LIMITS Limit POSX , POSY coordinates
		; --- Uses : r16 , r17
LIMITS :
		lds r16 , POSX ; variable
		ldi r17 ,7 ; upper limit +1
		call POS_LIM ; actual work
		sts POSX , r16
		lds r16 , POSY ; variable
		ldi r17 ,5 ; upper limit +1
		call POS_LIM ; actual work
		sts POSY , r16
		ret
POS_LIM :
		ori r16 ,0 ; negative ?
		brmi POS_LESS ; POSX neg = > add 1
		cp r16 , r17 ; past edge
		brne POS_OK
		subi r16 ,2
POS_LESS :
		inc r16
POS_OK :
		ret
		; ---------------------------------------
		; --- UPDATE VMEM
		; --- with POSX /Y , TPOSX /Y
		; --- Uses : r16 , r17 , Z
UPDATE :
		clr ZH
		ldi ZL , LOW ( POSX )
		call SETPOS
		clr ZH
		ldi ZL , LOW ( TPOSX )
		call SETPOS
		ret
		; --- SETPOS Set bit pattern of r16 into * Z
		; --- Uses : r16 , r17 , Z
		; --- 1 st call Z points to POSX at entry and POSY at exit
		; --- 2 nd call Z points to TPOSX at entry and TPOSY at exit
SETPOS :
		ld r17 , Z + ; r17 = POSX
		call SETBIT ; r16 = bitpattern for VMEM + POSY
		ld r17 , Z ; r17 = POSY Z to POSY
		ldi ZL , LOW ( VMEM )
		add ZL , r17 ; Z= VMEM + POSY , ZL = VMEM +0..4
		ld r17 , Z ; current line in VMEM
		or r17 , r16 ; OR on place
		st Z , r17 ; put back into VMEM
		ret
		; --- SETBIT Set bit r17 on r16
		; --- Uses : r16 , r17
SETBIT :
		ldi r16 , $01 ; bit to shift
SETBIT_LOOP :
		dec r17
		brmi SETBIT_END ; til done
		lsl r16 ; shift
		jmp SETBIT_LOOP
SETBIT_END :
		ret
		; ---------------------------------------
		; --- Hardware init
		; --- Uses :
HW_INIT :
;*** Konfigurera hardvara och MUX - avbrott enligt ***
;*** ditt elektriska schema . Konfigurera ***
;*** flanktriggat avbrott pa INT0 ( PD2 ). ***
; // KLART
		; MUX
		ldi r16, (1 << ISC01) | (0 << ISC00)
		out MCUCR, r16
		ldi r16, (1 << INT0)
		out GICR, r16

		sei ; display on


		ldi r16, $1F			; Ladda de port som ska vara output i port a
		out DDRA, r16			; Stt den alla portar i port a till output
		
		ldi r16, $7F			; Ladda de port som ska vara output i port b
		out DDRB, r16			; Stt den alla portar i port b till output

		ret
		; ---------------------------------------
		; --- WARM start . Set up a new game .
		; --- Uses :
WARM :
;*** Satt startposition ( POSX , POSY )=(0 ,2) ***
		clr r16
		sts POSX, r16
		ldi r16, 2
		sts POSY, r16
; //KLAR 
		push r0
		push r0
		call RANDOM ; RANDOM returns TPOSX , TPOSY on stack
;*** Satt startposition ( TPOSX , TPOSY ) ***
		pop r16
		sts TPOSY, r16
		pop r16
		sts TPOSX, r16
; // KLART

		call ERASE
		ret
		; ---------------------------------------
		; --- RANDOM generate TPOSX , TPOSY
		; --- in variables passed on stack .
		; --- Usage as :
		; --- push r0
		; --- push r0
		; --- call RANDOM
		; --- pop TPOSX
		; --- pop TPOSY
		; --- Uses : r16
RANDOM :
		in r16 , SPH
		mov ZH , r16
		in r16 , SPL
		mov ZL , r16
		lds r16 , SEED

;*** Anvand SEED for att berakna TPOSX ***
;*** Anvand SEED for att berakna TPOSY ***
;		*** ; store TPOSX 2..6
;		*** ; store TPOSY 0..4
		andi r16, $07
		cpi  r16, $05
		brsh LIMIT_Y_SEED
		jmp RANDOM_X
LIMIT_Y_SEED:
		andi r16, $03
		std Z+2, r16
RANDOM_X:
		lds r16, SEED
		andi r16, 28
		lsl r16
		lsl r16
		cpi r16, 2
		brlo LIMIT_LX_SEED
		cpi r16, 7
		brsh LIMIT_HX_SEED
		jmp RANDOM_FINISH
LIMIT_LX_SEED:
		andi r16, $02
		jmp RANDOM_FINISH
LIMIT_HX_SEED:
		andi r16, $03
		jmp RANDOM_FINISH
RANDOM_FINISH:
		std Z+3, r16
		ret
		; ---------------------------------------
		; --- ERASE videomemory
		; --- Clears VMEM .. VMEM +4
		; --- Uses :
ERASE :
;*** Radera videominnet ***
		push ZL
		push ZH
		push r16
		push r17

		clr r16
		clr r17
		ldi ZL, low(VMEM)
		ldi ZH, high(VMEM)
ERASE_LOOP:
		st Z+, r16 
		inc r17
		cpi r17, VMEM_SZ
		brlo ERASE_LOOP

		pop r17
		pop r16
		pop ZH
		pop ZL
		ret
// KLAR
		; ---------------------------------------
		; --- BEEP ( r16 ) r16 half cycles of BEEP - PITCH
		; --- Uses :
BEEP :
;*** skriv kod for ett ljud som ska markera traff ***
		push r16
		push r17

		ldi r16, BEEP_PITCH
		ldi r17, BEEP_LENGTH
BEEP_WAVE:
		sbi PORTB, 7
		call DELAY
		cbi PORTB, 7
		call DELAY
		dec r17
		cpi r17, 0
		brne BEEP_WAVE
BEEP_END:
		pop r17
		pop r16
		ret
DELAY:				;
	ldi     r21,3   ; Decimal bas
delayYttreLoop:
	ldi     r22,2
delayInreLoop:
	dec     r22
	brne    delayInreLoop
	dec     r21
	brne    delayYttreLoop
	ret