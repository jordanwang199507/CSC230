; CSC 230 - Summer 2017 Assignment2.asm
; By: Jordan (Yu-Lin) Wang
;V00786970
; Some starter code for Assignment 2. You do not have
; to use this code if you'd rather start from scratch.
;
; B. Bird - 06/01/2017

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                        Constants and Definitions                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Special register definitions
.def Current = r24
.def Direction = r25
.def XL = r26
.def XH = r27
.def YL = r28
.def YH = r29
.def ZL = r30
.def ZH = r31

; Stack pointer and SREG registers (in data space)
.equ SPH = 0x5E
.equ SPL = 0x5D
.equ SREG = 0x5F

; Initial address (16-bit) for the stack pointer
.equ STACK_INIT = 0x21FF

; Port and data direction register definitions (taken from AVR Studio; note that m2560def.inc does not give the data space address of PORTB)
.equ DDRB = 0x24
.equ PORTB = 0x25
.equ DDRL = 0x10A
.equ PORTL = 0x10B

; Definitions for the analog/digital converter (ADC) (taken from m2560def.inc)
; See the datasheet for details
.equ ADCSRA = 0x7A ; Control and Status Register
.equ ADCSRB	= 0x7B ; Control and Status Register B
.equ ADMUX = 0x7C ; Multiplexer Register
.equ ADCL = 0x78 ; Output register (high bits)
.equ ADCH = 0x79 ; Output register (low bits)

; Definitions for button values from the ADC
; Some boards may use the values in option B
; The code below used less than comparisons so option A should work for both
; Option A (v 1.1)
;.equ ADC_BTN_RIGHT = 0x032
;.equ ADC_BTN_UP = 0x0FA
;.equ ADC_BTN_DOWN = 0x1C2
;.equ ADC_BTN_LEFT = 0x28A
;.equ ADC_BTN_SELECT = 0x352
; Option B (v 1.0)
.equ ADC_BTN_RIGHT = 0x032
.equ ADC_BTN_UP = 0x0C3
.equ ADC_BTN_DOWN = 0x17C
.equ ADC_BTN_LEFT = 0x22B
.equ ADC_BTN_SELECT = 0x316


; Definitions of the special register addresses for timer 0 (in data space)
.equ GTCCR = 0x43
.equ OCR0A = 0x47
.equ OCR0B = 0x48
.equ TCCR0A = 0x44
.equ TCCR0B = 0x45
.equ TCNT0  = 0x46
.equ TIFR0  = 0x35
.equ TIMSK0 = 0x6E

; Definitions of the special register addresses for timer 1 (in data space)
.equ TCCR1A = 0x80
.equ TCCR1B = 0x81
.equ TCCR1C = 0x82
.equ TCNT1H = 0x85
.equ TCNT1L = 0x84
.equ TIFR1  = 0x36
.equ TIMSK1 = 0x6F

; Definitions of the special register addresses for timer 2 (in data space)
.equ ASSR = 0xB6
.equ OCR2A = 0xB3
.equ OCR2B = 0xB4
.equ TCCR2A = 0xB0
.equ TCCR2B = 0xB1
.equ TCNT2  = 0xB2
.equ TIFR2  = 0x37
.equ TIMSK2 = 0x70

.cseg
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                          Reset/Interrupt Vectors                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.org 0x0000 ; RESET vector
	jmp main_begin

; The interrupt vector for timer 0 overflow is 0x2e
.org 0x002e
	jmp TIMER0_OVERFLOW_ISR 
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Main Program                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; According to the datasheet, the last interrupt vector has address 0x0070, so the first
; "unreserved" location is 0x0074
.org 0x0074
main_begin:

	; Initialize the stack
	ldi r16, high(STACK_INIT)
	sts SPH, r16
	ldi r16, low(STACK_INIT)
	sts SPL, r16

	; Set DDRB and DDRL
	ldi r16, 0xff
	sts DDRL, r16
	sts DDRB, r16

	; Set up ADCSRA (ADEN = 1, ADPS2:ADPS0 = 111 for divisor of 128)
	ldi	r16, 0x87
	sts	ADCSRA, r16
	
	; Set up ADCSRB (all bits 0)
	ldi	r16, 0x00
	sts	ADCSRB, r16
	
	; Set up ADMUX (MUX4:MUX0 = 00000, ADLAR = 0, REFS1:REFS0 = 1)
	ldi	r16, 0x40
	sts	ADMUX, r16

	ldi r16, 0x00
	sts OVERFLOW_INTERRUPT_COUNTER, r16

	ldi r16, 0x3D
	sts SPEED, r16

	ldi r16, 0x01
	sts PAUSE_FLAG, r16

	ldi r16, 0x00
	sts POSITION, r16
	

	ldi Current, 0x00
	ldi Direction, 0x01	
	
	call TIMER0_SETUP ; Set up timer 2 control registers (function below)
	sei ; Set the I flag in SREG to enable interrupt processing

