/*
 * test_anti_windup.asm
 *
 *  Created: 2025-07-14 ?? 2:26:11
 *   Author: kana0
 */ 
   #include "Myinclude.inc"

 #define	TMODE_LED	0x01	; LED testmode
 #define	TMODE_SEG1	0x02	; seg1 testmode
 #define	TMODE_SEGN	0x03	; segn testmode
 #define	TMODE_BUZ	0x04	; buzer testmode
 #define	TMODE_PHONE	0x05	; phone testmode
 #define	TMODE_PHOTO	0x06	; photo testmode
 #define	TMODE_TEMP	0x07	; photo testmode
 #define	TMODE_PROJ	0x08	; photo testmode
 #define	TESTmode	r23		; testmode register

 #define	PWMMAX_H	high(1600)
 #define	PWMMAX_L	low(1600)
 #define	PWMMAX_MH	high(-1600)
 #define	PWMMAX_ML	low(-1600)

 #define	PNFLAG		r17

 #define	refL		r4		
 #define	refH		r5

 #define	Ang_AC_XH	r9
 #define	Ang_AC_XL	r8
 #define	Ang_AC_YH	r7
 #define	Ang_AC_YL	r6

 #define	Ang_GY_XH	r21
 #define	Ang_GY_XL	r20
 #define	Ang_GY_YH	r19
 #define	Ang_GY_YL	r18

 #define	P_comH		r15
 #define	P_comL		r14
 
 .CSEG
	.ORG 0x0000 ;
	JMP		RESET
	.ORG 0x000C
	jmp	Ext_Int5
	.ORG 0x000E
	jmp	Ext_Int6
	.ORG 0x0014
	;jmp		Timer2_ovf
	.ORG 0x001C
	;jmp		Timer1_ovf
	.ORG 0x0024
	;jmp		UART_RXInt
	.ORG 0x0046;

 RESET:

	SETSP RAMEND		  ; Set Stack Pointer
	SET_Register_R0R1
	
	rcall	UART_Init
	rcall	EX_MPU_Init
	rcall	MPU_Init
	sei

	ldi		temp, 0xff
	out		DDRA, temp
	;out		PORTA, temp


	mov		TESTmode, temp


	;rcall	Read_MPU

	ldi		temp, 0x05
	out		PORTA, temp

	;****************************************************pwm 생성
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
	ldi		temp, PWMMAX_H
	out		ICR1H, temp
	ldi		temp, PWMMAX_L
	out		ICR1L, temp 
	
	; 4. duty 지정			pid 사용
	ldi		temp, high(100)
	out		OCR1BH, temp
	ldi		temp, low(100)
	out		OCR1BL, temp

	ldi		temp, high(100)
	sts		OCR1CH, temp
	ldi		temp, low(100)
	sts		OCR1CL, temp
	;-----------------------------------------------------------------------


Routine:
	cp		TESTmode, r0
	breq	NEST1


	rjmp	Routine
NEST1:
	rcall	TWI_Start
	ldi     I2Cdata, 0xD0          ; MPU6050 주소 + W
	rcall   TWI_Write
	ldi     I2Cdata, 0x6B          ; PWR_MGMT_1
	rcall   TWI_Write
	ldi     I2Cdata, 0x40          ; SLEEP = 1
	rcall   TWI_Write
	rcall   TWI_Stop

	clr		temp
	out		PORTA, temp
forever:
	rjmp	forever

StartStr:
	.db		"This is Test Program with UART Interrupt", CR, EOS
EndStr:
	.db		"Test is closed with CTRL-C", CR, EOS

#include	"UARTio.asm"
#include	"I2C.asm"
#include	"Timer.asm"
#include	"EXint.asm"
#include	"Delay.asm"
;******************************************************
MPU_Init:
	; 초기화
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

	; sample rate 설정
	rcall	TWI_Start
	ldi		I2Cdata, 0xD0			; SLA+W
	rcall	TWI_Write
	ldi		I2Cdata, 0x19			; SMPLRT_DIV
	rcall	TWI_Write
	ldi		I2Cdata, 0x7c			; 8khz / 1+249  = 32 hz  [0xfa] (DLPF is disable = 8k, enable = 1k)
	rcall	TWI_Write				; 8khz / 1+124  = 64 hz  [0x7c]
	rcall	TWI_Stop				; 8khz / 1+62  = 128 hz  [0x3e]
	
	; gyro scale 설정
	rcall	TWI_Start
	ldi		I2Cdata, 0xD0			; SLA+W
	rcall	TWI_Write
	ldi		I2Cdata, 0x1B			; gyro_config
	rcall	TWI_Write
	ldi		I2Cdata, 0x18			; +2000'/s max  ,  -2000'/s min
	rcall	TWI_Write
	rcall	TWI_Stop
	
	
	; accel scale 설정
	rcall	TWI_Start
	ldi		I2Cdata, 0xD0			; SLA+W
	rcall	TWI_Write
	ldi		I2Cdata, 0x1C			; accel_config
	rcall	TWI_Write
	ldi		I2Cdata, 0x18			; +16 g max  ,  -16 g min
	rcall	TWI_Write
	rcall	TWI_Stop
	
	; data ready interrupt enable
	rcall	TWI_Start
	ldi		I2Cdata, 0xD0			; SLA+W
	rcall	TWI_Write
	ldi		I2Cdata, 0x38			; INT_ENABLE
	rcall	TWI_Write
	ldi		I2Cdata, 0x01			; data ready interrupt enable
	rcall	TWI_Write
	rcall	TWI_Stop
