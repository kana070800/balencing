/*
 * I2C.asm
 *
 *  Created: 2025-05-19 ?? 8:12:42
 *   Author: kana0
 */
 ;************************************************************
 TWI_Init:
	ldi		temp, 0x03;
	out		PORTD,temp									; 온도센서의 SCL, SCA pull up on

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
	brne	TWI_Wait4									;spend w200 cycles for time delay, STOP 조건이 완전히 전송될 시간을 확보하기 위함 STOP 직후 바로 START 등 명령 넣으면 타이밍 문제 발생 가능
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
	ldi		temp, (1<<TWINT)|(1<<TWEN)|(1<<TWEA)		; Ack genneration < 수신 후 ack전송 > 한 번 더 수신
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
; 슬립 모드 해제 (0x6B ← 0x00)
;==============================
	rcall	TWI_Start
	ldi		I2Cdata, 0xD0			; SLA+W (0x68 << 1)
	rcall	TWI_Write
	ldi		I2Cdata, 0x6B			; PWR_MGMT_1
	rcall	TWI_Write
	ldi		I2Cdata, 0x00			; 슬립 비트 클리어
	rcall	TWI_Write
	rcall	TWI_Stop
;==============================
; 가속도계 데이터 읽기 시작 (0x3B부터 6바이트)
;==============================
	rcall	TWI_Start
	ldi		I2Cdata, 0xD0			; SLA+W
	rcall	TWI_Write
	ldi		I2Cdata, 0x3B			; ACCEL_XOUT_H  ldi			다음에 읽을 데이터의 시작 주소를 0x3B로 지정
	rcall	TWI_Write

; Repeated Start → Read 시작
	rcall	TWI_Start
	ldi		I2Cdata, 0xD1			; SLA+R
	rcall	TWI_Write

; 6바이트 수신 (ACK 5회, 마지막 NACK)
	ldi		temp, 6					; 반복 횟수
	SETXY	X, RawAccelBuffer
ReadLoop:
	dec		temp
	mov		I2CAck, temp			; 마지막 바이트일 때만 NACK
	rcall	TWI_Read
	st		X+, I2Cdata				; 버퍼에 저장
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