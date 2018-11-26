;Assignment_3.asm
;By: Jordan (Yu-Lin) Wang
; V00786970
; CSC 230 - Summer 2017
; A3 Starter code
; B. Bird - 06/29/2017
; No data address definitions are needed since we use the "m2560def.inc" file
.include "m2560def.inc"
.include "lcd_function_defs.inc"

.equ ADC_BTN_RIGHT = 0x032
.equ ADC_BTN_UP = 0x0C3
.equ ADC_BTN_DOWN = 0x17C
.equ ADC_BTN_LEFT = 0x22B
.equ ADC_BTN_SELECT = 0x316

.equ SPH_DATASPACE = 0x5E
.equ SPL_DATASPACE = 0x5D
.equ STACK_INIT = 0x21FF

.cseg
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                          Reset/Interrupt Vectors                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.org 0x0000 ; RESET vector
	jmp main_begin
	
; Add interrupt handlers for timer interrupts here. See Section 14 (page 101) of the datasheet for addresses.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Main Program                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.org 0x001e
	jmp TIMER2_OVERFLOW_ISR

.org 0x0072
main_begin:	
; Initialize the stack
	ldi r16, high(STACK_INIT)
	sts SPH_DATASPACE, r16
	ldi r16, low(STACK_INIT)
	sts SPL_DATASPACE, r16

; Set DDRB and DDRL	
	ldi r16, 0xff
	sts DDRL, r16
	sts DDRB, r16		
	
	push r19
	ldi r19, 1
	sts PAUSE_INDEX, r19
	pop r19

;initialize time	
	ldi r16, 0
	sts Add1, r16
	sts Tenth, r16
	sts Minute_1, r16
	sts Minute_2, r16
	sts Second_1, r16
	sts Second_2, r16

	clr r16

	call lcd_init

	ldi YL, low(LINE_1)
	ldi YH, high(LINE_1)

	; Set up the lcd display starting row 0 column 0
	ldi r16, 0  ; Row number 0
	push r16
	ldi r16, 0  ; Column number 0
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	ldi r16, 'T'
	st Y+, r16
	ldi r16, 'i'
	st Y+, r16
	ldi r16, 'm'
	st Y+, r16
	ldi r16, 'e'
	st Y+, r16
	ldi r16, ':'
	st Y+, r16
	ldi r16, ' '
	st Y+, r16
	ldi r16, 0
	st Y+, r16

	;Display the string
	ldi r16, high(LINE_1)
	push r16
	ldi r16, low(LINE_1)
	push r16
	call lcd_puts
	pop r16

	call TIMER2_SETUP
	call display_time

	jmp main_loop


Scan_Buttons:
	push r16

	  ; Set up the ADC   
    ldi    r16, 0x87
    sts    ADCSRA, r16  
    ldi    r16, 0x00
    sts    ADCSRB, r16  
    ldi    r16, 0x40
    sts    ADMUX, r16

	ldi r20, low(ADC_BTN_SELECT)
	ldi r21, high(ADC_BTN_SELECT)

Button_Loop:	
	lds r16, ADCSRA
	ori r16, 0x40
	sts ADCSRA, r16

wait_for_adc:
	lds		r16, ADCSRA
	andi	r16, 0x40
	brne	wait_for_adc

	lds	XL, ADCL
	lds	XH, ADCH
	
	ldi	r20, low(ADC_BTN_SELECT)
	ldi	r21, high(ADC_BTN_SELECT)
	cp	XL, r20 ; Low byte
	cpc	XH, r21 ; High byte
	brsh Mid_Point

	lds r28, IGNORE_INDEX
	cpi r28, 0x01
	breq Loop_Done
	
	ldi	r20, low(ADC_BTN_LEFT)
	ldi	r21, high(ADC_BTN_LEFT)
	cp	XL, r20 ; Low byte
	cpc	XH, r21 ; High byte
	brlo Left_Button
	brsh Select_Button

	pop r16
	ret

main_loop:
	rjmp main_loop

Loop_Done:
	pop r16
	ret

Mid_Point:
	rjmp Reset

Reset:
	push r28
	ldi r28, 0x00
	sts IGNORE_INDEX, r28
	pop r28
	pop r16
	ret

Select_Button:
	lds r18, PAUSE_INDEX
	cpi r18, 0x00
	breq Pause
	cpi r18, 0x01
	breq Unpause
	
	pop r16
	ret

Pause: 
	ldi r18, 0x01
	push r17
	ldi r17, 0x00
	sts Add1, r17
	pop r17
	push r28
	ldi r28, 0x01
	sts IGNORE_INDEX, r28
	pop r28
	pop r16
	ret

Unpause:
	ldi r18, 0x00
	push r17
	ldi r17, 0x01
	sts Add1, r17
	pop r17
	push r28
	ldi r28, 0x01
	sts IGNORE_INDEX, r28
	pop r28
	pop r16
	ret