ret
	;**************************************************************************
Read_MPU:
;==============================
; 가속도계 데이터 읽기 시작 (0x3B부터 14바이트)
;==============================
	rcall	TWI_Start
	ldi		I2Cdata, 0xD0			; SLA+W
	rcall	TWI_Write
	ldi		I2Cdata, 0x3B			; ACCEL_XOUT_H
	rcall	TWI_Write

; Repeated Start → Read 시작
	rcall	TWI_Start
	ldi		I2Cdata, 0xD1			; SLA+R
	rcall	TWI_Write

; 14바이트 수신 (ACK 5회, 마지막 NACK)
	ldi		r20, 14					; 반복 횟수
	ldi		ZL, low(RawAccelBuffer)
	ldi		ZH, high(RawAccelBuffer)

ReadLoop:
	dec		r20
	mov		I2CAck, r20				; 마지막 바이트일 때만 NACK
	rcall	TWI_Read
	st		Z+, I2Cdata				; 버퍼에 저장
	tst		r20
	brne	ReadLoop

	rcall	TWI_Stop
; print result
	PUTC	CR

	SETXY	X, RawAccelBuffer
	ld		temp, X+
	mov		r5, temp
	ld		temp, X+
	mov		r4, temp
	
	rcall	CONV_DEG
	
	mov		r24, r5
	rcall	HexDisp
	PUTC	'.'
	mov		r24, r4
	rcall	HexDisp
	PUTC	' '
	
	; 저장 >>>  angle_accel_x
	mov		Ang_AC_XH, r5
	mov		Ang_AC_XL, r4



	ld		temp, X+
	mov		r5, temp
	ld		temp, X+
	mov		r4, temp
	
	rcall	CONV_DEG
	
	mov		r24, r5
	rcall	HexDisp
	PUTC	'.'
	mov		r24, r4
	rcall	HexDisp
	PUTC	' '
	
	; 저장 >>  angle_accel_y
	mov		Ang_AC_YH, r5
	mov		Ang_AC_YL, r4




	ld		temp, X+
	mov		r5, temp
	ld		temp, X+
	mov		r4, temp	;Z
	
    sbrc    r5, 7       ; r5의 7번째 비트(부호 비트)가 0이면 양수 → skip
    rjmp    Make_Z ; 음수 → 2의 보수화 루틴으로 점프
	;PUTC	'+'
    rjmp    DoneZ          ; 양수면 아무 작업도 하지 않고 종료

Make_Z:
    com     r5           ; 하위 바이트 1의 보수
    com     r4           ; 상위 바이트 1의 보수
    add     r4, r1        ; 1 더해 2의 보수
	adc		r5, r0
	;PUTC	'-'
DoneZ:
	lsr		r5		; 부호 유지를 위해서는 asr
	ror		r4
	/*
	mov		r24, r5
	rcall	HexDisp
	mov		r24, r4
	rcall	HexDisp
	PUTC	' '
	*/
	


	ld		temp, X+
	mov		r5, temp
	ld		temp, X+
	mov		r4, temp	;temp
	



	ld		temp, X+
	mov		r5, temp
	ld		temp, X+
	mov		r4, temp	;*************************각속도 데이터 보수처리는 불필요
	

	; 각속도 r5:r4 를 각도변화량으로 변환
	asr		r5		; 32 hz 일 때 shift 한번, 64 hz 이면 shift 두번
	ror		r4
	asr		r5
	ror		r4
	/*
	mov		r24, r5
	rcall	HexDisp
	mov		r24, r4
	rcall	HexDisp
	PUTC	' '
	*/
	; 저장 >>  angle_accel_G_y      >>>   x 각속도 데이터는 y 축 각에 영향을 준다
	mov		Ang_GY_YH, r5
	mov		Ang_GY_YL, r4

	SETXY	Y, Ang_F_Y
	ld		temp, Y+
	add		Ang_GY_YH, temp		; 변화량 + 기존각
	ld		temp, Y
	adc		Ang_GY_YL, temp



	ld		temp, X+
	mov		r5, temp
	ld		temp, X+
	mov		r4, temp	;*************************각속도 데이터 보수처리는 불필요
	

	; 각속도 r5:r4 를 각도변화량으로 변환
	asr		r5		; 32 hz 일 때 shift 한번, 64 hz 이면 shift 두번
	ror		r4
	asr		r5
	ror		r4
	/*
	mov		r24, r5
	rcall	HexDisp
	mov		r24, r4
	rcall	HexDisp
	PUTC	' '
	*/
	;  저장 >>  angle_accel_G_x       >>>    y 각속도 데이터는 x 축 각에 영향을 준다
	mov		Ang_GY_XH, r5
	mov		Ang_GY_XL, r4

	SETXY	Y, Ang_F_X
	ld		temp, Y+
	add		Ang_GY_XH, temp		; 변화량 + 기존각
	ld		temp, Y
	adc		Ang_GY_XL, temp



	ld		temp, X+
	mov		r5, temp
	ld		temp, X+
	mov		r4, temp
	
    sbrc    r5, 7       ; r5의 7번째 비트(부호 비트)가 0이면 양수 → skip
    rjmp    Make_GZ ; 음수 → 2의 보수화 루틴으로 점프
	;PUTC	'+'
    rjmp    DoneGZ          ; 양수면 아무 작업도 하지 않고 종료

