/*
 * Copyright (c) 2012 John Hopkins University
 * Copyright (c) 2009-2010 People Power Co.
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
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
 *
 * Core implementation for any USCI module present on an MSP430 chip.
 *
 * This module makes available the module-specific registers, along
 * with a small number of higher-level functions like generic USCI
 * chip configuration that are shared among the various modes of the
 * module.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com> 
 * @author Doug Carlson <carlson@cs.jhu.edu> 
 **/

#include "msp430usci.h"

generic module HplMsp430UsciAP(
  /** Offset of UCmxCTLW0_ register for m=module_type and x=module_instance */
  unsigned int UCmxCTL0_
) @safe() {
  provides {
    interface HplMsp430UsciA as UsciA;
  }
}
implementation {
#define UCmxABCTL (*TCAST(volatile uint8_t* ONE, UCmxCTL0_ - 0x03))
#define UCmxIRTCTL (*TCAST(volatile uint8_t* ONE, UCmxCTL0_ - 0x02))
#define UCmxIRRCTL (*TCAST(volatile uint8_t* ONE, UCmxCTL0_ - 0x01))

  async command uint8_t UsciA.getAbctl() { return UCmxABCTL; }
  async command void UsciA.setAbctl(uint8_t v) { UCmxABCTL = v; }
  async command uint8_t UsciA.getIrtctl() { return UCmxIRTCTL; }
  async command void UsciA.setIrtctl(uint8_t v) { UCmxIRTCTL = v; }
  async command uint8_t UsciA.getIrrctl() { return UCmxIRRCTL; }
  async command void UsciA.setIrrctl(uint8_t v) { UCmxIRRCTL = v; }

#undef UCmxIRRCTL
#undef UCmxIRTCTL
#undef UCmxABCTL
}
