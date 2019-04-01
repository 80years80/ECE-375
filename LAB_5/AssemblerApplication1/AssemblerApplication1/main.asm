;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file for Lab 5 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Emre Akbulut
;*	   Date: 2/14/2017
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; A variable
.def	B = r4					; Another variable

.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:							; The initialization routine
		; Initialize Stack Pointer
		; TODO					; Init the 2 stack pointer registers
		ldi		mpr, low(RAMEND)
		out		SPL, mpr
		ldi		mpr, high(RAMEND)
		out		SPH, mpr
		clr		zero			; Set the zero register to zero, maintain
								; these semantics, meaning, don't
								; load anything else into it.

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program

		; Setup the ADD16 function direct test

				; (IN SIMULATOR) Enter values 0xA2FF and 0xF477 into data
				; memory locations where ADD16 will get its inputs from
				; (see "Data Memory Allocation" section below)

				; Call ADD16 function to test its correctness
				; (calculate A2FF + F477)

				; Observe result in Memory window
				rcall ADD16

		; Setup the SUB16 function direct test

				; (IN SIMULATOR) Enter values 0xF08A and 0x4BCD into data
				; memory locations where SUB16 will get its inputs from

				; Call SUB16 function to test its correctness
				; (calculate F08A - 4BCD)

				; Observe result in Memory window

				rcall SUB16

		; Setup the MUL24 function direct test

				; (IN SIMULATOR) Enter values 0xFFFFFF and 0xFFFFFF into data
				; memory locations where MUL24 will get its inputs from

				; Call MUL24 function to test its correctness
				; (calculate FFFFFF * FFFFFF)

				; Observe result in Memory window
				rcall MUL24

		; Call the COMPOUND function
		rcall COMPOUND

				; Observe final result in Memory window

