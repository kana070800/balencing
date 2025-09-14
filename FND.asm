/*
 * FND.asm
 *
 *  Created: 2025-05-14 ?? 1:32:23
 *   Author: kana0
 */ 
FND_Init:
 	ldi		temp, 0xff
	out		DDRC, temp; set portC output

	ldi		temp, 0x0f
	sts		DDRG, temp; set portG low,output
	ret

FND_Off:
	ldi		temp, 0
	mov		FND_En, temp
	sts		PORTG, FND_En
	out		DDRC, temp; portC off
	sts		DDRG, temp; portG off
	ret

FND_display:
	 SETXY	X, digit4
	 ldi	FND_En, 0x08
FNDloop:
	 ld		temp, X+
	 SETZ	Segdata
	 add	ZL, temp
	 adc	ZH, r0	
	 lpm	FND_Data, Z
	 sts	PORTG, FND_En
	 out	PORTC, FND_Data ;	display '0'
	 DELAYMS FND_TIME		; Delay FND_TIME msec
	 lsr	FND_En
	 brne	FNDloop
	 ret
;********************************************
;temperature sensor 관련함수들
;********************************************
FND_dis_temp:
	 SETXY	X, digit4
	 ldi	FND_En, 0x08
FND_temp:
	 ld		temp, X+
	 SETZ	Segdata
	 add	ZL, temp
	 adc	ZH, r0	
	 lpm	FND_Data, Z
	 sts	PORTG, FND_En
	 sbrc	FND_En, 1		; 2번째 fnd 차례가 아니면 다음 스킵
	 ori	FND_Data, 0x80	; dot ori
	 out	PORTC, FND_Data ;	display '0'
	 DELAYMS FND_TIME		; Delay FND_TIME msec
	 lsr	FND_En
	 brne	FND_temp
	 ret
;********************************************
;temperature sensor read
;********************************************
TempRead:
	rcall	TWI_Start
	ldi		I2Cdata, 0x98				; temp sensor write mode(1001 100 0)
	rcall	TWI_Write
	ldi		I2Cdata, ATS75_TEMP_REG		;configuration reg setting 생략
	rcall	TWI_Write

	rcall	TWI_Start
	ldi		I2Cdata, 0x99				; temp sensor read mode (1001 100 1)
	rcall	TWI_Write

	ldi		I2CAck, 1					; 한번 더 입력 요구
	rcall	TWI_Read
	mov		TWIdataH, r24
	ldi		I2CAck, 0					; 끝
	rcall	TWI_Read
	mov		TWIdataL, r24
	rcall	TWI_Stop

	ret
;*********************************************
ModifyFND:							; move 4 nibbles								TWIdataH(7:4),TWIdataH(3:0),  TWIdataL(7:4),TWIdataL(3:0) to digit4
	SETXY	Y, digit4
	mov		temp, TWIdataH
	swap    temp
	andi	temp, 0x0f
	st		Y+, temp				; TWIdataH(7:4)
	mov		temp, TWIdataH
	andi	temp, 0x0f
	st		Y+, temp				; TWIdataH(3:0)
	mov		temp, TWIdataL
	swap    temp
	andi	temp, 0x0f
	st		Y+, temp				; TWIdataL(7:4)
	mov		temp, TWIdataL
	andi	temp, 0x0f
	st		Y+, temp				; TWIdataL(3:0)
	ret
;*****************************************   11bits input  0000 0000 000x xxxx
Bi2De:
	SETXY	Y, digit4
	clr		Quotient

    sbrs	TWIdataH, 7       ; 음 양 판별
    rjmp	MSB_0
MSB_1:
	com		TWIdataH			; 1보수
	com		TWIdataL															; 안쓰이는 하위 bit은 2보수 취하면 자동으로 0		, 쓰이는 bit부터 +1하는 효과를 지님
	inc		TWIdataL
	adc		TWIdataH, r0		; 2보수
	ldi		temp, 16
	st		Y+, temp			; '-'
	rjmp	TenDe
MSB_0:
	ldi		temp, 17
	st		Y+, temp			; non, instead of '+'
TenDe:						;10의 자리 수 결정  TWIdataH 만 - 10
	ldi		temp, 9
	cp		temp, TWIdataH	
	brge	OneDe				;great or equeal signed
	inc		Quotient
	ldi		temp, 10
	sub		TWIdataH, temp
	rjmp	TenDe
OneDe:
	st		Y+, Quotient		; 몫을 10의 자리로 저장
	st		Y+, TWIdataH		; 나머지를 일의 자리로 저장
After:						 ; 내 보드에 적용된 센서는 11bit를 출력
	clr		Quotient		; 몫 reg를 소수점으로 재사용
	sbrs	TWIdataL, 7
	rjmp	CheckB6
	ldi		temp, 5
	add		Quotient, temp
CheckB6:
	sbrs	TWIdataL, 6
	rjmp	CheckB5
	ldi		temp, 3
	add		Quotient, temp
CheckB5:
	sbrs	TWIdataL, 5
	rjmp	CheckB_END
	ldi		temp, 1
	add		Quotient, temp
CheckB_END:
	st		Y+, Quotient
	ret