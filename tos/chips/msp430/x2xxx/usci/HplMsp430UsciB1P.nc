/*
 * Copyright (c) 2010-2011 Eric B. Decker
 * Copyright (c) 2009-2010 DEXMA SENSORS SL
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * Copyright (c) 2004-2005, Technische Universitaet Berlin
 * All rights reserved.
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

#include "msp430usci.h"

/*
 * Implementation of Usci_B1 (spi or i2c) lowlevel functionality - stateless.
 * Setting a mode will by default disable USCI-Interrupts.
 *
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author: Jonathan Hui <jhui@archedrock.com>
 * @author: Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author: Joe Polastre
 * @author: Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 * @author: Xavier Orduna <xorduna@dexmatech.com>
 * @author: Eric B. Decker <cire831@gmail.com>
 * @author: Jordi Soucheiron <jsoucheiron@dexmatech.com>
 *
 * A0, A1: uart, spi, irda.
 * B0, B1: spi, i2c.
 *
 * This module interfaces to usciB1: spi or i2c.
 */

module HplMsp430UsciB1P @safe() {
  provides {
    interface HplMsp430UsciB as Usci;
    interface HplMsp430UsciInterrupts as Interrupts;
  }
  uses {
    interface HplMsp430GeneralIO as SIMO;
    interface HplMsp430GeneralIO as SOMI;
    interface HplMsp430GeneralIO as UCLK;
    interface HplMsp430GeneralIO as USDA;
    interface HplMsp430GeneralIO as USCL;
    interface HplMsp430UsciRawInterrupts as UsciRawInterrupts;
  }
}

