;******************************************************************************
;   MSP-FET430P140 Demo - USART0, SPI Interface to HC165 Shift Register
;
;   Description: This program demonstrate a USART0 in SPI mode interface to a
;   an 'HC165 shift register.  Read 8-bit Data from A-H are stored at a RAM
;   byte 0200h defined as Data.
;   ACLK = n/a, MCLK = SMCLK = default DCO ~ 800k, UCLK0 = SMCLK/2
;   // **SWRST** please see MSP430x1xx Users Guide for description //
;
;                          MSP430F149
;                       -----------------
;                   /|\|              XIN|-
;                    | |                 |
;          HC165     --|RST          XOUT|-
;        ----------    |                 |
;    8  |      /LD|<---|P3.0             |
;   -\->|A-H   CLK|<---|P3.3/UCLK0       |
;     |-|INH    QH|--->|P3.2/SOMI        |
;     |-|SER      |    |                 |
;     v
;
Data        .equ    0200h
;
;   M. Buccini / G. Morton
;   Texas Instruments Inc.
;   May 2005
;   Built with Code Composer Essentials Version: 1.0
;******************************************************************************
 .cdecls C,LIST,  "msp430x14x.h"
;-----------------------------------------------------------------------------
            .text                           ; Program Start
;-----------------------------------------------------------------------------
RESET       mov.w   #0A00h,SP               ; Initialize stackpointer
            call    #Init_Sys               ; Initialize system
                                            ;
Mainloop    call    #RX_HC165               ; Read HC165
            mov.b   &RXBUF0,&Data           ; Data = HC165
            jmp     Mainloop                ; Repeat
                                            ;
;-----------------------------------------------------------------------------
RX_HC165
;-----------------------------------------------------------------------------
            bic.b   #01h,&P3OUT             ; Latch data into 'HC165
            bis.b   #01h,&P3OUT             ;
            bic.b   #URXIFG0,&IFG1          ; Clear RXBUF flag
            mov.b   #00h,&TXBUF0            ; Dummy write to start SPI
L1          bit.b   #URXIFG0,&IFG1          ; RXBUF ready?
            jnc      L1                     ; 1 = ready
            ret                             ;
                                            ;
;-----------------------------------------------------------------------------
Init_Sys;   Subroutine to Initialize MSP430F149 Peripherials
;-----------------------------------------------------------------------------
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop watchdog timer
SetupP3     bis.b   #0Ch,&P3SEL             ; P3.2,3 SPI option select
            bis.b   #09h,&P3DIR             ; P3.3,0 output direction
SetupSPI    bis.b   #040h,&ME1              ; Enable USART0 SPI
            bis.b   #CKPH+SSEL1+SSEL0+STC,&UTCTL0 ;* SMCLK, 3-pin mode
            bis.b   #CHAR+SYNC+MM,&UCTL0    ; 8-bit SPI Master **SWRST**
            mov.b   #02h,&UBR00             ; SMCLK/2 for baud rate
            clr.b   &UBR10                  ; SMCLK/2 for baud rate
            clr.b   &UMCTL0                 ; Clear modulation
            bic.b   #SWRST,&UCTL0           ; **Initialize USART state machine**
            ret                             ; Return from subroutine
;
;-----------------------------------------------------------------------------
;           Interrupt Vectors
;-----------------------------------------------------------------------------
             .sect   ".reset"                ; POR, ext. Reset, Watchdog, Flash
             .short  RESET                   ;
             .end

