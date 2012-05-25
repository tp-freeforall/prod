/**
 * Copyright (c) 2011 Eric B. Decker
 * Copyright (c) 2011 Redslate Ltd.
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
 */

/**
 * Control of an MSP430 USCI module.
 *
 * This interface is completely agnostic of the modes supported by a
 * particular USCI module.  It supports the union of the module
 * registers across all modes.
 *
 * Where the same memory location reflects different registers
 * depending on USCI mode, independent functions are provided.
 *
 * Access to individual halves of a 16-bit register is not supported
 * except where the halves have independent functions, as with IRTCTL
 * and IRRCTL.  For example, UCmxCTLW0 is not made available as
 * UCmxCTL1 and UCmxCTL0 halves, as it is unlikely that one would be
 * set without simultaneously setting the other.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author Derek Baker <derek@red-slate.co.uk>
 * @author Eric B. Decker <cire831@gmail.com>
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

  /**
   * Reads the UCmxCTLW0 Control register.
   * This register is present on all USCI modules, and is used in all modes.
   *
   * CTLW0 is the 16 bit concatenation of CTL0 and CTL1.  Note on the x5
   * CTL1 is at offset 0 (x5 is base register based) and CTL0 is the msb.
   *
   * This is swapped with respect to where CTL0 and CTL1 live on the x2 processors,
   * CTL0 is at 0 and CTL1 is at 1 (not base register but relative to where the
   * registers are defined).  This makes config block platform/cpu dependent (which
   * they are anyway because of clocking issues).
   *
   * {get,set}Ctlw0: gets or sets the 16 bit version of the control register.
   * {get,set}Ctl{0,1}: gets or sets the 8 bit version of the 0 or 1 register.
   */
  async command uint16_t getCtlw0();
  async command uint8_t  getCtl0();
  async command uint8_t  getCtl1();

  /**
   * Writes the UCmxCTLW0 Control register.
   * This register is present on all USCI modules.
   */
  async command void setCtlw0(uint16_t v);
  async command void setCtl0(uint8_t v);
  async command void setCtl1(uint8_t v);

  /**
   * Reads the UCmxBRW Baud Rate Control registers.
   * This register is present on all USCI modules.
   */
  async command uint16_t getBrw();

  /**
   * Writes the UCmxBRW Baud Rate Control registers.
   * This register is present on all USCI modules.
   */
  async command void setBrw(uint16_t v);

  /**
   * Reads the USCmBxMCTL Modulation Control register.
   * This register is present on all USCI modules except I2C.
   */
  async command uint8_t getMctl();

  /**
   * Write the UCmxMCTL Modulation Control register.
   * This register is present on all USCI modules except I2C.
   */
  async command void setMctl(uint8_t v);

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

  /**
   * Read the UCmxABCTL Auto Baud Rate Control register.
   * This register is present only on USCI_A modules in UART mode.
   */
  async command uint8_t getAbctl();

  /**
   * Write the UCmxABCTL Auto Baud Rate Control register.
   * This register is present only on USCI_A modules in UART mode.
   */
  async command void setAbctl(uint8_t v);

  /**
   * Read the UCmxIRCTL IrDA Control register.
   * This register is present only on USCI_A modules in UART mode.
   */
  async command uint16_t getIrctl();

  /**
   * Write the UCmxIRCTL IrDA Control register.
   * This register is present only on USCI_A modules in UART mode.
   */
  async command void setIrctl(uint16_t v);

  /**
   * Read the UCmxIRTCTL IrDA Transmit Control register.
   * This register is present only on USCI_A modules in UART mode.
   */
  async command uint8_t getIrtctl();

  /**
   * Write the UCmxIRTCTL IrDA Transmit Control register.
   * This register is present only on USCI_A modules in UART mode.
   */
  async command void setIrtctl(uint8_t v);

  /**
   * Read the UCmxIRRCTL IrDA Receive Control register.
   * This register is present only on USCI_A modules in UART mode.
   */
  async command uint8_t getIrrctl();

  /**
   * Write the UCmxIRRCTL IrDA Receive Control register.
   * This register is present only on USCI_A modules in UART mode.
   */
  async command void setIrrctl(uint8_t v);

  /**
   * Read the UCmxI2COA I2C Own Address register.
   * This register is present only on USCI_B modules in I2C mode.
   */
  async command uint16_t getI2Coa();

  /**
   * Write the UCmxI2COA I2C Own Address register.
   * This register is present only on USCI_B modules in I2C mode.
   */
  async command void setI2Coa(uint16_t v);

  /**
   * Read the UCmxI2CSA I2C Slave Address register.
   * This register is present only on USCI_B modules in I2C mode.
   */
  async command uint16_t getI2Csa();

  /**
   * Write the UCmxI2CSA I2C Slave Address register.
   * This register is present only on USCI_B modules in I2C mode.
   */
  async command void setI2Csa(uint16_t v);

  /**
   * Reads the UCmxICTL Interrupt Control register.
   * This register is present on all USCI modules, and is used in all modes.
   */
  async command uint16_t getIctl();
  
  /**
   * Writes the UCmxICTL Interrupt Control register.
   * This register is present on all USCI modules.
   *
   * ICTL is the 16 bit concatenation of IE (interrupt enable) and IFG
   * (interrupt flag).   WARNING: Using this to set or clear interrupt
   * enables and/or IFGs is not recommended.    There are potential
   * h/w race conditions.   It is much better to use the byte accessors
   * get/setIe, get/setIfg.
   */
  async command uint16_t setIctl(uint16_t v);

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

  /*
   * using setIfg and setIe to control interrupt state requires something like
   *
   *     setIe(getIe() & ~UCTXIE)          // turn of TX ie.
   *
   * The following provide a more optimized interface that directly references
   * the bit in question.  Generates better code.   Also some drivers have been
   * written using these interface specs while others with the direct register
   * access specs.
   */

  async command bool isRxIntrPending();
  async command void clrRxIntr();
  async command void disableRxIntr();
  async command void enableRxIntr();

  async command bool isTxIntrPending();
  async command void clrTxIntr();
  async command void disableTxIntr();
  async command void enableTxIntr();

  /*
   * The following are being deprecated.   They existed in the x1 USART
   * definitions and also the original x2 definitions.  They are broken
   * because the semantic is unclear.
   *
   *   async command void disableIntr();
   *   async command void enableIntr();
   *   async command void clrIntr();
   *
   * As the USCI modules became more sophisticated what interrupt is being
   * enabled or disabled.   This then warped into being simply a set/get
   * on the appropriate register.   So why have the sugar?
   */


  /*
   * TI h/w provides a busy bit.  return tx or rx is doing something
   *
   * This isn't really that useful.  This used to be called txEmpty on the x1
   * USART (where it really did represent that the tx path was empty) but that
   * isn't true on USCI modules.  Rather it indicates that tx, rx, or both are
   * active.  These paths are double buffered.
   *
   * For TX state machines (packet based etc), we want to know that all the bytes
   * went out, typically when switching resources.  For RX, we will have received
   * all the bytes we are interested in, so don't really care that the RX buffers in
   * the h/w are empty.
   *
   * In other words TI exchanged the txEmpty which worked for the isBusy which
   * doesn't really work.  Thanks, but no thanks, TI!
   */
  async command bool isBusy();


  /**
   * Reads the UCmxIV Interrupt Vector register.
   * This register is present on all USCI modules, and is used in all modes.
   * It is read-only.
   */
  async command uint8_t getIv();

  /* I2C bits
   *
   * set direction of the bus
   */
  async command void setTransmitMode();
  async command void setReceiveMode();

  /* Various I2C bits */
  async command bool getStopBit();
  async command bool getStartBit();
  async command bool getNackBit();
  async command bool getTransmitReceiveMode();

  /* transmit NACK, Stop, or Start condition, automatically cleared */
  async command void setTXNACK();
  async command void setTXStop();
  async command void setTXStart();

  async command bool isNackIntrPending();
  async command void clrNackIntr();

  /* ----------------------------------------
   * Higher-level operations consistent across all modes.
   */

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
   * functions.
   */
  async command void enterResetMode_ ();

  /**
   * Take the USCI out of software reset mode.
   * This command should only be invoked by modules that implement
   * specific USCI modes, in their mode-specific configuration
   * functions.
   */
  async command void leaveResetMode_ ();

  /**
   * Return an enumeration value indicating the currently configured USCI
   * mode.  Values are from the MSP430_USCI_Mode_e enumeration.
   */
  async command uint8_t currentMode ();
}