implementation {
  MSP430REG_NORACE(UC1IE);
  MSP430REG_NORACE(UCB1CTL0);
  MSP430REG_NORACE(UCB1CTL1);
  MSP430REG_NORACE(UCB1STAT);
  MSP430REG_NORACE(UCB1I2COA);
  MSP430REG_NORACE(UCB1I2CSA);
  MSP430REG_NORACE(UCB1I2CIE);
  MSP430REG_NORACE(UC1IFG);
  MSP430REG_NORACE(UCB1TXBUF);
  MSP430REG_NORACE(UCB1RXBUF);

  async event void UsciRawInterrupts.rxDone(uint8_t temp) {
    signal Interrupts.rxDone(temp);
  }

  async event void UsciRawInterrupts.txDone() {
    signal Interrupts.txDone();
  }

  /* Control registers */
  async command void Usci.setUctl0(msp430_uctl0_t control) {
    UCB1CTL0 = uctl02int(control);
  }

  async command msp430_uctl0_t Usci.getUctl0() {
    return int2uctl0(UCB1CTL0);
  }

  async command void Usci.setUctl1(msp430_uctl1_t control) {
    UCB1CTL1 = uctl12int(control);
  }

  async command msp430_uctl1_t Usci.getUctl1() {
    return int2uctl1(UCB1CTL1);
  }

  /*
   * setUbr: change the Baud Rate divisor
   *
   * The BR registers are 2 bytes and accessed as two byte references.
   * We want it to be atomic.   On the x2xxx part can UBR be referenced
   * as a single atomic word?  NO.  (This is how it is done on the x5xxx).
   * For now we do it atomically and using two byte references (because
   * of the address space and according to TI documentation).
   */

  async command void Usci.setUbr(uint16_t control) {
    atomic {
      UCB1BR0 = control & 0x00FF;
      UCB1BR1 = (control >> 8) & 0x00FF;
    }
  }

  async command uint16_t Usci.getUbr() {
    atomic {
      return (UCB1BR1 << 8) + UCB1BR0;
    }
  }

  async command void Usci.setUstat(uint8_t control) {
    UCB1STAT = control;
  }

  async command uint8_t Usci.getUstat() {
    return UCB1STAT;
  }

  /*
   * Reset/unReset
   *
   * resetUsci(bool): (deprecated) TRUE puts device into reset, FALSE takes it out.  But this
   *   requires pushing the parameter on the stack and all those extra instructions.
   *
   * {un,}resetUsci_n(): reset and unreset the device but result in single instruction that
   *   sets or clears the appropriate bit in the h/w.
   */
  async command void Usci.resetUsci(bool reset) {
    if (reset)
      SET_FLAG(UCB1CTL1, UCSWRST);
    else
      CLR_FLAG(UCB1CTL1, UCSWRST);
  }

  async command void Usci.resetUsci_n() {
    SET_FLAG(UCB1CTL1, UCSWRST);
  }

  async command void Usci.unresetUsci_n() {
    CLR_FLAG(UCB1CTL1, UCSWRST);
  }

  bool isSpi() {
    msp430_uctl0_t tmp;

    tmp = int2uctl0(UCB1CTL0);
    return (tmp.ucsync && tmp.ucmode != 3);
  }

  async command bool Usci.isSpi() {
    return isSpi();
  }

  bool isI2C() {
    msp430_uctl0_t tmp;

    tmp = int2uctl0(UCB1CTL0);
    return (tmp.ucsync && tmp.ucmode == 3);
  }

  async command msp430_uscimode_t Usci.getMode() {
    if (isSpi())
      return USCI_SPI;
    if (isI2C())
      return USCI_I2C;
    return USCI_NONE;
  }

  async command void Usci.enableSpi() {
    atomic {
      call SIMO.selectModuleFunc();
      call SOMI.selectModuleFunc();
      call UCLK.selectModuleFunc();
    }
  }

  async command void Usci.disableSpi() {
    atomic {
      call SIMO.selectIOFunc();
      call SOMI.selectIOFunc();
      call UCLK.selectIOFunc();
    }
  }

  void configSpi(const msp430_spi_union_config_t* config) {
    UCB1CTL1 = (config->spiRegisters.uctl1 | UCSWRST);
    UCB1CTL0 = (config->spiRegisters.uctl0 | UCSYNC);
    call Usci.setUbr(config->spiRegisters.ubr);
    /* MCTL (modulation register) is zero'd on module reset
     * per TI MSP430x2xx User's Guide SLAUF, pg 16-16. */
  }

  /*
   * setModeSpi: configure the usci for spi mode
   *
   * note: make sure all interrupts are clear when taking the port
   * out of reset.  There is an assumption in the system that the
   * tx path needs a first write to fire off the interrupt system.
   *
   * Also note that resetting the usci will clear any interrupt enables
   * for the device.  Don't need to explicitly disableIntr.
   */
  async command void Usci.setModeSpi(const msp430_spi_union_config_t* config) {
    atomic {
      call Usci.resetUsci_n();
      call Usci.enableSpi();
      configSpi(config);
      call Usci.unresetUsci_n();
      call Usci.clrIntr();
    }
  }

  async command bool Usci.isTxIntrPending() {
    return (UC1IFG & UCB1TXIFG);
  }

  async command bool Usci.isRxIntrPending() {
    return (UC1IFG & UCB1RXIFG);
  }

  async command void Usci.clrTxIntr(){
    UC1IFG &= ~UCB1TXIFG;
  }

  /*
   * clear any pending RxIntr.
   *
   * We want to clean out atomically any pending rx interrupt pending.
   * This should also clean out any error bits that might have been set.
   * The best way to do this is to simply read the RXBUF.  The TI hardware
   * atomically cleans out any error indicators and the IFG.
   */
  async command void Usci.clrRxIntr() {
    call Usci.rx();
  }

  /*
   * clrIntr: clear all rx and tx interrupts
   *
   * clear any pending interrupts.  Intended to be used when
   * starting up a port and we want a pristine state.
   */
  async command void Usci.clrIntr() {
    atomic {
      call Usci.rx();			/* clean rx side out */
      UC1IFG &= ~UCB1TXIFG;		/* and turn off tx ifg */
    }
  }

  async command void Usci.disableRxIntr() {
    UC1IE &= ~UCB1RXIE;
  }

  async command void Usci.disableTxIntr() {
    UC1IE &= ~UCB1TXIE;
  }

  async command void Usci.disableIntr() {
    UC1IE &= ~(UCB1TXIE | UCB1RXIE);
  }

  async command void Usci.enableRxIntr() {
    UC1IE  |=  UCB1RXIE;
  }

  /*
   * enableTxIntr
   *
   * enable the usci tx h/w to interrupt.
   *
   * Note: The TI module when reset sets UCxxTXIFG so enabling the tx interrupt
   * would cause an interrupt.  Many implementations use this to cause
   * the output path to fire up.
   *
   * TinyOS however assumes that one needs to fire off the first byte and this
   * will cause a TX interrupt later which will fire up the output path.  We
   * clear out the pending tx interrupt.  The first byte must be forced out by
   * hand and then interrupts will continue the process.
   */
  async command void Usci.enableTxIntr() {
    atomic {
      UC1IFG &= ~UCB1TXIFG;
      UC1IE  |=  UCB1TXIE;
    }
  }

  /*
   * enableIntr: enable rx and tx interrupts
   * DEPRECATED.
   *
   * Doesn't make sense to do this.   RX and TX side get dealt with independently
   * so why would this ever get called?    Deprecate.
   *
   * First clear out any pending tx interrupt flags then set interrupt enables.
   * If there is a rx byte available then enabling the rx interrupt will kick.
   */
  async command void Usci.enableIntr() {
    atomic {
      UC1IFG &= ~UCB1TXIFG;		/* and tx side */
      UC1IE  |= (UCB1TXIE | UCB1RXIE);	/* enable both tx and rx */
    }
  }

  async command bool Usci.isBusy() {
    return (UCB1STAT & UCBUSY);
  }

  async command void Usci.tx(uint8_t data) {
    UCB1TXBUF = data;
  }

  /*
   * grab current Rx buf from the h/w.
   * This will also clear any pending error status bits.
   */
  async command uint8_t Usci.rx() {
    return UCB1RXBUF;
  }

  /*
   * i2c operations
   */
  async command bool Usci.isI2C(){
    return isI2C();
  }

  async command void Usci.enableI2C() {
    atomic {
 #ifdef PLATFORM_Z1
      /* Dirty, needs fixing */
        P5OUT &= ~0x06;
        P5REN &= ~0x06;
        P5OUT |= 0x06;
        P5REN |= 0x06;
      #endif
      call USDA.selectModuleFunc();
      call USCL.selectModuleFunc();
    }
  }

  async command void Usci.disableI2C() {
    atomic {
      call USDA.selectIOFunc();
      call USCL.selectIOFunc();
    }
  }

  void configI2C(const msp430_i2c_union_config_t* config) {
    UCB1CTL1 = (config->i2cRegisters.uctl1 | UCSWRST);
    UCB1CTL0 = (config->i2cRegisters.uctl0 | UCSYNC);
    call Usci.setUbr(config->i2cRegisters.ubr);
    UCB1I2COA = config->i2cRegisters.ui2coa;
    UCB1I2CSA = 0;
    UCB1I2CIE = 0;
  }

  async command void Usci.setModeI2C(const msp430_i2c_union_config_t* config) {
    atomic {
      call Usci.resetUsci_n();
      call Usci.enableI2C();
      configI2C(config);
      call Usci.unresetUsci_n();
      call Usci.clrIntr();
    }
  }

  /*
   * commands subsummed into config structure.
   *
   * setMasterMode,  setSlaveMode
   *
   * the get commands can be replaced by .getUctl0 etc.
   *
   * similar things should be done for the other registers.  It keeps things
   * simple and consise.
   */

  /* set direction of the bus */
  async command void Usci.setTransmitMode() { UCB1CTL1 |=  UCTR; }
  async command void Usci.setReceiveMode()  { UCB1CTL1 &= ~UCTR; }

  /* get stop bit in i2c mode */
  async command bool Usci.getStopBit() { return (UCB1CTL1 & UCTXSTP); }
  async command bool Usci.getTransmitReceiveMode() { return (UCB1CTL1 & UCTR); }

  /* transmit a NACK, Stop condition, or Start condition, automatically cleared */
  async command void Usci.setTXNACK()  { UCB1CTL1 |= UCTXNACK; }
  async command void Usci.setTXStop()  { UCB1CTL1 |= UCTXSTP;  }
  async command void Usci.setTXStart() { UCB1CTL1 |= UCTXSTT; }

  /*
   * get/set I2COA, Own Address register
   */
  async command uint16_t Usci.getOwnAddress() {
    return (UCB1I2COA & ~UCGCEN);
  }

  async command void Usci.setOwnAddress( uint16_t addr ) {
    atomic {
      UCB1I2COA &= UCGCEN;
      UCB1I2COA |= (addr & ~UCGCEN);
    }
  }

  /* set whether to respond to GeneralCall. */
  async command void Usci.clearGeneralCall() { UCB1I2COA &= ~UCGCEN; }
  async command void Usci.setGeneralCall()   { UCB1I2COA |=  UCGCEN; }

  /* get/set Slave Address, I2Csa */
  async command uint16_t Usci.getSlaveAddress()            { return UCB1I2CSA; }
  async command void Usci.setSlaveAddress( uint16_t addr ) { UCB1I2CSA = addr; }

  /* enable/disable NACK interrupt */
  async command void Usci.disableNACKInt() { UCB1I2CIE &= ~UCNACKIE; }
  async command void Usci.enableNACKInt()  { UCB1I2CIE |=  UCNACKIE; }

  /* enable/disable stop condition interrupt */
  async command void Usci.disableStopInt() { UCB1I2CIE &= ~UCSTPIE; }
  async command void Usci.enableStopInt()  { UCB1I2CIE |=  UCSTPIE; }

  /* enable/disable start condition interrupt */
  async command void Usci.disableStartInt() { UCB1I2CIE &= ~UCSTTIE; }
  async command void Usci.enableStartInt()  { UCB1I2CIE |=  UCSTTIE; }

  /* enable/disable arbitration lost interrupt */
  async command void Usci.disableArbLostInt() { UCB1I2CIE &= ~UCALIE; }
  async command void Usci.enableArbLostInt()  { UCB1I2CIE |=  UCALIE; }
}