button_test_loop:
	
	; Start an ADC conversion
	
	; Set the ADSC bit to 1 in the ADCSRA register to start a conversion
	lds	r16, ADCSRA
	ori	r16, 0x40
	sts	ADCSRA, r16
	
	; Wait for the conversion to finish
wait_for_adc:
	lds		r16, ADCSRA
	andi	r16, 0x40
	brne	wait_for_adc
	
	; Load the ADC result into the X pair (XH:XL). Note that XH and XL are defined above.
	lds	XL, ADCL
	lds	XH, ADCH

	ldi	r20, low(ADC_BTN_SELECT)
	ldi	r21, high(ADC_BTN_SELECT)
	cp	XL, r20 ; Low byte
	cpc	XH, r21 ; High byte
	brsh button_test_loop

	ldi	r20, low(ADC_BTN_RIGHT)
	ldi	r21, high(ADC_BTN_RIGHT)
	cp	XL, r20 ; Low byte
	cpc	XH, r21 ; High byte
	brlo Right_Button

	ldi	r20, low(ADC_BTN_UP)
	ldi	r21, high(ADC_BTN_UP)
	cp	XL, r20 ; Low byte
	cpc	XH, r21 ; High byte
	brlo Up_Button

	ldi	r20, low(ADC_BTN_DOWN)
	ldi	r21, high(ADC_BTN_DOWN)
	cp	XL, r20 ; Low byte
	cpc	XH, r21 ; High byte
	brlo Down_Button
	

	ldi	r20, low(ADC_BTN_LEFT)
	ldi	r21, high(ADC_BTN_LEFT)
	cp	XL, r20 ; Low byte
	cpc	XH, r21 ; High byte
	brlo Left_Button
	brsh Select_Button

	Up_Button:
		ldi r16, 20
		sts SPEED, r16
		rjmp button_test_loop
	Right_Button:
		ldi r22, 0
		lds r16, SPEED
		sts SPEED, r16
		rjmp button_test_loop	
	Left_Button:
		ldi r22, 1
		rjmp button_test_loop

	Select_Button:
		ldi r22, 2
		rjmp button_test_loop	

	Down_Button:
		ldi r16, 0x3D
		sts SPEED, r16
		rjmp button_test_loop
	
	


TIMER0_SETUP:
	push r16
	
	; Control register A
	; We set all bits to 0, which enables "normal port operation" and no output-compare
	; mode for all of the bit fields in TCCR0A and also disables "waveform generation mode"
	ldi r16, 0x00
	sts TCCR0A, r16
	
	; Control register B
	; Select prescaler = clock/64 and all other control bits 0 (see page 126 of the datasheet)
	ldi r16, 0x05 
	sts	TCCR0B, r16
	
	; Interrupt mask register (to select which interrupts to enable)
	ldi r16, 0x01 ; Set bit 0 of TIMSK0 to enable overflow interrupt (all other bits 0)
	sts TIMSK0, r16
	
	; Interrupt flag register
	; Writing a 1 to bit 0 of this register clears any interrupt state that might
	; already exist (thereby resetting the interrupt state).
	
	;change r16 to memory 
	;ldi r16, 0x01
	lds r16, PAUSE_FLAG
	sts TIFR0, r16
	
	pop r16
	ret

; TIMER0_OVERFLOW_ISR()
TIMER0_OVERFLOW_ISR:

	; protect registers	
	push r16
	lds r16, SREG ; Load the value of SREG into r16
	push r16 ; Push SREG onto the stack
	push r17
	push r18
	push r19
	push r20
	push r21

	ldi r20, 0x01
	; every second, change LED
	
	lds r21, SPEED
	lds r18, OVERFLOW_INTERRUPT_COUNTER
	
	add r18, r20

	cp r21, r18
	brsh timer0_is_done
	
	clr r18
	
	call Clear
	call Regular
	call Function
	
	add Current, Direction

	call First_Check

	call Last_Check

