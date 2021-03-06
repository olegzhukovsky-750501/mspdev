;*******************************************************************************
;   MSP430x261x Demo - DMA0/1, Rpt'd single transfer to DAC12_0/1, Sin/Cos, TACCR1, XT2
;
;   Description: DMA0 and DMA1 are used to transfer a sine and cos look-up
;   table word-by-word as a repeating block to DAC12_0 and DAC12_1. The effect
;   is sine and cos wave outputs. Timer_A operates in upmode with TACCR1
;   loading DAC12_0 amd DAC12_1 on rising edge and DAC12_OIFG triggering next
;   DMA transfers. DAC12_0 and DAC12_1 are grouped for jitter-free operation.
;   ACLK= n/a, MCLK = SMCLK = TACLK = XT2 = 8MHz
;   //* An external 8MHz XTAL on X2IN X2OUT is required for XT2CLK *//
;
;                MSP430x2619
;             -----------------
;         /|\|            XT2IN|-
;          | |                 | 8MHz
;          --|RST        XT2OUT|-
;            |                 |
;            |        DAC0/P6.6|--> ~ 10kHz sine wave
;            |        DAC1/P6.7|--> ~ 10kHz cos wave
;
;  JL Bile
;  Texas Instruments Inc.
;  June 2008
;  Built Code Composer Essentials: v3 FET
;*******************************************************************************
 .cdecls C,LIST, "msp430x26x.h"
;-------------------------------------------------------------------------------
			.text	;Program Start
;-------------------------------------------------------------------------------
RESET       mov.w   #0850h,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop watchdog timer

SetupBC     bic.b   #XT2OFF,&BCSCTL1        ; Activate XT2 high freq xtal
            bis.b   #XT2S_2,&BCSCTL3        ; 3 � 16MHz crystal or resonator

SetupOsc    bic.b   #OFIFG,&IFG1            ; Clear OSC fault flag
            mov.w   #0FFh,R15               ; R15 = Delay
SetupOsc1   dec.w   R15                     ; Additional delay to ensure start
            jnz     SetupOsc1               ;
            bit.b   #OFIFG,&IFG1            ; OSC fault flag set?
            jnz     SetupOsc                ; OSC Fault, clear flag again
                                           
            bis.b   #SELM_2, &BCSCTL2       ; MCLK = XT2 HF XTAL (safe)

SetupADC12  mov.w   #REF2_5V+REFON,&ADC12CTL0 ; Internal 2.5V ref
            mov.w   #13600,&TACCR0          ; Delay to allow Ref to settle
            bis.w   #CCIE,&TACCTL0          ; Compare-mode interrupt.
            mov.w   #TACLR+MC_1+TASSEL_2,&TACTL; up mode, SMCLK
            bis.w   #LPM0+GIE,SR            ; Enter LPM0, enable interrupts
            bic.w   #CCIE,&TACCTL0          ; Disable timer interrupt
            dint                            ; Disable Interrupts

SetupDMAx   mov.w   #DMA0TSEL_5+DMA1TSEL_5,&DMACTL0 ; DAC12IFG triggers
            movx.a   #Sin_tab,&DMA0SA        ; Source block address
            movx.a   #DAC12_0DAT,&DMA0DA     ; Destination single address
            mov.w   #020h,&DMA0SZ           ; Block size
            mov.w   #DMADT_4+DMASRCINCR_3+DMAEN,&DMA0CTL; Rpt, inc src, word-word
            movx.a   #Cos_tab,&DMA1SA        ; Source block address
            movx.a   #DAC12_1DAT,&DMA1DA     ; Destination single address
            mov.w   #020h,&DMA1SZ           ; Block size
            mov.w   #DMADT_4+DMASRCINCR_3+DMAEN,&DMA1CTL; Rpt, inc src, word-word
SetupDAC12x mov.w   #DAC12LSEL_2+DAC12IR+DAC12AMP_5+DAC12IFG+DAC12ENC+DAC12GRP,&DAC12_0CTL
            mov.w   #DAC12LSEL_2+DAC12IR+DAC12AMP_5+DAC12IFG+DAC12ENC,&DAC12_1CTL

SetupC1     mov.w   #OUTMOD_3,&TACCTL1      ; TACCR1 set/reset
            mov.w   #01,&TACCR1             ; TACCR1 PWM Duty Cycle
SetupC0     mov.w   #025-1,&TACCR0          ; Clock period of TACCR0
SetupTA     mov.w   #TASSEL_2+MC_1,&TACTL   ; SMCLK, contmode

Mainloop    bis.b   #CPUOFF,SR              ; Enter LPM0
            jmp     Mainloop
;-------------------------------------------------------------------------------
TIMERA0_ISR;
;-------------------------------------------------------------------------------
            clr.w   &TACTL                  ; Clear Timer_A control registers
            bic.w   #LPM0,0(SP)             ; Exit LPMx, interrupts enabled
            reti                            ;
;-------------------------------------------------------------------------------
; 12-bit Sine Lookup table with 32 steps
;-------------------------------------------------------------------------------
Sin_tab     .word 2048, 2447, 2831, 3185, 3495, 3750, 3939, 4056
            .word 4095, 4056, 3939, 3750, 3495, 3185, 2831, 2447
            .word 2048, 1648, 1264,  910,  600,  345,  156,   39
            .word    0,   39,  156,  345,  600,  910, 1264, 1648
;-------------------------------------------------------------------------------
; 12-bit Cosine Lookup table with 32 steps
;-------------------------------------------------------------------------------
Cos_tab     .word 1648, 1264,  910,  600,  345,  156,   39,    0
            .word   39,   56,  345,  600,  910, 1264, 1648, 2048
            .word 2447, 2831, 3185, 3495, 3750, 3939, 4056, 4095
            .word 4056, 3939, 3750, 3495, 3185, 2831, 2447, 2048
;-------------------------------------------------------------------------------
;			Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".int25"          ; Timer_A0 Vector
            .short  TIMERA0_ISR
            .sect	".reset"	           ; POR, ext. Reset, Watchdog
            .short  RESET
            .end
