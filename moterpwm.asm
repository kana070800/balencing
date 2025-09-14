/*
 * moterpwm.asm
 *
 *  Created: 2025-06-01 ?? 1:24:49
 *   Author: kana0
 */ 
;********************************
PWM_Init:
	push	temp
	; 1. OC2 ��(PB7) ��� ����
	in temp, DDRB
	ori temp, (1<<PB7)
	out DDRB, temp

	; 2. Fast PWM ��� + Non-inverting ���
	ldi temp, (1<<WGM21)|(1<<WGM20)|(1<<COM21)
	out TCCR2, temp

	; 3. ���ֺ� clk/64
	ori temp, (1<<CS22)
	out TCCR2, temp
	pop		temp
ret
;***********************
PWM_Off:
	push temp

	; 1. Stop Timer2 (PWM)
	clr temp
	out TCCR2, temp

	; 2. OC2 �� (PB7) �� LOW ������� ����
	in temp, DDRB
	ori temp, (1<<PB7)
	out DDRB, temp

	in temp, PORTB
	andi temp, ~(1<<PB7)
	out PORTB, temp

	; 3. ���� �� (PORTD ��ü LOW)
	clr temp
	out PORTD, temp

	pop temp
	ret