/*
 * Delay.asm
 *
 *  Created: 2025-05-05 ?? 3:16:29
 *   Author: kana0
 */ 
 ; time delay funcion (r25:r24 mili seconds)
delay_ms:
	call	delay1mS
	sbiw	r25:r24, 1 
	brne	delay_ms
ret	

delay1mS:    ; 약 16000 clk >  약 1ms 지연
	push	YH				
	push	YL		
	ldi YL, low(((F_CPU/1000)-18)/4) ;  ~4000
	ldi YH, high(((F_CPU/1000)-18)/4)

delay1ms_01:  ; 약 4clk을 4000번 반복
	sbiw	YH:YL, 1
	brne	delay1ms_01	

	pop	YH							 
	pop YL							 
ret	

delay4us:
	push	r24
	ldi		r24, 200		; 약 10us (16MHz 기준)  50
L1:	dec		r24
	brne	L1
	pop		r24
	ret