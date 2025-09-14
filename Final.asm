/*
 * Final.asm
 *
 *  Created: 2025-05-30 ?? 10:21:27
 *   Author: kana0
 */ 
     #include	"Myinclude.inc"

#define		SetRED		0x1b, "[0;31m"
#define		ClrCOLOR	0x1b, "[0m"

 #define	TMODE_LED	0x01	; LED testmode
 #define	TMODE_SEG1	0x02	; seg1 testmode
 #define	TMODE_SEGN	0x03	; segn testmode
 #define	TMODE_BUZ	0x04	; buzer testmode
 #define	TMODE_PHONE	0x05	; phone testmode
 #define	TMODE_PHOTO	0x06	; photo testmode
 #define	TMODE_TEMP	0x07	; photo testmode
 #define	TMODE_PROJ	0x08	; photo testmode
 #define	TESTmode	r23		; testmode register

 #define	GoStop_state	 r10

 #define	refL		r4		
 #define	refH		r5		;FND 와 동시에 사용 x 

 #define	Direction	r7
 #define	Ki			r8

.macro	ADDI6
	subi	@0L, low(-@1)
	sbci	@0H, high(-@1)
.endmacro

;*******************************************
;interrupt vector table
;*******************************************
 .CSEG
	.ORG 0x0000 ;
	JMP		RESET
	.ORG 0x00A
	jmp		Ext_Int4		;SEGN
	jmp		Ext_Int5		;SEGN
	.ORG 0x0014
	jmp		Timer2_ovf		;BUZ
	.ORG 0x001C
	jmp		Timer1_ovf		;SEGN
	.ORG 0x0020
	jmp		Timer0_ovf		;PHOTO, TEMP, PHONE
	.ORG 0x0024
	jmp		UART_RXInt		; mode break
	.ORG 0x0046;

RESET:
	SETSP	RAMEND
	SET_Register_R0R1R2
	cli
	rcall	UART_Init
	sei
	rcall	PrintTitle

forever:
	rcall	PntCMD
	rcall	GetCmd
	rcall	CmdInterprete
	rjmp	forever
;*****************************************************
BuildTime:
	.db		"Built on ",__DATE__," ",__TIME__,CR, EOS, EOS	
Title:
	.db		"+===========================================================+", CR
	.db		"| This is an AVR board TEST                                 |", CR
	.db		"|  Programmed by Cho Hyeon Jun (202011052)                  |", CR
	.db		"+===========================================================+", CR
	.db		"| help : Display all supported command                      |", CR
	.db		"| led  : LED Test                                           |", CR
	.db		"| seg1 : Single Segment Display Test                        |", CR
	.db		"| segn : Multiple Segment Display Test                      |", CR
	.db		"| phone: phone number Display Test                          |", CR
	.db		"| buz  : buzzer Test                                        |", CR
	.db		"| photo: photo sensor test                                  |", CR
	.db		"| temp : temperature sensor test                            |", CR
	.db		"| proj : your project Test                                  |", CR
	.db		"+===========================================================+", CR
	.db		"  Pressing CTRL-C terminates selected test !!  ", CR, EOS, EOS
CMDcursor:
	.db		SetRED, "CMD:>> ",ClrCOLOR, EOS, EOS	
CMDList:		;char CMDList[9][6]
	.db		"help",		EOS, EOS
	.db		"led",EOS,  EOS, EOS
	.db		"seg1",		EOS, EOS
	.db		"segn",		EOS, EOS
	.db		"phone"		   , EOS
	.db		"buz",EOS,	EOS, EOS
	.db		"photo"		   , EOS
	.db		"temp",		EOS, EOS
	.db		"proj",		EOS, EOS

BAD_MSG:
	.db		"Wrong Command......", EOS

#include	"UARTio.asm"
#include	"Delay.asm"
#include	"FND.asm"
#include	"Timer.asm"
#include	"EXint.asm"
#include	"ADC.asm"
#include	"I2C.asm"
#include	"moterpwm.asm"

PrintTitle:
	PRINT	BuildTime
	PRINT	Title
	ret
PntCMD:
	PRINT	CMDcursor
	ret
;******************************************************
GetCmd:
    SETXY	Y, buffer
    ldi     r16, 80         ; 버퍼 크기
CB_loop:
    st      Y+, r0          ; r0 = 0 (clr r0로 미리 초기화)
    dec     r16
    brne    CB_loop

	SETXY	Y, buffer
	rcall	GetString
	PUTC	CR				; CR은 echo안되기에 임의로 줄바꿈
