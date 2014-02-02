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
 * Author: Eric B. Decker (exp5438_2520, 5438a, CC2520)
 */

#ifndef __RADIOCONFIG_H__
#define __RADIOCONFIG_H__

#include <Timer.h>
#include <message.h>

/*
 * TXPOWER register value, see Table 17 of the 2520 data sheet
 * Note.   Using a 2591 range extender will change the actual
 * power emitted.
 *
 * This can no long be done here because the 2591 changes what
 * must be programmed into the PA_POWER field.  It is no longer
 * a RadioConfig thing but is now a h/w platform thing.
 */
#ifdef notdef
#ifndef CC2520_DEF_RFPOWER
#define CC2520_DEF_RFPOWER	0x32
#endif
#endif

/*
 * channel to use for FREQCTRL
 */
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
typedef TMicro   TRadio;
typedef uint16_t tradio_size;

/**
 * The number of radio alarm ticks per one microsecond .
 *
 * The main exp5438 clock is at 8MHz (decimal), TA0 is used to
 * provide TMicro (DCO -> MCLK -> SMCLK -> /8 -> TA0).
 *
 * The SFD pin is on pin 8.1 which is connected to TA0.CCI1B.
 * TA0 is run off the TMicro so we use TA0 for the capture and also
 * runs the TMicro clocks.
 */
#define RADIO_ALARM_MICROSEC    1


/**
 * The base two logarithm of the number of radio alarm ticks per one millisecond
 *
 * Originally TinyOS defined time in terms of powers of two.  And 
 * RADIO_ALARM_MILLI_EXP expressing millisecs (actually mis, binary millisecs)
 * isn't a problem.
 *
 * 2**10 = 1024
 */
#define RADIO_ALARM_MILLI_EXP	10



/**
 * Make PACKET_LINK automaticaly enabled for Ieee154MessageC
 */
#if !defined(TFRAMES_ENABLED) && !defined(PACKET_LINK)
#define PACKET_LINK
#endif

#endif          //__RADIOCONFIG_H__