DONE:	rjmp	DONE			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;		where the high byte of the result contains the carry
;		out bit.
;-----------------------------------------------------------
ADD16:

		push XL
		push XH
		push YL
		push YH
		push ZL
		push ZH
		push A
		push B

		clr zero
		CLC ; clear out the carry flag.
		; Load beginning address of first operand into X
		ldi		XL, low(ADD16_OP1)	; Load low byte of address
		ldi		XH, high(ADD16_OP1)	; Load high byte of address
		ldi r17, 0
		; Load beginning address of second operand into Y
		ldi		YL, low(ADD16_OP2)
		ldi		YH, high(ADD16_OP2)

		; Load beginning address of result into Z
		ldi		ZL, low(ADD16_Result)
		ldi		ZH, high(ADD16_Result)

		; Execute the function
		ld		A, X+			; Get byte of A operand
		ld		B, Y+			; Get byte of B operand
		add		A, B
		st		Z+, A			; First set added & saved

		ld		A, X			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		adc		B, A
		st		Z+, B			; Second set added & saved
		
				
		adc		r17, zero		; 
		st		Z, r17			; store carry.

		pop B
		pop A
		pop ZH
		pop ZL
		pop YH
		pop YL
		pop XH
		pop XL
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: SUB16
; Desc: Subtracts two 16-bit numbers and generates a 16-bit
;		result.
;-----------------------------------------------------------
SUB16:
		
		push B
		push A
		push ZH
		push ZL
		push YH
		push YL
		push XH
		push XL



		clr zero
		CLC ; clear out the carry flag.
		; Load beginning address of first operand into X
		ldi		XL, low(SUB16_OP1)	; Load low byte of address
		ldi		XH, high(SUB16_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(SUB16_OP2)
		ldi		YH, high(SUB16_OP2)

		; Load beginning address of result into Z
		ldi		ZL, low(SUB16_Result)
		ldi		ZH, high(SUB16_Result)

		; Execute the function here

		ld		A, X+			; Get byte of A operand
		ld		B, Y+			; Get byte of B operand
		sub		A, B
		st		Z+, A			; First set subtracted & saved

		ld		A, X			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		sbc		A, B	
		st		Z, A			; Second set subtracted & saved

		pop XL
		pop XH
		pop YL
		pop YH
		pop ZL
		pop ZH
		pop A
		pop B

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit 
;		result.
;-----------------------------------------------------------
MUL24:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero

		clr		zero			; Maintain zero semantics
		CLC						;make sure carry flag is clear.

		; Set Y to beginning address of B
		ldi		YL, low(MUL24_OP2)	; Load low byte
		ldi		YH, high(MUL24_OP2)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(MUL24_Result)	; Load low byte
		ldi		ZH, high(MUL24_Result); Load high byte

		; Begin outer for loop
		ldi		oloop, 3		; Load counter
MUL24_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(MUL24_OP1)	; Load low byte
		ldi		XH, high(MUL24_OP1)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 3		; Load counter
MUL24_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z+			; Get a third byte from the result, increment Z
		adc		A, zero			; Add carry to A
		clr		B				; clear B
		ld		B, Z			; get byte from result.
		adc		B, zero			; Add carry to B
		st		Z, B			; store B into memory
		st		-Z, A			; Store third byte to memory & decrement
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store third byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1
		dec		iloop			; Decrement counter
		brne	MUL24_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 2		; Z <= Z - 2
		adiw	YH:YL, 1		; Y <= Y + 1
		sbiw	XH:XL, 3		; X <= X - 3
		dec		oloop			; Decrement counter
		brne	MUL24_OLOOP		; Loop if oLoop != 0
		; End outer for loop

		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		 		
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: COMPOUND
; Desc: Computes the compound expression ((D - E) + F)^2
;		by making use of SUB16, ADD16, and MUL24.
;
;		D, E, and F are declared in program memory, and must
;		be moved into data memory for use as input operands.
;
;		All result bytes should be cleared before beginning.
;-----------------------------------------------------------
COMPOUND:

		; Setup SUB16 with operands D and E
		; Perform subtraction to calculate D - E

		ldi ZL,	low( OperandD << 1 )
		ldi ZH,	high( OperandD << 1)
		ldi XL,	low(SUB16_OP1)
		ldi XH,	high(SUB16_OP1)

		;set up SUB16 to be loaded into Z similiar to intialization  process from lab3

		lpm		mpr, Z+
		st		X+, mpr
		lpm		mpr, Z
		st		X, mpr

		ldi		ZL, low(OperandE << 1)
		ldi		ZH, high(OperandE << 1)
		ldi		YL, low(SUB16_OP2)
		ldi		YH, high(SUB16_OP2)

		lpm		mpr, Z+
		st		Y+, mpr
		lpm		mpr, Z
		st		Y, mpr



		rcall SUB16
;stores result in what Z points to.
	
		; Setup the ADD16 function with SUB16 result and operand F
		; Perform addition next to calculate (D - E) + F
		clc
		ldi ZL, low(SUB16_Result)
		ldi ZH, high(SUB16_Result)
		ldi XL, low(ADD16_OP1)
		ldi XH, high(ADD16_OP1)
		
		
		ld		mpr, Z+
		st		X+, mpr
		ld		mpr, Z
		st		X, mpr

		ldi		ZL, low(OperandF<<1)
		ldi		ZH, high(OperandF<<1)
		ldi		YL, low(ADD16_OP2)
		ldi		YH, high(ADD16_OP2)

		lpm		mpr, Z+
		st		Y+, mpr
		lpm		mpr, Z
		st		Y, mpr

		rcall ADD16

		; Setup the MUL24 function with ADD16 result as both operands
		; Perform multiplication to calculate ((D - E) + F)^2
		clc
		ldi ZL, low(ADD16_Result)
		ldi ZH, high(ADD16_Result)
		ldi XL, low(MUL24_OP1)
		ldi XH, high(MUL24_OP1)

		ld		mpr, Z+
		st		X+, mpr
		ld		mpr, Z+
		st		X+, mpr
		ld		mpr, Z+
		st		X, mpr
		ldi ZL, low(ADD16_Result)
		ldi ZH, high(ADD16_Result)
		ldi YL, low(MUL24_OP2)
		ldi YH, high(MUL24_OP2)

		ld		mpr, Z+
		st		Y+, mpr
		ld		mpr, Z+
		st		Y+, mpr
		ld		mpr, Z
		st		Y, mpr
		
		rcall MUL24

		;correct answer should be: 37DB295A1
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;			A - Operand A is gathered from address $0101:$0100
;			B - Operand B is gathered from address $0103:$0102
;			Res - Result is stored in address 
;					$0107:$0106:$0105:$0104
;		You will need to make sure that Res is cleared before
;		calling this function.
;-----------------------------------------------------------
MUL16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Begin outer for loop
		ldi		oloop, 2		; Load counter
MUL16_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 2		; Load counter
MUL16_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store third byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1
		dec		iloop			; Decrement counter
		brne	MUL16_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL16_OLOOP		; Loop if oLoop != 0
		; End outer for loop
		 		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variable by pushing them to the stack

		; Execute the function here
		
		; Restore variable by popping them from the stack in reverse order
		ret						; End a function with RET


;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

OperandD:
	.DW	0xFD51				; test value for operand D
OperandE:
	.DW	0x1EFF				; test value for operand E
OperandF:
	.DW	0xFFFF				; test value for operand F

;***********************************************************
;*	Data Memory Allocation
;***********************************************************

.dseg
.org	$0100				; data memory allocation for MUL16 example
addrA:	.byte 3				; changed from 2 to 3
addrB:	.byte 3				; changed from 2 to 3
LAddrP:	.byte 6				; changed from 2 to 3

; Below is an example of data memory allocation for ADD16.
; Consider using something similar for SUB16 and MUL24.

.org	$0110				; data memory allocation for operands
ADD16_OP1:
		.byte 2				; allocate two bytes for first operand of ADD16
ADD16_OP2:
		.byte 2				; allocate two bytes for second operand of ADD16

.org	$0120			; data memory allocation for results
ADD16_Result:
		.byte 3				; allocate three bytes for ADD16 result

.org	$0130
MUL24_OP1:
		.byte 3
MUL24_OP2:
		.byte 3
.org $0140
MUL24_Result:
		.byte 6
.org $0150
SUB16_OP1:
		.byte 2
SUB16_OP2:
		.byte 2
.org $0160
SUB16_Result:
		.byte 3




;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program