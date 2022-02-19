$NOLIST
$MODLP51
$LIST


START_BUTTON   	equ P4.5
P1_BUTTON		equ	P2.4
P2_BUTTON	    equ	P2.6
UPDOWN        	equ P0.1

CLK           EQU 22118400
TIMER0_RATE   EQU 1000     ; 1000Hz, for a timer tick of 1ms
TIMER0_RELOAD EQU ((65536-(CLK/TIMER2_RATE)))
TIMER1_RATE   EQU 6000      ; 2048Hz squarewave (peak amplitude of CEM-1203 speaker)
TIMER1_RELOAD EQU ((65536-(CLK/TIMER1_RATE)))
TIMER1_RATE1   EQU 2000  
TIMER1_RELOAD1 EQU ((65536-(CLK/TIMER1_RATE1)))               ;2000Hz frequency lose frequency
TIMER2_RATE   EQU 4200                 ;2100Hz frequency win frequency
TIMER2_RELOAD EQU ((65536-(CLK/TIMER2_RATE)))

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

Initial_Message:  db 'Player1:          ', 0
Initial_Message2: db 'Player2:          ', 0

Winner1_message1: db 'Win!:D', 0
Winner1_message2: db 'Lose:P', 0

Winner2_message1: db 'Loser:P', 0
Winner2_message2: db 'Winner!:D', 0

Playagain       : db 'Play again ?', 0
Clear_screen    : db '          ', 0

$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$include(math32.inc)
$LIST


Timer1_Init:
	mov a, TMOD
	anl a, #0xf0 ; Clear the bits for timer 0
	orl a, #0x01 ; Configure timer 0 as 16-timer
	mov TMOD, a
	mov TH1, #high(TIMER1_RELOAD)
	mov TL1, #low(TIMER1_RELOAD)
	; Set autoreload value
	mov RH1, #high(TIMER1_RELOAD)
	mov RL1, #low(TIMER1_RELOAD)
	; Enable the timer and interrupts
    setb ET1  ; Enable timer 0 interrupt
    setb TR1  ; Start timer 0
	ret

;---------------------------------;
; ISR for timer 0.  Set to execute;
; every 1/4096Hz to generate a    ;
; 2048 Hz square wave at pin P1.1 ;
;---------------------------------;
Timer1_ISR:
	clr TF1  ; According to the data sheet this is done for us already.
	cpl SOUND_OUT ; Connect speaker to P1.1!
	reti

Timer1_Init1:
	mov a, TMOD
	anl a, #0xf0 ; Clear the bits for timer 0
	orl a, #0x01 ; Configure timer 0 as 16-timer
	mov TMOD, a
	mov TH1, #high(TIMER1_RELOAD1)
	mov TL1, #low(TIMER1_RELOAD1)
	; Set autoreload value
	mov RH1, #high(TIMER1_RELOAD1)
	mov RL1, #low(TIMER1_RELOAD1)
	; Enable the timer and interrupts
    setb ET1  ; Enable timer 0 interrupt
    setb TR1  ; Start timer 0
	ret
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
Timer0_Init:

	;mov TCON, #0 ; Stop timer/counter.  Autoreload mode.
	mov TH0, #high(TIMER0_RELOAD)
	mov TL0, #low(TIMER0_RELOAD)
	; Set the reload value
	; Init One millisecond interrupt counter.  It is a 16-bit variable made with two 8-bit parts
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
	; Enable the timer and interrupts
    setb ET0  ; Enable timer 2 interrupt
    setb TR0  ; Enable timer 2
	ret

;---------------------------------;
; ISR for timer 2                 ;
;---------------------------------;
Timer0_ISR:
	clr TF0  ; Timer 2 doesn't clear TF2 automatically. Do it in ISR ; To check the interrupt rate with oscilloscope. It must be precisely a 1 ms pulse.
	cpl P0.1
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
	cjne a, #low(1000), Timer0_ISR_done ; Warning: this instruction changes the carry flag!
	mov a, Count1ms+1
	cjne a, #high(1000), Timer0_ISR_done
	
	; 500 milliseconds have passed.  Set a flag so the main program knows
	setb half_seconds_flag ; Let the main program know half second had passed
	cpl TR0 ; Enable/disable timer/counter 0. This line creates a beep-silence-beep-silence sound.
	; Reset to zero the milli-seconds counter, it is a 16-bit variable
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
	; Increment the BCD counter
	mov a, seconds
	jnb UPDOWN, Timer0_ISR_decrement
	add a, #0x01
	sjmp Timer0_ISR_da
