$NOLIST
$MODLP51
$LIST

$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$LIST

$NOLIST
$include(math32.inc)
$LIST


org 0000H
   ljmp MyProgram

DSEG at 30H
x:   ds 4
y:   ds 4

seed: ds 4  
bcd: ds 5
p1points: ds 1
p2points: ds 1
cap1: ds 1
cap2: ds 1

BSEG
mf: dbit 1
cseg
; These 'equ' must match the hardware wiring
LCD_RS equ P3.2
;LCD_RW equ PX.X ; Not used in this code, connect the pin to GND
LCD_E  equ P3.3
LCD_D4 equ P3.4
LCD_D5 equ P3.5
LCD_D6 equ P3.6
LCD_D7 equ P3.7

Initial_Message:  db 'Player1:', 0
Initial_Message2: db 'Player2:', 0
                     ;12345678
Winner1_message1: db 'Winner!:D', 0
Winner1_message2: db 'Loser:P', 0

Winner2_message1: db 'Loser:P', 0
Winner2_message2: db 'Winner!:D', 0

Playagain       : db 'Play again ?', 0
					 ;1234567891234567
Clear_screen    : db '          ', 0

Wait1s:
    mov R2, #176
X3: mov R1, #250
X2: mov R0, #166
X1: djnz R0, X1 ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, X2 ; 22.51519us*250=5.629ms
    djnz R2, X3 ; 5.629ms*176=1.0s (approximately)
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

