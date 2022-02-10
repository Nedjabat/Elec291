; ISR_example.asm: a) Increments/decrements a BCD variable every half second using
; an ISR for timer 2; b) Generates a 2kHz square wave at pin P1.1 using
; an ISR for timer 0; and c) in the 'main' loop it displays the variable
; incremented/decremented using the ISR for timer 2 on the LCD.  Also resets it to 
; zero if the 'BOOT' pushbutton connected to P4.5 is pressed.
$NOLIST
$MODLP51
$LIST

; There is a couple of typos in MODLP51 in the definition of the timer 0/1 reload
; special function registers (SFRs), so:

CLK           EQU 22118400 ; Microcontroller system crystal frequency in Hz
TIMER0_RATE   EQU 4096     ; 2048Hz squarewave (peak amplitude of CEM-1203 speaker)
TIMER0_RELOAD EQU ((65536-(CLK/TIMER0_RATE)))
TIMER2_RATE   EQU 1000     ; 1000Hz, for a timer tick of 1ms
TIMER2_RELOAD EQU ((65536-(CLK/TIMER2_RATE)))

BOOT_BUTTON   	equ P0.0
HOUR_BUTTON		equ	P2.4
MINUTE_BUTTON	equ	P2.6
SECOND_BUTTON 	equ	P0.6
AMPM_BUTTON 	equ	P0.3
OFF_BUTTON		equ P2.1
SOUND_OUT     	equ P1.1
UPDOWN        	equ P0.1
MODE_BUTTON 	equ P4.5

; Reset vector
org 0x0000
    ljmp main

; External interrupt 0 vector (not used in this code)
org 0x0003
	reti

; Timer/Counter 0 overflow interrupt vector
org 0x000B
	ljmp Timer0_ISR

; External interrupt 1 vector (not used in this code)
org 0x0013
	reti

; Timer/Counter 1 overflow interrupt vector (not used in this code)
org 0x001B
	reti

; Serial port receive/transmit interrupt vector (not used in this code)
org 0x0023 
	reti
	
; Timer/Counter 2 overflow interrupt vector
org 0x002B
	ljmp Timer2_ISR

; In the 8051 we can define direct access variables starting at location 0x30 up to location 0x7F
dseg at 0x30
Count1ms:     ds 2 ; Used to determine when half second has passed
seconds:  ds 1 ; The BCD counter incrememted in the ISR and displayed in the main loop
minutes:  ds 1
hours:    ds 1
apms:     ds 1
mode_select: ds 1
clk_hours: ds 1
clk_minutes: ds 1
; In the 8051 we have variables that are 1-bit in size.  We can use the setb, clr, jb, and jnb
; instructions with these variables.  This is how you define a 1-bit variable:
bseg
half_seconds_flag: dbit 1 ; Set to one in the ISR every time 500 ms had passed
second_high: dbit 1
minute_high: dbit 1
hour_high1: dbit 1
hour_high2: dbit 1
clk_stop: dbit 1
cseg
; These 'equ' must match the hardware wiring
LCD_RS equ P3.2
;LCD_RW equ PX.X ; Not used in this code, connect the pin to GND
LCD_E  equ P3.3
LCD_D4 equ P3.4
LCD_D5 equ P3.5
LCD_D6 equ P3.6
LCD_D7 equ P3.7

$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$LIST

;                     1234567890123456    <- This helps determine the location of the counter
Initial_Message:  db 'Time :xx:xx:xxA', 0
Initial_Message2: db 'Alarm:xx:xxA   ', 0
am: db 'A', 0
pm: db 'P', 0
fm: db 'F', 0
off: db 'OFF', 0
off1: db 'of1',0
on: db 'ON ', 0
work: db 'yes',0
work2: db 'no',0
work1: db 'ALM',0
;---------------------------------;
; Routine to initialize the ISR   ;
; for timer 0                     ;
;---------------------------------;
Timer0_Init:
	mov a, TMOD
	anl a, #0xf0 ; Clear the bits for timer 0
	orl a, #0x01 ; Configure timer 0 as 16-timer
	mov TMOD, a
	mov TH0, #high(TIMER0_RELOAD)
	mov TL0, #low(TIMER0_RELOAD)
	; Set autoreload value
	mov RH0, #high(TIMER0_RELOAD)
	mov RL0, #low(TIMER0_RELOAD)
	; Enable the timer and interrupts
    clr ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
	ret

