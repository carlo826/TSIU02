;
; Lab4.asm
;
; Created: 12/12/2017 10:30:56 AM
; Author : Carl
;

		; --- lab4_skal . asm
		.equ VMEM_SZ = 5        ; # rows on display
		.equ AD_CHAN_X = 0      ; ADC0 = PA0 , PORTA bit 0 X - led
		.equ AD_CHAN_Y = 1      ; ADC1 = PA1 , PORTA bit 1 Y - led
		.equ GAME_SPEED = 70    ; inter - run delay ( millisecs )
		.equ PRESCALE = 7       ; AD - prescaler value
		.equ BEEP_LENGTH1 = 200  ; Victory beep length
		.equ BEEP_LENGTH2 = 125  ; Victory beep length
		.equ BEEP_LENGTH3 = 50  ; Victory beep lengt
		.equ BEEP_PITCH1 = 120    ; Victory beep pitch
		.equ BEEP_PITCH2 = 80   ; Victory beep pitch
		.equ BEEP_PITCH3 = 40   ; Victory beep pitch

		.def BPITCH = r24
		.def BLENGTH = r25
		.def ZERO = r23
		; ---------------------------------------
		; --- Memory layout in SRAM
		.dseg
		.org SRAM_START
POSX  :	.byte 1         ; Own position
POSY  :	.byte 1
TPOSX : .byte 1         ; Target position
TPOSY : .byte 1
LINE  : .byte 1         ; Current line
VMEM  : .byte VMEM_SZ   ; Video MEMory
SEED  : .byte 1         ; Seed for Random

		; ---------------------------------------
		; --- Macros for inc / dec - rementing
		; --- a byte in SRAM
		.macro INCSRAM  ; inc byte in SRAM
				lds r16 , @0
				inc r16
				sts @0 , r16
		.endmacro

		.macro DECSRAM  ; dec byte in SRAM
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

START:
		ldi r16, low(RAMEND)	; stack pointer
		out spl, r16
		ldi r16, high(RAMEND)
		out sph, r16

		call HW_INIT
		call WARM
RUN:
		call JOYSTICK
		call ERASE
		call UPDATE
;*** Vanta en stund sa inte spelet gar for fort ***
;*** Avgor om traff ***

		call DELAY
		call DELAY

        ; X position
		lds r16, POSX
		lds r17, TPOSX
        cp r16, r17
        brne NO_HIT 

        ; Y position
		lds r16, POSY
		lds r17, TPOSY
        cp r16, r17
        brne NO_HIT 

		call VICTORY_BEEP

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
		push r16
		push r17

		ldi r16, VMEM_SZ
		lds r17, LINE
		cpse r17, r16   ; is current line to draw at 5?
		jmp MUX_INNER   ; if not then continue MUX
		jmp MUX_RESET
MUX_END:
		pop r17
		pop r16
		reti
MUX_RESET:
		sts LINE, ZERO  ; reset mux counter to 0
		lds r17, LINE
MUX_INNER:
		out PORTB, ZERO	; clear portb for next
		INCSRAM SEED    ; incr seed
		lsl r17         ; double leftshift 
		lsl r17			; to place in appropriate PORTA bits
		out PORTA, r17
		call DRAW_GAME  ; draw game
		INCSRAM LINE    ; incr next line
		jmp MUX_END
DRAW_GAME:
		push ZL
		push ZH

		lsr r17         ; double rightshift
		lsr r17         ; reset byte from previous shifts

		ldi ZL, low(VMEM)
		ldi ZH, high(VMEM)
		add ZL, r17
		adc ZH, ZERO

		ld r16, Z
		out PORTB, r16

		pop ZH
		pop ZL
		ret
		; ---------------------------------------
		; --- JOYSTICK Sense stick and update POSX , POSY
		; --- Uses :

JOYSTICK :
;*** skriv kod som okar eller minskar POSX beroende ***
;*** pa insignalen fran A/D - omvandlaren i X - led ... ***
;*** ... och samma for Y - led ***
        push r16
        push r17

JOY_READY_X:
        ; configure ADC on ADC00
		ldi r16, (0<<REFS1) | (0<<REFS0)
		out ADMUX, r16
        ; enable adc with prescaling 0|1|1
		ldi r16, (1<<ADEN) | (1<<ADSC) | (0<<ADPS2) | (1<<ADPS1) | (1<<ADPS0)
		out ADCSRA, r16
		