timer0_is_done:

	sts OVERFLOW_INTERRUPT_COUNTER, r18

	pop r21
	pop r20
	pop r19
	pop r18
	pop r17
	pop r16
	sts SREG, r16
	pop r16

	reti

First_Check:
	cpi Current,0
	breq Forward
	ret

Last_Check:
	cpi Current, 5
	breq Backward
	ret

Forward:
	clr Direction
	ldi Direction, 1
	ret

Backward:	
	clr Direction
	ldi Direction, -1
	ret

Function:
	cpi r22, 0x00
	breq Regular
	
	cpi r22, 0x01
	breq abs_Invert

	cpi r22, 0x02
	breq abs_Select
	
	ret

abs_Invert:
	jmp Invert
abs_Select:
	jmp Select

Regular:
	ldi r17, 0x00
	cpi Current, 0x00
	breq LED52

	cpi Current, 0x01
	breq LED50

	cpi Current, 0x02
	breq LED48

	cpi Current, 0x03
	breq LED46

	cpi Current, 0x04
	breq LED44

	cpi Current, 0x05
	breq LED42

	ret

	LED52:
		push r18
		ldi r18, 0x02
		sts PORTL, r17
		sts PORTB, r18
		pop r18
		ret
	LED50:
		push r18
		ldi r18, 0x08
		sts PORTL, r17
		sts PORTB, r18
		pop r18
		ret
	LED48:
		push r18
		ldi r18, 0x02
		sts PORTB, r17
		sts PORTL, r18
		pop r18
		ret
	LED46:
		push r18
		ldi r18, 0x08
		sts PORTB, r17
		sts PORTL, r18
		pop r18
		ret
	LED44:
		push r18
		ldi r18, 0x20
		sts PORTB, r17
		sts PORTL, r18
		pop r18
		ret
	LED42:
		push r18
		ldi r18, 0x80
		sts PORTB, r17
		sts PORTL, r18
		pop r18
		ret

Invert:
	ldi r17, 0xff
	cpi Current, 0x00
	breq Invert_LED52

	cpi Current, 0x01
	breq Invert_LED50

	cpi Current, 0x02
	breq Invert_LED48

	cpi Current, 0x03
	breq Invert_LED46

	cpi Current, 0x04
	breq Invert_LED44

	cpi Current, 0x05
	breq Invert_LED42

	ret

	Invert_LED52:
		push r18
		ldi r18, 0x02
		com r18
		sts PORTL, r17
		sts PORTB, r18
		pop r18
		ret
	Invert_LED50:
		push r18
		ldi r17, 0xff
		ldi r18, 0x08
		com r18
		sts PORTL, r17
		sts PORTB, r18
		pop r18
		ret
	Invert_LED48:
		push r18
		ldi r18, 0x02
		com r18
		sts PORTB, r17
		sts PORTL, r18
		pop r18
		ret
	Invert_LED46:
		push r18
		ldi r18, 0x08
		com r18
		sts PORTB, r17
		sts PORTL, r18
		pop r18
		ret
	Invert_LED44:
		push r18
		ldi r18, 0x20
		com r18
		sts PORTB, r17
		sts PORTL, r18
		pop r18
		ret
	Invert_LED42:
		push r18
		ldi r18, 0x80
		com r18
		sts PORTB, r17
		sts PORTL, r18
		pop r18
		ret

Clear:
	push r16
	
	ldi r16, 0x00
	sts PORTL, r16
	sts PORTB, r16
	
	pop r16	
	ret

Select:
	push r16
	;when select press, pause first 
		; by killing interrupt
			;set memeory for Pauseflag
				;when killing interrupt, set memory to 0
	lds r16, PAUSE_FLAG
	cpi r16, 0x01
	brne unpause
	rjmp pause

pause:

	lds r16, PAUSE_FLAG
	ldi r16, 0x00
	sts PAUSE_FLAG, r16

	;sts POSITION, Direction

	ldi r16, 0x00
	mov Direction, r16


unpause:
	lds r16, PAUSE_FLAG
	ldi r16, 0x01
	sts PAUSE_FLAG, r16

	;lds r16, POSITION
	;mov Direction, r16
	
Select_done:

	pop r16
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Data Section                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.dseg
.org 0x200
; Put variables and data arrays here...
OVERFLOW_INTERRUPT_COUNTER: .byte 1
SPEED: .byte 1
PAUSE_FLAG: .byte 1
POSITION: .byte 1
