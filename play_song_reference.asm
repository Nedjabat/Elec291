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
TIMER00_RATE   EQU 3000     ; 2048Hz squarewave (peak amplitude of CEM-1203 speaker)
TIMER00_RELOAD EQU ((65536-(CLK/TIMER00_RATE)))
TIMER01_RATE   EQU 5000     ; 2048Hz squarewave (peak amplitude of CEM-1203 speaker)
TIMER01_RELOAD EQU ((65536-(CLK/TIMER01_RATE)))
TIMER2_RATE   EQU 1000     ; 1000Hz, for a timer tick of 1ms
TIMER2_RELOAD EQU ((65536-(CLK/TIMER2_RATE)))
;Normal notes
TIMER0C_RATE EQU 2093
TIMER0C_RELOAD EQU ((65536-(CLK/TIMER0C_RATE)))
TIMER0D_RATE EQU 2349
TIMER0D_RELOAD EQU ((65536-(CLK/TIMER0D_RATE)))
TIMER0E_RATE EQU 2637
TIMER0E_RELOAD EQU ((65536-(CLK/TIMER0E_RATE)))
TIMER0F_RATE EQU 2794
TIMER0F_RELOAD EQU ((65536-(CLK/TIMER0F_RATE)))
TIMER0G_RATE EQU 3136
TIMER0G_RELOAD EQU ((65536-(CLK/TIMER0G_RATE)))
TIMER0A_RATE EQU 3520
TIMER0A_RELOAD EQU ((65536-(CLK/TIMER0A_RATE)))
TIMER0B_RATE EQU 3951
TIMER0B_RELOAD EQU ((65536-(CLK/TIMER0B_RATE)))
;Sharps
TIMER0C1_RATE EQU 2217
TIMER0C1_RELOAD EQU ((65536-(CLK/TIMER0C1_RATE)))
TIMER0D1_RATE EQU 2489
TIMER0D1_RELOAD EQU ((65536-(CLK/TIMER0D1_RATE)))
TIMER0F1_RATE EQU 2960
TIMER0F1_RELOAD EQU ((65536-(CLK/TIMER0F1_RATE)))
TIMER0G1_RATE EQU 3322
TIMER0G1_RELOAD EQU ((65536-(CLK/TIMER0G1_RATE)))
TIMER0A1_RATE EQU 3729
TIMER0A1_RELOAD EQU ((65536-(CLK/TIMER0A1_RATE)))



BOOT_BUTTON   equ P4.5
SOUND_OUT     equ P1.1
UPDOWN        equ P0.0
FREQ_CHANGE1   equ P2.1
FREQ_CHANGE2   equ P2.4

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
; In the 8051 we can define direct access variables starting at location 0x30 up tolocation 0x7F
dseg at 0x30
Count1ms:     ds 2 ; Used to determine when half second has passed
BCD_counter:  ds 1 ; The BCD counter incrememted in the ISR and displayed in the main loop
; In the 8051 we have variables that are 1-bit in size.  We can use the setb, clr, jb, and jnb
; instructions with these variables.  This is how you define a 1-bit variable:
bseg
half_seconds_flag: dbit 1 ; Set to one in the ISR every time 500 ms had passed
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
Initial_Message:  db 'L:2500 R:1500', 0
Initial_Message1:  db 'Frequency: 2000', 0
Initial_Message2:  db 'Frequency: 1500', 0
;---------------------------------;
; Routine to initialize the ISR   ;
; for timer 0                     ;
;---------------------------------;
Timer00_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER00_RELOAD)
mov TL0, #low(TIMER00_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER00_RELOAD)
mov RL0, #low(TIMER00_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret

Timer01_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER01_RELOAD)
mov TL0, #low(TIMER01_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER01_RELOAD)
mov RL0, #low(TIMER01_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret

Timer0C_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER0C_RELOAD)
mov TL0, #low(TIMER0C_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER0C_RELOAD)
mov RL0, #low(TIMER0C_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret

