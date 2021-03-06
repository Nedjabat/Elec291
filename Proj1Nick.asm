$NOLIST
$MODLP51
$LIST


START_BUTTON   	equ P0.0
P1_BUTTON		equ	P2.4
P2_BUTTON	    equ	P2.6

CLK           EQU 22118400
;TIMER0_RATE   EQU 2048     ; 
;TIMER0_RELOAD EQU ((65536-(CLK/TIMER0_RATE)))
TIMER00_RATE   EQU 4000                 ;2000Hz frequency lose frequency lose tone
TIMER01_RATE   EQU 4200                 ;2100Hz frequency win frequency win tone
TIMER00_RELOAD EQU ((65536-(CLK/TIMER00_RATE)));2000Hz frequency lose frequency
TIMER01_RELOAD EQU ((65536-(CLK/TIMER01_RATE)));2100Hz frequency win frequency

org 0000H
   ljmp MyProgram

org 0x000B
	ljmp Timer0_ISR

DSEG at 30H
x:   ds 4
y:   ds 4
seed: ds 4  
bcd: ds 5
p1points: ds 1
p2points: ds 1

BSEG
mf: dbit 1
p1_press: dbit 1
p2_press: dbit 1

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

Winner1_message1: db 'Winner!:D', 0
Winner1_message2: db 'Loser:P', 0

Winner2_message1: db 'Loser:P', 0
Winner2_message2: db 'Winner!:D', 0

Playagain       : db 'Play again ?', 0
Clear_screen    : db '          ', 0

$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$include(math32.inc)
$LIST

Timer00_Init:;;for 2000Hz lose tone
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
    clr TR0  ; Start timer 0
	ret

Timer00_ISR:
	;clr TF0  ; According to the data sheet this is done for us already.
	cpl SOUND_OUT ; Connect speaker to P1.1!
	reti

Timer01_Init:;for 2100Hz win tone
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
    clr TR0  ; Start timer 0
	ret


Timer01_ISR1:
	;clr TF0  ; According to the data sheet this is done for us already.
	cpl SOUND_OUT ; Connect speaker to P1.1!
	reti



Wait1s:
    mov R2, #176
X3: mov R1, #250
X2: mov R0, #166
X1: djnz R0, X1 ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, X2 ; 22.51519us*250=5.629ms
    djnz R2, X3 ; 5.629ms*176=1.0s (approximately)
    ret

random:;random number generator
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
wait_random:;wait random milli seconds
    Wait_Milli_Seconds(seed+0)
    Wait_Milli_Seconds(seed+1)
    Wait_Milli_Seconds(seed+2)
    Wait_Milli_Seconds(seed+3)
    ret

MyProgram:
    ;lcall Timer0_Init
    ;lcall Timer2_Init
    Set_Cursor(1, 1)
    Send_Constant_String(#Initial_Message)
    Set_Cursor(2, 1)
    Send_Constant_String(#Initial_Message2)
    mov p1points, #0x00
    mov p2points, #0x00
    setb EA
    setb TR0
    jb P4.5, $
    mov seed+0, TH2
    mov seed+1, #0x01
    mov seed+2, #0x87
    mov seed+3, TL2
    clr TR0
    clr TR2
    ljmp loop
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
    Set_Cursor(1, 11)
    Display_BCD(p1points)
    Set_Cursor(2, 11)
    Display_BCD(p2points)
    lcall random
    lcall wait_random
    mov a, seed+1
    mov c, acc.3
    ;mov HLbit, c
    jc lose_tone
    ljmp win_tone

lose_tone:;2000Hz lose tone
    ;ljmp play_lose
    lcall Timer00_Init
    setb TR0
    ljmp start_game_nohit1
win_tone: ;;2100Hz win tone
    ;ljmp play_win
    lcall Timer01_Init
    setb TR0
    ljmp start_game_hit1
   ;;How to make speaker play for 1s?

start_game_hit1:
    jb P1_BUTTON, start_game_hit2
    Wait_Milli_Seconds(#50)
    jb P1_BUTTON, start_game_hit2
    jnb P1_BUTTON, $
    clr TR0
    clr a 
    mov a, p1points
    add a, #0x01
    mov p1points, a
    cjne a, #0x05, p1win_jmp
    clr a
	;mov p1points, a ; to make it back to zero
    ljmp start_game

p1win_jmp:
    ljmp p1win

start_game_hit2:
    jb P2_BUTTON, start_game_hit1
    Wait_Milli_Seconds(#50)
    jb P2_BUTTON, start_game_hit1
    jnb P2_BUTTON, $
    clr TR0
    clr a 
    mov a, p2points
    add a, #0x01
    mov p2points, a
    cjne a, #0x05, p2win_jmp
    clr a
    ljmp start_game

p2win_jmp:
    ljmp p2win

start_game_nohit1:
    jb P1_BUTTON, start_game_nohit2
    Wait_Milli_Seconds(#50)
    jb P1_BUTTON, start_game_nohit2
    jnb P1_BUTTON, $
    clr TR0
    clr a 
    mov a, p1points
    cjne a, #0x00, start_jmp
    mov x, a
    Load_y(1)
    lcall sub32
    mov a, x
    da a
    mov p1points, a
    clr a
    ljmp start_game

start_game_nohit2:
    jb P2_BUTTON, start_game_nohit1
    Wait_Milli_Seconds(#50)
    jb P2_BUTTON, start_game_nohit1
    jnb P2_BUTTON, $
    clr TR0
    clr a 
    mov a, p2points
    cjne a, #0x00, start_jmp
    mov x, a
    Load_y(1)
    lcall sub32
    mov a, x
    da a
    mov p2points, a
    clr a
    ljmp start_jmp

start_jmp:
    ljmp start_game
p1win:  
    Set_Cursor(1, 9)
    Send_Constant_String(#Winner1_message1)
    Send_Constant_String(#Winner1_message2)
    Wait_Milli_Seconds(#5)
    Set_Cursor(1,1)
    Send_Constant_String(#Playagain)
    Set_Cursor(2,1)
    Send_Constant_String(#Clear_screen)
    jb P2_BUTTON, p1win_jmp2
    Wait_Milli_Seconds(#5)
    jb P2_BUTTON, p1win_jmp2
    jnb P2_BUTTON, $
    ljmp restart_jmp
p1win_jmp2:
    ljmp p1win
p2win: 
    Set_Cursor(1, 9)
    Send_Constant_String(#Winner2_message1)
    Set_Cursor(2,9)
    Send_Constant_String(#Winner2_message2)
    Wait_Milli_Seconds(#50)
    Set_Cursor(1,1)
    Send_Constant_String(#Playagain)
    Set_Cursor(2,1)
    Send_Constant_String(#Clear_screen)
    jb P2_BUTTON, p1win_jmp1
    Wait_Milli_Seconds(#50)
    jb P2_BUTTON, p1win_jmp1
    jnb P2_BUTTON, $
    ljmp restart_jmp

p1win_jmp1:
    ljmp p1win

p2win_jmp2:
    ljmp p2win

restart_jmp:
    ljmp restart_game

restart_game:
    mov p1points, #0x00
    mov p2points, #0x00
    ljmp start_game
end