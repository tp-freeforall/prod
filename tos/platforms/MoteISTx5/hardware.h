/*
 * Copyright (c) 2011 João Gonçalves
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
 * @author João Gonçalves
 */

#ifndef _H_hardware_h
#define _H_hardware_h

#include "msp430hardware.h"

// enum so components can override power saving,
// as per TEP 112.
enum {
  TOS_SLEEP_NONE = MSP430_POWER_ACTIVE,
};

//#define TOS_DEFAULT_BAUDRATE 9600
#define TOS_DEFAULT_BAUDRATE 115200

/* uart is sourced by SMCLK that has 4MHz XTAL reference
 * only works with 9600 and 115200 baudrates
 * for other baudrates edit msp430usci.h
 */

//#define UART_SMCLK_XTAL_4MHz 
#define UART_SMCLK_XTAL_16MHz
//#define UART_SOURCE_REFOCLK
/* Use the 32kHz crystal or REFOCLK */

//Unlock for Special funcionality of PINS such as SPI

/* Use the PlatformAdcC component, and enable 8 pins */
#define ADC12_USE_PLATFORM_ADC 1
#define ADC12_PIN_AUTO_CONFIGURE 1
#define ADC12_PINS_AVAILABLE 8

#ifndef PLATFORM_MSP430_HAS_XT1
#define PLATFORM_MSP430_HAS_XT1 1
#endif /* PLATFORM_MSP430_HAS_XT1 */

#ifndef PLATFORM_MSP430_HAS_XT2
#define PLATFORM_MSP430_HAS_XT2 1
#endif /* PLATFORM_MSP430_HAS_XT2 */

/* default DCO configuration */
#define MSP430XV2_DCO_CONFIG MSP430XV2_DCO_2MHz_RSEL2

#endif // _H_hardware_h
