;*******************************************************************************
;   MSP430F23x0 Demo - Timer_B, PWM TB1-2, Up Mode, DCO SMCLK
;
;   Description: This program generates two PWM outputs on P4.1-2 using
;   Timer_B configured for up mode. The value in TBCCR0, 512-1, defines the PWM
;   period and the values in TBCCR1-2 the PWM duty cycles. Using ~1.2MHz SMCLK
;   as TBCLK, the timer period is ~425us.
;   ACLK = n/a, MCLK = SMCLK = TBCLK = default DCO ~1.2MHz
;
;                MSP430F23x0
;             -----------------
;         /|\|              XIN|-
;          | |                 |
;          --|RST          XOUT|-
;            |                 |
;            |         P4.1/TB1|--> TBCCR1 - 75% PWM
;            |         P4.2/TB2|--> TBCCR2 - 25% PWM
;
;  JL Bile
;  Texas Instruments Inc.
;  June 2008
;  Built Code Composer Essentials: v3 FET
;*******************************************************************************
 .cdecls C,LIST, "msp430x23x0.h"
;-------------------------------------------------------------------------------
			.text	;Program Start
;-------------------------------------------------------------------------------
RESET       mov.w   #450h,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
SetupP4     bis.b   #06h,&P4DIR             ; P4.1-P4.2 output
            bis.b   #06h,&P4SEL             ; P4.1-P4.2 TB1-2 otions
SetupC0     mov.w   #512-1,&TBCCR0          ; PWM Period
SetupC1     mov.w   #OUTMOD_7,&TBCCTL1      ; TBCCR1 reset/set
            mov.w   #384,&TBCCR1            ; TBCCR1 PWM Duty Cycle
SetupC2     mov.w   #OUTMOD_7,&TBCCTL2      ; TBCCR2 reset/set
            mov.w   #128,&TBCCR2            ; TBCCR2 PWM duty cycle
SetupTB     mov.w   #TBSSEL_2+MC_1,&TBCTL   ; SMCLK, upmode
                                            ;
Mainloop    bis.w   #CPUOFF,SR              ; CPU off
            nop                             ; Required only for debugger
                                            ;
;-------------------------------------------------------------------------------
;			Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect	".reset"            ; MSP430 RESET Vector
            .short	RESET                   ;
            .end
