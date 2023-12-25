.macro delay
	push r18
	push r24
	push r25
	
	ldi r18, @0/10

l1:
	ldi r24, low(39998)
	ldi r25, high(39998)
l2:
	sbiw r24, 1
	brne l2
	dec r18
	brne l1
	nop

	pop r25
	pop r24
	pop r18
.endmacro