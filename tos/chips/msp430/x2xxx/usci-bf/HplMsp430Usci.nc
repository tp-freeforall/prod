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
 * Control of an MSP430 USCI module.
 *
 * This interface is completely agnostic of the modes supported by a
 * particular USCI module.  It supports the common module registers
 * for all modules/modes. 
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com> 
 * @author Doug Carlson <carlson@cs.jhu.edu>
 */

#include "msp430usci.h"

interface HplMsp430Usci {
  
  /* ----------------------------------------
   * Introspection to identify a module when given a reference to its
   * component
   */

  /**
   * Return a unique identifier for this module among all USCI modules on the chip.
   * 
   * There is a one-to-one correspondence between the value returned
   * by this function and the set of pairs of (module_type,
   * module_instance).
   */
  async command uint8_t getModuleIdentifier ();
    
  /* ----------------------------------------
   * Read and write the module registers.
   */
  async command void setCtl0(uint8_t v);
  async command uint8_t getCtl0();

  async command void setCtl1(uint8_t v);
  async command uint8_t getCtl1();

  async command void setBr0(uint8_t v);
  async command uint8_t getBr0();

  async command void setBr1(uint8_t v);
  async command uint8_t getBr1();

//  /**
//   * Reads the USCmxMCTL Modulation Control register.
//   * This register is present on USCI A modules.
//   */
//  async command uint8_t getMctl();
//  
//  /**
//   * Write the UCmxMCTL Modulation Control register.
//   * This register is present on USCI A modules.
//   */
//  async command void setMctl(uint8_t v);
//
//  /**
//   * Reads the UCmxI2CIE register.
//   * This register is present on only USCI modules with I2C.
//   */
//  async command uint8_t getI2Cie();
//  
//  /**
//   * Write the UCmxI2CIE register.
//   * This register is present on all USCI modules with I2C.
//   */
//  async command void setI2Cie(uint8_t v);
//   

  /**
   * Read the UCmxSTAT Status register.
   * This register is present on all USCI modules.
   */
  async command uint8_t getStat();
  
  /**
   * Write the UCmxSTAT Status register.
   * This register is present on all USCI modules.
   */
  async command void setStat(uint8_t v);

  /**
   * Read the UCmxRXBUF Receive Buffer register.
   * This register is present on all USCI modules.
   */
  async command uint8_t getRxbuf();
  
  /**
   * Write the UCmxRX Receive Buffer register.
   * This register is present on all USCI modules.
   */
  async command void setRxbuf(uint8_t v);

  /**
   * Read the UCmxTXBUF Transmit Buffer register.
   * This register is present on all USCI modules.
   */
  async command uint8_t getTxbuf();
  
  /**
   * Write the UCmxTX Transmit Buffer register.
   * This register is present on all USCI modules.
   */
  async command void setTxbuf(uint8_t v);

//  /**
//   * Read the UCmxABCTL Auto Baud Rate Control register.
//   * This register is present only on USCI_A modules in UART mode.
//   */
//  async command uint8_t getAbctl();
//  
//  /**
//   * Write the UCmxABCTL Auto Baud Rate Control register.
//   * This register is present only on USCI_A modules in UART mode.
//   */
//  async command void setAbctl(uint8_t v);
//
//  /**
//   * Read the UCmxI2COA I2C Own Address register.
//   * This register is present only on USCI_B modules in I2C mode.
//   */
//  async command uint8_t getI2Coa();
//  
//  /**
//   * Write the UCmxI2COA I2C Own Address register.
//   * This register is present only on USCI_B modules in I2C mode.
//   */
//  async command void setI2Coa(uint8_t v);
//
//  /**
//   * Read the UCmxIRCTL IrDA Control register.
//   * This register is present only on USCI_A modules in UART mode.
//   */
//  async command uint8_t getIrctl();
//  
//  /**
//   * Write the UCmxIRCTL IrDA Control register.
//   * This register is present only on USCI_A modules in UART mode.
//   */
//  async command void setIrctl(uint8_t v);
//
//  /**
//   * Read the UCmxIRTCTL IrDA Transmit Control register.
//   * This register is present only on USCI_A modules in UART mode.
//   */
//  async command uint8_t getIrtctl();
//  
//  /**
//   * Write the UCmxIRTCTL IrDA Transmit Control register.
//   * This register is present only on USCI_A modules in UART mode.
//   */
//  async command void setIrtctl(uint8_t v);
//
//  /**
//   * Read the UCmxIRRCTL IrDA Receive Control register.
//   * This register is present only on USCI_A modules in UART mode.
//   */
//  async command uint8_t getIrrctl();
//  
//  /**
//   * Write the UCmxIRRCTL IrDA Receive Control register.
//   * This register is present only on USCI_A modules in UART mode.
//   */
//  async command void setIrrctl(uint8_t v);
//
//  /**
//   * Read the UCmxI2CSA I2C Slave Address register.
//   * This register is present only on USCI_B modules in I2C mode.
//   */
//  async command uint8_t getI2Csa();
//  
//  /**
//   * Write the UCmxI2CSA I2C Slave Address register.
//   * This register is present only on USCI_B modules in I2C mode.
//   */
//  async command void setI2Csa(uint8_t v);
//
//  /**
//   * Reads the UCmxICTL Interrupt Control register.
//   * This register is present on all USCI modules, and is used in all modes.
//   */
//  async command uint8_t getIctl();
//  
//  /**
//   * Writes the UCmxICTL Interrupt Control register.
//   * This register is present on all USCI modules.
//   */
//  async command uint8_t setIctl(uint8_t v);
  
  /**
   * Reads the UCmxIE Interrupt Enable register.
   * This register is present on all USCI modules, and is used in all modes.
   */
  async command uint8_t getIe();
  
  /**
   * Writes the UCmxIE Interrupt Enable register.
   * This register is present on all USCI modules.
   */
  async command void setIe(uint8_t v);

  /**
   * Reads the UCmxIFG Interrupt Enable register.
   * This register is present on all USCI modules, and is used in all modes.
   */
  async command uint8_t getIfg();
  
  /**
   * Writes the UCmxIFG Interrupt Flag register.
   * This register is present on all USCI modules.
   */
  async command void setIfg(uint8_t v);

//  /**
//   * Reads the UCmxIV Interrupt Vector register.
//   * This register is present on all USCI modules, and is used in all modes.
//   * It is read-only.
//   */
//  async command uint8_t getIv();

  /* ----------------------------------------
   * Higher-level operations consistent across all modes. */

  /**
   * Set the USCI to the mode and speed specified in the given configuration.
   *
   * @param config The speed-relevant parameters for module
   * configuration.  Must be provided.
   * 
   * @param leave_in_reset If TRUE, the module is left in software
   * reset mode upon exit, allowing the caller to perform additional
   * configuration steps such as configuring mode-specific ports.  It
   * is the caller's responsibility to invoke leaveResetMode_() upon
   * completion.
   */
  async command void configure (const msp430_usci_config_t* config,
                                bool leave_in_reset);

  /**
   * Place the USCI into software reset mode.
   * This command should only be invoked by modules that implement
   * specific USCI modes, in their mode-specific configuration
   * functions. */
  async command void enterResetMode_ ();

  /**
   * Take the USCI out of software reset mode.
   * This command should only be invoked by modules that implement
   * specific USCI modes, in their mode-specific configuration
   * functions. */
  async command void leaveResetMode_ ();

  /** Return an enumeration value indicating the currently configured USCI
   * mode.  Values are from the MSP430_USCI_Mode_e enumeration. */
  async command uint8_t currentMode ();
}
