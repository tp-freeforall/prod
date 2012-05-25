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

generic module HplMsp430UsciBP(
  /** Offset of UCmxCTL0_ register for m=module_type and x=module_instance */
  unsigned int UCmxCTL0_,
  unsigned int UCmxI2COA_
) @safe() {
  provides {
    interface HplMsp430UsciB as UsciB;
  }
}
implementation {
#define UCmxI2CIE (*TCAST(volatile uint8_t*  ONE, UCmxCTL0_  + 0x04))
#define UCmxI2COA (*TCAST(volatile uint16_t* ONE, UCmxI2COA_ + 0x00))
#define UCmxI2CSA (*TCAST(volatile uint16_t* ONE, UCmxI2COA_ + 0x02))

  async command uint16_t UsciB.getI2Coa()           { return UCmxI2COA; }
  async command void     UsciB.setI2Coa(uint16_t v) { UCmxI2COA = v; }
  async command uint16_t UsciB.getI2Csa()           { return UCmxI2CSA; }
  async command void     UsciB.setI2Csa(uint16_t v) { UCmxI2CSA = v; }
  async command uint8_t  UsciB.getI2Cie()           { return UCmxI2CIE; }
  async command void     UsciB.setI2Cie(uint8_t v)  { UCmxI2CIE = v; }

#undef UCmxI2CSA
#undef UCmxI2COA
#undef UCmxI2CIE
}
