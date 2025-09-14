/*
 * Timer.asm
 *
 *  Created: 2025-05-14 ?? 1:42:52
 *   Author: kana0
 */ 
;*****************************************

;****************************************
Timer2_Init:
	ldi		temp, 0x07
	out		TCCR2, temp			 ; timer clk = 16Mhz / 1064 / 256 = 주기 == 약 59 hz

	ldi		temp,  0			 ; 초기값/기준값
	out		TCNT2, temp	 

	ldi		temp, 0x40			 ;ldi	temp, 1<<6
	out		TIMSK, temp			; timer2-overflow interrupt 활성화
ret
;*****************************************

Timer2_ovf:						 ; change BUZmode for make sound i want(pulse)
	cli
	in		SREG2, SREG			; back up status reg
	push	temp


	SETXY	Y, HARD_RE
	ld		temp, Y 
	inc		temp

	cpi		temp, 10
	brlo	END_TIMER	
	
	ldi		temp, 0
	out		PORTA, temp

END_TIMER:
	
	st		Y, temp

	pop		temp
	OUT		SREG, SREG2			; restore status reg
	sei
reti
	;****************************************
Timer2_Init2:
	ldi		temp, 0x05
	out		TCCR2, temp		; timer clk = 16Mhz / 8

	ldi		temp, 0		  ; 초기값/기준값
	out		TCNT2, temp	 

	ldi		temp, 0x40
	out		TIMSK, temp			; timer3-overflow interrupt 활성화
ret
;*****************************************
