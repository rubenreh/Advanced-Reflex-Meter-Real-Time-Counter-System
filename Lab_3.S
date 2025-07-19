.section .text
.align 2
.globl _start


// -------------------------------------------------------------------------------------
// Name:        Lab_3.S
// Purpose:     This code has 2 parts: the first part is to create a simple counter
//              subroutine that increments from 0x00 to 0xFF, wraps to 0 and continues
//              counting.  There is a 100ms delay between the display of the count. 
//		The second part is a reflex meter that will measure how fast
//              a user responds to an event accurate to a 10th of a millisecond.
//              Initially, all LED's are off and after a random amount of time
//              (between 2 and 10 seconds), one LED turns on (LED_6) and then the user
//		presses pushbutton S1.  The press of the button will be monitored by
//		using "polling".
//
// Author:      Julius Olajos
// -------------------------------------------------------------------------------------


_start:

// -------------------------------------------------------------------------------------
// GPIO Control Registers Memory Mapping

    .equ GPIO_BASE_CTRL_ADDR, 0x10012000    // Base address for the GPIO control registers
    .equ GPIO_OUTPUT_EN,      0x08          // address offset for enabling GPIO outputs
    .equ GPIO_OUTPUT_VAL,     0x0C          // Address offset for writing to GPIO outputs
    .equ GPIO_OUTPUT_XOR,     0x40          // Address offset for GPIO Outputs XOR
    .equ GPIO_INPUT_VAL,      0x00          // Address offset for reading GPIO inputs
    .equ GPIO_INPUT_EN,       0x04          // address offset for enabling GPIO inputs
    .equ GPIO_PUE,            0x10          // address offset for internal GPIO pull-up resistor

// -------------------------------------------------------------------------------------
// 8 LEDS, 7 Segment LED Display Pins Register Address Mapping

    .equ GPIO_7SEGLED_PINS,   0x0000023F      // Seven Segment LED Display Pins (7)
    .equ GPIO_LEDBAR_PINS,    0x00FC0C00      // LED Bar Pins (8)
    .equ GPIO_ALL_LED_PINS,   0x00FC0E3F      // All LED Pins (15)
    .equ GPIO_LEDBAR_LED_1,   0x00000800      // LEDBAR LED1

// -------------------------------------------------------------------------------------
// Pushbuttons SW(x) Register Address Mapping

    .equ GPIO_SW_1,           0x00001000      // SW1 pushbutton (bit 12)
    .equ GPIO_SW_2,           0x00002000      // SW2 Pushbutton (bit 13)
    .equ GPIO_ALL_PBS,        0x00003000      // All Pushbutton Pins (bits 12, 13)

// Initialize the GPIO control registers
// -------------------------------------------------------------------------------------

    li t0, GPIO_BASE_CTRL_ADDR          // Load Base Address for GPIO Control Registers
    li t1, GPIO_ALL_LED_PINS            // Load GPIO Register to set GPIO_OUTPUT_EN and GPIO_OUTPUT_XOR registers for all GPIO LED Pins
    sw t1, GPIO_OUTPUT_EN(t0)           // Enable outputs on all GPIO LED Pins
    li t2, 0xFF03F1C0
    sw t2, GPIO_OUTPUT_VAL(t0)          // Set all LED pins to zero to turn off all LEDS.
    li t1, GPIO_SW_1                    // Load GPIO Register to set GPIO_INPUT_EN for input pins
    sw t1, GPIO_INPUT_EN(t0)            // Enable inputs on all Pushbutton pins

// -------------------------------------------------------------------------------------


INITIAL:


// Initialize random number generator
 	li a7, 0xABCD                   // Initializes register a7 to a 16-bit non-zero value and NOTHING else can write to a7 !!!!
    j loop
    /*

COUNTER:

    li s0, 0
    li s1, 256

counter_loop:
    
    mv a0, s0
    jal ra, DISPLAY_NUM

    // Increment Counter
    addi s0, s0, 1

    // Call 100ms Delay
    li a0, 1000
    jal ra, DELAY
    
    beq s0, s1, COUNTER
    j counter_loop
    

//   --------------- Place your code here for the 00 - FF counter here ---------------

*/


// -------------------------------------------------------------------------------------

loop:

//  Generate random number
        jal ra, RandomNum


//  Once your number has been generated, it will be stored in register a7. Do not overwrite this!
//  You will now need to set up delays, subroutines to turn the LED ON and OFF, and for polling whether the Pushbutton S1 has been pressed.
//  Keep in mind that you will get a 32-bit number back from the random number generator.  You will need to display this 8 bits at a time,
//  starting with the lowest 8 bits.
//  You will probably want to rotate 8 bits at a time for display.



