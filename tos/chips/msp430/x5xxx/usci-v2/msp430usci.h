/*
 * Copyright (c) 2010-2011, 2016 Eric B. Decker
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
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * Support the x5 version of the USCI for the TI MSPx{5,6}xxx processors,
 * (see TI MSP430x{5,6}xxx Users guide slau208).
 *
 * This is somewhat based on the x2 USCI interface, however, the x2 is seriously
 * screwed (see tos/chips/msp430/x2xxx/usci/msp430usci.h).  This is somewhat
 * cleaned up in the x5.  The processor include files from TI tell the story...
 *
 * x1:  __MSP430_HAS_UART0__	usart0 present
 *	__MSP430_HAS_I2C__	usart0 has I2C
 *	__MSP430_HAS_UART1__
 *
 * x2:	__MSP430_HAS_USCI__
 *	__MSP430_HAS_USCI_AB0__	indicates interrupts messy.
 *	__MSP430_HAS_USCI_AB1__
 *
 * x5:	__MSP430_HAS_USCI_A0__	indicates vectors are module specific.
 *	__MSP430_HAS_USCI_B0__
 *	__MSP430_HAS_USCI_A1__
 *	__MSP430_HAS_USCI_B1__	etc.
 */

#ifndef _H_Msp430Usci_h
#define _H_Msp430Usci_h

#include "msp430hardware.h"

//#define X5_USCI

#ifndef UCSSEL__SMCLK

/*
 * Both the x2 and x5 families have UCSIs and need a clock source.
 * The x5 cpu header files define UCSSEL__SMCLK but the x2 headers
 * don't  (please TI, can you be more consistent?...   nah.  that's
 * fine, we'll deal)
 *
 * Note: this is x5xxx/usci/msp430usci.h and is inherently a x5 file.
 */

#define UCSSEL__SMCLK       (0x80)    /* USCI 0 Clock Source: SMCLK */
#endif

/* MSP430_USCI_RESOURCE is used for USCI_IDs */
#define MSP430_USCI_RESOURCE "Msp430Usci.Resource"

#define MSP430_USCI_A0_RESOURCE "Msp430Usci.A0.Resource"
#define MSP430_USCI_B0_RESOURCE "Msp430Usci.B0.Resource"
#define MSP430_USCI_A1_RESOURCE "Msp430Usci.A1.Resource"
#define MSP430_USCI_B1_RESOURCE "Msp430Usci.B1.Resource"
#define MSP430_USCI_A2_RESOURCE "Msp430Usci.A2.Resource"
#define MSP430_USCI_B2_RESOURCE "Msp430Usci.B2.Resource"
#define MSP430_USCI_A3_RESOURCE "Msp430Usci.A3.Resource"
#define MSP430_USCI_B3_RESOURCE "Msp430Usci.B3.Resource"

enum {
  MSP430_USCI_Inactive,
  MSP430_USCI_UART,
  MSP430_USCI_SPI,
  MSP430_USCI_I2C,
};

/**
 * Aggregates basic configuration registers for an MSP430 USCI.
 * These are specifically the registers common to all configurations.
 * Mode-specific configuration data should be provided elsewise.
 */
typedef struct msp430_usci_config_t {
  uint8_t ctl0;				/* various control bits, msb */
  uint8_t ctl1;				/* clock select and swreset, lsb */
  uint8_t br0;				/* lsb divider */
  uint8_t br1;				/* msb divider */
  uint8_t mctl;
  uint16_t i2coa;
} msp430_usci_config_t;

/*
 * see Msp430UsciI2CP.nc, I2CBasicAddr.read.
 *
 * I2C_ONE_BYTE_READ_COUNTER is used as a limit to keep
 * the routine from going infinite when things go wrong.
 *
 * DEPRECATED.   It is going away!!!!
 *
 * The x5 code has been converted to use time via Platform raw time
 * interfaces.   The x2 code currently uses the counters.   This
 * should be changed by the x2 folks.
 *
 * x5 uses 0x500, x2 uses 0xe00 can they be the same?
 */

#define I2C_ONE_BYTE_READ_COUNTER 0x0500

#ifndef TOS_DEFAULT_BAUDRATE
#define TOS_DEFAULT_BAUDRATE 115200
#endif /* TOS_DEFAULT_BAUDRATE */


