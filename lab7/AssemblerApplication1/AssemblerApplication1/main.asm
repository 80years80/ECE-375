;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file for Lab 7 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Emre J Akbulut
;*	   Date: 2/27/2017
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	speed = r17
.equ	EngEnR = 4				; right Engine Enable Bit
.equ	EngEnL = 7				; left Engine Enable Bit
.equ	EngDirR = 5				; right Engine Direction Bit
.equ	EngDirL = 6				; left Engine Direction Bit
.def	waitcnt = r18				; Wait Loop Counter
.def	ilcnt = r19				; Inner Loop Counter
.def	olcnt = r20				; Outer Loop Counter
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt
		
		.org	$0002
		rcall	SPEED_UP
		reti
		
		.org	$0004
		rcall	SPEED_DOWN
		reti
		
		.org	$0006
		rcall	MAX_SPEED
		reti
		
		.org	$0008
		rcall	STOP_SPEED
		reti 
		; place instructions in interrupt vectors here, if needed

.org	$0046					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer
		ldi mpr, high(RAMEND)
		out SPH, mpr
		ldi mpr, low(RAMEND)
		out SPL, mpr

		; Configure I/O ports
		; Initialize Port B for output
		ldi	mpr, $FF		; Set Port B Data Direction Register
		out	DDRB, mpr		; for output
		;ldi mpr, 0b00110000		; pin 4 and 5 for the output (engine status)
		;out PORTB, mpr
		;initialize portD for input
		ldi mpr, 0b00000000
		out DDRD, mpr
		ldi mpr, 0b00001111
		out PORTD, mpr
		; Configure External Interrupts, if needed
		; need 4 different interrupts, will be set to falling edge since thats how we dealt with it in the pervious lab.
		ldi mpr, 0b10101010
		sts EICRA, mpr

		; Configure 8-bit Timer/Counters
		ldi mpr, 0b01101001
		out TCCR0, mpr
		out TCCR2, mpr
		
		ldi mpr, 0b00001111
		out EIMSK, mpr
		

		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL)
		
		ldi mpr, (1<<EngDirR|1<<EngDirL)
		out PORTB, mpr
		in mpr, PORTB
		mov speed, mpr
		ldi mpr, 0b00000000; initialize speed zero
		or mpr, speed
		out PORTB, mpr
		;ldi mpr, $FF		;resets interrupts so they maintain piority
		;out EIFR, mpr
		
		; Set initial speed, display on Port B pins 3:0
		; initial speed zero
		; Enable global interrupts (if any are used)
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		; poll Port D pushbuttons (if needed)
		in mpr, PORTB
		in speed, OCR0; becasuse of how it iterates we only need the top or bottom bits.
		rcall Wait
		andi mpr, 0xf0
		andi speed, 0x0f
		or mpr, speed
		out PORTB, mpr
		ldi mpr, $FF		;resets interrupts so they maintain piority
		out EIFR, mpr									; if pressed, adjust speed
									; also, adjust speed indication

		rjmp	MAIN						; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
SPEED_UP:	
			; Begin a function with a label
			push mpr
			cpi speed, 255
			breq next1
			in speed, OCR0
			ldi mpr, 17
			rcall Wait
			add speed, mpr
			out OCR0, speed
			out OCR2, speed


			next1:
			pop mpr
			ldi mpr, $FF		;resets interrupts so they maintain piority
			out EIFR, mpr
		; If needed, save variables by pushing to the stack

		; Execute the function here
		
		; Restore any saved variables by popping from stack

		ret						; End a function with RET

;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
SPEED_DOWN:	
			; Begin a function with a label
			push mpr
			in speed, OCR0
			cpi speed, 0
			breq next2
			in speed, OCR0
			ldi mpr, 17
			rcall Wait
			sub speed, mpr
			out OCR0, speed
			out OCR2, speed
			
			next2:
			pop mpr
			ldi mpr, $FF		;resets interrupts so they maintain piority
			out EIFR, mpr


		; If needed, save variables by pushing to the stack

		; Execute the function here
		
		; Restore any saved variables by popping from stack

		ret						; End a function with RET



;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
MAX_SPEED:	

		
		; Begin a function with a label
			
			in speed, OCR0
			rcall Wait
			ldi speed, 0
			out OCR0, speed
			out OCR2, speed
			
			ldi mpr, $FF		;resets interrupts so they maintain piority
			out EIFR, mpr
			
		; If needed, save variables by pushing to the stack

		; Execute the function here
		
		; Restore any saved variables by popping from stack

		ret						; End a function with RET

;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
STOP_SPEED:	
			; Begin a function with a label
			
			in speed, OCR0
			rcall Wait
			ldi speed, 255
			out OCR0, speed
			out OCR2, speed
			ldi mpr, $FF		;resets interrupts so they maintain piority
			out EIFR, mpr

		; If needed, save variables by pushing to the stack

		; Execute the function here
		
		; Restore any saved variables by popping from stack

		ret						; End a function with RET
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
Loop:	ldi		olcnt, 124		; load olcnt register
OLoop:	ldi		ilcnt, 137		; load ilcnt register
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
;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program
