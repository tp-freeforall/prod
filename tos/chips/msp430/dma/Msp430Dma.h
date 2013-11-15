/*
 * Copyright (c) 2011 Eric B. Decker
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Ben Greenstein <ben@cs.ucla.edu>
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Mark Hays
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * Major rewrite: 4/4/2011 (is that US or European order?)
 * Rewrite to support the x1, x2, and x5 families, single driver.
 *
 *
 * - Make a minimal driver.  Only include what is actually used and no more.
 *   Simplify what one needs to pay attention to and what needs to be
 *   supported.
 *
 * - Remove internal state variable.   Make the h/w be the keeper of the faith.
 *   This is fine as long as the h/w tells the truth.  If we think in the
 *   future that there is an issue with the h/w then we will need to revisit
 *   this.  This also works because there is no write only h/w nonsense.
 *
 * - Eliminate redefinition of h/w defines in Msp430Dma.h.   Rather force use
 *   of the h/w defines provided by cpu headers (ie. msp430/include/
 *   msp430f1611.h).  This allows us to adapt the code for different processors
 *   (ie. x1 vs x2 vs x5) without having our own processor dependent files we
 *   have to find.
 *
 *
 * - DMA OpControl
 *
 *   each DMA Controller (as opposed to a DMA Channel) has 3 bits that control
 *   certain parameters of the overall DMA operations.
 *
 *   x1/x2: DMAONFETCH, ROUNDROBIN, and ENNMI.
 *   x5:    DMARMWDIS,  ROUNDROBIN, and ENNMI.
 *
 *   These are set via (HplMsp430DmaControlP) DmaControl.   We default to all
 *   off.  This can be overridden by use of the DmaControl.setOpControl
 *   interface.  Note: turning on DMAONFETCH or DMARMWDIS will slow the DMA
 *   down but possibly avoids DMA/cpu interaction side effects.
 *
 *
 * - 3 vars control Trigger Select.
 *
 *   TSEL_BASE:		address of control word.   Indicates where trigger
 *			select for a given DMA channel lives.
 *   TSEL_SHIFT:	Any shift needed (left shift) to find where TSEL starts.
 *   TSEL_MASK:		Mask denoting how wide TSEL is (4 or 5 bits).
 *
 *   These are established when creating a DMA channel via HplMsp430DmaChannelP.
 *
 *   WARNING: Care must be taken when accessing the control cells where TSEL lives.
 *   On the x1 and x2 processors, these control cells live in the 16 bit i/o memory
 *   starting at 0x0100.  This area MUST be accessed using only 16 bit instructions,
 *   ie. mov not mov.b.    mov.b to an odd IO16 address does nothing.   mov.b to
 *   an even IO16 will do strange things.  Only use full 16 bit instructions.
 *
 *   There are one or more TSEL words.  These words get zeroed on a full reset of
 *   the DMA engines.   The x1 and x2 dma engine (using 4 bit TSEL fields) have one
 *   TSEL word and all 3 TSEL fields fit in this word.   The x5 dma engine uses
 *   5 bit TSEL fields and has 2 TSEL words.   We define TSELW_x for each TSEL
 *   control word that exists for the processor.   These are used in the reset
 *   routine that hits all the engines.
 *
 *
 * - Interrupt Vector
 *
 *   The x1 processors have no DMAIV register, so determining which dma engine
 *   is interrupting has do be done by hand.  The x2 and x5 processors provide
 *   the DMAIV register which indicates which channel is interrupting.
 *
 * - DMA Channel Control is the same across all three processor families.
 *
 * - DMA trigger values are provided by the dma_trigger_t enum.  It changes
 *   for the different processor being selected.   The names are carefully
 *   chosen so a compile error will be generated if used on processor where
 *   the trigger value isn't supported.
 */

#ifndef MSP430DMA_H
#define MSP430DMA_H