MyProgram:
    Set_Cursor(1, 1)
    Send_Constant_String(#Initial_Message)
    Set_Cursor(2, 1)
    Send_Constant_String(#Initial_Message2)
    setb TR2
    jb P4.5, $
    mov seed+0, TH2
    mov seed+1, #0x01
    mov seed+2, #0x87
    mov seed+3, TL2
    clr TR2
    
     ; Initialize the hardware: (timer code from lab3)
    mov SP, #7FH
    lcall Initialize_All
    setb P0.0 ; Pin is used as input
    

loop:
    Set_Cursor(1, 11)
    Display_BCD(p1points)
    Set_Cursor(2, 11)
    Display_BCD(p2points)
    
    jb START_BUTTON, start_game
    Wait_Milli_Seconds(#50)
    jb START_BUTTON, start_game
    jnb START_BUTTON, $
    ljmp loop

start_game:
    lcall random
    lcall wait_random
    mov a, seed+1
    mov c, acc.3
    ;mov HLbit, c

    jc lose_tone
    ljmp win_tone

lose_tone:
    ;play sound
    ljmp start_game_nohit1
    
win_tone: 
    ;play sound
    ljmp start_game_hit1
    


start_game_hit1:
;    jb P1_BUTTON, start_game_hit2
;    Wait_Milli_Seconds(#50)
;    jb P1_BUTTON, start_game_hit2
;    jnb P1_BUTTON, $
	mov a, cap1
	cjne a, #14, start_game_hit2 ;check if player1 hit , if not go check player2
	Wait_Milli_Seconds(#2000)
	mov a, cap1
	cjne a, #14, start_game_hit2
    clr a 
    mov a, p1points
    add a, #0x01
    da a
    mov p2points, a
    cjne a, #0x05, p1win
    clr a
    ljmp start_game

start_game_hit2:
 ;   jb P2_BUTTON, start_game_hit1
 ;   Wait_Milli_Seconds(#50)
 ;   jb P2_BUTTON, start_game_hit1
 ;   jnb P2_BUTTON, $
 	mov a, cap2
 	cjne a, #14, start_game_hit1 ;check if player 2 hit, if not go check player 1
	Wait_Milli_Seconds(#2000)
	
	mov a, cap2
	cjne a, #14, start_game_hit1
 	
    clr a 
    mov a, p2points
    add a, #0x01
    da a
    mov p2points, a
    cjne a, #0x05, p2win
    clr a
    ljmp start_game

start_game_nohit1:
;    jb P1_BUTTON, start_game_nohit2
;    Wait_Milli_Seconds(#50)
;    jb P1_BUTTON, start_game_nohit2
;    jnb P1_BUTTON, $
	mov a, cap1
	cjne a, #14, start_game_nohit2 ;check if player 1 hit
	Wait_Milli_Seconds(#2000)
	mov a, cap1
	cjne a, #14, start_game_nohit2
	
    clr a 
    mov a, p1points
    cjne a, #0x00, start_game
    mov x,a
    Load_y(1)
    lcall sub32
    mov a,x
    da a
    mov p1points, a
    clr a
    ljmp start_game

start_game_nohit2:
;    jb P2_BUTTON, start_game_nohit1
;    Wait_Milli_Seconds(#50)
;    jb P2_BUTTON, start_game_nohit1
;    jnb P2_BUTTON, $
	mov a, cap2
	cjne a, #14, start_game_nohit1 ;check if player 2 hit
	Wait_Milli_Seconds(#2000)
	mov a, cap2
	cjne a, #14, start_game_nohit1
	
    clr a 
    mov a, p2points
    cjne a, #0x00, start_game
    mov x, a
    Load_y(1)
    lcall sub32
    mov a, x
    da a
    mov p2points, a
    clr a
    ljmp start_game

p1win:  
    Set_Cursor(1, 9)
    Send_Constant_String(#Winner1_message1)
    Send_Constant_String(#Winner1_message2)
    Wait_Milli_Seconds(#5000)
    Set_Cursor(1,1)
    Send_Constant_String(#Playagain)
    Set_Cursor(2,1)
    Send_Constant_String(#Clear_screen)
    jb P2_BUTTON, p1win
    Wait_Milli_Seconds(#50)
    jb P2_BUTTON, p1win
    jnb P2_BUTTON, $
    ljmp restart_game

p2win: 
    Set_Cursor(1, 9)
    Send_Constant_String(#Winner2_message1)
    Set_Cursor(2,9)
    Send_Constant_String(#Winner2_message2)
    Wait_Milli_Seconds(#50000)
    Set_Cursor(1,1)
    Send_Constant_String(#Playagain)
    Set_Cursor(2,1)
    Send_Constant_String(#Clear_screen)
    jb P2_BUTTON, p1win
    Wait_Milli_Seconds(#50)
    jb P2_BUTTON, p1win
    jnb P2_BUTTON, $
    ljmp restart_game

restart_game:
    mov p1points, #0x00
    mov p2points, #0x00
    ljmp start_game


;timer stuff to measure frequency
;Initializes timer/counter 2 as a 16-bit timer (given code from lab 3)
InitTimer2:
	mov T2CON, #0 ; Stop timer/counter.  Set as timer (clock input is pin 22.1184MHz).
	; Set the reload value on overflow to zero (just in case is not zero)
	mov RCAP2H, #0
	mov RCAP2L, #0
	setb ET2
    ret

Timer2_ISR:
	clr TF2  ; Timer 2 doesn't clear TF2 automatically. Do it in ISR
	push acc
	inc T2ov+0
	mov a, T2ov+0
	jnz Timer2_ISR_done
	inc T2ov+1
Timer2_ISR_done:
	pop acc
	reti
	
;---------------------------------;
; Hardware initialization         ;
;---------------------------------;
Initialize_All:
    lcall InitTimer2
    lcall LCD_4BIT ; Initialize LCD
    setb EA
	ret
	
forever:
    ; synchronize with rising edge of the signal applied to pin P0.0
    clr TR2 ; Stop timer 2
    mov TL2, #0
    mov TH2, #0
    mov T2ov+0, #0
    mov T2ov+1, #0
    clr TF2
    setb TR2
synch1:
	mov a, T2ov+1
	anl a, #0xfe
	jnz no_signal ; If the count is larger than 0x01ffffffff*45ns=1.16s, we assume there is no signal
    jb P0.0, synch1
synch2:    
	mov a, T2ov+1
	anl a, #0xfe
	jnz no_signal
    jnb P0.0, synch2
    
    ; Measure the period of the signal applied to pin P0.0
    clr TR2
    mov TL2, #0
    mov TH2, #0
    mov T2ov+0, #0
    mov T2ov+1, #0
    clr TF2
    setb TR2 ; Start timer 2
measure1:
	mov a, T2ov+1
	anl a, #0xfe
;	jnz no_signal 
    jb P0.0, measure1
measure2:    
	mov a, T2ov+1
	anl a, #0xfe
;	jnz no_signal
    jnb P0.0, measure2
    clr TR2 ; Stop timer 2, [T2ov+1, T2ov+0, TH2, TL2] * 45.21123ns is the period

	sjmp skip_this
;no_signal:	
;	Set_Cursor(2, 1)
;    Send_Constant_String(#No_Signal_Str)
;    ljmp forever ; Repeat! 
skip_this:

	; Make sure [T2ov+1, T2ov+2, TH2, TL2]!=0
	mov a, TL2
	orl a, TH2
	orl a, T2ov+0
	orl a, T2ov+1
	jz no_signal
	; Using integer math, convert the period to frequency:
	mov x+0, TL2
	mov x+1, TH2
	mov x+2, T2ov+0
	mov x+3, T2ov+1
	Load_y(45) ; One clock pulse is 1/22.1184MHz=45.21123ns
	lcall mul32
	
	Load_y(2079) ;C = T /*(0.693*(R1+2*R2)) -> r1 = r2 = 1k -> C = T / 2079
	lcall div32
;capacitance is now in x
	mov cap1, x

    ljmp forever ; Repeat! 
    

end
	