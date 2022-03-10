$NOLIST
$MODLP51
$LIST


START_BUTTON   	equ P4.5
P1_BUTTON		equ	P2.4
P2_BUTTON	    equ	P2.6
UPDOWN        	equ P0.1

CLK           EQU 22118400
TIMER1_RATE   EQU 100     ; 1000Hz, for a timer tick of 1ms
TIMER1_RELOAD EQU ((65536-(CLK/TIMER1_RATE)))     ; 2100Hz Win Tone
TIMER00_RATE   EQU 6000     ; 2100Hz Win Tone, made very high freq to check
TIMER00_RELOAD EQU ((65536-(CLK/TIMER00_RATE))) 
TIMER01_RATE   EQU 2000  ;2000Hz Lose Tone, made very low freq to check
TIMER01_RELOAD EQU ((65536-(CLK/TIMER01_RATE))) ;2000Hz frequency lose frequency
TIMER2_RATE   EQU 4200                 ;2100Hz frequency win frequency
TIMER2_RELOAD EQU ((65536-(CLK/TIMER2_RATE)))

;Music player
;Normal notes Octave6
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
;Sharps Octave 6
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
;other Octaves
TIMER0A2_RATE EQU 1865 ;Octave 5 A#
TIMER0A2_RELOAD EQU ((65536-(CLK/TIMER0A2_RATE)))
TIMER0C2_RATE EQU 262 ;Octave 3 C
TIMER0C2_RELOAD EQU ((65536-(CLK/TIMER0C2_RATE)))


org 0000H
   ljmp MyProgram

org 0x000B
	ljmp Timer0_ISR
; Timer/Counter 1 overflow interrupt vector (not used in this code)
org 0x001B
	ljmp Timer1_ISR


DSEG at 0x30
x:   ds 4
y:   ds 4
seed: ds 4  
bcd: ds 5
Count1ms:     ds 2 
seconds:  ds 1 ;
p1points: ds 1
p2points: ds 1
freq1: ds 4
freq2: ds 4
counter: ds 4
Period_A: ds 2
Period_B: ds 2
bcd1: ds 5
bcd2: ds 5

BSEG
mf: dbit 1
p1_press: dbit 1
p2_press: dbit 1
second_high: dbit 1
half_seconds_flag: dbit 1

cseg
; These 'equ' must match the hardware wiring
LCD_RS equ P3.2
;LCD_RW equ PX.X ; Not used in this code, connect the pin to GND
LCD_E  equ P3.3
LCD_D4 equ P3.4
LCD_D5 equ P3.5
LCD_D6 equ P3.6
LCD_D7 equ P3.7
SOUND_OUT equ P1.1


Initial_Message:  db 'Player1:    ', 0
Initial_Message2: db 'Player2:    ', 0

Winner1_message1: db 'P1:Win!:D', 0
Winner1_message2: db 'P2:Lose:P', 0

Winner2_message1: db 'Loser:P', 0
Winner2_message2: db 'Winner!:D', 0

Playagain       : db 'Play   ', 0;changed for aesthetic
Clear_screen    : db 'Again ?', 0

$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$include(math32.inc)
$LIST


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

;---------------------------------;
; ISR for timer 0.  Set to execute;
; every 1/4096Hz to generate a    ;
; 2048 Hz square wave at pin P1.1 ;
;---------------------------------;


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

Timer0A2_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER0A2_RELOAD)
mov TL0, #low(TIMER0A2_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER0A2_RELOAD)
mov RL0, #low(TIMER0A2_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret

Timer0C2_Init:
mov a, TMOD
anl a, #0xf0 ; Clear the bits for timer 0
orl a, #0x01 ; Configure timer 0 as 16-timer
mov TMOD, a
mov TH0, #high(TIMER0C2_RELOAD)
mov TL0, #low(TIMER0C2_RELOAD)
; Set autoreload value
mov RH0, #high(TIMER0C2_RELOAD)
mov RL0, #low(TIMER0C2_RELOAD)
; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
ret



