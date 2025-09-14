/*
 * ADC.asm
 *
 *  Created: 2025-05-14 ?? 7:48:07
 *   Author: kana0
 */ 
 ;*************************************
ADC_Init:
	out		ADMUX, r0	;initial AREF, ARLAR=0, MUX(4:0)=0, use ADC0 single ended

	ldi		temp, 0x87
	out		ADCSRA, temp	; ADEN=1, single=0, AADPS(2:0)=111  16M/128
	ret
;*************************************
Read_ADC:
	in		temp, ADCSRA
	ori		temp, 0x40 
	out		ADCSRA, temp	; ADC start Conversion(ADCS = 1)
ADCwait:
	in		temp, ADCSRA	; ADIF = 4bit
	sbrs	temp, ADIF		;skip next instruction if reg set(conversion complete)
	rjmp	ADCwait

	in		ADdataL, ADCL
	in		ADdataH, ADCH	;store data
	ret
;****************************************
ADC_Off:
	ldi		temp, 0x00
	out		ADCSRA, temp
	ret