$NOLIST
$MODLP51
$LIST

$NOLIST
$include(LCD_4bit.inc)
$LIST

CLK           EQU 22118400
TIMER1_RATE   EQU 4000                 ;2000Hz frequency lose frequency
TIMER2_RATE   EQU 4200                 ;2100Hz frequency win frequency
TIMER1_RELOAD EQU ((65536-(CLK/TIMER1_RATE)))
TIMER2_RELOAD EQU ((65536-(CLK/TIMER2_RATE)))

BUTTON equ P
SOUND_OUT equ P1.1

second_flag: dbit 1

Win_Sound_Init:
	mov a, TMOD
	anl a, #0xf0
	orl a, #0x01
	mov TMOD, a
	mov TH0, #high(TIMER2_RELOAD)
	mov TL0, #low(TIMER2_RELOAD)
	mov RH0, #high(TIMER2_RELOAD)
	mov RL0, #low(TIMER2_RELOAD)
	setb ET0
	setb TR0
	ret

Lose_Sound_Init:
	mov a, TMOD
	anl a, #0xf0
	orl a, #0x01
	mov TMOD, a
	mov TH0, #high(TIMER1_RELOAD)
	mov TL0, #low(TIMER1_RELOAD)
	mov RH0, #high(TIMER1_RELOAD)
	mov RL0, #low(TIMER1_RELOAD)
	setb ET0
	setb TR0
	ret

Win_tone:
	jump Win_Sound_Init
	cpl SOUND_OUT
	reti

Lose_tone:
	jump Lose_Sound_Init
	cpl SOUND_OUT
	reti

Beep_for_1sec:
	;;figure out how to make it beep for 1~2 second then loop
	