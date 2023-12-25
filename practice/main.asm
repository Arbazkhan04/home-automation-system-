.include "m328pdef.inc"
.include "delayMacro.inc"
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

	loop:

		call ldrRead
		delay 1000

		call led1On
		call led2On
		call led3On
		call fan2On

		delay 1000

		call led1Off
		call led2Off
		call led3Off
		call fan2Off

		delay 1000

		call runVariableFan

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

	ldrRead:

		; ADC Configuration
		LDI A,0b11000111 ; [ADEN ADSC ADATE ADIF ADIE ADIE ADPS2 ADPS1 ADPS0]
		STS ADCSRA,A
		LDI A,0b01100000 ; [REFS1 REFS0 ADLAR – MUX3 MUX2 MUX1 MUX0]
		STS ADMUX,A ; Select ADC0 (PC0) pin
		SBI PORTC,PC0 ; Enable Pull-up Resistor

		LDS A,ADCSRA ; Start Analog to Digital Conversion
		ORI A,(1<<ADSC)
		STS ADCSRA,A

		wait:
			LDS A,ADCSRA ; wait for conversion to complete
			sbrc A,ADSC
			rjmp wait
			LDS A,ADCL ; Must Read ADCL before ADCH
			LDS AH,ADCH
			;value is in AH , how to send it to mqtt?
			

		ret

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