Timer0_ISR:
	clr TF0  ; According to the data sheet this is done for us already.
	cpl SOUND_OUT ; Connect speaker to P1.1!
	reti
	
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
Timer1_Init:

	mov TH1, #high(TIMER1_RELOAD)
	mov TL1, #low(TIMER1_RELOAD)
	; Set the reload value
	; Init One millisecond interrupt counter.  It is a 16-bit variable made with two 8-bit parts
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
	; Enable the timer and interrupts
    setb ET1  ; Enable timer 2 interrupt
    setb TR1  ; Enable timer 2
	ret

;---------------------------------;
; ISR for timer 2                 ;
;---------------------------------;
Timer1_ISR:
	clr TF1  ; Timer 2 doesn't clear TF2 automatically. Do it in ISR ; To check the interrupt rate with oscilloscope. It must be precisely a 1 ms pulse.
	
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
	cjne a, #low(1000), Timer1_ISR_done ; Warning: this instruction changes the carry flag!
	mov a, Count1ms+1
	cjne a, #high(1000), Timer1_ISR_done
	
	; 500 milliseconds have passed.  Set a flag so the main program knows
	setb half_seconds_flag ; Let the main program know half second had passed
	cpl TR0 ; Enable/disable timer/counter 0. This line creates a beep-silence-beep-silence sound.
	; Reset to zero the milli-seconds counter, it is a 16-bit variable
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
	; Increment the BCD counter
	mov a, seconds
	jnb UPDOWN, Timer1_ISR_decrement
	add a, #0x01
	sjmp Timer1_ISR_da
Timer1_ISR_decrement:
	add a, #0x99 ; Adding the 10-complement of -1 is like subtracting 1.
Timer1_ISR_da:
	da a ; Decimal adjust instruction.  Check datasheet for more details!
	mov seconds, a
    cjne a, #0x60, Timer1_ISR_done
    setb second_high
    clr a
    mov seconds, a
Timer1_ISR_done:
	pop psw
	pop acc
	reti
;---------------------------------;
; ISR for timer 0.  Set to execute;
; every 1/4096Hz to generate a    ;
; 2048 Hz square wave at pin P1.1 ;
;---------------------------------;
; When using a 22.1184MHz crystal in fast mode
; one cycle takes 1.0/22.1184MHz = 45.21123 ns
; (tuned manually to get as close to 1s as possible)
Wait1s:
    mov R2, #176
X3: mov R1, #250
X2: mov R0, #166
X1: djnz R0, X1 ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, X2 ; 22.51519us*250=5.629ms
    djnz R2, X3 ; 5.629ms*176=1.0s (approximately)
    ret

;Initializes timer/counter 2 as a 16-bit counter
InitTimer2:
	mov T2CON, #0b_0000_0000 ; Stop timer/counter.  Set as counter (clock input is pin T2).
	; Set the reload value on overflow to zero (just in case is not zero)
	mov RCAP2H, #0
	mov RCAP2L, #0
    setb P2.0 ; Pin is used as input
    setb P2.1  ; P1.0 is connected to T2.  Make sure it can be used as input.
    ret


;Converts the hex number in TH2-TL2 to BCD in R2-R1-R0

hex2bcd1:
	clr a
    mov R0, #0  ;Set BCD result to 00000000 
    mov R1, #0
    mov R2, #0
    mov R3, #16 ;Loop counter.

hex2bcd_loop1:
    mov a, TL2 ;Shift TH0-TL0 left through carry
    rlc a
    mov TL2, a
    
    mov a, TH2
    rlc a
    mov TH2, a
      
	; Perform bcd + bcd + carry
	; using BCD numbers
	mov a, R0
	addc a, R0
	da a
	mov R0, a
	
	mov a, R1
	addc a, R1
	da a
	mov R1, a
	
	mov a, R2
	addc a, R2
	da a
	mov R2, a
	
	djnz R3, hex2bcd_loop1
	ret
; Dumps the 5-digit packed BCD number in R2-R1-R0 into the LCD
DisplayBCD_LCD:
	; 5th digit:
    mov a, R2
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
	; 4th digit:
    mov a, R1
    swap a
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
	; 3rd digit:
    mov a, R1
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
	; 2nd digit:
    mov a, R0
    swap a
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
	; 1st digit:
    mov a, R0
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
    
    ret

random:
    mov x+0, seed+0
    mov x+1, seed+1
    mov x+2, seed+2
    mov x+3, seed+3
    Load_y(214013)
    lcall mul32
    Load_y(2451011)
    lcall add32
    mov seed+0, x+0
    mov seed+1, x+1
    mov seed+2, x+2
    mov seed+3, x+3
    ret