;---------------------------------;
; ISR for timer 0.  Set to execute;
; every 1/4096Hz to generate a    ;
; 2048 Hz square wave at pin P1.1 ;
;---------------------------------;
Timer0_ISR:
	push acc
	push psw
	;setb ET0
	;clr TF0  ; According to the data sheet this is done for us already.
	;cpl SOUND_OUT ; Connect speaker to P1.1!	; Debounce delay.  This macro is also in 'LCD_4bit.inc'  ; if the 'BOOT' button is not pressed skip	
	pop psw
	pop acc
	reti

;---------------------------------;
; Routine to initialize the ISR   ;
; for timer 2                     ;
;---------------------------------;
Timer2_Init:

	mov T2CON, #0 ; Stop timer/counter.  Autoreload mode.
	mov TH2, #high(TIMER2_RELOAD)
	mov TL2, #low(TIMER2_RELOAD)
	; Set the reload value
	mov RCAP2H, #high(TIMER2_RELOAD)
	mov RCAP2L, #low(TIMER2_RELOAD)
	; Init One millisecond interrupt counter.  It is a 16-bit variable made with two 8-bit parts
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
	; Enable the timer and interrupts
    setb ET2  ; Enable timer 2 interrupt
    setb TR2  ; Enable timer 2
	ret

;---------------------------------;
; ISR for timer 2                 ;
;---------------------------------;
Timer2_ISR:
	clr TF2  ; Timer 2 doesn't clear TF2 automatically. Do it in ISR
	cpl P1.0 ; To check the interrupt rate with oscilloscope. It must be precisely a 1 ms pulse.
	
	; The two registers used in the ISR must be saved in the stack
	push acc
	push psw
	
	; Increment the 16-bit one mili second counter
	inc Count1ms+0    ; Increment the low 8-bits first
	mov a, Count1ms+0 ; If the low 8-bits overflow, then increment high 8-bits
	jnz Inc_Done
	inc Count1ms+1

Inc_Done:
	; Check if half second has passed
	mov a, Count1ms+0
	cjne a, #low(1000), Timer2_ISR_done ; Warning: this instruction changes the carry flag!
	mov a, Count1ms+1
	cjne a, #high(1000), Timer2_ISR_done
	
	; 500 milliseconds have passed.  Set a flag so the main program knows
	setb half_seconds_flag ; Let the main program know half second had passed
	cpl TR0 ; Enable/disable timer/counter 0. This line creates a beep-silence-beep-silence sound.
	; Reset to zero the milli-seconds counter, it is a 16-bit variable
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
	; Increment the BCD counter
	mov a, seconds
	jnb UPDOWN, Timer2_ISR_decrement
	add a, #0x01
	sjmp Timer2_ISR_da
Timer2_ISR_decrement:
	add a, #0x99 ; Adding the 10-complement of -1 is like subtracting 1.
Timer2_ISR_da:
	da a ; Decimal adjust instruction.  Check datasheet for more details!
	mov seconds, a
    cjne a, #0x60, Timer2_ISR_done
    setb second_high
    clr a
    mov seconds, a
Timer2_ISR_done:
	pop psw
	pop acc
	reti
