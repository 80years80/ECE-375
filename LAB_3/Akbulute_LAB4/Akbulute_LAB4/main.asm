;***********************************************************
;*
;*	Enter name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file for Lab 4 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Emre Akbulut
;*	   Date: 2/8/2017
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is
								; required for LCD Driver

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************	
INIT:								; The initialization routine
		ldi		mpr, low(RAMEND)	; initialize Stack Pointer
		out		SPL, mpr			;got this intitalization from lab3
		ldi		mpr, high(RAMEND)
		out		SPH, mpr

		rcall LCDInit	; Initialize LCD Display
		
		ldi ZH, high(STRING_BEG<<1);intitalizes the Z pointer
		ldi ZL, low(STRING_BEG<<1)
		lpm mpr, Z+
		;intitialize and store Y pointer
		ldi YH, high($0100)	;lab says it will read from mem loc $0100 to $010F for the first line of the LCD
		ldi YL, low($0100)
		ST Y+, mpr

		rcall FUNC

		; Move strings from Program Memory to Data Memory
		
		; NOTE that there is no RET or RJMP from INIT, this
		; is because the next instruction executed is the
		; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		; Display the strings on the LCD Display
		rcall LCDwrite; one of the LCD functions to display strings on screen.
		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:	
	loop:						; Begin a function with a label
		LPM mpr, Z+
		ST Y+, mpr	; Save variables by pushing them to the stack

		CPI ZH, high(STRING_END<<1)
		BRNE	Loop
		CPI ZL, low(STRING_END<<1)
		BRNE	Loop
	EXIT:
		; Execute the function here
		
		; Restore variables by popping them from the stack,
		; in reverse order

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING_BEG:
.DB		"Emre Akbulut"	; Declaring data in ProgMem
.DB		"    Hello World!"
STRING_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