wait_random:
    Wait_Milli_Seconds(seed+0)
    Wait_Milli_Seconds(seed+1)
    Wait_Milli_Seconds(seed+2)
    Wait_Milli_Seconds(seed+3)
    ret

movtox:
	; 5th digit:
    mov a, R2
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
    mov bcd+4, #0
    mov bcd+3, #0
    mov bcd+2, R2
	;lcall ?WriteData
	; 4th digit:
    mov a, R1
    swap a
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	;lcall ?WriteData
	; 3rd digit:
    mov a, R1
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
    mov bcd+1, R1
	;lcall ?WriteData
	; 2nd digit:
    mov a, R0
    swap a
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
    
	;lcall ?WriteData
	; 1st digit:
    mov a, R0
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
    mov bcd+0, R0
	;lcall ?WriteData
    
    ret
;---------------------------------;
; Hardware initialization         ;
;---------------------------------;

;---------------------------------;
; Main program loop               ;
;---------------------------------;
MyProgram:
    ; Initialize the hardware:
    mov SP, #7FH
    lcall InitTimer2
    lcall LCD_4BIT
    lcall Timer1_Init
    Set_Cursor(1, 1)
    Send_Constant_String(#Initial_Message)
    Set_Cursor(2, 1)
    Send_Constant_String(#Initial_Message2)
    setb EA
    setb TR0
    setb TR2;random number
    setb half_seconds_flag
    jb P4.5, $
    mov seed+0, TH2
    mov seed+1, #0x01
    mov seed+2, #0x87
    mov seed+3, TL2
    clr TR2
    mov p1points, #0x00
    mov p2points, #0x00
    
forever:
    ; Measure the frequency applied to pin T2
    ; Measure the period applied to pin P2.0
    clr TR2 ; Stop counter 2
    mov TL2, #0
    mov TH2, #0
    jb P2.0, $
    jnb P2.0, $
    setb TR2 ; Start counter 0
    jb P2.0, $
    jnb P2.0, $
    clr TR2 ; Stop counter 2, TH2-TL2 has the period
    ; save the period of P2.0 for later use
	; Convert the result to BCD and display on LCD
	Set_Cursor(1, 12)
	lcall hex2bcd1
    ;lcall DisplayBCD_LCD
    
    ; Measure the period applied to pin P2.1
    clr TR2 ; Stop counter 2
    mov TL2, #0
    mov TH2, #0
    jb P2.1, $
    jnb P2.1, $
    setb TR2 ; Start counter 0
    jb P2.1, $
    jnb P2.1, $
    clr TR2 ; Stop counter 2, TH2-TL2 has the period
    ; save the period of P2.1 for later use
	; Convert the result to BCD and display on LCD
	Set_Cursor(2, 12)
	lcall hex2bcd1
   ; lcall DisplayBCD_LCD
	; Convert the result to BCD and display on LCD
	ljmp start_game
    ljmp forever ;  Repeat! 

forever1:
    Set_Cursor(1, 9)
    Display_BCD(p1points)
    Set_Cursor(2, 9)
    Display_BCD(p2points)
    ; Measure the period applied to pin P2.0
    clr TR2 ; Stop counter 2
    mov TL2, #0
    mov TH2, #0
    jb P2.0, $
    jnb P2.0, $
    setb TR2 ; Start counter 0
    jb P2.0, $
    jnb P2.0, $
    clr TR2 ; Stop counter 2, TH2-TL2 has the period
    ; save the period of P2.0 for later use
	; Convert the result to BCD and display on LCD
	Set_Cursor(1, 12)
	lcall hex2bcd1
    ;lcall DisplayBCD_LCD
    ret
forever2:
    Set_Cursor(1, 9)
    Display_BCD(p1points)
    Set_Cursor(2, 9)
    Display_BCD(p2points)
    ; Measure the period applied to pin P2.1
    clr TR2 ; Stop counter 2
    mov TL2, #0
    mov TH2, #0
    jb P2.1, $
    jnb P2.1, $
    setb TR2 ; Start counter 0
    jb P2.1, $
    jnb P2.1, $
    clr TR2 ; Stop counter 2, TH2-TL2 has the period
    ; save the period of P2.1 for later use
	; Convert the result to BCD and display on LCD
	Set_Cursor(2, 12)
	lcall hex2bcd1
    ;lcall DisplayBCD_LCD
    ret
start_game:
    setb p1_press
    setb p2_press 
    ;Set_Cursor(1, 1)
    ;Send_Constant_String(#Initial_Message);put initial message here too
    ;Set_Cursor(2, 1)
    ;Send_Constant_String(#Initial_Message2)	
    Set_Cursor(1, 1)
    Send_Constant_String(#Initial_Message);put initial message here too
    Set_Cursor(2, 1)
    Send_Constant_String(#Initial_Message2)	
    Set_Cursor(1, 9)
    Display_BCD(p1points)
    Set_Cursor(2, 9)
    Display_BCD(p2points)  
	;Set_Cursor(1, 12) ;period? for visibility
	;lcall hex2bcd1
	;Set_Cursor(2, 12)
	;lcall hex2bcd1
	clr TR0
	clr TR1
    lcall random
    lcall wait_random
    mov a, seed+1
    mov c, acc.3
    ;mov HLbit, c
    jc win_tone
    ljmp lose_tone

;figure out how to make it wait few seconds and then skip if none of the players pushes

lose_tone:
    lcall Timer01_Init
    		Wait_Milli_Seconds(#255)
    		Wait_Milli_Seconds(#255)
    		Wait_Milli_Seconds(#255)
    ljmp start_game_nohit1
win_tone: 
    lcall Timer00_Init
    		Wait_Milli_Seconds(#255)
    		Wait_Milli_Seconds(#255)
    		Wait_Milli_Seconds(#255)
    ljmp start_game_hit1
    
checkfreq1:
    load_y(4645)
    load_y(100);change made for my sensor
    lcall x_gteq_y
    jbc mf, freq1_nopress
    setb p1_press
    ret

freq1_nopress:
    clr p1_press
    ret

checkfreq2:
    load_y(4650)
    load_y(100);change made for my sensor
    lcall x_gteq_y
    jbc mf, freq2_press
    setb p2_press
    ret

freq2_press:
    clr p2_press
    ret

start_game_hit1:
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    jbc p1_press, start_game_hit2
    clr TR1
    clr a 
    mov a, p1points
    add a, #0x01
    mov p1points, a
    cjne a, #0x05, start_jmp1
    clr a
    setb p1_press
    setb p2_press
    ljmp p1win_jmp

p1win_jmp:
    setb p1_press
    setb p2_press
    ljmp p1win
checkfreq1_jmp:
    ljmp checkfreq1
start_game_hit2:
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
    jbc p2_press, start_game_hit1
    clr TR1
    clr a 
    mov a, p2points
    add a, #0x01
    mov p2points, a
    cjne a, #0x05, start_jmp1
    setb p1_press
    setb p2_press
    clr a
    ljmp p2win_jmp
start_game_hit1_jmp:
	ljmp start_game_hit1
	
start_jmp1:
    ljmp start_game

p2win_jmp:
    setb p1_press
    setb p2_press
    ljmp p2win

start_game_nohit1:
    setb p1_press
    setb p2_press
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
    ;jbc p1_press, start_game_nohit2
 ;   jbc half_seconds_flag, start_game_jmp
    Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
    Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
    Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
      Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
    Wait_Milli_Seconds(#10)
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
    jbc p1_press, check_p2
    jbc p2_press, p1_pressed
    

    clr a 
    mov a, p1points
    cjne a, #0x00, start_jmpsub1
    ljmp start_jmpsub2
    
check_p2_jmp:
	ljmp check_p2

p1_pressed:
    clr a 
    mov a, p1points
    cjne a, #0x00, subplayer1
    ljmp start_game

check_p2:
    jbc p2_press, start_game_jmp
    ljmp subplayer2

subplayer1:
    clr a
    mov a, p1points
    mov x, a
    Load_y(1)
    lcall sub32
    mov a, x
    da a
    mov p1points, a
    clr a
    setb p1_press
    setb p2_press
    clr a 
    ljmp start_game

subplayer2:
    clr a
    mov a, p2points
    cjne  a, #0x00, start_jmpsub2
    ljmp start_game

start_game_jmp:
    ljmp start_game

start_jmpsub1:
    
    mov x, a
    Load_y(1)
    lcall sub32
    mov a, x
    da a
    mov p1points, a
    clr a
    setb p1_press
    setb p2_press
    clr a 
    mov a, p2points
    cjne a, #0x00, start_jmpsub2
    ljmp start_game
    
start_jmpsub2:
    mov x, a
    Load_y(1)
    lcall sub32
    mov a, x
    da a
    mov p2points, a
    clr a
    clr p1_press
    clr p2_press
    ljmp start_jmp

start_jmp:
    setb p1_press
    setb p2_press
    ljmp start_game
p1win:
    setb p1_press
    setb p2_press
    Set_Cursor(1, 11)
    Set_Cursor(1, 8)
    Send_Constant_String(#Winner1_message1)
    Set_Cursor(2, 11)
    Set_Cursor(2, 8)
    Send_Constant_String(#Winner1_message2)
    Wait_Milli_Seconds(#5)
    Set_Cursor(1,1)
    Send_Constant_String(#Playagain)
    Set_Cursor(2,1)
    Send_Constant_String(#Clear_screen)
    clr TR0;stops timer
    ;plays music 
    ;new music ideas?
	lcall Timer0C2_Init
		Wait_Milli_Seconds(#255)
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
	lcall Timer0C_Init
		Wait_Milli_Seconds(#255)
		Wait_Milli_Seconds(#255)
		Wait_Milli_Seconds(#255)
	lcall Timer0A2_Init
		Wait_Milli_Seconds(#150)
	lcall Timer0D_Init
		Wait_Milli_Seconds(#150)
	lcall Timer0C_Init
		Wait_Milli_Seconds(#150)
		Wait_Milli_Seconds(#255)
		Wait_Milli_Seconds(#255)
		Wait_Milli_Seconds(#255)
	clr TR0
			Wait_Milli_Seconds(#255)
		Wait_Milli_Seconds(#255)
		Wait_Milli_Seconds(#255)
		
    jb START_BUTTON, p1win_jmp2
    Wait_Milli_Seconds(#5)
    Wait_Milli_Seconds(#50)
    jb START_BUTTON, p1win_jmp2
    jnb START_BUTTON, $
    ljmp restart_jmp
	
p1win_jmp2:
    ljmp p1win
	
p2win: 
    setb p1_press
    setb p2_press
    Set_Cursor(1, 11)
    Set_Cursor(1, 8)
    Send_Constant_String(#Winner1_message2)
    Set_Cursor(2,11)
    Set_Cursor(2,8)
    Send_Constant_String(#Winner1_message1)
    Wait_Milli_Seconds(#50)
    Set_Cursor(1,1)
    Send_Constant_String(#Playagain)
    Set_Cursor(2,1)
    Send_Constant_String(#Clear_screen)
    clr TR0;stops timer
	;plays music
	
		lcall Timer0C2_Init
		Wait_Milli_Seconds(#255)
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
	lcall Timer0C_Init
		Wait_Milli_Seconds(#255)
		Wait_Milli_Seconds(#255)
		Wait_Milli_Seconds(#255)
	lcall Timer0A2_Init
		Wait_Milli_Seconds(#150)
	lcall Timer0D_Init
		Wait_Milli_Seconds(#150)
	lcall Timer0C_Init
		Wait_Milli_Seconds(#150)
		Wait_Milli_Seconds(#255)
		Wait_Milli_Seconds(#255)
		Wait_Milli_Seconds(#255)
	clr TR0
			Wait_Milli_Seconds(#255)
		Wait_Milli_Seconds(#255)
		Wait_Milli_Seconds(#255)
		
    jb START_BUTTON, p2win_jmp1
    Wait_Milli_Seconds(#50)
    jb START_BUTTON, p2win_jmp1
    jnb START_BUTTON, $
    ljmp restart_jmp
  
  

	
p1win_jmp1:
    ljmp p1win

p2win_jmp1:
    ljmp p2win

restart_jmp:
    ljmp restart_game

restart_game:
    mov p1points, #0x00
    mov p2points, #0x00
    ljmp MyProgram	;goes back to MyProgram instead of start_game			
    ;ljmp start_game	;goes back to MyProgram instead of start_game				
end