Timer0C1_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER0C1_RELOAD)
mov TL0, #low(TIMER0C1_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER0C1_RELOAD)
mov RL0, #low(TIMER0C1_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret

Timer0D_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER0D_RELOAD)
mov TL0, #low(TIMER0D_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER0D_RELOAD)
mov RL0, #low(TIMER0D_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret


Timer0D1_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER0D1_RELOAD)
mov TL0, #low(TIMER0D1_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER0D1_RELOAD)
mov RL0, #low(TIMER0D1_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret
Timer0E_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER0E_RELOAD)
mov TL0, #low(TIMER0E_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER0E_RELOAD)
mov RL0, #low(TIMER0E_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret

Timer0F_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER0F_RELOAD)
mov TL0, #low(TIMER0F_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER0F_RELOAD)
mov RL0, #low(TIMER0F_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret

Timer0F1_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER0F1_RELOAD)
mov TL0, #low(TIMER0F1_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER0F1_RELOAD)
mov RL0, #low(TIMER0F1_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret

Timer0G_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER0G_RELOAD)
mov TL0, #low(TIMER0G_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER0G_RELOAD)
mov RL0, #low(TIMER0G_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret

Timer0G1_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER0G1_RELOAD)
mov TL0, #low(TIMER0G1_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER0G1_RELOAD)
mov RL0, #low(TIMER0G1_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret

Timer0A_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER0A_RELOAD)
mov TL0, #low(TIMER0A_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER0A_RELOAD)
mov RL0, #low(TIMER0A_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret

Timer0A1_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER0A1_RELOAD)
mov TL0, #low(TIMER0A1_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER0A1_RELOAD)
mov RL0, #low(TIMER0A1_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret

Timer0B_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER0B_RELOAD)
mov TL0, #low(TIMER0B_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER0B_RELOAD)
mov RL0, #low(TIMER0B_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret
;---------------------------------;
; ISR for timer 0.  Set to execute;
; every 1/4096Hz to generate a    ;
; 2048 Hz square wave at pin P1.1 ;
;---------------------------------;
Timer0_ISR:
;clr TF0  ; According to the data sheet this is done for us already.
cpl SOUND_OUT ; Connect speaker to P1.1!
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
cjne a, #low(500), Timer2_ISR_done ; Warning: this instruction changes the carry flag!
mov a, Count1ms+1
cjne a, #high(500), Timer2_ISR_done
; 500 milliseconds have passed.  Set a flag so the main program knows
setb half_seconds_flag ; Let the main program know half second had passed
cpl TR0 ; Enable/disable timer/counter 0. This line creates a beep-silence-beep-silence sound.
; Reset to zero the milli-seconds counter, it is a 16-bit variable
clr a
mov Count1ms+0, a
mov Count1ms+1, a
; Increment the BCD counter
mov a, BCD_counter
jnb UPDOWN, Timer2_ISR_decrement
add a, #0x01
sjmp Timer2_ISR_da
Timer2_ISR_decrement:
add a, #0x99 ; Adding the 10-complement of -1 is like subtracting 1.
Timer2_ISR_da:
da a ; Decimal adjust instruction.  Check datasheet for more details!
mov BCD_counter, a
Timer2_ISR_done:
pop psw
pop acc
reti
;---------------------------------;
; Main program. Includes hardware ;
; initialization and 'forever'    ;
; loop.                           ;
;---------------------------------;
main:
; Initialization
    mov SP, #0x7F
    ;lcall Timer2_Init
    ;lcall Timer00_Init
    ; In case you decide to use the pins of P0, configure the port in bidirectional mode:
    mov P0M0, #0
    mov P0M1, #0
    setb EA   ; Enable Global interrupts
    lcall LCD_4BIT
    ; For convenience a few handy macros are included in 'LCD_4bit.inc':