Left_Button:
	ldi r16, 0x00
	sts Tenth, r16
	sts Second_1, r16
	sts Second_2, r16
	sts Minute_1, r16
	sts Minute_2, r16
	sts Add1, r16
	
	push r28
	ldi r28, 0x01
	sts IGNORE_INDEX, r28
	pop r28
	pop r16
	ret

	
TIMER2_SETUP:
	push r16

	ldi r16, 0x00
	sts TCCR2A, r16
	ldi r16, 0x06
	sts TCCR2B, r16
	ldi r16, 0x01
	sts TIMSK2, r16
	ldi r16, 0x01
	sts TIFR2, r16

	sei

	pop r16
	ret

TIMER2_OVERFLOW_ISR:
	push r16
	lds r16, SREG
	push r16
	push r17
	push r18

	call Scan_Buttons

	lds r16, OVERFLOW_INTERRUPT_COUNTER
	lds r17, Add1
	add r16, r17
	sts OVERFLOW_INTERRUPT_COUNTER, r16

	cpi r16, 24
	brlo timer2_isr_done

	clr r16
	sts OVERFLOW_INTERRUPT_COUNTER, r16

	call display_time

	lds r16, Tenth 
	inc r16
	sts Tenth, r16
	clr r16
	call Set_Tenth
		
timer2_isr_done:
	call display_time
	sts OVERFLOW_INTERRUPT_COUNTER, r16

	pop r18
	pop r17

	pop r16
	sts SREG, r16

	pop r16

	reti
				
display_time:	
	push r16
	push ZL
	push ZH

	ldi ZL, low(LINE_1)
	ldi ZH, high(LINE_1)

	;set LCD to display first line
	ldi r16, 0x00
	push r16
	ldi r16, 0x06
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	lds r16, Minute_1
	call GET_DIGIT
	st Z+, r16
	lds r16, Minute_2
	call GET_DIGIT
	st Z+, r16
	ldi r16, ':'
	st Z+, r16
	lds r16, Second_1
	call GET_DIGIT
	st Z+, r16
	lds r16, Second_2
	call GET_DIGIT
	st Z+, r16	
	ldi r16, '.'
	st Z+, r16
	lds r16, Tenth
	call GET_DIGIT
	st Z+, r16
	ldi r16, 0
	st Z, r16

	;now call lcd_puts to display string
	ldi r16, high(LINE_1)
	push r16
	ldi r16, low(LINE_1)
	push r16
	call lcd_puts
	pop r16
	pop r16
	
	pop ZH
	pop ZL
	pop r16

	ret

Set_Minute_2:
	ldi r16, 0
	sts Second_1, r16
	lds r16, Minute_2
	lds r17, Add1
	add r16, r17
	sts Minute_2, r16
	
	cpi r16, 10
	brsh Set_Minute_1
	clr r16
	pop r16
	ret

Set_Minute_1:
	ldi r16, 0
	sts Minute_2, r16
	lds r16, Minute_1
	lds r17, Add1
	add r16, r17
	sts Minute_1, r16
	cpi r16, 10
	brsh Over
	clr r16
	pop r16
	ret

Set_Tenth:
	push r16

	lds r16, Tenth
	cpi r16, 10
	brsh Set_Second_2
	pop r16

	ret

Set_Second_2:
	ldi r16, 0 
	sts Tenth, r16
	lds r16, Second_2
	lds r17, Add1
	add r16, r17
	sts Second_2, r16
	cpi r16, 10
	brsh Set_Second_1
	clr r16
	pop r16
	ret

Set_Second_1:
	ldi r16, 0
	sts Second_2, r16
	lds r16, Second_1
	lds r17, Add1
	add r16, r17
	sts Second_1, r16
	cpi r16, 6
	brsh Set_Minute_2
	clr r16
	pop r16
	ret

Over:
	jmp timer2_isr_done
	 
; GET_DIGIT( d: r16 )
; Given a value d in the range 0 - 9 (inclusive), return the ASCII character
; code for d. This function will produce undefined results if d is not in the
; required range.
; The return value (a character code) is stored back in r16

GET_DIGIT:
	push r17
	
	; The character '0' has ASCII value 48, and the character codes
	; for the other digits follow '0' consecutively, so we can obtain
	; the character code for an arbitrary single digit by simply
	; adding 48 (or just using the constant '0') to the digit.
	ldi r17, '0' ; Could also write "ldi r17, 48"
	add r16, r17
	
	pop r17
	ret





	;set the speed to 0 ; ~~~~~~~~~~~~~~		
	
; Include LCD library code
.include "lcd_function_code.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Data Section                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.dseg
; Note that no .org 0x200 statement should be present

LINE_1: .byte 100
LINE_2: .byte 100
OVERFLOW_INTERRUPT_COUNTER: .byte 1

Minute_1: .byte 1
Minute_2: .byte 1
Second_1: .byte 1
Second_2: .byte 1
Tenth: .byte 1

Add1: .byte 1
IGNORE_INDEX: .byte 1
PAUSE_INDEX: .byte 1