JOY_PARSE_X:
		;in r17, ADCSRA      ; Other alternative than hardcoded check on bit 6
		;andi r17, (1<<ADSC)
		;cp r17, ZERO
		;brne JOY_PARSE_X

        in r17, ADCSRA
        sbic ADCSRA, 6      ; Listen on 6th bit (the ADSC "flag")
        jmp JOY_PARSE_X

		in r16, ADCH        ; Get moste significant byte
		andi r16, $03       ; Mask byte for most significant bits (0000 0011)

		cpi r16, $03        ; if equals 0000 0011 
		breq JOY_INC_POSX   ; then increase XPOS

		cpi r16, $00        ; if equals 0000 0000
		breq JOY_DEC_POSX   ; then decrease YPOS

		jmp JOY_READY_Y

JOY_INC_POSX:
		INCSRAM POSX
		jmp JOY_READY_Y
JOY_DEC_POSX:
		DECSRAM POSX
JOY_READY_Y:
        ; configure ADC on ADC02
		ldi r16, (0<<REFS1) | (0<<REFS0) | (1<<MUX0)
		out ADMUX, r16
		ldi r16, (1<<ADEN) | (1<<ADSC) | (0<<ADPS2) | (1<<ADPS1) | (1<<ADPS0)
		out ADCSRA, r16

JOY_PARSE_Y:
        ; Same procedure as with POSX
		;in r17, ADCSRA
		;andi r17, (1<<ADSC)
		;cp r17, ZERO
		;brne JOY_PARSE_Y
        sbic ADCSRA, 6
        jmp JOY_PARSE_Y

		in r16, ADCH
		andi r16, $03     

		cpi r16, $03       
		breq JOY_INC_POSY

		cpi r16, $00       
		breq JOY_DEC_POSY

		jmp JOY_LIM
JOY_INC_POSY:
		INCSRAM POSY
		jmp JOY_LIM
JOY_DEC_POSY:
		DECSRAM POSY
JOY_LIM:
		call LIMITS ; don ’ t fall off world !*/
        pop r17
        pop r16
		ret
		; ---------------------------------------
		; --- LIMITS Limit POSX , POSY coordinates
		; --- Uses : r16 , r17
LIMITS:
		lds r16 , POSX ; variable
		ldi r17 ,7 ; upper limit +1
		call POS_LIM ; actual work
		sts POSX , r16
		lds r16 , POSY ; variable
		ldi r17 ,5 ; upper limit +1
		call POS_LIM ; actual work
		sts POSY , r16
		ret
POS_LIM:
		ori r16 ,0 ; negative ?
		brmi POS_LESS ; POSX neg = > add 1
		cp r16 , r17 ; past edge
		brne POS_OK
		subi r16 ,2
POS_LESS:
		inc r16
POS_OK:
		ret
		; ---------------------------------------
		; --- UPDATE VMEM
		; --- with POSX /Y , TPOSX /Y
		; --- Uses : r16 , r17 , Z
UPDATE:
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
SETPOS:
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
SETBIT:
		ldi r16 , $01 ; bit to shift
SETBIT_LOOP:
		dec r17
		brmi SETBIT_END ; til done
		lsl r16 ; shift
		jmp SETBIT_LOOP
SETBIT_END:
		ret
		; ---------------------------------------
		; --- Hardware init
		; --- Uses :
HW_INIT:
;*** Konfigurera hardvara och MUX - avbrott enligt ***
;*** ditt elektriska schema . Konfigurera ***
;*** flanktriggat avbrott pa INT0 ( PD2 ). ***
; // KLART
        
        ; CONFIGURE MUX INT01 interruption
		ldi r16, (1 << ISC01) | (0 << ISC00)   
		out MCUCR, r16
		ldi r16, (1 << INT0)
		out GICR, r16

		sei ; display on

		ldi r16, $1C			; Ladda de port som ska vara output i port a
		out DDRA, r16			; Sätt den alla portar i port a till output
		
		ldi r16, $FF			; Ladda de port som ska vara output i port b
		out DDRB, r16			; Sätt den alla portar i port b till output

		ldi BPITCH, BEEP_PITCH1
		ldi BLENGTH, BEEP_LENGTH1
		clr ZERO
		sts LINE, ZERO          ; Nollställer LINE

		ret
		; ---------------------------------------
		; --- WARM start . Set up a new game .
		; --- Uses :