Make_GZ:
    com     r5           ; 하위 바이트 1의 보수
    com     r4           ; 상위 바이트 1의 보수
    add     r4, r1        ; 1 더해 2의 보수
	adc		r5, r0
	;PUTC	'-'
DoneGZ:
/*
	mov		r24, r5
	rcall	HexDisp
	mov		r24, r4
	rcall	HexDisp
	PUTC	' '
		
	PUTC	' '
	PUTC	'|'
	PUTC	' '
	*/
;****************************************************************
; (1-alpha) * Ang_AC  +  (alpha) * Ang_GY			[alpha  = 7/8]
; AC는 signed로 연산,     GY는 signed로 연산
;****************************************************************
	asr		Ang_AC_XH
	ror		Ang_AC_XL		; + - 주의
	asr		Ang_AC_XH
	ror		Ang_AC_XL
	asr		Ang_AC_XH
	ror		Ang_AC_XL


	asr		Ang_AC_YH
	ror		Ang_AC_YL
	asr		Ang_AC_YH
	ror		Ang_AC_YL
	asr		Ang_AC_YH
	ror		Ang_AC_YL


;*******************************************************************************for debug
	/*
	sbrc    Ang_AC_XH, 7       ; r5의 7번째 비트(부호 비트)가 0이면 양수 → skip
    rjmp    TESTTT ; 음수 → 2의 보수화 루틴으로 점프
	PUTC	'+'
    rjmp    DoneTTT          ; 양수면 아무 작업도 하지 않고 종료
TESTTT:
    com     Ang_AC_XH           ; 하위 바이트 1의 보수
    com     Ang_AC_XL           ; 상위 바이트 1의 보수
    add     Ang_AC_XL, r1        ; 1 더해 2의 보수
	adc		Ang_AC_XH, r0
	PUTC	'-'
DoneTTT:
	mov		r24, Ang_AC_XH
	rcall	HexDisp
	mov		r24, Ang_AC_XL
	rcall	HexDisp
	PUTC	' '
	

	sbrc    Ang_AC_YH, 7       ; r5의 7번째 비트(부호 비트)가 0이면 양수 → skip
    rjmp    TESTK ; 음수 → 2의 보수화 루틴으로 점프
	PUTC	'+'
    rjmp    DoneTK          ; 양수면 아무 작업도 하지 않고 종료
TESTK:
    com     Ang_AC_YH           ; 하위 바이트 1의 보수
    com     Ang_AC_YL           ; 상위 바이트 1의 보수
    add     Ang_AC_YL, r1        ; 1 더해 2의 보수
	adc		Ang_AC_YH, r0
	PUTC	'-'
DoneTK:
	mov		r24, Ang_AC_YH
	rcall	HexDisp
	mov		r24, Ang_AC_YL
	rcall	HexDisp
	PUTC	' '*/
	;***************************************************************************
		;							초기치 더하기 주의   현재 초기치는 0 >> mpu init 이전 한번 읽고 각 추정 필요
	clr		r5
	clr		r4

	asr		Ang_GY_XH
	ror		Ang_GY_XL		; 1/2

	mov		r5, Ang_GY_XH
	mov		r4, Ang_GY_XL

	asr		r5
	ror		r4

	add		Ang_GY_XL, r4
	adc		Ang_GY_XH, r5	; 1/2 + 1/4

	asr		r5
	ror		r4

	add		Ang_GY_XL, r4
	adc		Ang_GY_XH, r5	; 1/2 + 1/4 + 1/8



	clr		r5
	clr		r4

	asr		Ang_GY_YH
	ror		Ang_GY_YL		; 1/2

	mov		r5, Ang_GY_YH
	mov		r4, Ang_GY_YL

	asr		r5
	ror		r4

	add		Ang_GY_YL, r4
	adc		Ang_GY_YH, r5	; 1/2 + 1/4

	asr		r5
	ror		r4

	add		Ang_GY_YL, r4
	adc		Ang_GY_YH, r5	; 1/2 + 1/4 + 1/8



	clr		r4
	clr		r5
	; final 
	add		Ang_GY_YL, Ang_AC_YL
	adc		Ang_GY_YH, Ang_AC_YH

	add		Ang_GY_XL, Ang_AC_XL
	adc		Ang_GY_XH, Ang_AC_XH
	
	;*** store memory

	SETXY	Y, Ang_F_Y
	st		Y+, Ang_GY_YH
	st		Y+, Ang_GY_YL

	SETXY	Y, Ang_F_X
	st		Y+, Ang_GY_XH
	st		Y+, Ang_GY_XL
	;*************************************************************************for debug

	
	sbrc    Ang_GY_XH, 7       ; r5의 7번째 비트(부호 비트)가 0이면 양수 → skip
    rjmp    ASD ; 음수 → 2의 보수화 루틴으로 점프
	PUTC	'+'
    rjmp    SDF          ; 양수면 아무 작업도 하지 않고 종료
ASD:
    com     Ang_GY_XH           ; 하위 바이트 1의 보수
    com     Ang_GY_XL           ; 상위 바이트 1의 보수
    add     Ang_GY_XL, r1        ; 1 더해 2의 보수
	adc		Ang_GY_XH, r0
	PUTC	'-'
