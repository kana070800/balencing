/*
 * EXint.asm
 *
 *  Created: 2025-05-14 ?? 1:43:05
 *   Author: kana0
 */ 
 ;***************************************
ExInt_Init:
	cli

	ldi		temp, low(0x00)
	sts		EICRA, temp
	ldi		temp, low(0x02)
	out		EICRB, temp		; use ex interrupt 4,5 as Falling edge

	ldi		temp, 0x10
	out		EIMSK, temp		; set ex interrupt 4,5 enable

	sei
ret

ExInt_Off:
	ldi		temp, 0x00
	out		EIMSK, temp		; set ex interrupt 4,5 disable
	ret
;*******************************************
Ext_Int5: ; ex interrupt 5 service routine
	cli
	in		SREG2, SREG
	push	r24
	push	r25				; in DELAYS func

	clr		TESTmode	; change state of timer
	DELAYMS	10				; wait 10m sec for protection from glitch

	pop		r25
	pop		r24
	out		SREG, SREG2
	sei
reti
;********************************************************
Ext_Int4: ; ex interrupt 4 service routine
	cli
	in		SREG2, SREG
	push	r24
	push	r25				; in DELAYS func

	clr		TESTmode	; change state of timer
	DELAYMS	10				; wait 10m sec for protection from glitch

	pop		r25
	pop		r24
	out		SREG, SREG2
	sei
reti
;*******************************************************
EX_MPU_Init:
	cli

	ldi		temp, low(0x00)
	sts		EICRA, temp
	ldi		temp, low(0x38)
	out		EICRB, temp		; use ex interrupt 5 as Falling edge, 6 as rising edge

	ldi		temp, 0x60
	out		EIMSK, temp		; set ex interrupt 5,6 enable

	sei
ret
;************************************************
Ext_Int6:
	sei
	in		SREG2, SREG
	push	r31
	push	r30
	push	r29
	push	r28
	push	r27
	push	r26
	push	r25
	push	r24
	push	r23
	push	r22
	push	r21
	push	r20
	push	r19
	push	r18
	push	r17
	push	r16
	push	r15
	push	r14
	push	r13
	push	r12
	push	r11
	push	r10
	push	r9
	push	r8
	push	r7
	push	r6
	push	r5
	push	r4
	push	r3
	push	r2
	push	r1
	push	r0

	rcall	Read_MPU

	SETXY	X, HARD_RE
	ld		temp, X
	cpi		temp, 100		;1 = 일단 에러나면 종료
	brlo	KEEP_GO

	clr		temp
	out		PORTA, temp
	out		OCR1BH, temp
	out		OCR1BL, temp

	sts		OCR1CH, temp
	sts		OCR1CL, temp
	rjmp	STOP_PWM

KEEP_GO:
	rcall	DUTY_GEN
STOP_PWM:
	pop		r0
	pop		r1
	pop		r2
	pop		r3
	pop		r4
	pop		r5
	pop		r6
	pop		r7
	pop		r8
	pop		r9
	pop		r10
	pop		r11
	pop		r12
	pop		r13
	pop		r14
	pop		r15
	pop		r16
	pop		r17
	pop		r18
	pop		r19
	pop		r20
	pop		r21
	pop		r22
	pop		r23
	pop		r24
	pop		r25
	pop		r26
	pop		r27
	pop		r28
	pop		r29
	pop		r30
	pop		r31
	out		SREG, SREG2
reti