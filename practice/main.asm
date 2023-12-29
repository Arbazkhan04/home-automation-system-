.include "m328pdef.inc"
.include "delayMacro.inc"
.include "UART_Macros.inc"
.include "div_Macro.inc"
.include "16bit_reg_read_write_Macro.inc"

.dseg
		.org SRAM_START
		buffer:	.byte	20	



	.cseg

		; Macro to calculate the value for PWM dutycycle and output it on PWM pin
		.macro PWM_set_dutycycle
			PUSH r16
			PUSH r17

			; formula  = dutycycle * 256 / 100
			;	ldi r16, dutycycle * 256 / 100
			;	out OCR0A,r16
			; where dutycycle could be from 0 to 99

			; r17 contains the input value
			mov r17, @0
			ldi r16, 2			; 256/100=2.56
			mul r16, r17		; Multiply r16 by r17, result in r1:r0
			mov r16, r0			; Copy the low byte of the result to r16
			mov r17, r1			; Copy the high byte of the result to r17

			; At this point, r16 contains the result of the expression (dutycycle*256/100)
			; So set the PWM dutycycle
			out OCR0A,r16

			POP r17
			POP r16
		.endmacro

	.def A = r20
	.def AH = r21

	.org 0x0000
		
		sbi ddrb, 3		; led1 port D3
		sbi ddrb, 4		; led2 port D4
		sbi ddrb, 5		; led3 port D5
		sbi ddrb, 6	    ; fan1 variable
		sbi ddrb, PD7	; fan2 normal

		; ADC Configuration		
		LDI A,0b11000111		; [ADEN ADSC ADATE ADIF ADIE ADIE ADPS2 ADPS1 ADPS0]
		STS ADCSRA,A
		LDI A,0b01100000		; [REFS1 REFS0 ADLAR – MUX3 MUX2 MUX1 MUX0]
		STS ADMUX,A				; Select ADC0 (PC0) pin
		SBI PORTC,PC0			; Enable Pull-up Resistor

		Serial_begin			; initilize UART serial communication


		;variable fan

		; Timer 0 in Fast PWM mode, output A low at cycle start
		ldi r16,(1<<COM0A1)|(1<<COM0A0)|(1<<WGM01)|(1<<WGM00) 
		out TCCR0A,r16			; to timer control port A
	
		; Start Timer 0 with prescaler = 1
		ldi r16,1<<CS00			; Prescaler = 1
		out TCCR0B,r16			; to timer control port B


	loop:

			; reading and sending LDR reading to UART
			LDS A,ADCSRA			; Start Analog to Digital Conversion
			ORI A,(1<<ADSC)
			STS ADCSRA,A
			wait:
				LDS A,ADCSRA		; wait for conversion to complete
				sbrc A,ADSC
			rjmp wait
			LDS A,ADCL				; Must Read ADCL before ADCH
			LDS AH,ADCH
			delay 100				; delay 100ms
	
			;Serial_writeReg_ASCII AH	; sending the received value to UART
			;Serial_writeChar ':'		; just for formating (e.g. 180: Day Time or 220: Night Time)
			;Serial_writeChar ' '

			;cpi AH,200			; compare LDR reading with our desired threshold
			;brsh LED_ON			; jump if same or higher (AH >= 200)
			;call led1Off		; LED OFF
			; writes the string "Day Time" to the UART
			;LDI ZL, LOW (2 * day_string)
			;LDI ZH, HIGH (2 * day_string)
			;Serial_writeStr
			;delay 500

			; finished here sending LDR reading

			; reading UART recieved by UNO
			LDI r16, 0
			; Check UART serial input buffer for any incoming data and place in r16
			//Serial_read
			; If there is no data received in UART serial buffer (r16==0)
			; then don't send it to UART
			LDI ZL, LOW (buffer)
			LDI ZH, HIGH (buffer)
			Serial_readStr


			CPI r16, 0
			BREQ skip_UART
			call led1On
			call skip_UART
			; Send value to variable fan
			//cpi r16, 10		; if value is greater than 10 then it is for variable fan
			//brsh setVariableFan
			
			cpi r16, 1		; turn on led1
			breq led1On
			
			cpi r16, 2		; turn on led2
			breq led2On

			cpi r16, 3		; turn on led3
			breq led3On

			cpi r16, 4		; turn off led1
			breq led1Off

			cpi r16, 5		; turn off led2
			breq led2Off

			cpi r16, 6		; turn off led3
			breq led3Off

			cpi r16, 7		; turn on fan2
			breq fan2On

			cpi r16, 8		; turn off fan2
			breq fan2Off

	
			skip_UART:
				call led1On

	rjmp loop

	led1On:
		sbi portd, 3
		ret

	led1Off:
		cbi portd, 3
		ret

	led2On:
		sbi portd, 4
		ret

	led2Off:
		cbi portd, 4
		ret

	led3On:
		sbi portd, 5
		ret

	led3Off:
		cbi portd, 5
		ret

	fan2On:
		cbi portd, 7
		ret

	fan2Off:
		sbi portd, 7
		ret

	

	LED_ON:
		call led1On		; LED ON
		; writes the string "Night Time" to the UART
		LDI ZL, LOW (2 * night_string)
		LDI ZH, HIGH (2 * night_string)
		Serial_writeStr
		delay 500
		ret
		

	setVariableFan:
		PWM_set_dutycycle r16
		delay 500
		ret
		

	day_string: .db "Day Time ",0x0D,0x0A,0
	night_string: .db "Night Time ",0x0D,0x0A,0