SDF:

	mov		r24, Ang_GY_XH
	rcall	HexDisp
	mov		r24, Ang_GY_XL
	rcall	HexDisp
	PUTC	' '
	
	
	sbrc    Ang_GY_YH, 7       ; r5의 7번째 비트(부호 비트)가 0이면 양수 → skip
    rjmp    ASDK ; 음수 → 2의 보수화 루틴으로 점프
	PUTC	'+'
    rjmp    SDFK          ; 양수면 아무 작업도 하지 않고 종료
ASDK:
    com     Ang_GY_YH           ; 하위 바이트 1의 보수
    com     Ang_GY_YL           ; 상위 바이트 1의 보수
    add     Ang_GY_YL, r1        ; 1 더해 2의 보수
	adc		Ang_GY_YH, r0
	PUTC	'-'
SDFK:

	mov		r24, Ang_GY_YH
	rcall	HexDisp
	mov		r24, Ang_GY_YL
	rcall	HexDisp
	PUTC	' '

ret


CONV_DEG:    ; 가속도 r5:r4 를 각도로 변환
	asr		r5		; 부호 유지를 위해서는 asr
	ror		r4
	asr		r5
	ror		r4


	ldi		temp, 10		; 무게중심-수평 오차 조정  77, 37
	add		r4, temp
	adc		r5, r0


	clr		PNFLAG

	;음수판별
    sbrc    r5, 7       ; r5의 7번째 비트(부호 비트)가 0이면 양수 → skip
    rjmp    MY ; 음수 → 2의 보수화 루틴으로 점프
	PUTC	'+'
    rjmp    PY          ; 양수면 아무 작업도 하지 않고 종료

MY:
    com     r5           ; 하위 바이트 1의 보수
    com     r4           ; 상위 바이트 1의 보수
    add     r4, r1        ; 1 더해 2의 보수
	adc		r5, r0
	PUTC	'-'
	com		PNFLAG		;음수면 ff, 양수면 00
PY:


	ldi		temp, low(532)
	cp		r4, temp
	ldi		temp, high(532)
	cpc		r5, temp
	brsh	SAT_DEG

	SETZ	LOOK_0

	; 주소변환 + 각 구하기(lpm)
	lsl		r4
	rol		r5	; 2 곱하기
	add		ZL, r4
	adc		ZH, r5

	rjmp	END_DEG
SAT_DEG:
	SETZ	LOOK_up
END_DEG:
	lpm		r5, Z+
	lpm		r4, Z

	; 음수일 경우 2의 보수
	tst		PNFLAG
	breq	REM
	com     r5		;-
    com     r4
    add     r4, r1
	adc		r5, r0
REM:				;+
	clr		PNFLAG
	ret
	/*
DUTY_GEN:
	push	P_comH
	push	P_comL
	SETXY	Y, Ang_F_X

	ld		P_comH, Y+
	ld		P_comL,	Y+


	;음수판별
    sbrc    P_comH, 7       ; r5의 7번째 비트(부호 비트)가 0이면 양수 → skip
    rjmp    RE_SPIN			; 음수 → 2의 보수화 루틴으로 점프 후 역방향 지정
	ldi		temp, 0x05
	out		PORTA, temp
    rjmp    FO          ; 양수면 정방향 지정 후 점프

RE_SPIN:
	ldi		temp, 0x0a
	out		PORTA, temp

FO:
	pop		P_comL
	pop		P_comH
	ret
	*/
	/*
DUTY_GEN:
	
	push	P_comH
	push	P_comL
	SETXY	Y, Ang_F_X

	ld		P_comH, Y+
	ld		P_comL,	Y+


	;음수판별
    sbrc    P_comH, 7       ; r5의 7번째 비트(부호 비트)가 0이면 양수 → skip
    rjmp    RE_SPIN			; 음수 → 2의 보수화 루틴으로 점프 후 역방향 지정
	ldi		temp, 0x05
	out		PORTA, temp
    rjmp    DUTY_CUL          ; 양수면 정방향 지정 후 점프

RE_SPIN:
	ldi		temp, 0x0a
	out		PORTA, temp

	com		P_comH
	com		P_comL
	add		P_comL, r1
	adc		P_comH, r0
DUTY_CUL:		;duty 계산 파트   >> 현재 각도는 unsigned + 고정소수점 (1,7,8) >> 00.00 ~ 2a.70


	;**************************************        2/25 부터 모터 동작 
	;>> saturation 계산

	ldi		temp, low(100)
	mov		r4, temp
	ldi		temp, high(100)
	mov		r5, temp
	cp		P_comL, r4
	cpc		P_comH, r5		;최소
	brlo	SATURA

	ldi		temp, low(8000)
	mov		r4, temp
	ldi		temp, high(8000)
	mov		r5, temp
	cp		P_comL, r4
	cpc		P_comH, r5		;최대
	brsh	SATURA
	rjmp	CALCUL

SATURA:	;최소,최대 이상은 x
	clr		P_comH
	clr		P_comL
	rjmp	ACTIVE

CALCUL: ; PID calculation
;********************************P
; 곱
	;lsl		P_comL 
	;rol		P_comH
; 나누기
	;lsr		P_comH
	;ror		P_comL

	lsl		P_comL 
	rol		P_comH
;********************************I

;********************************D
ACTIVE:


	mov		temp, P_comH
	out		OCR1BH, temp
	mov		temp, P_comL
	out		OCR1BL, temp

	mov		temp, P_comH
	sts		OCR1CH, temp
	mov		temp, P_comL
	sts		OCR1CL, temp



	pop		P_comL
	pop		P_comH
	ret
	*/

