/*
 * bluetooth_test.asm
 *
 *  Created: 2025-07-16 ?? 9:30:03
 *   Author: kana0
 */ 

 #include	"Myinclude.inc"

 .CSEG
	.ORG 0x0000 ;
	JMP		RESET
	.ORG 0x003C
	jmp		USART1_RXC
	.ORG 0x0046;

 RESET:

	ldi		temp, high(RAMEND)
	out		SPH,  temp
	ldi		temp, low(RAMEND)
	out		SPL,  temp

	ldi		temp, 0xff
	out		DDRA, temp

	rcall	UART1_Init
	rcall	UART1int_On

	sei
forever:
	rjmp	forever

#include	"UART1io.asm"

