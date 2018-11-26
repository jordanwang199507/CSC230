; divmod16.asm
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
	; The default values set A = 0x3412 and B = 0x0003
	ldi r16, 0x28 ; Low byte of operand A
	ldi r17, 0x82 ; High byte of operand A
	ldi r18, 0x82 ; Low byte of operand B
	ldi r19, 0x00 ; High byte of operand B
	
	; Your task: Perform the integer division operation A/B and store the result in data memory. 
	; Store the 2 byte quotient in DIV1:DIV0 and store the 2 byte remainder in MOD1:MOD0.
		
	clr r20
	clr r21
	clr r22 
	clr r23 
	clr r24 
	clr r25 
	clr r26 

	mov r20, r16
	mov r21, r17
	ldi r29, 0x01

divide_loop:
		
	cp r21, r19
	brlo final_result
	breq branch_check

	sub r20, r18
	sbc r21, r19

	add r25, r29
	adc r26, r24

	rjmp divide_loop

branch_check:

	cp r20, r18
	brlo final_result

	sub r20, r18
	sbc r21, r19

	add r25, r29
	adc r26, r24

	rjmp divide_loop

final_result: 

	sts DIV0, r25
	sts DIV1, r26
	sts MOD0, r20
	sts MOD1, r21
	rjmp stop
		
	
	
	; End of program (do not change the next two lines)
stop:
	rjmp stop
	
; Do not move or modify any code below this line. You may add extra variables if needed.
; The .dseg directive indicates that the following directives should apply to data memory
.dseg 
.org 0x200 ; Start assembling at address 0x200 of data memory (addresses less than 0x200 refer to registers and ports)

DIV0:	.byte 1 ; Bits  7...0 of the quotient
DIV1:	.byte 1 ; Bits 15...8 of the quotient
MOD0:	.byte 1 ; Bits  7...0 of the remainder
MOD1:	.byte 1 ; Bits 15...8 of the remainder