Set_Cursor(1, 1)
    Send_Constant_String(#Initial_Message)
    setb half_seconds_flag
mov BCD_counter, #0x00
; After initialization the program stays in this 'forever' loop

Freq2:
jb FREQ_CHANGE2, Freq1; if right button is not pressed go to Freq1
Wait_Milli_Seconds(#50)
jb FREQ_CHANGE2, Freq1
jnb FREQ_CHANGE2, $	
	lcall Timer00_Init
	ljmp Freq2

Freq1:
jb FREQ_CHANGE1, Freq2;if left button is not pressed go to Freq2
Wait_Milli_Seconds(#50)
jb FREQ_CHANGE1, Freq2
jnb FREQ_CHANGE1, $
	lcall Timer0C_Init
	Wait_Milli_Seconds(#255)
	lcall Timer0C1_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0D1_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0F_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0F1_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0F_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0D1_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0C_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0A1_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0D_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0C_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0G_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0C_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0C_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0D1_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0F_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0F1_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0F_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0D1_Init
		Wait_Milli_Seconds(#255)
	lcall Timer0F1_Init
	clr TR0
	ljmp Freq1
	
;Freq2:
;jb FREQ_CHANGE2, Freq1; if right button is not pressed go to Freq1
;Wait_Milli_Seconds(#50)
;jb FREQ_CHANGE2, Freq1
;jnb FREQ_CHANGE2, $	
;	lcall Timer00_Init
	


;jnb FREQ_CHANGE1, anotherloop2

;anotherloop2:
;jb FREQ_CHANGE2, loop_2
;Wait_Milli_Seconds(#50)
;jb FREQ_CHANGE2, loop_2
;jnb FREQ_CHANGE2, $

loop:
jb BOOT_BUTTON, loop_a  ; if the 'BOOT' button is not pressed skip
Wait_Milli_Seconds(#50) ; Debounce delay.  This macro is also in 'LCD_4bit.inc'
jb BOOT_BUTTON, loop_a  ; if the 'BOOT' button is not pressed skip
jnb BOOT_BUTTON, $ ; Wait for button release.  The '$' means: jumpto same instruction.
; A valid press of the 'BOOT' button has been detected, reset the BCD counter.
; But first stop timer 2 and reset the milli-seconds counter, to resync everything.



clr TR2                 ; Stop timer 2
clr a
mov Count1ms+0, a
mov Count1ms+1, a
; Now clear the BCD counter
mov BCD_counter, a
setb TR2                ; Start timer 2
sjmp loop_b             ; Display the new value
loop_a:
jnb half_seconds_flag, loop
loop_b:
;    clr half_seconds_flag ; We clear this flag in the main loop, but it is set in the ISR for timer 2
Set_Cursor(2, 14)     ; the place in the LCD where we want the BCD counter value
Display_BCD(BCD_counter) ; This macro is also in 'LCD_4bit.inc'
;    ljmp loop
 
;Freq1:
;jb FREQ_CHANGE1, loop_1;if left button is not pressed go to Freq2
;Wait_Milli_Seconds(#50)
;jb FREQ_CHANGE1, loop_1
;jnb FREQ_CHANGE1, $
;ljmp Freq2
 
 
;loop_1:
;	lcall Timer01_Init
;	Set_Cursor(2, 1)
;    Send_Constant_String(#Initial_Message1)
	;Wait_Milli_Seconds(#100)
	;ljmp anotherloop
;	ljmp Freq2

;Freq2:
;jb FREQ_CHANGE2, loop_2
;Wait_Milli_Seconds(#50)
;jb FREQ_CHANGE2, loop_2
;jnb FREQ_CHANGE2, $	
;ljmp Freq1

;loop_2:
	;lcall Timer00_Init
	;Set_Cursor(2, 1)
    ;Send_Constant_String(#Initial_Message2)
	;ljmp Freq1
END