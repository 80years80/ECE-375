;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the RECEIVE skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Emre J Akbulut
;*	   Date: 3/12/2017
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	freezeNum = r17			; counts num times froozen
.def	skip = r22
.def	action = r23
.def	waitcnt = r18			; Wait Loop Counter
.def	ilcnt = r19				; Inner Loop Counter
.def	olcnt = r20				; Outer Loop Counter
.def	moveTracker	= r21			; holds the current move made, like speed held speed in lab 7.
.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotAddress = $8D;(Enter your robot's address here (8 bits))
.equ	Wtime = 100
;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forward Action Code
.equ	MovBck =  $00						;0b00000000 Move Backward Action Code
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Action Code
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Action Code
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Action Code
.equ	Freeze = 0b11111000
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

;Should have Interrupt vectors for:
;- Left whisker
.org $0002
		rcall HitLeft
		reti
;- Right whisker
.org $0004
		rcall HitRight
		reti
;- USART receive
.org $003C
		rcall USART_receive
		reti
.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi mpr, high(RAMEND)
	out SPH, mpr
	ldi mpr, low(RAMEND)
	out SPL, mpr
	;I/O Ports
	ldi mpr, $FF
	out DDRB, mpr
	ldi	mpr, $00
	out DDRD, mpr
	ldi mpr, (1 << WskrL | 1 << WskrR); pun 0 & 1
	out PORTD, mpr
	;USART1
	;Set baudrate at 2400bps
	ldi mpr, (1 << U2X1)
	sts UCSR1A, mpr
	;Set baudrate at 2400bps
	ldi mpr, high(832) ; Load high byte of 0x0340
	sts UBRR1H, mpr ; UBRR1H in extended I/O space
	ldi mpr, low(832) ; Load low byte of 0x0340
	sts UBRR1L, mpr
	;Enable receiver and enable receive interrupts
	ldi mpr, (1 << TXEN1 | 1 << RXEN1 | 1 << RXCIE1)
	sts UCSR1B, mpr
	;Set frame format: 8 data bits, 2 stop bits
	ldi mpr, (0 << UMSEL1 | 1 << USBS1 | 1 << UCSZ11 | 1 << UCSZ10) ; asynchronous
	sts UCSR1C, mpr
	;External Interrupts
	;Set the Interrupt Sense Control to falling edge detection
	ldi mpr, 0b00101010
	sts EICRA, mpr
	;Set the External Interrupt Mask
	ldi mpr, 0b00000011
	out EIMSK, mpr
	ldi mpr, $FF
	out EIFR, mpr
	;Other
	ldi freezeNum, 0; set the number of times froozen to zero inititally.
	ldi mpr, (1<<EngDirR|1<<EngDirL)
	mov moveTracker, mpr
	or mpr, moveTracker
	out PORTB, mpr
	sei

	
;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;----------------------------------------------------------------
; Sub:	HitLeft
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HitLeft:
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;
		;ldi mpr, (0<<ISC01)|(0<<ISC00)|(0<<ISC11)|(0<<ISC10)
		;sts EICRA, mpr
		; Move Backwards for a second
		in		moveTracker, PORTB
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function
		ldi mpr, (1<<EngDirR|1<<EngDirL);unlike lab 6 these are in here instead of main to restore both motors moving fwd
		out PORTB, mpr
		rcall wait
		out PORTB, moveTracker
		;ldi mpr, 0
		;sts UDRE1, mpr
		ldi mpr, $FF			;resets the interrupts so they maintain pirority
		out EIFR, mpr

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr
		sei
		ret				; Return from subroutine
;----------------------------------------------------------------
; Sub: HitRight
; Desc: Handles functionality of the TekBot when the right whisker is triggered.
;----------------------------------------------------------------
HitRight:
		push mpr			; Save mpr register
		push waitcnt		; Save wait register
		in mpr, SREG		; Save program state
		push mpr			;
		; Move Backwards for a second
		;ldi mpr, (0<<ISC01)|(0<<ISC00)|(0<<ISC11)|(0<<ISC10)
		;sts EICRA, mpr
		in moveTracker, PORTB
		ldi mpr, MovBck	    ; Load Move Backwards command
		out PORTB, mpr		; Send command to port
		ldi waitcnt, Wtime	; Wait for 1 second
		rcall Wait			; Call wait function
		; Turn left for a second
		ldi mpr, TurnL		; Load Turn Left Command
		out PORTB, mpr		; Send command to port
		ldi waitcnt, Wtime  ; Wait for 1 second
		rcall Wait			; Call wait function
		ldi mpr, (1<<EngDirR|1<<EngDirL)
		out PORTB, mpr
		rcall wait
		out PORTB, moveTracker
		;ldi mpr, 0
		;sts UDRE1, mpr
		ldi mpr, $FF		;resets interrupts so they maintain piority
		out EIFR, mpr
		
		pop mpr				; Restore program state
		out SREG, mpr		;
		pop waitcnt			; Restore wait register
		pop mpr				; Restore mpr
		sei
		ret					; Return from subroutine
;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register
		ldi		waitcnt, 100
Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine
;----------------------------------------------------------------
; Sub:	U_receive
; Desc:	handles the recieved signal
;----------------------------------------------------------------
USART_receive: 
		in	moveTracker, PORTB
		lds mpr, UDR1
		cpi mpr, BotAddress ;checks if it's the address 
		breq noFrooze; if equal skips over frooze
frooze: ;if it is not froozen, since we are here due to invalid address put portB back to what it was before.
		cpi mpr, 0b01010101 	;frooze until restore is apart of froooze
		brne restore	;if not froozen then it skips over restoring portb @ the end
		ldi mpr, (1 << TXEN1 | 0 << RXEN1 | 0 << RXCIE1)
		sts UCSR1B, mpr
		lds mpr, UCSR1A
		cpi mpr, UDRE1
		breq frooze
		ldi mpr, Halt
		out PORTB, mpr
		rcall Wait;each delays it by 1 second, is called x5, delays for 5 sec 
		rcall Wait
		rcall Wait
		rcall Wait
		rcall Wait
		inc freezeNum; increment number of times froozen, if reaches 3 kill the procress with an infinite loop.
		cpi freezeNum, 3
		brne let_live
let_die:
		cpi freezeNum, 3
		breq let_die; throws it into infinite while loop to kill the procress.
let_live: 
		;fix the interrupts
		ldi mpr, $FF
		out EIFR, mpr
		ldi mpr, (0 << TXEN1 | 1 << RXEN1 | 1 << RXCIE1)
		sts UCSR1B, mpr
		jmp restore
restore:
		out PORTB, moveTracker
		jmp end
noFrooze:
		;check first for freeze command
		
		;need to do buffer stuff again and good to go!
		; address is triggered
		rcall wait
		lds action, UDR1
		cpi action, BotAddress
		breq restore;
		;out PORTB, action
		cpi	action, 0b11111000
		breq send_freeze
		cpi action, 0b11001000
		breq take_halt
		cpi action, 0b10110000
		breq take_MovFwd
		cpi action, 0b10000000
		breq take_MovBck
		cpi action, 0b10100000
		breq take_right
		cpi action, 0b10010000
		breq take_left
		jmp end

send_freeze:
		ldi mpr, (1 << TXEN1 | 0 << RXEN1 | 0 << RXCIE1)
		sts UCSR1B, mpr
		lds mpr, UCSR1A
		cpi mpr, UDRE1
		breq send_freeze
		ldi mpr, 0b01010101;BotAddress;0b01010101	;load in freeze command
		out PORTB, mpr
		sts UDR1, mpr;sends it here
		rcall Wait
;branch:
;		lds mpr, UCSR1A
;		cpi mpr, UDRE1
;		breq branch
;		ldi mpr, 0b01010101
;		out PORTB, mpr
;		sts UDR1, mpr
;
		ldi mpr, (1 << TXEN1 | 1 << RXEN1 | 1 << RXCIE1)
		sts UCSR1B, mpr
		jmp end
;send_freeze:
;		ldi mpr, (1 << TXEN1 | 0 << RXEN1 | 0 << RXCIE1)
;		sts UCSR1B, mpr
;		lds mpr, UCSR1A
;		cpi mpr, UDRE1
;		breq send_freeze
;		ldi mpr, 0b01010101	;load in freeze command
;		out PORTB, mpr
;		sts UDR1, mpr;sends it here
;		ldi mpr, (1 << TXEN1 | 1 << RXEN1 | 1 << RXCIE1)
;		sts UCSR1B, mpr
;		jmp end
take_halt:
		ldi action, Halt
		out PORTB, action
		jmp end
take_MovFwd:
		ldi action, MovFwd 
		out PORTB, action 
		jmp end
take_MovBck:
		ldi action, MovBck
		out PORTB, action 
		jmp end
take_right:
		ldi action, TurnR
		out PORTB, action 
		jmp end
take_left:

		ldi action, TurnL
		out PORTB, action
		jmp end
		
end:
		ldi mpr, $FF
		out EIFR, mpr
		ret


		

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************