sound_send:
	Set_Cursor(2,14)   
    Send_Constant_String(#work1)
	cpl SOUND_OUT
	jb OFF_BUTTON, sound_send  ; if the 'BOOT' button is not pressed skip
	Wait_Milli_Seconds(#50)	; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb OFF_BUTTON, sound_send  ; if the 'BOOT' button is not pressed skip
	jnb OFF_BUTTON , $
	mov a, mode_select
	add a, #0x01
	da a 
	mov mode_select, a	
	ljmp loop

pmcheck:
	jb hour_high2, sound_send
	ljmp loop_b

amcheck:
	jnb hour_high2, sound_send
	ljmp loop_b

main:
    mov SP, #0x7F ; Initialization
    lcall Timer0_Init
    lcall Timer2_Init ; In case you decide to use the pins of P0, configure the port in bidirectional mode:
    mov P0M0, #0
    mov P0M1, #0
    setb EA   ; Enable Global interrupts
    lcall LCD_4BIT
    ; For convenience a few handy macros are included in 'LCD_4bit.inc':
	Set_Cursor(1, 1)
    Send_Constant_String(#Initial_Message)
    Set_Cursor(2, 1)
    Send_Constant_String(#Initial_Message2)
    setb half_seconds_flag
	setb clk_stop
	clr hour_high1
	clr hour_high2
	mov seconds, #0x00
    mov minutes, #0x00
    mov hours, #0x01
	mov clk_minutes, #0x00
    mov clk_hours, #0x01
    mov apms, #0x00
	mov mode_select, #0x00

stop:
	clr TR2
	sjmp jmp_mode1

loop:
	jb BOOT_BUTTON, jmp_mode1  ; if the 'BOOT' button is not pressed skip
	Wait_Milli_Seconds(#50)	; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb BOOT_BUTTON, jmp_mode1  ; if the 'BOOT' button is not pressed skip
	jnb BOOT_BUTTON, $		; Wait for button release.  The '$' means: jump to same instruction.                 ; Stop timer 2
	clr a
	cpl clk_stop
	jb clk_stop, stop
	setb TR2                ; Start timer 2
	sjmp loop_b

check_alarm:
	Set_Cursor(2,14)   
    Send_Constant_String(#on)
	mov a, hours
	cjne a, clk_hours, loop
	mov a, minutes
	cjne a, clk_minutes, loop
	jb hour_high1, jmp_pm
	jnb hour_high1, jmp_am
	ljmp loop_b

jmp_pm:
	ljmp pmcheck
jmp_am:
	ljmp amcheck
loop_a:
	jnb half_seconds_flag, loop
jmp_mode1:
	jnb half_seconds_flag, jmp_mode2
loop_b:
    jbc second_high, min
    jbc minute_high, jmp_hour
    clr half_seconds_flag ; We clear this flag in the main loop, but it is set in the ISR for timer 2
	Set_Cursor(1, 13)     ; the place in the LCD where we want the BCD counter value
	Display_BCD(seconds) ; This macro is also in 'LCD_4bit.inc'
    Set_Cursor(1,10)
    Display_BCD(minutes)
    Set_Cursor(1,7)
    Display_BCD(hours)
	Set_Cursor(2, 7)
	Display_BCD(clk_hours)
	Set_Cursor(2,10)   
    Display_BCD(clk_minutes)
	ljmp loop
    

jmp_mode2:
	ljmp jmp_mode3

min:
    mov a, minutes
    ADD a, #0x01
    da a
    mov minutes, a
    clr second_high
    cjne a, #0x60, loop_b
    setb minute_high
    mov a, #0x00
    mov minutes, a
    ljmp loop_b
	
jmp_hour:
	ljmp hour
jmp_ampm:
	ljmp ampms1
jmp_loopb2:
	ljmp loop_b
hour:
    mov a, hours
    ADD a, #0x01
    da a
    mov hours, a
    clr minute_high
    cjne a, #0x13, ampms1
    cpl hour_high1
    mov a, #0x01
    mov hours, a
    ljmp ampms1

ampms1:
	jb hour_high1, resolution
	Set_Cursor(1,15)
    Send_Constant_String(#am)
    ljmp loop_b

resolution:
    Set_Cursor(1,15)
    Send_Constant_String(#pm)
	ljmp loop_b

jmp_mode3:
	ljmp modestart
jmp_loopb1:
	ljmp jmp_loopb2
jmp_alarm:
	ljmp check_alarm

modestart:
	jb MODE_BUTTON, mode_sel  ; if the 'BOOT' button is not pressed skip
	Wait_Milli_Seconds(#50)	; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb MODE_BUTTON, mode_sel  ; if the 'BOOT' button is not pressed skip
	jnb MODE_BUTTON, $
	clr a
	mov a, mode_select
	add a, #0x01
	da a 
	mov mode_select, a
	cjne a, #0x03, mode_sel
	mov a, #0x00
	mov mode_select, a
	clr a
	ljmp mode_sel

mode_sel:
	mov a, mode_select
	cjne a, #0x01, mode_sel2
	ljmp jmp_alarm
	
mode_sel2:
	cjne a, #0x00, jmp_modesel
	clr a 
	ljmp mode_hour_clk

mode_hour_clk:
	Set_Cursor(2,14)   
    Send_Constant_String(#off)
	jb HOUR_BUTTON, ampms1_clk  ; if the 'BOOT' button is not pressed skip
	Wait_Milli_Seconds(#50)	; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb HOUR_BUTTON, ampms1_clk  ; if the 'BOOT' button is not pressed skip
	jnb HOUR_BUTTON, $
	clr a
	mov a, clk_hours
	add a, #0x01
	da a
	mov clk_hours, a
	cjne a, #0x13, ampms1_clk 
	cpl hour_high2
	mov a, #0x01
	mov clk_hours, a
	clr a
	sjmp ampms1_clk
jmp_modesel:
	ljmp mode_hour
ampms1_clk:
	jb hour_high2, resolution_clk
	Set_Cursor(2,12)
    Send_Constant_String(#am)
    ljmp set_minute_clk

resolution_clk:
    Set_Cursor(2,12)
    Send_Constant_String(#pm)
	ljmp set_minute_clk

mode_hour:
	Set_Cursor(2,14)
	Send_Constant_String(#off)
	jb HOUR_BUTTON, ampms2 ; if the 'BOOT' button is not pressed skip
	Wait_Milli_Seconds(#50)	; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb HOUR_BUTTON, ampms2  ; if the 'BOOT' button is not pressed skip
	jnb HOUR_BUTTON, $
	clr a
	mov a, hours
	add a, #0x01
	da a
	mov hours, a
	cjne a, #0x13, ampms2
	cpl hour_high1
	mov a, #0x01
	mov hours, a
	clr a
	sjmp ampms2

ampms2:
	jb hour_high1, resolution2
	Set_Cursor(1,15)
    Send_Constant_String(#am)
    ljmp set_minute

resolution2:
    Set_Cursor(1,15)
    Send_Constant_String(#pm)
	ljmp set_minute

jmp_loopb0:
	ljmp jmp_loopb1

set_minute_clk:
	jb MINUTE_BUTTON, jmp_loopb0  ; if the 'BOOT' button is not pressed skip
	Wait_Milli_Seconds(#50)	; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb MINUTE_BUTTON, jmp_loopb0  ; if the 'BOOT' button is not pressed skip
	jnb MINUTE_BUTTON, $
	clr a
	mov a, clk_minutes
	add a, #0x01
	da a
	mov clk_minutes, a
	cjne a, #0x60, jmp_loopb
	mov a, #0x00
	mov clk_minutes, a
	clr a
	sjmp jmp_loopb

set_minute:
	jb MINUTE_BUTTON, set_second  ; if the 'BOOT' button is not pressed skip
	Wait_Milli_Seconds(#50)	; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb MINUTE_BUTTON, set_second  ; if the 'BOOT' button is not pressed skip
	jnb MINUTE_BUTTON, $
	clr a
	mov a, minutes
	add a, #0x01
	da a
	mov minutes, a
	cjne a, #0x60, set_second
	mov a, #0x01
	mov minutes, a
	clr a
	sjmp set_second

set_second:
	jb SECOND_BUTTON, jmp_loopb  ; if the 'BOOT' button is not pressed skip
	Wait_Milli_Seconds(#50)	; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb SECOND_BUTTON, jmp_loopb  ; if the 'BOOT' button is not pressed skip
	jnb SECOND_BUTTON, $
	clr a
	mov a, seconds
	add a, #0x01
	da a
	mov seconds, a
	cjne a, #0x60, jmp_loopb
	mov a, #0x01
	mov seconds, a
	clr a
	sjmp jmp_loopb

jmp_loopb:
	ljmp jmp_loopb1


   
END
