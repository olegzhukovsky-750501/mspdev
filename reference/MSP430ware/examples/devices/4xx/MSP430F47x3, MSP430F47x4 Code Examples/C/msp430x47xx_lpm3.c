//******************************************************************************
//  MSP430x47xx Demo - FLL+, LPM3 Using Basic Timer ISR, 32kHz ACLK
//
//  Description: System runs normally in LPM3 with basic timer clocked by
//  32kHz ACLK. At a 2 second interval the basic timer ISR will wake the
//  system and flash the LED on P5.1 inside of the Mainloop.
//  ACLK = LFXT1 = 32768Hz, MCLK = SMCLK = default DCO = 32 x ACLK = 1048576Hz
//  //* An external watch crystal between XIN & XOUT is required for ACLK *//	
//
//
//            MSP430x47xx
//         ---------------
//     /|\|            XIN|-
//      | |               | 32kHz
//      --|RST        XOUT|-
//        |               |
//        |           P5.1|-->LED
//
//  P. Thanigai / K.Venkat
//  Texas Instruments Inc.
//  November 2007
//  Built with CCE Version: 3.2.0 and IAR Embedded Workbench Version: 3.42A
//******************************************************************************
#include <msp430x47x4.h>

void main(void)
{
  WDTCTL = WDTPW + WDTHOLD;                 // Stop WDT
  FLL_CTL0 |= XCAP14PF;                     // Configure load caps

  IE2 |= BTIE;                              // Enable BT interrupt
  BTCTL = BTDIV+BTIP2+BTIP1+BTIP0;          // 2s Interrupt
  P1DIR = 0xFF;                             // All P1.x outputs
  P1OUT = 0;                                // All P1.x reset
  P2DIR = 0xFF;                             // All P2.x outputs
  P2OUT = 0;                                // All P2.x reset
  P3DIR = 0xFF;                             // All P3.x outputs
  P3OUT = 0;                                // All P3.x reset
  P4DIR = 0xFF;                             // All P4.x outputs
  P4OUT = 0;                                // All P4.x reset
  P5DIR = 0xFF;                             // All P5.x outputs
  P5OUT = 0;                                // All P5.x reset
  PADIR = 0xFFFF;                           // All PA.x outputs
  PAOUT = 0; 
  PBDIR = 0xFFFF;                           // All PB.x outputs
  PBOUT = 0; 
  while(1)
  {
    volatile int i;
    _BIS_SR(LPM3_bits + GIE);               // Enter LPM3 w/ interrupts
    P5OUT |= BIT1;                          // Set P5.1 LED on
    for (i = 5000; i>0; i--);               // Delay
    P5OUT &= ~BIT1;                         // Clear P5.1 LED off
  }
}

// Basic Timer interrupt service routine
#pragma vector=BASICTIMER_VECTOR
__interrupt void basic_timer(void)
{
    _BIC_SR_IRQ(LPM3_bits);                 // Clear LPM3 bits from 0(SR)
}