DUTY_GEN:
	
	push	P_comH
	push	P_comL

	SETXY	Y, Ang_F_X

	ld		P_comH, Y+		;error >>  signed
	ld		P_comL,	Y+    

	SETXY	Y, Integral
	ld		r5, Y+
	ld		r4,	Y+			; error 적분 signed

/*
	; 오차가 너무 작으면 적분 생략*******************
	ldi		temp, low(300)
	mov		r18, temp
	ldi		temp, high(300)
	mov		r19, temp
	cp		P_comL, r18
	cpc		P_comH, r19	
	brge	END_INTE

	ldi		temp, low(-300)
	mov		r18, temp
	ldi		temp, high(-300)
	mov		r19, temp
	cp		P_comL, r18
	cpc		P_comH, r19	
	brlt	END_INTE
	;***************************

	clr		P_comL
	clr		P_comH		;적분 제거

END_INTE:
*/
	add		r4, P_comL
	adc		r5, P_comH		;integ = integ + error 적분


	SETXY	Y, P_ANTI
	ld		r19, Y+
	ld		r18, Y+

;Ka********************************
	asr		r19
	ror		r18
	asr		r19
	ror		r18
	asr		r19
	ror		r18
	
	sub		r4, r18
	sbc		r5, r19			;integ = integ + error - Ka*P_ANTI


	SETXY	Y, Integral
	st		Y+, r5
	st		Y+,	r4			; error 적분 저장
;P************************************************
	SETXY	Y, Ang_F_X

	ld		P_comH, Y+		;error >>  signed
	ld		P_comL,	Y+

	asr		P_comH
	ror		P_comL
	asr		P_comH
	ror		P_comL			; KP*error

	
;I************************************************
	asr		r5
	ror		r4
	asr		r5
	ror		r4
	asr		r5
	ror		r4
	asr		r5
	ror		r4				; KI*integ





	add		P_comL, r4
	adc		P_comH, r5	;PI 성분

	
;D****************************************************
	; 1. 현재 오차 로딩 (e_now)
	SETXY   Y, Ang_F_X
	ld      r19, Y+      ; High byte
	ld      r18, Y+      ; Low byte

; 2. 이전 오차 로딩 (e_prev)
	SETXY   Y, Prev_Error
	ld      r21, Y+      ; High byte
	ld      r20, Y+      ; Low byte

; 3. e_now - e_prev (signed subtract)
	sub     r18, r20     ; low byte
	sbc     r19, r21     ; high byte → r19:r18 = 미분값

	
; 4. D 게인 적용

	asr     r19
	ror     r18		;나누기 시 반응 느려짐 but 적은 오차에서 진동 발생 >> 적은 오차에서 D항 제거


END_DIG:
; 5. 결과를 P_com에 더함 (또는 별도 저장)
	add     P_comL, r18
	adc     P_comH, r19

; 6. 현재 오차를 Prev_Error로 저장
	; 1. 현재 오차 로딩 (e_now)
	SETXY   Y, Ang_F_X
	ld      r19, Y+      ; High byte
	ld      r18, Y+      ; Low byte
	SETXY   Y, Prev_Error
	st      Y+, r19      ; High byte
	st      Y+, r18      ; Low byte


; anti_windup (pid 연산 결과 P_com 이용)
	ldi		temp, PWMMAX_L		;1400
	mov		r4, temp
	ldi		temp, PWMMAX_H
	mov		r5, temp
	cp		P_comL, r4
	cpc		P_comH, r5		
	brge	H_SAT

	ldi		temp, PWMMAX_ML		;-1400
	mov		r4, temp
	ldi		temp, PWMMAX_MH
	mov		r5, temp
	cp		P_comL, r4
	cpc		P_comH, r5		
	brlt	L_SAT

	; +-1400 이내일때
	clr		r4
	SETXY	Y, P_ANTI
	st		Y+, r4
	st		Y+, r4
	rjmp	END_SAT

H_SAT:	; +1400 이상일 때 
	mov		r18, P_comL
	mov		r19, P_comH
	sub		r18, r4
	sbc		r19, r5		; P_com = P_com - 1400
	SETXY	Y, P_ANTI
	st		Y+, r18
	st		Y+, r19
	rjmp	END_SAT
L_SAT:	; -1400 이하일 때 
	mov		r18, P_comL
	mov		r19, P_comH
	sub		r18, r4
	sbc		r19, r5		; P_com = P_com - (-1400)
	SETXY	Y, P_ANTI
	st		Y+, r18
	st		Y+, r19
	rjmp	END_SAT

;**************************************************************
	;음수판별
END_SAT:
    sbrc    P_comH, 7       ; r5의 7번째 비트(부호 비트)가 0이면 양수 → skip
    rjmp    RE_SPIN			; 음수 → 2의 보수화 루틴으로 점프 후 역방향 지정

	ldi		temp, 0x05
	out		PORTA, temp
    rjmp    DUTY_CUL          ; 양수면 정방향 지정 후 점프

RE_SPIN:
	ldi		temp, 0x0a
	out		PORTA, temp

	com		P_comH
	com		P_comL
	add		P_comL, r1
	adc		P_comH, r0
