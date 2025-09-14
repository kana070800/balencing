;
; balancing.asm
;
; Created: 2025-07-02 오후 3:30:10
; Author : kana0
;


; Replace with your application code

  #include "Myinclude.inc"

 #define	refL		r4		
 #define	refH		r5		;FND 와 동시에 사용 x 

 #define	Direction	r7

 .CSEG
	.ORG 0x0000 ;
	JMP		RESET
	.ORG 0x00A
	;jmp		Ext_Int4
	;jmp		Ext_Int5
	.ORG 0x0014
	;jmp		Timer2_ovf		;BUZ
	.ORG 0x001C
	;jmp		Timer1_ovf
	.ORG 0x0024
	;jmp		UART_RXInt
	.ORG 0x0046;

 RESET:
	;방향제어 port A
	ldi		temp, 0x0f		; 0000 1111
	out		DDRA, temp
	; moter 1 >> pin 1, 0       moter 2 >> pin 2, 3 
	ldi		temp, 0x05
	out		PORTA, temp


	;------------------------------------------------------------------
	; 1. 출력지정
	in		temp, DDRB
	ori		temp, (1<<PB6)|(1<<PB7)
	out		DDRB, temp

	; 2. Fast PWM 모드(WGM) + Non-inverting in fast pwm mode (COM1B) + 분주비(CS)
	ldi		temp, (1<<COM1B1)|(1<<COM1C1)|(1<<WGM11)
	out		TCCR1A, temp
	ldi		temp, (1<<WGM13)|(1<<WGM12)|(1<<CS11)|(1<<CS10)
	out		TCCR1B, temp

	; 초기화
	ldi		temp, 0
	out		TCNT1H, temp
	out		TCNT1L, temp
	
	; 3. top 지정 
	ldi		temp, high(2500)
	out		ICR1H, temp
	ldi		temp, low(2500)
	out		ICR1L, temp

	; 4. duty 지정        200/250 부터 유효한 입력
	ldi		temp, high(500)
	out		OCR1BH, temp
	ldi		temp, low(500)
	out		OCR1BL, temp

	ldi		temp, high(250)
	sts		OCR1CH, temp
	ldi		temp, low(250)
	sts		OCR1CL, temp
	;-----------------------------------------------------------------------

forever:
	rjmp	forever

#include	"UARTio.asm"
#include	"Delay.asm"
;#include	"FND.asm"
;#include	"Timer.asm"
;#include	"EXint.asm"
#include	"ADC.asm"
#include	"I2C.asm"



SegData:  ; 0 ~ 16, -, non   FND display data
	.db	0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x27, 0x7f, 0x6f, 0x77, 0x7c, 0x58, 0x5e, 0x79, 0x71, 0x40, 0x00

PhoneNum:
	.db 17, 17, 17, 17, 17, 0, 1, 0, 16, 4, 0, 8, 7, 16, 1, 7, 2, 8, 17, 17, 17, 17
.DSEG
buffer:
	.byte	80
digit4:
	.db 	4

RawAccelBuffer: 
	.byte 6	