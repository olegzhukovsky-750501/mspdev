/* --COPYRIGHT--,BSD
 * Copyright (c) 2011, Texas Instruments Incorporated
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * *  Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * *  Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * *  Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * --/COPYRIGHT--*/
#include "inc/hw_memmap.h"
#include "driverlib/5xx_6xx/adc10.h"
#include "driverlib/5xx_6xx/dma.h"
#include "driverlib/5xx_6xx/wdt.h"
#include "driverlib/5xx_6xx/gpio.h"

//******************************************************************************
//!
//! ADC10 - Sample A2-0 Inputs directly to DMA, 8-Bit Res, Single Seq.
//!
//!  MSP430F550x Demo
//!  Sample A2/A1/A0 as single sequence with reference to AVcc. Software sets
//!  ADC10SC to trigger sample sequence. In Mainloop MSP430 waits in LPM0 to
//!  save power until ADC10 conversion complete, DMA_ISR will force exit from
//!  any LPMx. ADC10 internal oscillator times sample period (16x) and
//!  conversion (13x). DMA transfers conv results ADC_Result variable.
//!  Notice that the conversions go in the order of A2, A1, then A0.
//1
//!               MSP430F550x
//!            -----------------
//!        /|\|              XIN|-
//!         | |                 |
//!         --|RST          XOUT|-
//!           |          P6.2/A2|<- Sample Signal 1
//!           |          P6.1/A1|<- Sample Signal 2
//!           |          P6.0/A0|<- Sample Signal 3
//!           |                 |
//!
//!
//! This example uses the following peripherals and I/O signals.  You must
//! review these and change as needed for your own board:
//! - ADC10 peripheral
//! - DMA peripheral
//! - GPIO Port peripheral
//! - A2
//! - A1
//! - A0
//!
//! This example uses the following interrupt handlers.  To use this example
//! in your own application you must add these interrupt handlers to your
//! vector table.
//! - DMA_VECTOR
//!
//******************************************************************************


void main (void)
{
	
    //8-bit ADC conversion result array
    unsigned char ADC_Result[3];

    //Stop Watchdog Timer
    WDT_hold(__MSP430_BASEADDRESS_WDT_A__);

    //Initialize the ADC10 Module
    /*
     * Base Address for the ADC10 Module
     * Use internal ADC10 bit as sample/hold signal to start conversion
     * USE MODOSC 5MHZ Digital Oscillator as clock source
     * Use default clock divider of 1
     */
    ADC10_init(__MSP430_BASEADDRESS_ADC10_A__,
        ADC10_SAMPLEHOLDSOURCE_SC,
        ADC10_CLOCKSOURCE_ADC10OSC,
        ADC10_CLOCKDIVIDER_1);
    
    ADC10_enable(__MSP430_BASEADDRESS_ADC10_A__);
    
    /*
     * Base Address for the ADC10 Module
     * Sample/hold for 16 clock cycles
     * Enable Multiple Sampling
     */
    ADC10_setupSamplingTimer(__MSP430_BASEADDRESS_ADC10_A__,
        ADC10_CYCLEHOLD_16_CYCLES,
        ADC10_MULTIPLESAMPLESENABLE);
    //Change the resolution to 8-bit
    ADC10_setResolution(__MSP430_BASEADDRESS_ADC10_A__,
        ADC10_RESOLUTION_8BIT);

    //Configure Memory Buffer
    /*
     * Base Address for the ADC10 Module
     * Use input A2
     * Use positive reference of AVcc
     * Use negative reference of AVss
     */
    ADC10_memoryConfigure(__MSP430_BASEADDRESS_ADC10_A__,
        ADC10_INPUT_A2,
        ADC10_VREFPOS_AVCC,
        ADC10_VREFNEG_AVSS);


    //Initialize and Setup DMA Channel 0
    /*
     * Base Addrress of the DMA Module
     * Configure DMA channel 0
     * Configure channel for repeated single transfer
     * DMA interrupt flag will be set after every 3 transfers
     * Use DMA Trigger Source 24 (ADC10IFG)
     * Transfer Byte-to-byte
     * Trigger upon the Rising Edge of the Trigger Source
     */
    DMA_init(__MSP430_BASEADDRESS_DMAX_3__,
        DMA_CHANNEL_0,
        DMA_TRANSFER_REPEATED_SINGLE,
        3,
        DMA_TRIGGERSOURCE_24,
        DMA_SIZE_SRCBYTE_DSTBYTE,
        DMA_TRIGGER_RISINGEDGE);
    /*
     * Base Address of the DMA Module
     * Configure DMA channel 0
     * Use ADC10 Memory Buffer as source
     * Increment destination address after every transfer
     */
    DMA_setSrcAddress(__MSP430_BASEADDRESS_DMAX_3__,
        DMA_CHANNEL_0,
        ADC10_getMemoryAddressForDMA(__MSP430_BASEADDRESS_ADC10_A__),
        DMA_DIRECTION_UNCHANGED);
    /*
     * Base Address of the DMA Module
     * Configure DMA channel 0
     * Use ADC_Result[0] as destination
     * Increment destination address after every transfer
     */
    DMA_setDstAddress(__MSP430_BASEADDRESS_DMAX_3__,
        DMA_CHANNEL_0,
        (unsigned long)&ADC_Result[0],
        DMA_DIRECTION_INCREMENT);

    //Enable DMA channel 0 interrupt
    DMA_enableInterrupt(__MSP430_BASEADDRESS_DMAX_3__,
        DMA_CHANNEL_0);

    //Enable transfers on DMA channel 0
    DMA_enableTransfers(__MSP430_BASEADDRESS_DMAX_3__,
        DMA_CHANNEL_0);

    while (1)
    {
        //Wait if ADC10 core is active
        while (ADC10_isBusy(__MSP430_BASEADDRESS_ADC10_A__)) ;

        //Enable and Start the conversion
        //in Sequence of Channels Conversion Mode
        ADC10_startConversion(__MSP430_BASEADDRESS_ADC10_A__,
            ADC10_SEQOFCHANNELS);

        //LPM0, ADC10_ISR will force exit
        __bis_SR_register(CPUOFF + GIE);
        //Delay between sequence convs
        __delay_cycles(5000);
        //BREAKPOINT; check ADC_Result
        __no_operation();
    }
}

#pragma vector=DMA_VECTOR
__interrupt void DMA0_ISR (void)
{
    switch (__even_in_range(DMAIV,16)){
        case  0: break; //No interrupt
        case  2:        //DMA0IFG
            //Sequence of Channels Conversion Complete
            //exit LPM
            __bic_SR_register_on_exit(CPUOFF);
            break;
        case  4: break; //DMA1IFG
        case  6: break; //DMA2IFG
        default: break;
    }
}