DUTY_CUL:		;duty 계산 파트   >> 현재 각도는 unsigned + 고정소수점 (1,7,8) >> 00.00 ~ 2a.70


	;**************************************        2/25 부터 모터 동작 
	;>> saturation 계산 >> 오차가 작으면 인가 x

	SETXY   Y, Ang_F_X
	ld      r19, Y+      ; High byte
	ld      r18, Y+      ; Low byte
	
	ldi		temp, low(300)
	mov		r4, temp
	ldi		temp, high(300)
	mov		r5, temp
	cp		r18, r4
	cpc		r19, r5		
	brge	CALCUL

	ldi		temp, low(-300)
	mov		r4, temp
	ldi		temp, high(-300)
	mov		r5, temp
	cp		r18, r4
	cpc		r19, r5		
	brlt	CALCUL

SATURA:	;최소,최대 이상은 x
	clr		P_comH
	clr		P_comL

CALCUL:

	mov		temp, P_comH
	out		OCR1BH, temp
	mov		temp, P_comL
	out		OCR1BL, temp

	mov		temp, P_comH
	sts		OCR1CH, temp
	mov		temp, P_comL
	sts		OCR1CL, temp



	pop		P_comL
	pop		P_comH
	ret

SegData:  ; 0 ~ 16, -, non   FND display data
	.db	0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x27, 0x7f, 0x6f, 0x77, 0x7c, 0x58, 0x5e, 0x79, 0x71, 0x40, 0x00

PhoneNum:
	.db 17, 17, 17, 17, 17, 0, 1, 0, 16, 4, 0, 8, 7, 16, 1, 7, 2, 8, 17, 17, 17, 17


