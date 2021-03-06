; MSP430x66x Demo - COMPB Toggle from LPM4; input channel CB1;
; 		Vcompare is compared against the internal reference 2.0V
;
; Description: Use CompB (input channel CB1) and internal reference to
;	  determine if input'Vcompare'is high of low.  When Vcompare exceeds 2.0V 
;    CBOUT goes high and when Vcompare is less than 2.0V then CBOUT goes low.
;    Connect P3.0/CBOUT to P1.0 externally to see the LED toggle accordingly.
;                                                   
;                 MSP430x66x
;             ------------------                        
;         /|\|                  |                       
;          | |                  |                       
;          --|RST       P6.1/CB1|<--Vcompare            
;            |                  |                                         
;            |        P3.0/CBOUT|----> 'high'(Vcompare>2.0V); 'low'(Vcompare<2.0V)
;            |                  |  |
;            |            P1.0  |__| LED 'ON'(Vcompare>2.0V); 'OFF'(Vcompare<2.0V)
;            |                  | 
;
;   Priya Thanigai
;   Texas Instruments Inc.
;   August 2011
;   Built with CCS V5
;******************************************************************************
            .cdecls C,LIST,"msp430f6638.h"

;-------------------------------------------------------------------------------
            .global _main
            .text                           ; Assemble to Flash memory
;-------------------------------------------------------------------------------
_main
RESET       mov.w   #0x63FE,SP              ; Initialize stackpointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT

SetupPort   bis.b   #BIT0,&P3DIR            ; P3.0 output
            bis.b   #BIT0,&P3SEL            ; P3.0 option select
            
            bis.w   #CBIPEN+CBIPSEL_1,&CBCTL0; Enable V+, input channel CB1
            bis.w   #CBPWRMD_1,&CBCTL1      ; normal power mode
            bis.w   #CBRSEL,&CBCTL2         ; Vref to -ve terminal
            bis.w   #CBRS_3+CBREFL_2,&CBCTL2; R ladder off, 1.2V
            
            bis.w   #BIT1,&CBCTL3           ; Input buffer disable P6.0
            bis.w   #CBON,&CBCTL1
            
; Delay for reference settle = 75us
            mov.w   #01ffh,R15
delay_L1    dec.w   R15
            jnz     delay_L1
            
            bis.w   #LPM4,SR                ; Enter low power mode
            nop

;-------------------------------------------------------------------------------
                  ; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; POR, ext. Reset
            .short  RESET
            .end
