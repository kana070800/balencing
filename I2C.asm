/*
 * I2C.asm
 *
 *  Created: 2025-05-19 ?? 8:12:42
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
TWI_Wait1:
	lds		temp, TWCR
	sbrs	temp, TWINT									; HW set TWINT to 1 when Start bit is successfully transmitted
	rjmp	TWI_Wait1
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
TWI_Wait2:
	lds		temp, TWCR
	sbrs	temp, TWINT
	rjmp	TWI_Wait2
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

TWI_Wait3:
	lds		temp, TWCR
	sbrs	temp, TWINT		;check the job complete flag
	rjmp	TWI_Wait3

	lds		r24, TWDR		;store read data
	pop		temp
	ret
;*****************************************************************
/*
Read_MPU:
;==============================
; ���� ��� ���� (0x6B �� 0x00)
;==============================
	rcall	TWI_Start
	ldi		I2Cdata, 0xD0			; SLA+W (0x68 << 1)
	rcall	TWI_Write
	ldi		I2Cdata, 0x6B			; PWR_MGMT_1
	rcall	TWI_Write
	ldi		I2Cdata, 0x00			; ���� ��Ʈ Ŭ����
	rcall	TWI_Write
	rcall	TWI_Stop
;==============================
; ���ӵ��� ������ �б� ���� (0x3B���� 6����Ʈ)
;==============================
	rcall	TWI_Start
	ldi		I2Cdata, 0xD0			; SLA+W
	rcall	TWI_Write
	ldi		I2Cdata, 0x3B			; ACCEL_XOUT_H  ldi			������ ���� �������� ���� �ּҸ� 0x3B�� ����
	rcall	TWI_Write

; Repeated Start �� Read ����
	rcall	TWI_Start
	ldi		I2Cdata, 0xD1			; SLA+R
	rcall	TWI_Write

; 6����Ʈ ���� (ACK 5ȸ, ������ NACK)
	ldi		temp, 6					; �ݺ� Ƚ��
	SETXY	X, RawAccelBuffer
ReadLoop:
	dec		temp
	mov		I2CAck, temp			; ������ ����Ʈ�� ���� NACK
	rcall	TWI_Read
	st		X+, I2Cdata				; ���ۿ� ����
	tst		temp
	brne	ReadLoop

	rcall	TWI_Stop
; Change moter direction, duty

	SETXY	X, RawAccelBuffer
	ld		temp, X+
	mov		refH, temp
	ld		temp, X+
	mov		refL, temp

	mov		r24, refH
	rcall	HexDisp
	mov		r24, refL
	rcall	HexDisp

DoneZ:
	ret*/