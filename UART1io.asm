/*
 * UART1io.asm
 *
 *  Created: 2025-07-16 ?? 8:34:19
 *   Author: kana0
 */ 
  ;**********************************
UART1_Init:
	ldi		temp, high(103)
	sts		UBRR1H, temp
	ldi		temp, low(103)
	sts		UBRR1L, temp		; set baudrate 38400

	ldi		temp, 0x18
	sts		UCSR1B, temp		; Tx, Rx enable without interrupt
	ldi		temp, 0x06
	sts		UCSR1C, temp		; data8 bit, 1 stop bit, no parity bit --- default mode
ret
;*********************************
UART1int_On:
	lds		temp, UCSR1B
	ori		temp, (1<<RXCIE1)	; RXCIE1 == 7  interrupt enable     >> or with 1000000
	sts		UCSR1B, temp
	ret
UART1int_Off:
	lds		temp, UCSR1B
	andi	temp, ~(1<<RXCIE1)	; RXCIE1 == 7  interrupt disable    >> and with 0111111
	sts		UCSR1B, temp
	ret
;*****************************************************
;interrupt service routine (RX)
;*****************************************************
USART1_RXC:
	cli
	in		SREG2, SREG
	push	r24
	push	temp
	
	
	lds		r24, UDR1			; read UDR

	SETXY	Y, RUN_ROT
	st		Y, r24

	ldi		temp, 0x0f

	cpi		r24, 0x31
	brne	WARD_2

	ldi		temp, 0x08
	rjmp	WARD_END
WARD_2:
	cpi		r24, 0x32
	brne	WARD_3

	ldi		temp, 0x04
	rjmp	WARD_END
WARD_3:
	cpi		r24, 0x33
	brne	WARD_4

	ldi		temp, 0x02
	rjmp	WARD_END
WARD_4:
	cpi		r24, 0x34
	brne	WARD_END

	ldi		temp, 0x01
	rjmp	WARD_END

WARD_END:
	sts		PORTG, temp
	ldi		temp, 0xff
	out		PORTC, temp

	pop		temp
	pop		r24
	out		SREG, SREG2
	sei
	reti
;******************************************************
/*
// UART Transmit -- input r24,		send a character to RS232S port
PutChar:
	cpi		r24, CR				; check if r24 == CR
	brne	PutData
InsertLF:
	push	r24					; putchar 하기전 r24 백업 
	ldi		r24, LF
	rcall	PutChar				; LF(줄바꾸고) CR(줄처음)
	pop		r24					; restore r24
PutData:
	sbis	UCSR0A, UDRE0		; skip next instruction if bit is set (UDRE0 = 5)
	rjmp	PutData
								//put data(r24) into buffer, send data to PC
	out		UDR0, r24
ret

// UART Receive -- input r24,		reseive a character from RS232S port
GetChar1:
	sbis	UCSR0A, RXC0		; skip next instruction if bit is set (RXC0 = 7)
	rjmp	GetChar
								//get the received data(r24) from buffer, send data to AVR board
	in		r24, UDR0
ret*/
;---------------------------------------------------------
/*
PutString:
	lpm		r24, Z+
	cpi		r24, EOS
	breq	EXIT
	rcall	PutChar
	rjmp	PutString
EXIT:
	ret
;-------------------------------------------------------
PutStringD:						; print string in buffer to terminal
	ld		r24, Y+
	cpi		r24, EOS
	breq	Exit_P
	rcall	PutChar				; 문자출력
	rjmp	PutStringD
Exit_P:
	ret
;---------------------------------------------------------------------
GetString:						; buffer에 string 저장 + 마지막에 EOS 저장
	push	r24
	push	r25
	push	r28
	push	r29
	clr		r25

Loop:
	rcall	GetChar		; r24에 char 저장
	cpi		r24, CR
	breq	Exit_G
	cpi		r24, BS		; backspace?
	brne	NotBS
	;backspace 처리
	cpi		r25, 0		; 아무것도 입력 안 했으면 무시
	breq	Loop
	sbiw	YH:YL, 1
	dec		r25			; 문자 수 1 감소
	rcall	PutChar		; 뒤로 이동, space, 뒤로이동
	rjmp	Loop
NotBS:
	inc		r25
	rcall	PutChar		; echoing
	st		Y+, r24		; store r24 to buffer
	rjmp	Loop		; CR(enter) 나올 때까지 반복
Exit_G:
	ldi		r24, EOS
	st		Y, r24
	pop		r29
	pop		r28
	pop		r25
	pop		r24
ret

;*************************************
// 
HexDisp:				; print hex format (in = r24, no out)
	push	temp
	push	r25
	mov		r25, r24	; backup r24 for low 4 bit
	lsr		r24
	lsr		r24
	lsr		r24
	lsr		r24
	rcall	I2A
	rcall	PutChar		; print high 4 bit hex

	mov		r24, r25	; restore r24
	andi	r24, 0x0f
	rcall	I2A
	rcall	PutChar		; print low 4 bit hex
	pop		r25
	pop		temp
ret

I2A:					; add offset for integer to ascii (in, out = r24)
	push	temp
	cpi		r24, 10
	brlo	I2A_digit		; if r24 < 10, go to digit conversion
						; r24 >= 10 → convert to 'A'~'F'
	subi	r24, 10			; r24 = 0~5
	ldi		temp, 'A'
	add		r24, temp		; r24 = 'A' + (0~5)
	pop		temp
	ret

I2A_digit:
	ldi		temp, '0'
	add		r24, temp		; r24 = '0' + (0~9)
	pop		temp
ret
;********************************************
HexDisp1:				; store Y reg to r24 data hex format (in = r24, no out)
	push	temp
	push	r25
	mov		r25, r24	; backup r24 for low 4 bit
	lsr		r24
	lsr		r24
	lsr		r24
	lsr		r24
	st		Y+, r24
	rcall	I2A
	rcall	PutChar		; print high 4 bit hex

	mov		r24, r25	; restore r24
	andi	r24, 0x0f
	st		Y+, r24
	rcall	I2A
	rcall	PutChar		; print low 4 bit hex
	pop		r25
	pop		temp
ret
;********************************************
HexDisp2:				; store Y reg to r24 data hex format (in = r24, no out)
	push	temp
	push	r25
	mov		r25, r24	; backup r24 for low 4 bit
	lsr		r24
	lsr		r24
	lsr		r24
	lsr		r24
	st		Y+, r24
	rcall	I2A

	mov		r24, r25	; restore r24
	andi	r24, 0x0f
	st		Y+, r24
	rcall	I2A
	pop		r25
	pop		temp
ret
*/