;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the TRANSMIT skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Emre Akbulut
;*	   Date: 3/10/2017
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	transmit = r17
.equ	WskrR = 0
.equ	WskrL = 1
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

; Use these action codes between the remote and robot
; MSB = 1 thus:
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forward Action Code
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backward Action Code
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Action Code
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Action Code
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Action Code
;.equ	address = 0b011001001
;.equ	address = $77
;.equ	address = 0b10101010
.equ	address = $88
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
	ldi mpr, 0b00000000
	out DDRD, mpr
	ldi mpr, 0b11111111
	out PORTD, mpr

	;USART1
	ldi mpr, (1 << U2X1) ; Configure USART1 (Port D, pin 3)
	sts UCSR1A, mpr
	;Set baudrate at 2400bps
	;found in I/o slides
	ldi mpr, high(832) ; Load high byte of 0x0340
	sts UBRR1H, mpr ; UBRR1H in extended I/O space
	ldi mpr, low(832) ; Load low byte of 0x0340
	sts UBRR1L, mpr
	;Enable transmitter
	ldi mpr, (1 << TXEN1)
	sts UCSR1B, mpr
	;Set frame format: 8 data bits, 2 stop bits
	;taken from HW3 soln
	ldi mpr, (0 << UMSEL1 | 1 << USBS1 | 1 << UCSZ11 | 1 << UCSZ10) ; asynchronous
	sts UCSR1C, mpr ; UCSR1C in extended I/O space, use sts

	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		in	mpr, PIND
		out PORTB, transmit
		andi mpr, (1 << WskrR | 1 << WskrL | 1 << EngEnR | 1 << EngEnL | 1 << EngDirR | 1 << EngDirL)
		cpi mpr, (1 << WskrL | 1 << EngEnR | 1 << EngEnL | 1 << EngDirR | 1 << EngDirL);pin 0
		brne NEXT
		ldi transmit, TurnR
		rcall Right
		rjmp MAIN
NEXT:
		cpi mpr, (1 << WskrR | 1 << EngEnR | 1 << EngEnL | 1 << EngDirR | 1 << EngDirL); pin 1
		brne NEXT1
		ldi transmit, TurnL
		rcall Left
		rjmp	MAIN
NEXT1:
		cpi mpr, (1 << WskrR | 1 << WskrL | 1 << EngEnL | 1 << EngDirR | 1 << EngDirL) ;pin 4
		brne NEXT2
		ldi transmit, MovFwd
		rcall Fwd
		rjmp MAIN
NEXT2:
		cpi mpr, (1 << WskrR | 1 << WskrL | 1 << EngEnR | 1 << EngDirR | 1 << EngDirL) ;pin 7
		brne NEXT3
		ldi transmit, MovBck
		rcall Bk
		rjmp MAIN
NEXT3:
		cpi mpr,  (1 << WskrR | 1 << WskrL | 1 << EngEnR | 1 << EngEnL |  1 << EngDirL) ;pin 5
		brne NEXT4
		ldi transmit, Halt
		rcall HaltFun
		rjmp MAIN
NEXT4:
		cpi mpr, (1 << WskrR | 1 << WskrL | 1 << EngEnR | 1 << EngEnL | 1 << EngDirR) ; pin 6
		brne MAIN
		ldi transmit, Freeze
		rcall FreezeFun
		rjmp MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;----------------------------------------------------------------
; Sub:	right
; Desc:	sends signal to turn tekbot right
;----------------------------------------------------------------
Right:
			ldi transmit, address
			rcall Send_OUT
;transmit1:	lds mpr, UCSR1A	
;			cpi mpr, UDRE1
;			breq transmit1
;			sts UDR1, transmit
			ldi transmit, TurnR
			rcall Send_OUT
;transmit2:  lds mpr, UCSR1A
;			cpi mpr, UDRE1
;			breq transmit2
;			sts UDR1, transmit
			ret
;----------------------------------------------------------------
; Sub:	Left:
; Desc:	sends signal to turn tekbot left
;----------------------------------------------------------------
Left:
			ldi transmit, address
			rcall Send_OUT
;transmit3:	lds mpr, UCSR1A	
;			cpi mpr, UDRE1
;			breq transmit3
;			sts UDR1, transmit
			ldi transmit, TurnL
			rcall Send_OUT
;transmit4:  lds mpr, UCSR1A
;			cpi mpr, UDRE1
;			breq transmit4
;			sts UDR1, transmit
			ret
;----------------------------------------------------------------
; Sub:	Fwd
; Desc:	sends signal to move tekbot foward
;----------------------------------------------------------------
Fwd:
			ldi transmit, address
			rcall Send_OUT
;transmit5:	lds mpr, UCSR1A	
;			cpi mpr, UDRE1
;			breq transmit5
;			sts UDR1, transmit
			ldi transmit, MovFwd
			rcall Send_OUT
;transmit6:  lds mpr, UCSR1A
;			cpi mpr, UDRE1
;			breq transmit6
;			sts UDR1, transmit
			ret
;----------------------------------------------------------------
; Sub:	bk
; Desc:	sends signal to move tekbot back
;----------------------------------------------------------------

Bk:
			ldi transmit, address
			rcall Send_OUT
;transmit7:	lds mpr, UCSR1A	
;			cpi mpr, UDRE1
;			breq transmit7
;			sts UDR1, transmit
			ldi transmit, MovBck
			rcall Send_OUT
;transmit8:  lds mpr, UCSR1A
;			cpi mpr, UDRE1
;			breq transmit8
;			sts UDR1, transmit
			ret
;----------------------------------------------------------------
; Sub:	HaltFun
; Desc:	sends signal to make tekbot halt
;----------------------------------------------------------------
HaltFun:
			ldi transmit, address
			rcall Send_OUT
;transmit9:	lds mpr, UCSR1A	
;			cpi mpr, UDRE1
;			breq transmit9
;			sts UDR1, transmit
			ldi transmit, Halt
			rcall Send_OUT
;transmit10: lds mpr, UCSR1A
;			cpi mpr, UDRE1
;			breq transmit10
;			sts UDR1, transmit
			ret
;----------------------------------------------------------------
; Sub:	FreezeFun
; Desc:	sends signal to freeze other tekbots (not tekbot itself)
;----------------------------------------------------------------
FreezeFun:
			ldi transmit, address
			rcall Send_OUT
;transmit11:	lds mpr, UCSR1A	
;			cpi mpr, UDRE1
;			breq transmit11
;			sts UDR1, transmit
			ldi transmit, Freeze
			rcall Send_OUT
;transmit12: lds mpr, UCSR1A
;			cpi mpr, UDRE1
;			breq transmit12
;			sts UDR1, transmit
			ret
;basically found this in the data sheet
;----------------------------------------------------------------
; Sub:	Send_OUT
; Desc:	does the actual transmission of the command recieved from the functions above.
;----------------------------------------------------------------
Send_OUT:
	lds mpr, UCSR1A
	sbrs mpr, UDRE1
	rjmp send_OUT
	sts UDR1, transmit
	ret
;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************