WARM:
;*** Satt startposition ( POSX , POSY )=(0 ,2) ***
        push r16

		ldi r16, $00    ; Set starting xposition to 0
		sts POSX, r16   ; Write to SRAM posx
		ldi r16, $02    ; Set starting uposition to 2
		sts POSY, r16   ; Write to SRAM posy

		push r0
		push r0
		call RANDOM 

;*** RANDOM returns TPOSX, TPOSY on stack ***
;*** Satt startposition ( TPOSX , TPOSY ) ***
		pop r16
		sts TPOSY, r16	; Store y value from stack
		pop r16
		sts TPOSX, r16  ; Store x value from stack

		call ERASE
        pop r16
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
RANDOM:
        push r16
		in r16, SPH
		mov ZH, r16
		in r16, SPL
		mov ZL, r16
		lds r16, SEED

;*** Anvand SEED for att berakna TPOSX ***
;*** Anvand SEED for att berakna TPOSY ***
;		*** ; store TPOSX 2..6
;		*** ; store TPOSY 0..4
RANDOM_Y:
		andi r16, $07       ; Mask byte with 0000 0111 (limit to 7)
		cpi  r16, $05       ; Is random lower than 5?
		brlo RND_Y_DONE     ; Limit it
RND_TRIM_Y:
		andi r16, $03       ; Mask byte with 0000 0011 (its either 5, 6 or 7)
							; After mask it is 3 or 2         
RND_Y_DONE:
        std Z+4, r16        ; store POSY to stack

RANDOM_X:
		lds r16, SEED
		andi r16, $1C       ; Mask byte with 0001 1100 (take other bits in seed)
		lsr r16             ; adjust offset 
		lsr r16             ; finished at 0000 0111

		cpi r16, $02        ; Is X lower than 2?
		brlo RND_TRIM_LX    ; Limit it

		cpi r16, $07        ; Is X higher or same as 7?
		brsh RND_TRIM_HX    ; Limit it
		jmp RANDOM_X_DONE
RND_TRIM_LX:
		ori r16, $02       ; Mask byte with 0000 0010 (its either 0 or 1)
						   ; After mask value is 2 or 3
		jmp RANDOM_X_DONE
RND_TRIM_HX:
		andi r16, $03       ; Mask byte with 0000 0011
							; After mask value is 3 or 2
RANDOM_X_DONE:
		std Z+5, r16        ; store POSX to stack
RANDOM_DONE:
        pop r16             ; pop
		ret

		; ---------------------------------------
		; --- ERASE videomemory
		; --- Clears VMEM .. VMEM +4
		; --- Uses :
ERASE:
;*** Radera videominnet ***
		push ZL
		push ZH
		push r17
		clr r17
		ldi ZL, low(VMEM)
		ldi ZH, high(VMEM)
ERASE_LOOP:
		st Z+, ZERO 
		inc r17
		cpi r17, VMEM_SZ
		brsh ERASE_END
		jmp ERASE_LOOP
ERASE_END:
		pop r17
		pop ZH
		pop ZL
		ret
		; ---------------------------------------
		; --- BEEP ( r16 ) r16 half cycles of BEEP - PITCH
		; --- Uses :

VICTORY_BEEP:
		ldi BPITCH, BEEP_PITCH2
		call BEEP
		ldi BLENGTH, BEEP_PITCH3
		call BEEP
		ldi BLENGTH, BEEP_PITCH1
		call BEEP
		call BEEP
		call BEEP
		ret
BEEP:
;*** skriv kod for ett ljud som ska markera traff ***
		push r17
		push r22
		push r21
		mov r17, BLENGTH
BEEP_WAVE:
		sbi PORTB, 7
		call BEEP_DELAY
		cbi PORTB, 7
		call BEEP_DELAY
		dec r17
		cpi r17, 0
		brne BEEP_WAVE
BEEP_END:
		pop r21
		pop r22
		pop r17
		ret
BEEP_DELAY:
		mov r21, BPITCH
BEEP_OUTER_LOOP:
		ldi     r22, 12
BEEP_INNER_LOOP:
		dec     r22
		brne    BEEP_INNER_LOOP
		dec     r21
		brne    BEEP_OUTER_LOOP
		ret

DELAY:				
		ldi     r21, 255   ; Decimal bas
delayYttreLoop:
		ldi     r22, 255
delayInreLoop:
		dec     r22
		brne    delayInreLoop
		dec     r21
		brne    delayYttreLoop
		ret