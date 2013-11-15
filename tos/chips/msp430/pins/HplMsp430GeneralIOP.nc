/*
 * Copyright (c) 2012, 2013, Eric B. Decker
 * Copyright (c) 2000-2005 The Regents of the University of California.  
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
 */

/**
 * @author Joe Polastre
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include "msp430regtypes.h"

/**
 * Low level digital port access for Msp430 chips.
 * should work on all three major families, x1, x2, and x5.
 *
 * Simple GeneralIO.
 *
 * Depending on the optimization level of the toolchain and which toolchain,
 * access may or may not be single instructions (ie. atomic).  When not sure
 * of exactly what instructions are being used one should use the default
 * which is to surround accesses with "atomic".
 *
 * The define MSP430_PINS_ATOMIC_LOWLEVEL is used to control whether accesses
 * are protected from interrupts (via "atomic").  If not defined, it will
 * default to "atomic".   To generated optimized accesses, define it to be
 * empty.  From your Makefile, you can do
 *
 *    "CFLAGS += -DMSP430_PINS_ATOMIC_LOWLEVEL=".
 *
 * Any override will typically be done either in the platform's hardware.h
 * or in the applications "Makefile".
 *
 * WARNING: When MSP430_PINS_ATOMIC_LOWLEVEL is blank, this code makes
 * the assumption that access to the various registers occurs with single
 * instructions and thus is atomic.  It has been verified that with -Os
 * optimization, that indeed register access is via single instructions.
 * Other optimizations may not result in single instructions.  In those
 * cases, you should use the default value which causes "atomic" to protect
 * access from interrupts.
 *
 * If you turn off the atomic protection it is assumed that you know
 * what you are doing and will make sure the machine state is reasonable
 * for what you are doing.
 */

#ifndef MSP430_PINS_ATOMIC_LOWLEVEL
#define MSP430_PINS_ATOMIC_LOWLEVEL atomic
#endif

generic module HplMsp430GeneralIOP(
				unsigned int port_in_addr,
				unsigned int port_out_addr,
				unsigned int port_dir_addr,
				unsigned int port_sel_addr,
				uint8_t pin
				) @safe()
{
  provides interface HplMsp430GeneralIO as IO;
}
implementation {
  #define PORTxIN (*TCAST(volatile TYPE_PORT_IN* ONE, port_in_addr))
  #define PORTx (*TCAST(volatile TYPE_PORT_OUT* ONE, port_out_addr))
  #define PORTxDIR (*TCAST(volatile TYPE_PORT_DIR* ONE, port_dir_addr))
  #define PORTxSEL (*TCAST(volatile TYPE_PORT_SEL* ONE, port_sel_addr))

  async command void IO.set() { MSP430_PINS_ATOMIC_LOWLEVEL PORTx |= (0x01 << pin); }
  async command void IO.clr() { MSP430_PINS_ATOMIC_LOWLEVEL PORTx &= ~(0x01 << pin); }
  async command void IO.toggle() { MSP430_PINS_ATOMIC_LOWLEVEL PORTx ^= (0x01 << pin); }
  async command uint8_t IO.getRaw() { return PORTxIN & (0x01 << pin); }
  async command bool IO.get() { return (call IO.getRaw() != 0); }
  async command void IO.makeInput() { MSP430_PINS_ATOMIC_LOWLEVEL PORTxDIR &= ~(0x01 << pin); }
  async command bool IO.isInput() { return (PORTxDIR & (0x01 << pin)) == 0; }
  async command void IO.makeOutput() { MSP430_PINS_ATOMIC_LOWLEVEL PORTxDIR |= (0x01 << pin); }
  async command bool IO.isOutput() { return (PORTxDIR & (0x01 << pin)) != 0; }
  async command void IO.selectModuleFunc() { MSP430_PINS_ATOMIC_LOWLEVEL PORTxSEL |= (0x01 << pin); }
  async command bool IO.isModuleFunc() { return (PORTxSEL & (0x01<<pin)) != 0; }
  async command void IO.selectIOFunc() { MSP430_PINS_ATOMIC_LOWLEVEL PORTxSEL &= ~(0x01 << pin); }
  async command bool IO.isIOFunc() { return (PORTxSEL & (0x01<<pin)) == 0; }
  async command error_t IO.setResistor(uint8_t mode) { return EINVAL; }
  async command void    IO.resistorOff()      { }
  async command void    IO.resistorPullDown() { }
  async command void    IO.resistorPullUp()   { };
  async command uint8_t IO.getResistor() { return MSP430_PORT_RESISTOR_INVALID; }
  async command error_t IO.setDriveStrength(uint8_t mode) { return EINVAL; }
  async command uint8_t IO.getDriveStrength() { return MSP430_PORT_DRIVE_STRENGTH_INVALID;}
}
