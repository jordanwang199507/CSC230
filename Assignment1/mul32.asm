; mul32.asm
; CSC 230 - Summer 2017
; Jordan (Yu-Lin) Wang V00786970
; Starter code for assignment 1
;
; B. Bird - 04/30/2017

.cseg
.org 0


	; Initialization code
	; Do not move or change these instructions or the registers they refer to. 
	; You may change the data values being loaded.
	; The default values set A = 0x3412 and B = 0x2010

	ldi r16, 0x52 ; Low byte of operand A
	ldi r17, 0x26 ; High byte of operand A
	ldi r18, 0x81 ; Low byte of operand B
	ldi r19, 0x19 ; High byte of operand B


	
	; Your task: compute the 32-bit product A*B (using the bytes from registers r16 - r19 above as the values of
	; A and B) and store the result in the locations OUT3:OUT0 in data memory (see below).
	; You are encouraged to use a simple loop with repeated addition, not the MUL instructions, although you are
	; welcome to use MUL instructions if you want a challenge.
	
	clr r20
	clr r21
	clr r22
	clr r23
	clr r24
	clr r25
	clr r26

	ldi r27, 0x01

multiply_loop:
	
	add r20, r16
	adc r21, r17
	adc r22, r24
	adc r23, r24

	add r25, r27
	adc r26, r24

	cp r18, r25
	breq branch_check
	rjmp multiply_loop

branch_check:

	cp r19, r26
	breq final_result
	rjmp multiply_loop

final_result: 
	sts OUT0, r20
	sts OUT1, r21
	sts OUT2, r22
	sts OUT3, r23
	rjmp stop
	
	
	
	; End of program (do not change the next two lines)
stop:
	rjmp stop

	
; Do not move or modify any code below this line. You may add extra variables if needed.
; The .dseg directive indicates that the following directives should apply to data memory
.dseg 
.org 0x200 ; Start assembling at address 0x200 of data memory (addresses less than 0x200 refer to registers and ports)

OUT0:	.byte 1 ; Bits  7...0 of the output value
OUT1:	.byte 1 ; Bits 15...8 of the output value
OUT2:	.byte 1 ; Bits 23...16 of the output value
OUT3:	.byte 1 ; Bits 31...24 of the output value
