/*
 * Myinclude.inc
 *
 *  Created: 2025-05-05 ?? 2:58:39
 *   Author: kana0
 */ 
#define		F_CPU		16000000
#define		BAUDRATE	57600
#define		BAUDRATE1	38400
#define		UBRR0		(F_CPU / (BAUDRATE * 16)) - 1 
#define		UBRR1		(F_CPU / (BAUDRATE1 * 16)) - 1 
#define		SREG2		r11
#define		temp		r16

 #define		ATS75_TEMP_REG		0					; read only 16bit reg
 #define		ATS75_CONFIG_REG	1					; 8bit reg	read/write

 #define		TWIdataH			r12					; read only 16bit reg
 #define		TWIdataL			r13					; 8bit reg	read/write

 #define		Quotient			r20					; 8비트 정수를 10진수로 변환 시 사용되는 몫
 //delay 함수 input과 동일하니 주의
 #define		I2Cdata				r24					; i2c 통신을 위하여 온도센서에 보낼 데이터를 저장하는 reg
 #define		I2CAck				r25					; 16bit 데이터를 읽을 때 사용되는 ack/noack 생성용 reg

#define		TAP			0x09
#define		CTRL_C		0x03
#define		LF			0x0A							; move the cursor to the next line
#define		CR			0x0D							; enter	(return the cursor to start of line)
#define		EOS			0x00 ; end of string
#define		BS			0x7f

 #define	CDS_1Lux	564  ;0x0234
 #define	CDS_10Lux	871  ;0x0367
 #define	CDS_100Lux	987  ;0x03db

 #define	ADdataL		r14
 #define	ADdataH		r15
 #define	CPdataL		r26
 #define	CPdataH		r27

 #define	TESTmode	r23			; testmode register

.macro	SETSP
	ldi		temp, high(@0)
	out		SPH,  temp
	ldi		temp, low(@0)
	out		SPL,  temp
.endmacro
.macro	DELAYMS
	ldi		r25, high(@0)
	ldi		r24, low(@0)
	rcall	delay_ms
.endmacro
.macro	DELAYUS
	ldi		r25, high(@0)
	ldi		r24, low(@0)
	rcall	delay_ms
.endmacro
.macro	SETXY
	ldi		@0H, high(@1)
	ldi		@0L, low(@1)
.endmacro
.macro	SETZ
	ldi		ZH, high(2*@0)
	ldi		ZL, low(2*@0)
.endmacro
.macro	PUTC
	ldi		r24, @0
	rcall	PutChar
.endmacro
.macro	SET_Register_R0R1
	ldi		r16, 0x00
	mov		r0, r16
	ldi		r16, 0x01
	mov		r1, r16
.endmacro
.macro	PRINT
	SETZ	@0
	rcall	PutString
.endmacro