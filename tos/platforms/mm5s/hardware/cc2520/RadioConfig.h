/*
 * Copyright (c) 2013, Eric B. Decker
 * Copyright (c) 2010, Vanderbilt University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
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
 * Author: Janos Sallai, Miklos Maroti
 * Author: Thomas Schmid (adapted for CC2520)
 * Author: Eric B. Decker (mm5s, 5438a, CC2520)
 */

#ifndef __RADIOCONFIG_H__
#define __RADIOCONFIG_H__

#include <Timer.h>
#include <message.h>
//#include <CC2520DriverLayer.h>

/* This is the default value of the PA_POWER field of the TXCTL register. */
#ifndef CC2520_DEF_RFPOWER
#define CC2520_DEF_RFPOWER	0
#endif

/* This is the default value of the CHANNEL field of the FSCTRL register. */
#ifndef CC2520_DEF_CHANNEL
#define CC2520_DEF_CHANNEL	26
#endif

/* The number of microseconds a sending mote will wait for an acknowledgement */
#ifndef SOFTWAREACK_TIMEOUT
#define SOFTWAREACK_TIMEOUT	800
#endif

/**
 * This is the timer type of the radio alarm interface
 */
typedef T32khz   TRadio;
typedef uint16_t tradio_size;

/**
 * The number of radio alarm ticks per one microsecond .
 *
 * The main mm5s clock is at 8MHz (decimal), TA1 is used to
 * provide TMicro (DCO -> MCLK -> SMCLK -> /8 -> TA1).
 *
 * However, the SFD capture is on pin 8.1 which is connected to
 * TA0.CCI1B.  TA0 is run off the 32KiHz clock so we use TA0
 * for the capture and runs T32khz and TMilli.
 */
#define RADIO_ALARM_MICROSEC    1/32

enum cc2520_timing_enums {
  CC2520_SYMBOL_TIME =  17 * RADIO_ALARM_MICROSEC, //  16us, actual 16.2us
  IDLE_2_RX_ON_TIME  =  12 * CC2520_SYMBOL_TIME,   // 192us, actual 194.5us
  PD_2_IDLE_TIME     = 902 * RADIO_ALARM_MICROSEC, // 860us, actual 860.2us
};


/**
 * The base two logarithm of the number of radio alarm ticks per one millisecond
 *
 * Originally TinyOS defined time in terms of powers of two.  And 
 * RADIO_ALARM_MILLI_EXP expressing millisecs (actually mis, binary millisecs)
 * isn't a problem.
 *
 * 2**5 = 32.  Actually 32.7 which is about 2.3% off.
 */
#define RADIO_ALARM_MILLI_EXP	5

/**
 * Make PACKET_LINK automaticaly enabled for Ieee154MessageC
 */
#if !defined(TFRAMES_ENABLED) && !defined(PACKET_LINK)
#define PACKET_LINK
#endif

#endif          //__RADIOCONFIG_H__
