 ;timer stuff to measure frequency

;Initializes timer/counter 2 as a 16-bit timer (given code from lab 3)

;timer 0 stuff:
Timer0_Init:
	mov a, TMOD
	anl a, #0xf0 ; 11110000 Clear the bits for timer 0
	orl a, #0x01 ; 00000001 Configure timer 0 as 16-timer
	mov TMOD, a
	mov TH0, #high(TIMER0_RELOAD)
	mov TL0, #low(TIMER0_RELOAD)
	; Set autoreload value
	mov RH0, #high(TIMER0_RELOAD)
	mov RL0, #low(TIMER0_RELOAD)
	; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
	ret


Timer0_ISR:
	clr TF0  ; Timer 2 doesn't clear TF2 automatically. Do it in ISR
	push acc
	inc T0ov+0
	mov a, T0ov+0
	jnz Timer0_ISR_done
	inc T0ov+1


Timer0_ISR_done:
	pop acc
	reti
	
forever_0:
    ; synchronize with rising edge of the signal applied to pin P0.0
    clr TR0 ; Stop timer 2
    mov TL0, #0
    mov TH0, #0
    mov T0ov+0, #0
    mov T0ov+1, #0
    clr TF0
    setb TR2
synch1_0:
	mov a, T0ov+1
	anl a, #0xfe
;	jnz no_signal ; If the count is larger than 0x01ffffffff*45ns=1.16s, we assume there is no signal
    jb P0.0, synch1_0
synch2_0:    
	mov a, T0ov+1
	anl a, #0xfe
;	jnz no_signal
    jnb P0.0, synch2_0
    
    ; Measure the period of the signal applied to pin P0.0
    clr TR0
    mov TL0, #0
    mov TH0, #0
    mov T0ov+0, #0
    mov T0ov+1, #0
    clr TF0
    setb TR0 ; Start timer 2
measure1_0:
	mov a, T0ov+1
	anl a, #0xfe
;	jnz no_signal 
    jb P0.0, measure1_0
  
measure2_0:    
	mov a, T0ov+1
	anl a, #0xfe
;	jnz no_signal
    jnb P0.0, measure2_0
    clr TR2 ; Stop timer 2, [T2ov+1, T2ov+0, TH2, TL2] * 45.21123ns is the period

	sjmp skip_this_0
	

;no_signal:	
;	Set_Cursor(2, 1)
;    Send_Constant_String(#No_Signal_Str)
;    ljmp forever ; Repeat! 
skip_this_0:

	; Make sure [T2ov+1, T2ov+2, TH2, TL2]!=0
	mov a, TL0
	orl a, TH0
	orl a, T0ov+0
	orl a, T0ov+1
;	jz no_signal
	; Using integer math, convert the period to frequency:
	mov x+0, TL0
	mov x+1, TH0
	mov x+2, T0ov+0
	mov x+3, T0ov+1
	Load_y(45) ; One clock pulse is 1/22.1184MHz=45.21123ns
	lcall mul32
	
	mov freq1, x ;(frequency 1)

    ljmp forever_0 ; Repeat! 
    
;-----------------------------------------------------------------

;TIMER 2 STUFF
InitTimer2:
	mov T2CON, #0 ; Stop timer/counter.  Set as timer (clock input is pin 22.1184MHz).
	; Set the reload value on overflow to zero (just in case is not zero)
@ -296,12 +395,12 @@ forever:
synch1:
	mov a, T2ov+1
	anl a, #0xfe
;	jnz no_signal ; If the count is larger than 0x01ffffffff*45ns=1.16s, we assume there is no signal
    jb P0.0, synch1
synch2:    
	mov a, T2ov+1
	anl a, #0xfe
;	jnz no_signal
    jnb P0.0, synch2
    
    ; Measure the period of the signal applied to pin P0.0
@ -336,7 +435,7 @@ skip_this:
	orl a, TH2
	orl a, T2ov+0
	orl a, T2ov+1
;	jz no_signal
	; Using integer math, convert the period to frequency:
	mov x+0, TL2
	mov x+1, TH2

 skip_this:
	Load_y(45) ; One clock pulse is 1/22.1184MHz=45.21123ns
	lcall mul32
	
	Load_y(2079) ;C = T /*(0.693*(R1+2*R2)) -> r1 = r2 = 1k -> C = T / 2079
	lcall div32
;capacitance is now in x
	mov cap1, x
;freq is now in x
	mov freq2, x

    ljmp forever ; Repeat! 
    

end