Timer0_ISR_decrement:
	add a, #0x99 ; Adding the 10-complement of -1 is like subtracting 1.
Timer0_ISR_da:
	da a ; Decimal adjust instruction.  Check datasheet for more details!
	mov seconds, a
    cjne a, #0x60, Timer0_ISR_done
    setb second_high
    clr a
    mov seconds, a
Timer0_ISR_done:
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
    lcall Timer0_Init
    mov P0M0, #0
    mov P0M1, #0
    setb TR2
    Set_Cursor(1, 1)
    Send_Constant_String(#Initial_Message)
    Set_Cursor(2, 1)
    Send_Constant_String(#Initial_Message2)
    setb EA
    setb TR0
    setb half_seconds_flag
    jb P4.5, $
    mov seed+0, TH2
    mov seed+1, #0x01
    mov seed+2, #0x87
    mov seed+3, TL2
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
    Set_Cursor(1, 9)
    Display_BCD(p1points)
    Set_Cursor(2, 9)
    Display_BCD(p2points)  
    lcall random
    lcall wait_random
    mov a, seed+1
    mov c, acc.3
    ;mov HLbit, c
    jc win_tone
    ljmp lose_tone ; jc should come first???
    

lose_tone:
    lcall Timer1_Init
    ljmp start_game_nohit1
win_tone: 
    lcall Timer1_Init1
    ljmp start_game_hit1
    
checkfreq1:
    load_y(5000)
    lcall x_gteq_y
    jbc mf, freq1_nopress
    setb p1_press
    ret

freq1_nopress:
    clr p1_press
    ret

checkfreq2:
    load_y(5000)
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
    lcall forever1
    lcall movtox
    lcall bcd2hex
    lcall checkfreq1
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall Timer0_Init
    setb TR0
    jbc p1_press, start_game_nohit2
    jbc half_seconds_flag, start_game_jmp
    clr TR1
    clr TR0
    clr half_seconds_flag
    clr a 
    mov a, p1points
    cjne a, #0x00, start_jmpsub1
    ljmp start_game

start_game_jmp:
    clr TR0
    clr TR1
    clr half_seconds_flag
    clr a 
    mov a, p2points
    add a, #0x01
    mov p2points, a
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
    ljmp start_game

start_game_nohit2:
    lcall forever2
    lcall movtox
    lcall bcd2hex
    lcall checkfreq2
    lcall hex2bcd
    lcall DisplayBCD_LCD
    lcall Timer0_Init
    setb TR0
    jbc p2_press, start_game_nohit1_jmp
    jbc half_seconds_flag, start_game_jmp
    clr TR1
    clr TR0
    clr half_seconds_flag
    clr a 
    mov a, p2points
    cjne a, #0x00, start_jmpsub2
    ljmp start_jmp
    

    
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
    
start_game_nohit1_jmp:
	ljmp start_game_nohit1

start_jmp:
    setb p1_press
    setb p2_press
    ljmp start_game
p1win:
    setb p1_press
    setb p2_press
    Set_Cursor(1, 11)
    Send_Constant_String(#Winner1_message1)
    Set_Cursor(2, 11)
    Send_Constant_String(#Winner1_message2)
    Wait_Milli_Seconds(#5)
    Set_Cursor(1,1)
    Send_Constant_String(#Playagain)
    Set_Cursor(2,1)
    Send_Constant_String(#Clear_screen)
    jb START_BUTTON, p1win_jmp2
    Wait_Milli_Seconds(#5)
    jb START_BUTTON, p1win_jmp2
    jnb START_BUTTON, $
    ljmp restart_jmp
p1win_jmp2:
    ljmp p1win
p2win: 
    setb p1_press
    setb p2_press
    Set_Cursor(1, 11)
    Send_Constant_String(#Winner1_message2)
    Set_Cursor(2,11)
    Send_Constant_String(#Winner1_message1)
    Wait_Milli_Seconds(#50)
    Set_Cursor(1,1)
    Send_Constant_String(#Playagain)
    Set_Cursor(2,1)
    Send_Constant_String(#Clear_screen)
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
    Set_Cursor(1,1)
    Send_Constant_String(#Clear_screen)
    Set_Cursor(2,1)
    Send_Constant_String(#Clear_screen)
    ljmp start_game
end