/*
This code will cause a TekBot connected to the AVR board to
move forward and when it touches an obstacle, it will reverse
and turn away from the obstacle and resume forward motion.

PORT MAP
Port B, Pin 4 -> Output -> Right Motor Enable
Port B, Pin 5 -> Output -> Right Motor Direction
Port B, Pin 7 -> Output -> Left Motor Enable
Port B, Pin 6 -> Output -> Left Motor Direction
Port D, Pin 1 -> Input -> Left Whisker
Port D, Pin 0 -> Input -> Right Whisker
*/

#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>

int main(void)
{
	
	DDRB = 0b11110000;      // configure Port B pins for input/output
	PORTB = 0b11110000;     // set initial value for Port B outputs
	// (initially, disable both motors)
	
	DDRD = 0b11111100;  // configure Port D pins for input/output
	PORTD = 0b11111111; // set initial value for Port B outputs
	//last bit is right, second to last bit is left.
	
	//Sample code only backs up an output process with no need for input.
	//D for pin input and B for output

	while (1) // loop forever
	{
		PORTB = 0b01100000; //Move froward
		
		if(PIND == 0b11111110) //right bumper gets hit
		{
			PORTB = 0b00000000;  //backup
			_delay_ms(1000);  //wait for 1 second
			PORTB = 0b00100000; // turn left
			_delay_ms(1000);  //wait for 1 second
			PORTB = 0b01100000; // moves it froward.
			
		}
		
		if(PIND == 0b11111101) //left bumper gets hit
		{
			PORTB = 0b00000000;  //backup
			_delay_ms(1000); //wait 1 sec
			PORTB = 0b01000000; //turn right
			_delay_ms(1000); //wait 1 sec
		}
	}
}