;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file for Lab 6 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Emre J Akbulut
;*	   Date: 2//22/2017
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def waitcnt = r17 ; Wait Loop Counter
.def ilcnt = r18 ; Inner Loop Counter
.def olcnt = r19 ; Outer Loop Counter
.equ WTime = 100 ; Time to wait in wait loop

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit

.equ EngEnR = 4 ; Right Engine Enable Bit
.equ EngEnL = 7 ; Left Engine Enable Bit
.equ EngDirR = 5 ; Right Engine Direction Bit
.equ EngDirL = 6 ; Left Engine Direction Bit
.equ MovFwd = (1<<EngDirR|1<<EngDirL) ; Move Forward Command
.equ MovBck = $00 ; Move Backward Command
.equ TurnR = (1<<EngDirL) ; Turn Right Command
.equ TurnL = (1<<EngDirR) ; Turn Left Command
.equ Halt = (1<<EngEnR|1<<EngEnL) ; Halt Command 


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		.org	$0002
		rcall HitRight
		reti
		; Set up interrupt vectors for any interrupts being used
		.org	$0004
		rcall	HitLeft
		reti
		; This is just an example:
;.org	$002E					; Analog Comparator IV
;		rcall	HandleAC		; Call function to handle interrupt
;		reti					; Return from interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi mpr, high(RAMEND)
		out SPH, mpr
		ldi mpr, low(RAMEND)
		out SPL, mpr
		; Initialize Port B for output
		ldi mpr, (1<<EngEnL)|(1<<EngEnR)|(1<<EngDirR)|(1<<EngDirL)
		out DDRB, mpr ; Set Port B Directional Register for output
		ldi mpr, $00
		out PORTB, mpr ; Set the default output for Port B
		; Initialize Port D for input
		ldi mpr, (0<<WskrL)|(0<<WskrR)
		out DDRD, mpr 
		ldi mpr, (1<<WskrL)|(1<<WskrR)
		out PORTD, mpr
		
		; Initialize external interrupts
		; Set the Interrupt Sense Control to falling edge 
		ldi mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)
		sts EICRA, mpr
		; Configure the External Interrupt Mask
		ldi mpr, (1<<INT0)|(1<<INT1)
		out EIMSK, mpr
		ldi mpr, $FF	;so interrupts don't conflict.
		out EIFR, mpr
		; Turn on interrupts
		sei
			; NOTE: This must be the last thing to do in the INIT function

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		; Move Robot Forward
		ldi mpr, MovFwd ; Load FWD command
		out PORTB, mpr ; Send to motors
		; TODO: ???

		rjmp	MAIN			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
;	You will probably want several functions, one to handle the 
;	left whisker interrupt, one to handle the right whisker 
;	interrupt, and maybe a wait function
;------------------------------------------------------------
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
	
		ldi mpr, (0 << TXEN1 | 0 << RXEN1 | 0 << RXCIE1)
		sts UCSR1B, mpr
		ldi mpr, MovBck	    ; Load Move Backwards command
		out PORTB, mpr		; Send command to port
		ldi waitcnt, Wtime	; Wait for 1 second
		rcall Wait			; Call wait function
		; Turn left for a second
		ldi mpr, TurnL		; Load Turn Left Command
		out PORTB, mpr		; Send command to port
		ldi waitcnt, Wtime  ; Wait for 1 second
		rcall Wait			; Call wait function
		ldi mpr, $FF		;resets interrupts so they maintain piority
		out EIFR, mpr
		
		pop mpr				; Restore program state
		out SREG, mpr		;
		pop waitcnt			; Restore wait register
		pop mpr				; Restore mpr
		sei
		ret					; Return from subroutine
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
		ldi mpr, (0 << TXEN1 | 0 << RXEN1 | 0 << RXCIE1)
		sts UCSR1B, mpr
		
		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		ldi mpr, $FF			;resets the interrupts so they maintain pirority
		out EIFR, mpr

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr
		sei
		ret				; Return from subroutine
;----------------------------------------------------------------
; Sub: Wait
; Desc: A wait loop that is 16 + 159975*waitcnt cycles or roughly
; waitcnt*10ms. Just initialize wait for the specific amount
; of time in 10ms intervals. Here is the general equation
; for the number of clock cycles in the wait loop:
; ((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait:
	OLoop:
		ldi olcnt, 224  ; Load middle-loop count
	MLoop:
		ldi ilcnt, 237  ; Load inner-loop count
	ILoop:
		dec ilcnt  ; Decrement inner-loop count
		brne Iloop ; Continue inner-loop
		dec olcnt  ; Decrement middle-loop
		brne Mloop ; Continue middle-loop
		dec waitcnt  ; Decrement outer-loop count
		brne OLoop ; Continue outer-loop
	ret ; Return from subroutine

;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program