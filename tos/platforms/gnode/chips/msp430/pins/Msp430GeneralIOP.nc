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

#include "msp430_ports.h"

module Msp430GeneralIOP {
	provides interface Init;
}

implementation {

	/**
	 * Reset all of the ports to be input and using I/O functionality.
	 */
	command error_t Init.init() {
		atomic {
#ifdef MSP430_HAS_PORT_1
			P1SEL = 0;
			P1DIR = 0;
			P1OUT = 0;
			P1IE = 0;
#endif

#ifdef MSP430_HAS_PORT_2
			P2SEL = 0;
			P2DIR = 0;
			P2OUT = 0;
			P2IE = 0;
#endif

#ifdef MSP430_HAS_PORT_3
			P3SEL = 0;
			P3DIR = 0;
			P3OUT = 0;
#endif

#ifdef MSP430_HAS_PORT_4
			P4SEL = 0;
			P4DIR = 0;
			P4OUT = 0;
#endif

#ifdef MSP430_HAS_PORT_5
			P5SEL = 0;
			P5DIR = 0;
			P5OUT = 0;
#endif

#ifdef MSP430_HAS_PORT_6
			P6SEL = 0;
			P6DIR = 0;
			P6OUT = 0;
#endif
		}
		
		return SUCCESS;
	}
}
