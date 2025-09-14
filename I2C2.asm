/*
 * I2C2.asm
 *
 *  Created: 2025-07-15 ?? 7:00:58
 *   Author: kana0
 */ 
 ;************************************************************
 TWI_Init:
	ldi		temp, 0x03;
	out		PORTD,temp									; �µ������� SCL, SCA pull up on

	// Set i2c bitrate to 400K
	ldi		temp, 12
	sts		TWBR, temp
	ldi		temp, (0<<TWPS1)|(0<<TWPS0)
	sts		TWSR, temp

	ret
;**************************************************************
TWI_Start:
	ldi		temp, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)		; sends START to slave
	sts		TWCR, temp
	rcall	WAIT_TWINT
	ret
;**************************************************************
TWI_Off:
	ldi		temp, 0x00
	out		PORTD,temp

	ldi		temp, 0
	sts		TWBR, temp
	sts		TWSR, temp
	ret
;**************************************************************
TWI_Stop:
	ldi		temp, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)		; sends STOP to slave
	sts		TWCR, temp
	ldi		temp, 200
TWI_Wait4:
	dec		temp
	brne	TWI_Wait4									;spend w200 cycles for time delay, STOP ������ ������ ���۵� �ð��� Ȯ���ϱ� ���� STOP ���� �ٷ� START �� ��� ������ Ÿ�̹� ���� �߻� ����
	ret
;**************************************************************
TWI_Write:
	sts		TWDR, I2Cdata
	ldi		temp, (1<<TWINT)|(1<<TWEN)
	sts		TWCR, temp
	rcall	WAIT_TWINT
	ret
;**************************************************************

TWI_Read:
	push	temp
	ldi		temp, (1<<TWINT)|(1<<TWEN)|(0<<TWEA)
	cpi		I2CAck, 0
	breq	SecondRead
FirstRead:
	ldi		temp, (1<<TWINT)|(1<<TWEN)|(1<<TWEA)		; Ack genneration < ���� �� ack���� > �� �� �� ����
SecondRead:
	sts		TWCR, temp

	rcall	WAIT_TWINT

	lds		r24, TWDR		;store read data
	pop		temp
	ret



WAIT_TWINT:
	clr		r10
	ldi		r18, 250
WAIT_LOOP:
	lds		temp, TWCR
	sbrs	temp, TWINT
	rjmp	NO_DONE
	ret
NO_DONE:
	dec		r18
	brne	WAIT_LOOP

;TIMEOUT_handler
    ; Stop ���� ���� ����
    rcall	TWI_Stop

    ; ���� �÷��� ����, ���� �÷��� �� ó��
    ; ��: ldi r_error, 1
	SETXY	X, HARD_RE
	ld		temp, X
	inc		temp
	st		X, temp
	inc		r10
    ret