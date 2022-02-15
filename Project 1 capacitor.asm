$NOLIST
$MODLP51
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

BSEG
mf: dbit 1

$NOLIST
$include(LCD_4bit.inc) 
$include(math32.inc)
$LIST

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
    Load_y(2531011)
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
    mov HLbit, c
    jc lose_tone
    ljmp win_tone

lose_tone:
    ;play sound
    ljmp start_game_nohit1
win: 
    ;play sound
    ljmp start_game_hit1
    


start_game_hit1:
    jb P1_BUTTON, start_game_hit2
    Wait_Milli_Seconds(#50)
    jb P1_BUTTON, start_game_hit2
    jnb P1_BUTTON, $
    clr a 
    mov a, p1points
    add a, #0x01
    mov p2points, a
    cjne a, #0x05, p1win
    clr a
    ljmp start_game

start_game_hit2:
    jb P2_BUTTON, start_game_hit1
    Wait_Milli_Seconds(#50)
    jb P2_BUTTON, start_game_hit1
    jnb P2_BUTTON, $
    clr a 
    mov a, p2points
    add a, #0x01
    mov p2points, a
    cjne a, #0x05, p2win
    clr a
    ljmp start_game

start_game_nohit1:
    jb P1_BUTTON, start_game_nohit2
    Wait_Milli_Seconds(#50)
    jb P1_BUTTON, start_game_nohit2
    jnb P1_BUTTON, $
    clr a 
    mov a, p1points
    cjne a, #0x00, start_game
    sub a, #0x01
    mov p1points, a
    clr a
    ljmp start_game

start_game_nohit2:
    jb P2_BUTTON, start_game_nohit1
    Wait_Milli_Seconds(#50)
    jb P2_BUTTON, start_game_nohit1
    jnb P2_BUTTON, $
    clr a 
    mov a, p2points
    cjne a, #0x00, start_game
    sub a, #0x01
    mov p2points, a
    clr a
    ljmp start_game