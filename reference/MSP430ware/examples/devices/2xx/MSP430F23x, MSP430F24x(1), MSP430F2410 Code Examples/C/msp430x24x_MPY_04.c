//******************************************************************************
//   MSP430x24x Demo - 8x8 Signed Multiply
//
//   Description: Hardware multiplier is used to multiply two numbers.
//   The calculation is automatically initiated after the second operand is
//   loaded. Results are stored in RESLO, RESHI and SUMEXT = FFFF if result is
//   negative, SUMEXT = 0 otherwise.
//
//   ACLK = 32.768kHz, MCLK = SMCLK = default DCO
//
//                 MSP430F249
//             -----------------
//         /|\|                 |
//          | |                 |
//          --|RST              |
//            |                 |
//
//  B. Nisarga
//  Texas Instruments Inc.
//  September 2007
//  Built with CCE Version: 3.2.0 and IAR Embedded Workbench Version: 3.42A
//******************************************************************************
#include  <msp430x24x.h>

void main(void)
{
  unsigned char value1,value2;

  WDTCTL = WDTPW+WDTHOLD;                   // Stop WDT
  value1 = 0x04;                            // Assign operands for signed mult
  value2 = 0x84;

  // Sign-extend the values
  if (value1 >=0x80)
    MPYS = 0xFF00 | value1;
  else
    MPYS = value1;
  if (value2 >=0x80)
    OP2 = 0xFF00 | value2;
  else
    OP2 = value2;

  _BIS_SR(LPM4_bits);                       // LPM4
}