ret
;*************************************************
CmdInterprete:
	SETXY	Y, buffer
	SETZ	CMDList
	rcall	StrCmp		; compare input string with "help"  (return 0 if equal, return 1 if not equal)
	tst		r24
	breq	CMD_HELP
	ADDI6	Z, 6		; Z = Z + 6
	rcall	StrCmp
	tst		r24
	breq	CMD_LED
	ADDI6	Z, 6		; Z = Z + 6
	rcall	StrCmp
	tst		r24
	breq	CMD_SEG1
	ADDI6	Z, 6		; Z = Z + 6
	rcall	StrCmp
	tst		r24
	breq	CMD_SEGN
	ADDI6	Z, 6		; Z = Z + 6
	rcall	StrCmp
	tst		r24
	breq	CMD_PHONE
	ADDI6	Z, 6		; Z = Z + 6
	rcall	StrCmp
	tst		r24
	breq	CMD_BUZ
	ADDI6	Z, 6		; Z = Z + 6
	rcall	StrCmp
	tst		r24
	breq	CMD_PHOTO
	ADDI6	Z, 6		; Z = Z + 6
	rcall	StrCmp
	tst		r24
	breq	CMD_TEMP
	ADDI6	Z, 6		; Z = Z + 6
	rcall	StrCmp
	tst		r24
	breq	CMD_PROJ
	PRINT	BAD_MSG
	SETXY	Y, buffer
	rcall	PutStringD
	PUTC	'!'
	PUTC	CR
	ret

CMD_HELP:
	jmp		HELP_TEST
CMD_LED:
	jmp 	LED_TEST
CMD_SEG1:
	jmp 	SEG1_TEST
CMD_SEGN:
	jmp 	SEGN_TEST
CMD_PHONE:
	jmp		PHONE_TEST
CMD_BUZ:
	jmp		BUZ_TEST
CMD_PHOTO:
	jmp 	PHOTO_TEST
CMD_TEMP:
	jmp		TEMP_TEST
CMD_PROJ:
	jmp		PROJ_TEST

StrCmp:					; same > return r24 = 0,  not same > return r24 = 1
	push	ZH
	push	ZL
	push	YH
	push	YL
	push	r16
	push	r17
CmpLoop:
	lpm		r16, Z+
	ld		r17, Y+
	cp		r16, r17
	brne	NEQ_STR		; 다를 때 branch
	cpi		r16, EOS
	breq	EQ_STR		; 같을 때 EOS면 끝
	rjmp	CmpLoop		; 같을 때 EOS가 아니면 루프
NEQ_STR:
	ldi		r24, 1		; if not equal
	rjmp	ENDCMP
EQ_STR:
	ldi		r24, 0		; if equal
ENDCMP:
	pop		r17
	pop		r16
	pop		YL
	pop		YH
	pop		ZL
	pop		ZH
	ret
;***********************************************************
HELP_TEST:
	PUTC	CR
	PUTC	CR
	PUTC	CR
	PUTC	CR
	PUTC	CR
	PUTC	CR
	PUTC	CR
	rcall	PrintTitle
	ret
;*************************************************************
LED_TEST:
	call	UARTInt_On			;인터럽트 활성화
	out		DDRA, r2			; r2 == 0xff
	ldi		TESTmode, TMODE_LED ; 
	sei							; UART_RXInt can change TESTmode
LEDbody:
	tst		TESTmode			;check test mode (0 == done)
	breq	Done_LED

	ldi		temp, 0x80
	mov		LEDdata, temp
LED_Loop:
	out		PORTA, LEDdata
	DELAYMS 500

	lsr		LEDdata
	brne	LED_Loop
	rjmp	LEDbody
Done_LED:
	cli							;disable interrupt
	clr		LEDdata
	out		PORTA, LEDdata
	call	UARTInt_Off			;인터럽트 비활성화
	ret
;**********************************************************
SEG1_TEST:                   ;add push pop ?
	rcall	UARTint_On	; uart interrupt on
	ldi		TESTmode, TMODE_SEG1
	rcall	FND_Init
	sei
	//body
	SETZ	Segdata
SEG1body:
	ldi		FND_En, 0x08
	sts		PORTG, FND_En ; first FND enable
	ldi		FND_cnt, 10
loop10:  ; 10 번 0~9 출력
	tst		TESTmode		;check test mode (0 == done)
	breq	Done_SEG1

	lpm		r3, Z+
	out		PORTC, r3 ;  FND on
	ldi		r25, high(200)
	ldi		r24, low(200)
	rcall	delay_ms

	dec		FND_cnt
	brne	loop10
loopFND:				; FND enable 신호 lsr 변경
	SETZ	Segdata
	ldi		FND_cnt, 10
	lsr		FND_En
	sts		PORTG, FND_En ; enable FND update
	brne	loop10
	rjmp	SEG1body
Done_SEG1:
	cli
	rcall	UARTint_Off
	rcall	FND_Off
	ret