//   --------------- Place your code here ----------------------------------------

    // Copy Random Number to a0
    mv a0, a7

    // Loading our scaling factor into t1
    li t1, 122
    mul a0, a0, t1

    // Loading Scaling Factor
    li t1, 80000
    rem a0, a0, t1          // Take remainder of a0/80000 to scale/reduce it further

    li t1, 20000
    add a0, a0, t1


    // Calls the Delay with our modified random number (in a0)
    jal ra, DELAY


    // Turning on LED 6
    li t0, GPIO_BASE_CTRL_ADDR
    li t1, 1

    slli t1, t1, 22
    sw t1, GPIO_OUTPUT_VAL(t0)

    li s1, 0


    loop2:

        // Load the base address for GPIO control into register t0
        li t0, GPIO_BASE_CTRL_ADDR

        // Load the current value of the GPIO input register into t1
        // This value indicates the state of the push button
        lw t1, GPIO_INPUT_VAL(t0)       // load in address of S1 push button

        // Load the bitmask for switch 1 into t2
        li t2, GPIO_SW_1

        // Perform a bitwise AND operation to check if switch 1 is pressed
        and t1, t1, t2

        // If switch 1 is not pressed (result is zero), branch to the DISPLAY label
        beqz t1, DISPLAY

        // Increment the register s1 to indicate that the button was pressed
        addi s1, s1, 1                  // increment the register

        // Prepare for a short delay by loading the value 1 into a0
        li a0, 1

        // Call the DELAY function to wait for a short period
        jal ra, DELAY

        // Jump back to the start of the loop to continue polling
        j loop2


DISPLAY:    

// Display the 32-bit number on the 8-LED Bar

// Register t1 holds the value of the number to be displayed
// Map each bit of the number to the corresponding LED Bar bit
// MSB to LSB: bits 23, 22, 21, 20, 19, 18, 11, 10


    // Extract the least significant byte (LSB) from s1 and store it in a0
    andi a0, s1, 0x0FF

    // Call the function to display the current byte on the LED bar
    jal ra, DISPLAY_NUM

    // Set up a delay of 20,000 cycles
    li a0, 20000
    jal ra, DELAY

    // Shift the value in s1 right by 8 bits to prepare the next byte
    srli a0, s1, 8

    // Mask out all but the least significant byte
    andi a0, a0, 0x0FF
    
    // Display the next byte on the LED bar
    jal ra, DISPLAY_NUM

    // Set up another delay of 20,000 cycles
    li a0, 20000
    jal ra, DELAY

    // Shift the value in s1 right by 16 bits for the third byte
    srli a0, s1, 16

    // Mask out all but the least significant byte
    andi a0, a0, 0x0FF

    // Display the third byte on the LED bar
    jal ra, DISPLAY_NUM

    // Set up a delay of 20,000 cycles
    li a0, 20000
    jal ra, DELAY

    // Shift the value in s1 right by 24 bits for the fourth byte
    srli a0, s1, 24

    // Mask out all but the least significant byte
    andi a0, a0, 0x0FF
    
    // Display the fourth byte on the LED bar
    jal ra, DISPLAY_NUM

    // Set up a longer delay of 50,000 cycles before repeating
    li a0, 50000
    jal ra, DELAY

    // Jump back to the DISPLAY label to start the process again
    j DISPLAY
    

DISPLAY_NUM:

// Remember, the 8 LEDS are mapped to the GPIO as bits MSB to LSB: bits 23, 22, 21, 20, 19, 18, 11, 10


    // Loads the Base Address of the GPIO Controk into t0
    li t0, GPIO_BASE_CTRL_ADDR  

    // Sets t2 to 0, t2 will accumulate the final bit pattern for the GPIO pins based on the value in a0
    li t2, 0

    // Discards the lowest two bits, and moves the upper 6 bits into the lower 6 bits of t3
    srli t3, a0, 2
    slli t3, t3, 18

    // Extracting the Lower 2 Bits, shifts these bits by 10 - moving to positions 11 and 10
    and t2, a0, 0b11
    slli t2, t2, 10

    // Combines the Upper and Lower Bits - t2 now contains the entire Bit Pattern
    or t2, t3, t2

    // Write to GPIO
    sw t2, GPIO_OUTPUT_VAL(t0)
    ret


// Random Number generator
// Register a7 holds the random number.
// You can read this value anywhere in the code, but this register can only be written to by this subroutine
// Or Else!

RandomNum:
     addi sp, sp, -16
     sw ra, 12(sp)


     li s4, 0x8000		     // Load upper 20 bits
     and t1, a7, s4  		     // Mask to lower 16 bits
     li s4, 0x2000  		     // Load upper 20 bits
     and t3, a7, s4  		     // Mask to lower 16 bits


     slli t3, t3, 2
     xor t3, t1, t3
     li s4, 0x1000  		     // Load upper 20 bits
     and t1, a7, t0		     // Mask to lower 16 bits

     slli t1, t1, 3
     xor t3, t3, t1
     andi t1, a7, 0x0400
     slli t1, t1, 5
     xor t3, t3, t1
     srli t3, t3, 15
     slli a7, a7, 1
     or a7, a7, t3		     // Register a7 holds the random number

     lw ra, 12(sp)
     addi sp, sp, 16
     ret


DELAY:
    li t0, 800
    mul a0, a0, t0        
loop_delay:
    addi a0, a0, -1
    bnez a0, loop_delay
    ret