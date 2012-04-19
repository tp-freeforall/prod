/*
 * Copyright (c) 2008-2012, SOWNet Technologies B.V.
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
*/

#ifndef MSP430_PORTS_H
#define MSP430_PORTS_H

// define unified names for the various ways of specifying available ports

#if defined(__msp430_have_port1) || defined(__MSP430_HAS_PORT1__) || defined(__MSP430_HAS_PORT1_R__)
#define MSP430_HAS_PORT_1
#endif

#if defined(__msp430_have_port2) || defined(__MSP430_HAS_PORT2__) || defined(__MSP430_HAS_PORT2_R__)
#define MSP430_HAS_PORT_2
#endif

#if defined(__msp430_have_port3) || defined(__MSP430_HAS_PORT3__) || defined(__MSP430_HAS_PORT3_R__)
#define MSP430_HAS_PORT_3
#endif

#if defined(__msp430_have_port4) || defined(__MSP430_HAS_PORT4__) || defined(__MSP430_HAS_PORT4_R__)
#define MSP430_HAS_PORT_4
#endif

#if defined(__msp430_have_port5) || defined(__MSP430_HAS_PORT5__) || defined(__MSP430_HAS_PORT5_R__)
#define MSP430_HAS_PORT_5
#endif

#if defined(__msp430_have_port6) || defined(__MSP430_HAS_PORT6__) || defined(__MSP430_HAS_PORT6_R__)
#define MSP430_HAS_PORT_6
#endif

#endif