/*
 * We key off the existence of the 5th TSEL bit.  If TSEL4 is defined
 * then we assume we have an x5 family processor.
 *
 * x5 (TSEL4 defined):
 *
 *   TSEL registers (DMACTL{0,1} start at 0x500 (DMACTL0_).
 *   TSEL is 5 bits and packed one TSEL field per byte.
 *	TSEL_SHIFT denotes which byte.
 *   TSELW_0 and TSELW_1 are defined (3 TSEL fields take 2 words)
 *   OpControl (DMACTL4_) is at 0x508, and is DMARMWDIS | ROUNDROBIN | ENNMI.
 *
 * x1/x2 (TSEL4 not defined):
 *
 *   TSEL fields live in DMACTL0 0x122.
 *   TSEL is 4 bits and packed two TSEL fields per byte.
 *	TSEL_SHIFT denotes which nibble.
 *   TSELW_0 is defined.
 *   OpControl (DMACTL1_) is at 0x124, and is DMAONFETCH | ROUNDROBIN | ENNMI.
 */
 
#if defined(OLD_TOOLCHAIN) && defined(__msp430x26x) && !defined(DMA0TSEL_12)
/*
 * The old toolchain uses msp430/dma.h to define stuff for the dma engines.
 * The defines are based on the 1st gen and don't define TSEL_12/13.  The
 * 261x cpus use TSEL_12/13 as triggers for UCSI_B.
 *
 * New toolchains use the TI HEADERS which define everything correctly.  So
 * OLD_TOOLCHAIN only needs to be defined if still using the old toolchain
 * and compiling a program for a 261x cpu.  The old toolchain doesn't handle
 * newer chips properly so don't bother.
 */
#define DMA0TSEL_12         12
#define DMA0TSEL_13         13
#endif

#ifdef DMA0TSEL4
/* DMA0TSEL4 is defined --> 5 bit --> x5 family */

#define TSEL_MASK 0x1f

#define TSELW_0     DMACTL0
#define TSEL0_BASE  DMACTL0_
#define TSEL0_SHIFT 0
#define TSEL1_BASE  DMACTL0_
#define TSEL1_SHIFT 8

#define TSELW_1     DMACTL1
#define TSEL2_BASE  DMACTL1_
#define TSEL2_SHIFT 0

#define DMA_OP_CTRL_ DMACTL4_
#define DMA_OP_CTRL  DMACTL4

typedef enum {
  DMA_TRIGGER_DMAREQ	=	DMA0TSEL_0,	// DMA_REQ (sw)
  DMA_TRIGGER_TA0CCR0	=	DMA0TSEL_1,	// Timer0_A (TA0CCR0.IFG)
  DMA_TRIGGER_TA0CCR2	=	DMA0TSEL_2,	// Timer0_A (TA0CCR2.IFG)
  DMA_TRIGGER_TA1CCR0	=	DMA0TSEL_3,	// Timer1_A (TA1CCR0.IFG)
  DMA_TRIGGER_TA1CCR2	=	DMA0TSEL_4,	// Timer1_A (TA1CCR2.IFG)
  DMA_TRIGGER_TB0CCR0	=	DMA0TSEL_5,	// TimerB   (TB0CCR0.IFG)
  DMA_TRIGGER_TB0CCR2	=	DMA0TSEL_6,	// TimerB   (TB0CCR2.IFG)

  /* 7 through 15 are reserved */

  DMA_TRIGGER_UCA0RXIFG	=	DMA0TSEL_16,	// USCIA0 receive
  DMA_TRIGGER_UCA0TXIFG	=	DMA0TSEL_17,	// USCIA0 transmit
  DMA_TRIGGER_UCB0RXIFG	=	DMA0TSEL_18,	// USCIB0 receive
  DMA_TRIGGER_UCB0TXIFG	=	DMA0TSEL_19,	// USCIB0 transmit
  DMA_TRIGGER_UCA1RXIFG	=	DMA0TSEL_20,	// USCIA1 receive
  DMA_TRIGGER_UCA1TXIFG	=	DMA0TSEL_21,	// USCIA1 transmit
  DMA_TRIGGER_UCB1RXIFG	=	DMA0TSEL_22,	// USCIB1 receive
  DMA_TRIGGER_UCB1TXIFG	=	DMA0TSEL_23,	// USCIB1 transmit
  DMA_TRIGGER_ADC12IFG	=	DMA0TSEL_24,	// ADC12IFGx

  /* 25 - 28 are reserved. */
  
  DMA_TRIGGER_MULT	=	DMA0TSEL_29,	// Multiplier ready
  DMA_TRIGGER_DMAxIFG	=	DMA0TSEL_30,	// DMA0IFG triggers DMA channel 1
						// DMA1IFG triggers DMA channel 2
						// DMA2IFG triggers DMA channel 0
  DMA_TRIGGER_DMAE0	=	DMA0TSEL_31,	// ext. Trigger (DMAE0)
} dma_trigger_t;