;*****************************************************
SEGN_TEST:								; routine  diplay digit4 value to FND

	rcall	Timer1_Init									; timer1 interrupt 초기화
	rcall	ExInt_Init
	rcall	FND_Init
	rcall	UARTint_On									 ; uart int 활성화(for exit from segn test)
	ldi		TESTmode, TMODE_SEGN
	mov		GoStop_state, r0						  ; Go << '1', Stop << '0'
	sei												  ; interrupt 활성화

 // FND Display											  need to add testmode check, uart
	SETXY	X, digit4
	mov		temp, r0								 ; offset in digit4 > 0
	st		X+, temp
	st		X+, temp
	st		X+, temp
	st		X, temp
SEGNloop:
	 tst	TESTmode									;check test mode
	 breq	Done_SEGN
	 rcall	FND_display
	 rjmp	SEGNloop									; when FND_en '0'
Done_SEGN:
	cli
	rcall	UARTint_Off
	rcall	FND_Off
	rcall	Exint_Off
	rcall	Timer_Off
	ret
;********************************************************
PHONE_TEST:    ; routine  diplay digit4 value to FND

	rcall	Timer0_Init				  ; timer interrupt 초기화
	rcall	FND_Init
	rcall	UARTint_On			      ; uart int 활성화(for exit from segn test)
	ldi		TESTmode, TMODE_PHONE
	mov		GoStop_state, r2		  ; Go << '1', Stop << '0'
	clr		Phonecnt
	sei								  ; interrupt 활성화
	
 // FND Display                  just fnd display only
PHONEloop:
	 tst	TESTmode			;check test mode
	 breq	Done_PHONE
	 rcall	FND_display
	 rjmp	PHONEloop			; when FND_en '0'
Done_PHONE:
	cli
	rcall	UARTint_Off
	rcall	FND_Off
	rcall	Timer_Off
	ret
;*******************************************************
BUZ_TEST:;								add uart, check mode
	rcall	UARTint_On
	rcall	Timer2_Init
	ldi		TESTmode, TMODE_BUZ
	ldi		temp, 0x10
	out		DDRB, temp				 ;  set port B bit 4 as output       ; for BUZ on off signal
	clr		BUZmode

	SETZ	Song
	sei
BUZloop:							 ; main routine  update TCNT_value < array of Song
	cpi		TESTmode, TMODE_BUZ
	brne	Done_BUZ
	lpm		TCNT2_val, Z+
	cpi		TCNT2_val, endsong
	breq	Done_BUZ

	DELAYMS 500						; BUZ maintain sound 500ms
	rjmp	BUZloop
Done_BUZ:
	ldi		temp,  BUZ_off
	out		PORTB, temp
	cli								;	 interrupt off
	rcall	Timer_Off
	rcall	UARTint_Off
	ret
;*******************************************************
PHOTO_TEST:
	rcall	UARTint_On				; uart interrupt on
	rcall	Timer0_Init
	rcall	ADC_Init
	ldi		TESTmode, TMODE_PHOTO
	rcall	FND_Init
	sei

	SETZ	Segdata

 // FND Display						 need to add testmode check, uart
PHOTOloop:
	 tst	TESTmode				;check test mode
	 breq	Done_PHOTO
	 rcall	FND_display
	 rjmp	PHOTOloop
Done_PHOTO:
	cli
	rcall	ADC_Off
	rcall	UARTint_Off
	rcall	FND_Off
	rcall	Timer_Off
	ret
;*******************************************************
TEMP_TEST:
	rcall	UARTint_On				; uart interrupt on
	rcall	Timer0_Init
	rcall	TWI_Init				; pull up, bitrate setting for i2c
	ldi		TESTmode, TMODE_TEMP
	rcall	FND_Init
	sei

	SETZ	Segdata

 // FND Display						 need to add testmode check, uart
TEMPloop:
	 tst	TESTmode				;check test mode
	 breq	Done_TEMP
	 rcall	FND_dis_temp
	 rjmp	TEMPloop
Done_TEMP:
	cli
	rcall	UARTint_Off
	rcall	FND_Off
	rcall	Timer_Off
	ret
;********************************************************
PROJ_TEST:
	rcall	UARTint_On	; uart interrupt on
	rcall	Timer2_Init2	; 모터 속도 제어
	rcall	TWI_Init		; pull up, bitrate setting for i2c
	rcall	PWM_Init
	ldi		TESTmode, TMODE_PROJ
	sei					  ; interrupt 활성화

PROJloop:
	cp		TESTmode, r0
	brne	PROJloop
	rjmp	DonePOJ
DonePOJ:
	cli

	rcall	PWM_Off
	rcall	UARTint_Off
	rcall	Timer_Off
	rcall	TWI_Off
	ret
	;*******************************************************
Song:
	.db	DDo, Si, Ra, Sol, Pa, Mi, Re, Do, endsong, endsong

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