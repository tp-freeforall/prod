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
 */

#include "msp430usci.h"

generic module HplMsp430UsciP(
  /** Identifier for this USCI module, unique across (type, instance) pairs */
  uint8_t USCI_ID,
  /** Offset of UCmxCTL0_ register for m=module_type and x=module_instance */
  unsigned int UCmxCTL0_,
  /** offset of interrupt-enable register**/
  unsigned int IE_
) @safe() {
  provides {
    interface HplMsp430Usci as Usci;
    interface HplMsp430UsciInterrupts as TXInterrupts[ uint8_t mode ];
    interface HplMsp430UsciInterrupts as RXInterrupts[ uint8_t mode ];
    interface HplMsp430UsciInterrupts as StateInterrupts[ uint8_t mode ];
  }
  uses {
    interface HplMsp430UsciInterrupts as RawTXInterrupts;
    interface HplMsp430UsciInterrupts as RawRXInterrupts;
    interface HplMsp430UsciInterrupts as RawStateInterrupts;
    interface ArbiterInfo;
    interface Leds;
  }
}
implementation {
#define UCmxCTL0 (*TCAST(volatile uint8_t* ONE, UCmxCTL0_ + 0x00)) 
#define UCmxCTL1 (*TCAST(volatile uint8_t* ONE, UCmxCTL0_ + 0x01)) 
#define UCmxBR0 (*TCAST(volatile uint8_t* ONE, UCmxCTL0_ + 0x02))
#define UCmxBR1 (*TCAST(volatile uint8_t* ONE, UCmxCTL0_ + 0x03))
#define UCmxMCTL (*TCAST(volatile uint8_t* ONE, UCmxCTL0_ + 0x04))
#define UCmxSTAT (*TCAST(volatile uint8_t* ONE, UCmxCTL0_ + 0x05))
#define UCmxRXBUF (*TCAST(volatile uint8_t* ONE, UCmxCTL0_ + 0x06))
#define UCmxTXBUF (*TCAST(volatile uint8_t* ONE, UCmxCTL0_ + 0x07))

#define UCmxIE (*TCAST(volatile uint8_t* ONE, IE_ + 0x00))
#define UCmxIFG (*TCAST(volatile uint8_t* ONE, IE_ + 0x01))

  async command uint8_t Usci.getModuleIdentifier() { return USCI_ID; }

  async command void Usci.setCtl0(uint8_t v) { UCmxCTL0 = v;}
  async command uint8_t Usci.getCtl0() { return UCmxCTL0;}

  async command void Usci.setCtl1(uint8_t v) { UCmxCTL1 = v; }
  async command uint8_t Usci.getCtl1() { return UCmxCTL1; }

  async command uint8_t Usci.getBr0() {return UCmxBR0; }
  async command void Usci.setBr0(uint8_t v) { UCmxBR0 = v; }

  async command uint8_t Usci.getBr1() {return UCmxBR1; }
  async command void Usci.setBr1(uint8_t v) { UCmxBR1 = v; }

  async command uint8_t Usci.getStat() { return UCmxSTAT; }
  async command void Usci.setStat(uint8_t v) { UCmxSTAT = v; }
  async command uint8_t Usci.getRxbuf() { return UCmxRXBUF; }
  async command void Usci.setRxbuf(uint8_t v) { UCmxRXBUF = v; }
  async command uint8_t Usci.getTxbuf() { return UCmxTXBUF; }
  async command void Usci.setTxbuf(uint8_t v) { UCmxTXBUF = v; }
  async command uint8_t Usci.getIe() { return UCmxIE; }
  async command void Usci.setIe(uint8_t v) { 

    //This is the point where it fails. UCmxIE looks OK in app.c
    //(0x001, which is IE2 in msp430f235.h)
    // this succeeds the first time (when called by configure) not the
    // second (when called by uartstream.send
    //ok, looks like this is causing the interrupt to fire, but we're
    //not clearing it. now we're getting somewhere.
    UCmxIE = v; 
  }
  async command uint8_t Usci.getIfg() { return UCmxIFG; }
  async command void Usci.setIfg(uint8_t v) { UCmxIFG = v; }

  async command void Usci.enterResetMode_ () {
    __asm__ __volatile__("bis %0, %1" : : "i" UCSWRST, "m" UCmxCTL1);
    //UCmxCTL1 |= UCSWRST;
  }

  async command void Usci.leaveResetMode_ () {
    __asm__ __volatile__("bic %0, %1" : : "i" UCSWRST, "m" UCmxCTL1);
    //UCmxCTL1 &= ~UCSWRST;
  }

  async command void Usci.configure (const msp430_usci_config_t* config,
                                     bool leave_in_reset)
  {
    if (! config) {
      return;
    }
    call Usci.enterResetMode_();
    call Usci.setCtl0(config->ctl0);
    call Usci.setCtl1(config->ctl1 | UCSWRST);
    //UCmxCTLW0 = config->ctlw0 + UCSWRST;
    call Usci.setBr0(config->br0);
    call Usci.setBr1(config->br1);
    //UCmxBRW = config->brw;
    UCmxMCTL = config->mctl;
    if (! leave_in_reset) {
      call Usci.leaveResetMode_();
    }
  }

  async command uint8_t Usci.currentMode ()
  {
    atomic {
      if (! (UCmxCTL0 & UCSYNC)) {
        return MSP430_USCI_UART;
      }
      if (UCMODE_3 == (UCmxCTL0 & (UCMODE0 | UCMODE1))) {
        return MSP430_USCI_I2C;
      }
      return MSP430_USCI_SPI;
    }
  }

  /*
   * Upon receipt of an interrupt, if the USCI is active then demux
   * the interrupt to the handler for the appropriate USCI mode.
   */
  async event void RawTXInterrupts.interrupted (uint8_t iv) {
    if (call ArbiterInfo.inUse()) {
      signal TXInterrupts.interrupted[ call Usci.currentMode() ](iv);
    }
  }

  async event void RawRXInterrupts.interrupted (uint8_t iv) {
    if (call ArbiterInfo.inUse()) {
      signal RXInterrupts.interrupted[ call Usci.currentMode() ](iv);
    }
  }

  async event void RawStateInterrupts.interrupted (uint8_t iv) {
    if (call ArbiterInfo.inUse()) {
      signal StateInterrupts.interrupted[ call Usci.currentMode() ](iv);
    }
  }

  default async event void RXInterrupts.interrupted[uint8_t mode] (uint8_t iv) { }
  default async event void TXInterrupts.interrupted[uint8_t mode] (uint8_t iv) { }
  default async event void StateInterrupts.interrupted[uint8_t mode] (uint8_t iv) { }

#undef UCmxIFG
#undef UCmxIE
#undef UCmxTXBUF
#undef UCmxRXBUF
#undef UCmxSTAT
#undef UCmxMCTL
#undef UCmxBR1
#undef UCmxBR0
#undef UCmxCTL1
#undef UCmxCTL0
}