; arc sin  look up table for mpu 6050       오차가 크면 연산량 증가되는 문제, 문제 발생 시 cordic algorithm으로 바꿈    or    branch > 10~20개 단위로 case 나누어 연산
LOOK_0:
	.db 0x00,0x00 , 0x00,0x1b , 0x00,0x37 , 0x00,0x52 , 0x00,0x6e , 0x00,0x89 , 0x00,0xa5 , 0x00,0xc1 , 0x00,0xdc , 0x00,0xf8
	.db 0x01,0x13 , 0x01,0x2f , 0x01,0x4a , 0x01,0x66 , 0x01,0x82 , 0x01,0x9d , 0x01,0xb9 , 0x01,0xd4 , 0x01,0xf0 , 0x02,0x0b

	.db 0x02,0x27 , 0x02,0x43 , 0x02,0x5e , 0x02,0x7a , 0x02,0x95 , 0x02,0xb1 , 0x02,0xcd , 0x02,0xe8 , 0x03,0x04 , 0x03,0x1f
	.db 0x03,0x3b , 0x03,0x57 , 0x03,0x72 , 0x03,0x8e , 0x03,0xaa , 0x03,0xc5 , 0x03,0xe1 , 0x03,0xfc , 0x04,0x18 , 0x04,0x34

	.db 0x04,0x4f , 0x04,0x6b , 0x04,0x87 , 0x04,0xa2 , 0x04,0xbe , 0x04,0xda , 0x04,0xf5 , 0x05,0x11 , 0x05,0x2d , 0x05,0x48
	.db 0x05,0x64 , 0x05,0x80 , 0x05,0x9b , 0x05,0xb7 , 0x05,0xd3 , 0x05,0xef , 0x06,0x0a , 0x06,0x26 , 0x06,0x42 , 0x06,0x5e

	.db 0x06,0x79 , 0x06,0x95 , 0x06,0xb1 , 0x06,0xcd , 0x06,0xe8 , 0x07,0x04 , 0x07,0x20 , 0x07,0x3c , 0x07,0x57 , 0x07,0x73
	.db 0x07,0x8f , 0x07,0xab , 0x07,0xc7 , 0x07,0xe3 , 0x07,0xfe , 0x08,0x1a , 0x08,0x36 , 0x08,0x52 , 0x08,0x6e , 0x08,0x8a

	.db 0x08,0xa6 , 0x08,0xc1 , 0x08,0xdd , 0x08,0xf9 , 0x09,0x15 , 0x09,0x31 , 0x09,0x4d , 0x09,0x69 , 0x09,0x85 , 0x09,0xa1
	.db 0x09,0xbd , 0x09,0xd9 , 0x09,0xf5 , 0x0a,0x11 , 0x0a,0x2d , 0x0a,0x49 , 0x0a,0x65 , 0x0a,0x81 , 0x0a,0x9d , 0x0a,0xb9

	.db 0x0a,0xd5 , 0x0a,0xf1 , 0x0b,0x0d , 0x0b,0x29 , 0x0b,0x45 , 0x0b,0x62 , 0x0b,0x7e , 0x0b,0x9a , 0x0b,0xb6 , 0x0b,0xd2
	.db 0x0b,0xee , 0x0c,0x0b , 0x0c,0x27 , 0x0c,0x43 , 0x0c,0x5f , 0x0c,0x7b , 0x0c,0x98 , 0x0c,0xb4 , 0x0c,0xd0 , 0x0c,0xec

	.db 0x0d,0x09 , 0x0d,0x25 , 0x0d,0x41 , 0x0d,0x5e , 0x0d,0x7a , 0x0d,0x96 , 0x0d,0xb3 , 0x0d,0xcf , 0x0d,0xec , 0x0e,0x08
	.db 0x0e,0x24 , 0x0e,0x41 , 0x0e,0x5d , 0x0e,0x7a , 0x0e,0x96 , 0x0e,0xb3 , 0x0e,0xcf , 0x0e,0xec , 0x0f,0x08 , 0x0f,0x25

	.db 0x0f,0x41 , 0x0f,0x5e , 0x0f,0x7b , 0x0f,0x97 , 0x0f,0xb4 , 0x0f,0xd1 , 0x0f,0xed , 0x10,0x0a , 0x10,0x27 , 0x10,0x43
	.db 0x10,0x60 , 0x10,0x7d , 0x10,0x99 , 0x10,0xb6 , 0x10,0xd3 , 0x10,0xf0 , 0x11,0x0d , 0x11,0x2a , 0x11,0x46 , 0x11,0x63

	.db 0x11,0x80 , 0x11,0x9d , 0x11,0xba , 0x11,0xd7 , 0x11,0xf4 , 0x12,0x11 , 0x12,0x2e , 0x12,0x4b , 0x12,0x68 , 0x12,0x85
	.db 0x12,0xa2 , 0x12,0xbf , 0x12,0xdc , 0x12,0xfa , 0x13,0x17 , 0x13,0x34 , 0x13,0x51 , 0x13,0x6e , 0x13,0x8c , 0x13,0xa9

	.db 0x13,0xc6 , 0x13,0xe4 , 0x14,0x01 , 0x14,0x1e , 0x14,0x3c , 0x14,0x59 , 0x14,0x76 , 0x14,0x94 , 0x14,0xb1 , 0x14,0xcf
	.db 0x14,0xec , 0x15,0x0a , 0x15,0x27 , 0x15,0x45 , 0x15,0x63 , 0x15,0x80 , 0x15,0x9e , 0x15,0xbb , 0x15,0xd9 , 0x15,0xf7

	.db 0x16,0x15 , 0x16,0x32 , 0x16,0x50 , 0x16,0x6e , 0x16,0x8c , 0x16,0xaa , 0x16,0xc8 , 0x16,0xe5 , 0x17,0x03 , 0x17,0x21
	.db 0x17,0x3f , 0x17,0x5d , 0x17,0x7b , 0x17,0x9a , 0x17,0xb8 , 0x17,0xd6 , 0x17,0xf4 , 0x18,0x12 , 0x18,0x30 , 0x18,0x4f

	.db 0x18,0x6d , 0x18,0x8b , 0x18,0xa9 , 0x18,0xc8 , 0x18,0xe6 , 0x19,0x05 , 0x19,0x23 , 0x19,0x41 , 0x19,0x60 , 0x19,0x7f
	.db 0x19,0x9d , 0x19,0xbc , 0x19,0xda , 0x19,0xf9 , 0x1a,0x18 , 0x1a,0x36 , 0x1a,0x55 , 0x1a,0x74 , 0x1a,0x93 , 0x1a,0xb2

	.db 0x1a,0xd0 , 0x1a,0xef , 0x1b,0x0e , 0x1b,0x2d , 0x1b,0x4c , 0x1b,0x6b , 0x1b,0x8a , 0x1b,0xa9 , 0x1b,0xc9 , 0x1b,0xe8
	.db 0x1c,0x07 , 0x1c,0x26 , 0x1c,0x46 , 0x1c,0x65 , 0x1c,0x84 , 0x1c,0xa4 , 0x1c,0xc3 , 0x1c,0xe3 , 0x1d,0x02 , 0x1d,0x22

	.db 0x1d,0x41 , 0x1d,0x61 , 0x1d,0x80 , 0x1d,0xa0 , 0x1d,0xc0 , 0x1d,0xe0 , 0x1e,0x00 , 0x1e,0x1f , 0x1e,0x3f , 0x1e,0x5f
	.db 0x1e,0x7f , 0x1e,0x9f , 0x1e,0xbf , 0x1e,0xdf , 0x1e,0xff , 0x1f,0x20 , 0x1f,0x40 , 0x1f,0x60 , 0x1f,0x80 , 0x1f,0xa1

	.db 0x1f,0xc1 , 0x1f,0xe2 , 0x20,0x02 , 0x20,0x23 , 0x20,0x43 , 0x20,0x64 , 0x20,0x85 , 0x20,0xa5 , 0x20,0xc6 , 0x20,0xe7
	.db 0x21,0x08 , 0x21,0x29 , 0x21,0x4a , 0x21,0x6b , 0x21,0x8c , 0x21,0xad , 0x21,0xce , 0x21,0xef , 0x22,0x10 , 0x22,0x32

	.db 0x22,0x53 , 0x22,0x75 , 0x22,0x96 , 0x22,0xb8 , 0x22,0xd9 , 0x22,0xfb , 0x23,0x1c , 0x23,0x3e , 0x23,0x60 , 0x23,0x82
	.db 0x23,0xa4 , 0x23,0xc6 , 0x23,0xe8 , 0x24,0x0a , 0x24,0x2c , 0x24,0x4e , 0x24,0x70 , 0x24,0x93 , 0x24,0xb5 , 0x24,0xd7

	.db 0x24,0xfa , 0x25,0x1c , 0x25,0x3f , 0x25,0x62 , 0x25,0x84 , 0x25,0xa7 , 0x25,0xca , 0x25,0xed , 0x26,0x10 , 0x26,0x33
	.db 0x26,0x56 , 0x26,0x79 , 0x26,0x9c , 0x26,0xc0 , 0x26,0xe3 , 0x27,0x07 , 0x27,0x2a , 0x27,0x4e , 0x27,0x71 , 0x27,0x95

	.db 0x27,0xb9 , 0x27,0xdd , 0x28,0x01 , 0x28,0x25 , 0x28,0x49 , 0x28,0x6d , 0x28,0x91 , 0x28,0xb6 , 0x28,0xda , 0x28,0xff
	.db 0x29,0x23 , 0x29,0x48 , 0x29,0x6d , 0x29,0x91 , 0x29,0xb6 , 0x29,0xdb , 0x2a,0x00 , 0x2a,0x25 , 0x2a,0x4b , 0x2a,0x70

	.db 0x2a,0x95 , 0x2a,0xbb , 0x2a,0xe0 , 0x2b,0x06 , 0x2b,0x2c , 0x2b,0x52 , 0x2b,0x78 , 0x2b,0x9e , 0x2b,0xc4 , 0x2b,0xea
	.db 0x2c,0x10 , 0x2c,0x37 , 0x2c,0x5d , 0x2c,0x84 , 0x2c,0xab , 0x2c,0xd2 , 0x2c,0xf8 , 0x2d,0x1f , 0x2d,0x47 , 0x2d,0x6e

	.db 0x2d,0x95 , 0x2d,0xbd , 0x2d,0xe4 , 0x2e,0x0c , 0x2e,0x34 , 0x2e,0x5c , 0x2e,0x84 , 0x2e,0xac , 0x2e,0xd4 , 0x2e,0xfc
	.db 0x2f,0x25 , 0x2f,0x4d , 0x2f,0x76 , 0x2f,0x9f , 0x2f,0xc8 , 0x2f,0xf1 , 0x30,0x1a , 0x30,0x44 , 0x30,0x6d , 0x30,0x97

	.db 0x30,0xc0 , 0x30,0xea , 0x31,0x14 , 0x31,0x3e , 0x31,0x69 , 0x31,0x93 , 0x31,0xbe , 0x31,0xe9 , 0x32,0x13 , 0x31,0x3e
	.db 0x32,0x6a , 0x32,0x95 , 0x32,0x75 , 0x32,0xec , 0x33,0x18 , 0x33,0x44 , 0x33,0x70 , 0x33,0x9c , 0x33,0xc9 , 0x33,0xf6

	.db 0x34,0x22 , 0x34,0x4f , 0x34,0x7d , 0x34,0xaa , 0x34,0xd8 , 0x35,0x05 , 0x35,0x33 , 0x35,0x61 , 0x35,0x90 , 0x35,0xbe
	.db 0x35,0xed , 0x36,0x1c , 0x36,0x4b , 0x36,0x7a , 0x36,0xaa , 0x36,0xda , 0x37,0x0a , 0x37,0x3a , 0x37,0x6a , 0x37,0x9b

	.db 0x37,0xcc , 0x37,0xfd , 0x38,0x2f , 0x38,0x60 , 0x38,0x92 , 0x38,0xc4 , 0x38,0xf7 , 0x39,0x29 , 0x39,0x5c , 0x39,0x90
	.db 0x39,0xc3 , 0x39,0xf7 , 0x3a,0x2b , 0x3a,0x60 , 0x3a,0x94 , 0x3a,0xc9 , 0x3a,0xff , 0x3b,0x34 , 0x3b,0x6b , 0x3b,0xa1

	.db 0x3b,0xd8 , 0x3c,0x0f , 0x3c,0x46 , 0x3c,0x7e , 0x3c,0xb6 , 0x3c,0xef , 0x3d,0x28 , 0x3d,0x61 , 0x3d,0x9b , 0x3d,0xd5
	.db 0x3e,0x0f , 0x3e,0x4b , 0x3e,0x86 , 0x3e,0xc2 , 0x3e,0xff , 0x3f,0x3c , 0x3f,0x79 , 0x3f,0xb7 , 0x3f,0xf6 , 0x40,0x35

	.db 0x40,0x74 , 0x40,0xb5 , 0x40,0xf5 , 0x41,0x37 , 0x41,0x79 , 0x41,0xbc , 0x41,0xff , 0x42,0x43 , 0x42,0x88 , 0x42,0xce
	.db 0x43,0x14 , 0x43,0x5b , 0x43,0xa3 , 0x43,0xec , 0x44,0x36 , 0x44,0x81 , 0x44,0xcd , 0x45,0x19 , 0x45,0x67 , 0x45,0xb6

	.db 0x46,0x06 , 0x46,0x58 , 0x46,0xaa , 0x46,0xfe , 0x47,0x54 , 0x47,0xaa , 0x48,0x03 , 0x48,0x5d , 0x48,0xb9 , 0x49,0x17
	.db 0x49,0x77 , 0x49,0xd9 , 0x4a,0x3d , 0x4a,0xa4 , 0x4b,0x0d , 0x4b,0x79 , 0x4b,0xe9 , 0x4c,0x5c , 0x4c,0xd3 , 0x4d,0x4e

	.db 0x4d,0xce , 0x4e,0x54 , 0x4e,0xdf , 0x4f,0x72 , 0x50,0x0d , 0x50,0xb1 , 0x51,0x63 , 0x52,0x23 , 0x52,0xf8 , 0x53,0xe9
	.db 0x55,0x07 , 0x56,0x7c , 0x5a,0x00
LOOK_up:
	.db 0x5a,0x00

.DSEG
buffer:
	.byte	80
digit4:
	.db 	4

RawAccelBuffer: 
	.byte 14

Ang_F_X: 
	.byte 2
Ang_F_Y: 
	.byte 2


Integral:
	.byte 2

Prev_Error:
	.byte 2

P_ANTI:
	.byte 2


HARD_RE:
	.byte 1