#else
/* DMA0TSEL4 not defined --> 4 bit --> x1/x2 families */

#define TSEL_MASK 0xf

#define TSELW_0     DMACTL0
#define TSEL0_BASE  DMACTL0_
#define TSEL0_SHIFT 0
#define TSEL1_BASE  DMACTL0_
#define TSEL1_SHIFT 4
#define TSEL2_BASE  DMACTL0_
#define TSEL2_SHIFT 8

#define DMA_OP_CTRL_ DMACTL1_
#define DMA_OP_CTRL  DMACTL1

typedef enum {
  DMA_TRIGGER_DMAREQ	=	DMA0TSEL_0,	// software trigger
  DMA_TRIGGER_TACCR2	=	DMA0TSEL_1,	// TA CCR2.IFG
  DMA_TRIGGER_TBCCR2	=	DMA0TSEL_2,	// TB CCR2.IFG

  DMA_TRIGGER_URXIFG0	=	DMA0TSEL_3,	// RX on USART0 (UART/SPI/I2C)
  DMA_TRIGGER_UCA0RXIFG	=	DMA0TSEL_3,	//   also USCIA0 RX (x2)

  DMA_TRIGGER_UTXIFG0	=	DMA0TSEL_4,	// TX on USART0 (UART/SPI/I2C)
  DMA_TRIGGER_UCA0TXIFG	=	DMA0TSEL_4,	//   also USCIA0 TX (x2)

  DMA_TRIGGER_DAC12IFG	=	DMA0TSEL_5,	// DAC12_0CTL DAC12IFG bit
  DMA_TRIGGER_ADC12IFG	=	DMA0TSEL_6,
  DMA_TRIGGER_TACCR0	=	DMA0TSEL_7,	// CCIFG bit
  DMA_TRIGGER_TBCCR0	=	DMA0TSEL_8,	// CCIFG bit
  DMA_TRIGGER_URXIFG1	=	DMA0TSEL_9,	// RX on USART1 (UART/SPI)
  DMA_TRIGGER_UCA1RXIFG	=	DMA0TSEL_9,	//   also USCIA1 RX (x2)
  DMA_TRIGGER_UTXIFG1	=	DMA0TSEL_10,	// TX on USART1 (UART/SPI)
						//   also USCIA1 TX (x2)
  DMA_TRIGGER_MULT	=	DMA0TSEL_11,	// Hardware Multiplier Ready

  /*
   * note: old mspgcc 3.2.3 toolchains don't define DMA0TSEL_12,13.  Nor is
   * it defined for the x1 processors no matter what.   This is only a problem
   * if compiling a x2 processor with the old toolchain and one needs to use
   * USCIB0.   Don't worry about it.
   */
#ifdef DMA0TSEL_12
  DMA_TRIGGER_UCB0RXIFG =	DMA0TSEL_12,    // USCIB0 receive (x2 only)
  DMA_TRIGGER_UCB0TXIFG =	DMA0TSEL_13,    // USCIB0 receive (x2 only)
#endif

  DMA_TRIGGER_DMAxIFG	=	DMA0TSEL_14,	// DMA0IFG triggers DMA channel 1
						// DMA1IFG triggers DMA channel 2
						// DMA2IFG triggers DMA channel 0
  DMA_TRIGGER_DMAE0	=	DMA0TSEL_15	// External Trigger DMAE0
} dma_trigger_t;

#endif

#define DMA_SW_DW		DMASWDW
#define DMA_SB_DW		DMASBDW
#define DMA_SW_DB		DMASWDB
#define DMA_SB_DB		DMASBDB

#define DMA_SRC_NO_CHNG		DMASRCINCR_0
#define DMA_SRC_DEC		DMASRCINCR_2
#define DMA_SRC_INC		DMASRCINCR_3

#define DMA_DST_NO_CHNG		DMADSTINCR_0
#define DMA_DST_DEC		DMADSTINCR_2
#define DMA_DST_INC		DMADSTINCR_3

#define DMA_DT_RPT		DMADT_4
#define DMA_DT_SINGLE		DMADT_0
#define DMA_DT_BLOCK		DMADT_1
#define DMA_DT_BURST_BLOCK	DMADT_2

#endif		// MSP430DMA_H
