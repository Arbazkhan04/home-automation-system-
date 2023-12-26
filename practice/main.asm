.include "m328pdef.inc"
.include "delayMacro.inc"
.include "UART_Macros.inc"
	.cseg

	.def A = r16
	.def AH = r17
	.def temp = r18
	.def level = r19	; variable for storing variation of fan

	.org 0x00
		
		sbi ddrb, 3		; led1 port D3
		sbi ddrb, 4		; led2 port D4
		sbi ddrb, 5		; led3 port D5
		sbi ddrb, 6	    ; fan1 variable
		sbi ddrb, PD7	; fan2 normal

		call variableFan
		call ldrReadInitialize

	loop:

		
		call ldrTakeReading

	rjmp loop

	day_string: .db "Day Time ",0x0D,0x0A,0
	night_string: .db "Night Time ",0x0D,0x0A,0

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

	ldrReadInitialize:

		; ADC Configuration
		LDI A,0b11000111 ; [ADEN ADSC ADATE ADIF ADIE ADIE ADPS2 ADPS1 ADPS0]
		STS ADCSRA,A
		LDI A,0b01100000 ; [REFS1 REFS0 ADLAR – MUX3 MUX2 MUX1 MUX0]
		STS ADMUX,A ; Select ADC0 (PC0) pin
		SBI PORTC,PC0 ; Enable Pull-up Resistor

		Serial_begin ; initilize UART serial communication

		ret

	ldrTakeReading:

			LDS A,ADCSRA ; Start Analog to Digital Conversion
			ORI A,(1<<ADSC)
			STS ADCSRA,A

			wait:
				LDS A,ADCSRA ; wait for conversion to complete
				sbrc A,ADSC
			rjmp wait

			LDS A,ADCL ; Must Read ADCL before ADCH
			LDS AH,ADCH
			delay 100 ; delay 100ms
			Serial_writeReg_ASCII AH ; sending the received value to UART
			Serial_writeChar ':' ; just for formating (e.g. 180: Day Time or 220: Night Time)
			Serial_writeChar ' '
			cpi AH,200 ; compare LDR reading with our desired threshold
			call LED_On ; jump if same or higher (AH >= 200)
			call led1Off ; LED OFF
			; writes the string "Day Time" to the UART
			LDI ZL, LOW (2 * day_string)
			LDI ZH, HIGH (2 * day_string)
			Serial_writeStr
			delay 500

			ret

	LED_On:
		call led1On ; LED ON
		; writes the string "Night Time" to the UART
		LDI ZL, LOW (2 * night_string)
		LDI ZH, HIGH (2 * night_string)
		Serial_writeStr
		delay 500

	variableFan:

		ldi temp,0 * 256 / 100 
		out OCR0A,temp

		ldi temp,(1<<COM0A1)|(1<<COM0A0)|(1<<WGM01)|(1<<WGM00)
		out TCCR0A,temp

		ldi temp,1<<CS00 
		out TCCR0B,temp

		ret

	runVariableFan:

		ldi temp,90 * 256 / 100 ; set brightness
		out OCR0A,temp
		delay 500

		ret