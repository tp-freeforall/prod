/*
 * Copyright (c) 2013-2014, Eric B. Decker
 * Copyright (c) 2009-2010 People Power Co.
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
 * @author Peter Bigot
 * @author Eric B. Decker <cire831@gmail.com>
 */

#ifndef _H_hardware_h
#define _H_hardware_h

#include "msp430hardware.h"

#if !defined(__msp430x54xA)
#warning Expected Processor __msp430x54xA not found
#endif

/*
 * Hardware Notes:
 *
 * Main CPU clock 8 MHz.  (DCOCLK) sync'd to 32KiHz (ACLK)
 * see exp5438_2520/hardware/clock/PlatformClockP.nc for details.
 *
 * DCOCLK -> MCLK, SMCLK (8 MHz) /8 -> TMicro (1 MHz) TA1
 * ACLK   -> TA0 (32 KiHz) -> TMilli
 *
 * We are using the I2C single master driver.  Use the default configuration
 * so use UCMST instead of UCMM.
 *
 * 8MHz/80 -> 100KHz
 * 8MHz/20 -> 400KHz
 */
#define MSP430_I2C_MASTER_MODE UCMST
#define MSP430_I2C_DIVISOR 20

/*
 * Port definitions:
 *
 * TI MSP-EXP430F5438 Eval board.
 *
 * CC2520-2591EM radio module.
 *
 * Leds, cc2520em, uart, xin/xout, valid
 *
 * Various codes for port settings: (<dir><usage><default val>: Is0 <input><spi><0, zero>)
 * another nomenclature used is <value><function><direction>, 0pO (0 (zero), port, Output),
 *    xpI (don't care, port, Input), mI (module input).
 *
 * port 1.0	0pO	led1 (red)		port 5.0	0pI
 *       .1	0pO	led2 (yellow)		      .1	0pI
 *       .2	1pO	cc_resetn      		      .2	0pI
 *       .3     0pI	cc_g3 xxxx (cca, HGM)	      .3	0pI
 *       .4	0pI	cc_g0 (1MHz clk, sfd)         .4	0pI
 *       .5	0pI	cc_g1 (tx_active)             .5	0pI
 *       .6	0pI	cc_g2 (excA)                  .6	0pI
 *       .7	0pO	cc_vreg_en		      .7	0pI
 *
 * port 2.0	0pI   	          		port 6.0	0pI
 *       .1	0pI   	          		      .1	0pI
 *       .2	0pI   	                 	      .2	0pI
 *       .3	0pI   	           		      .3	0pI
 *       .4	0pI   	        		      .4	0pI
 *       .5	0pI   	        		      .5	0pI
 *       .6	0pI     user_1 (S1)		      .6	0pI
 *       .7	0pI   	user_2 (S2)		      .7	0pI
 *
 * port 3.0	1pO	cc_cs_n			port 7.0	0mI	xin   (32KiHZ)
 *       .1	0pI	cc_si   (b0simo)	      .1	0mO	xout
 *       .2	1pO	cc_so   (b0somi)	      .2	0pI
 *       .3	0pI	cc_sclk (b0clk)		      .3	0pI
 *       .4	1pO	uart_tx	(a0_tx)		      .4	0pI
 *       .5	1pI	uart_rx	(a0_rx)		      .5	0pI
 *       .6	1pI				      .6	0pI
 *       .7	1pI				      .7	0pI
 *
 * port 4.0	0pI   	      			port 8.0	0pI
 *       .1	0pI   	                    	      .1	0pI	cc_g4 xxx (fifo, EN)
 *       .2	0pI   	                    	      .2	0pI	cc_g5 xxx (cc2520 input, fifop, PAEN)
 *       .3	0pI   	                    	      .3	0pI
 *       .4	0pI   	       			      .4	0pI
 *       .5	0pO   	led3 (green)		      .5	0pI
 *       .6	0pI   				      .6	0pI
 *       .7	0pI   				      .7	0pI
 *
 * 4.5 is wired to a plain led.  It needs a pull up to Vcc.  It is wired weird
 * so we can get the REN in series.  Use P4REN 1 to turn the led on.  P4REN.5 1
 * controls led on off, P4DIR.5 0, P4OUT.5 1 (Vcc).
 */


// enum so components can override power saving,
// as per TEP 112.
enum {
  TOS_SLEEP_NONE = MSP430_POWER_ACTIVE,
};

/* @TODO@ Disable probe for XT1 support until the anomaly observed in
 * apps/bootstrap/LocalTime is resolved. */
#ifndef PLATFORM_MSP430_HAS_XT1
#define PLATFORM_MSP430_HAS_XT1 1
#endif /* PLATFORM_MSP430_HAS_XT1 */

// LEDs
TOSH_ASSIGN_PIN(RED_LED, 1, 0);
TOSH_ASSIGN_PIN(YELLOW_LED, 1, 1);
TOSH_ASSIGN_PIN(GREEN_LED, 4, 5);

#endif // _H_hardware_h