/*
 * The following default configurations assume SMCLK clock is 1MiHz (2^20Hz).
 *
 * WARNING: This is not necessarily a good assumption.    Choice of clocks is
 * really a platform thing and should be provided in some fashion by the platform.
 *
 * The common definition here is a carry over from the old initial way that T2 dealt
 * with this issue.
 *
 * In addition, there are issues with assuming binary vs. decimal clocks.  For example
 * the msp430f5438a with out tweak the PMM wants to be clocked no faster than 8,000,000
 * (8 MHz).
 */

const msp430_usci_config_t msp430_usci_uart_default_config = {
  /* N81 UART mode driven by SMCLK */
  ctl0 : 0,
  ctl1 : UCSSEL__SMCLK,

#if 9600 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 9600: UBR=109, BRS=2, BRF=0 */
  br0  : 109,
  br1  : 0,
  mctl : UCBRF_0 | UCBRS_2,
#elif 19200 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 19200: UBR=54, BRS=2, BRF=0 */
  br0  : 54,
  br1  : 0,
  mctl : UCBRF_0 | UCBRS_2,
#elif 38400 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 38400: UBR=27, BRS=2, BRF=0 */
  br0 : 27,
  br1 : 0,
  mctl : UCBRF_0 | UCBRS_2,
#elif 57600 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 57600: UBR=18, BRS=1, BRF=0 */
  br0  : 18,
  br1  : 0,
  mctl : UCBRF_0 | UCBRS_1,
#elif 115200 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 115200: UBR=9, BRS=1, BRF=0 */
  br0  : 9,
  br1  : 0,
  mctl : UCBRF_0 | UCBRS_1,
#else
#warning Unrecognized value for TOS_DEFAULT_BAUDRATE, using 115200
  br0  : 9,
  br1  : 0,
  mctl : UCBRF_0 | UCBRS_1,
#endif
  i2coa: 0
};

const msp430_usci_config_t msp430_usci_spi_default_config = {
  /* Inactive high MSB-first 8-bit 3-pin master driven by SMCLK */
  ctl0 : UCCKPL | UCMSB | UCMST | UCSYNC,
  ctl1 : UCSSEL__SMCLK,
  br0  : 2,			/* 2x Prescale, 1*2^19 (512 KiHz) */
  br1  : 0,
  mctl : 0,
  i2coa: 0
};

/*
 * Should the default be the following?  MM (multi-master) seems
 * like it should be a platform specific thing.
 * ctl0 : (UCMST | UCMODE_3 | UCSYNC),
 *
 * clock divisor is definitely a platform specific thing.   The
 * default should probably be SMCLK/div ~= 100kbps.
 *
 * MM vs. SM is also a platform thing.   But for now we let the
 * application or platform override it.
 */

#ifndef MSP430_I2C_MASTER_MODE
/*
 * default to multi-master, because the usci-bf code
 * was originally written as a multi-master.
 */
#define MSP430_I2C_MASTER_MODE UCMM
#endif


#ifndef MSP430_I2C_DIVISOR
#define MSP430_I2C_DIVISOR 10
#endif

const msp430_usci_config_t msp430_usci_i2c_default_config = {
  ctl0 : UCSYNC | UCMODE_3 | MSP430_I2C_MASTER_MODE,
  ctl1 : UCSSEL__SMCLK,
  br0  : MSP430_I2C_DIVISOR,		/* SMCLK/div */
  br1  : 0,				/* 1*2^20/div -> 104,858 Hz */
  mctl : 0,
  i2coa: 0x41,
};

enum {
  /** Bit set in Msp430UsciError.condition parameter when a framing
   * error (UART) or bus conflict (SPI) has been detected.  Applies in
   * UART mode, and SPI 4-wire master mode. */
  MSP430_USCI_ERR_Framing = UCFE,
  /** Bit set in Msp430UsciError.condition parameter when an overrun
   * error (lost character on input) has been detected.  Applies in
   * UART and SPI modes. */
  MSP430_USCI_ERR_Overrun = UCOE,
  /** Bit set in Msp430UsciError.condition parameter when a parity
   * error has been detected.  Applies in UART mode. */
  MSP430_USCI_ERR_Parity = UCPE,
  /** Mask for all UCxySTAT bits that represent reportable errors. */
  MSP430_USCI_ERR_UCxySTAT = MSP430_USCI_ERR_Framing | MSP430_USCI_ERR_Overrun | MSP430_USCI_ERR_Parity,
};

#endif // _H_Msp430Usci_h
