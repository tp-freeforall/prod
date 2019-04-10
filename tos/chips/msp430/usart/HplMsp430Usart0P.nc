/*
 * Copyright (c) 2011 Eric B. Decker
 * Copyright (c) 2005-2006 Arched Rock Corporation
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
 *
 * Implementation of USART0 lowlevel functionality - stateless.
 * Setting a mode will by default disable USART-Interrupts.
 *
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Jonathan Hui <jhui@archedrock.com>
 * @author Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author Joe Polastre
 * @author Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * Currently only supports x1 processors (msp430f149 and msp430f1611).
 * needs USART0 support, __MSP430_HAS_UART0__ which really is USART0.
 *
 * msp430usart.h checks for __MSP430_HAS_UART0__.
 */

#include "msp430usart.h"

module HplMsp430Usart0P @safe() {
  provides interface HplMsp430Usart as Usart;
  provides interface HplMsp430UsartInterrupts as Interrupts;
  provides interface HplMsp430I2CInterrupts as I2CInterrupts;
  
  uses interface HplMsp430I2C as HplI2C;
  uses interface HplMsp430GeneralIO as SIMO;
  uses interface HplMsp430GeneralIO as SOMI;
  uses interface HplMsp430GeneralIO as UCLK;
  uses interface HplMsp430GeneralIO as URXD;
  uses interface HplMsp430GeneralIO as UTXD;
}

implementation
{
#if defined(__msp430x12x2)
  MSP430REG_NORACE(IE2);
  MSP430REG_NORACE(ME2);
  MSP430REG_NORACE(IFG2);
#else
  MSP430REG_NORACE(IE1);
  MSP430REG_NORACE(ME1);
  MSP430REG_NORACE(IFG1);
#endif
  MSP430REG_NORACE(U0TCTL);
  MSP430REG_NORACE(U0RCTL);
  MSP430REG_NORACE(U0TXBUF);
  
  TOSH_SIGNAL(USART0RX_VECTOR) {
    uint8_t temp = U0RXBUF;
    signal Interrupts.rxDone(temp);
  }
  
  TOSH_SIGNAL(USART0TX_VECTOR) {
    if ( call HplI2C.isI2C() )
      signal I2CInterrupts.fired();
    else
      signal Interrupts.txDone();
  }
  
  async command void Usart.setUctl(msp430_uctl_t control) {
    U0CTL=uctl2int(control);
  }

  async command msp430_uctl_t Usart.getUctl() {
    return int2uctl(U0CTL);
  }

  async command void Usart.setUtctl(msp430_utctl_t control) {
    U0TCTL=utctl2int(control);
  }

  async command msp430_utctl_t Usart.getUtctl() {
    return int2utctl(U0TCTL);
  }

  async command void Usart.setUrctl(msp430_urctl_t control) {
    U0RCTL=urctl2int(control);
  }

  async command msp430_urctl_t Usart.getUrctl() {
    return int2urctl(U0RCTL);
  }

  async command void Usart.setUbr(uint16_t control) {
    atomic {
      U0BR0 = control & 0x00FF;
      U0BR1 = (control >> 8) & 0x00FF;
    }
  }

  async command uint16_t Usart.getUbr() {
    return (U0BR1 << 8) + U0BR0;
  }

  async command void Usart.setUmctl(uint8_t control) {
    U0MCTL=control;
  }

  async command uint8_t Usart.getUmctl() {
    return U0MCTL;
  }

  async command void Usart.resetUsart(bool reset) {
    if (reset) {
      U0CTL = SWRST;
    }
    else {
      CLR_FLAG(U0CTL, SWRST);
    }
  }

  async command bool Usart.isSpi() {
    atomic {
      return (U0CTL & SYNC) && (U0ME & USPIE0);
    }
  }

  async command bool Usart.isUart() {
    atomic {
      return !(U0CTL & SYNC) && ((U0ME & UTXE0) && (U0ME & URXE0));
    }
  }

  async command bool Usart.isUartTx() {
    atomic {
      return !(U0CTL & SYNC) && (U0ME & UTXE0);
    }
  }

  async command bool Usart.isUartRx() {
    atomic {
      return !(U0CTL & SYNC) && (U0ME & URXE0);
    }
  }

  async command msp430_usartmode_t Usart.getMode() {
    if (call Usart.isUart())
      return USART_UART;
    else if (call Usart.isUartRx())
      return USART_UART_RX;
    else if (call Usart.isUartTx())
      return USART_UART_TX;
    else if (call Usart.isSpi())
      return USART_SPI;
    else if (call HplI2C.isI2C())
      return USART_I2C;
    else
      return USART_NONE;
  }

  async command void Usart.enableUart() {
    atomic{
      call UTXD.selectModuleFunc();
      call URXD.selectModuleFunc();
    }
    U0ME |= (UTXE0 | URXE0);   // USART0 UART module enable
  }

  async command void Usart.disableUart() {
    atomic {
      U0ME &= ~(UTXE0 | URXE0);   // USART0 UART module enable
      call UTXD.selectIOFunc();
      call URXD.selectIOFunc();
    }

  }

  async command void Usart.enableUartTx() {
    call UTXD.selectModuleFunc();
    U0ME |= UTXE0;   // USART0 UART Tx module enable
  }

  async command void Usart.disableUartTx() {
    U0ME &= ~UTXE0;   // USART0 UART Tx module enable
    call UTXD.selectIOFunc();

  }

  async command void Usart.enableUartRx() {
    call URXD.selectModuleFunc();
    U0ME |= URXE0;   // USART0 UART Rx module enable
  }

  async command void Usart.disableUartRx() {
    U0ME &= ~URXE0;  // USART0 UART Rx module disable
    call URXD.selectIOFunc();

  }

  async command void Usart.enableSpi() {
    atomic {
      call SIMO.selectModuleFunc();
      call SOMI.selectModuleFunc();
      call UCLK.selectModuleFunc();
    }
    U0ME |= USPIE0;   // USART0 SPI module enable
  }

  async command void Usart.disableSpi() {
    atomic {
      U0ME &= ~USPIE0;   // USART0 SPI module disable
      call SIMO.selectIOFunc();
      call SOMI.selectIOFunc();
      call UCLK.selectIOFunc();
    }
  }
  
  void configSpi(const msp430_spi_union_config_t* config) {
    // U0CTL = (config->spiRegisters.uctl & ~I2C) | SYNC | SWRST;
    U0CTL = (config->spiRegisters.uctl) | SYNC | SWRST;  
    U0TCTL = config->spiRegisters.utctl;

    call Usart.setUbr(config->spiRegisters.ubr);
    call Usart.setUmctl(0x00);
  }

  async command void Usart.setModeSpi(const msp430_spi_union_config_t* config) {
    atomic {
    	call Usart.resetUsart(TRUE);
    	call HplI2C.clearModeI2C();
    	call Usart.disableUart();
      configSpi(config);
      call Usart.enableSpi();
      call Usart.resetUsart(FALSE);
      call Usart.clrIntr();
      call Usart.disableIntr();
    }    
    return;
  }

  void configUart(const msp430_uart_union_config_t* config) {

    U0CTL = (config->uartRegisters.uctl & ~SYNC) | SWRST;
    U0TCTL = config->uartRegisters.utctl;
    U0RCTL = config->uartRegisters.urctl;        
    
    call Usart.setUbr(config->uartRegisters.ubr);
    call Usart.setUmctl(config->uartRegisters.umctl);
  }

  async command void Usart.setModeUart(const msp430_uart_union_config_t* config) {
    atomic { 
      call Usart.resetUsart(TRUE);
     	call HplI2C.clearModeI2C();
    	call Usart.disableSpi();
      configUart(config);
      if ((config->uartConfig.utxe == 1) && (config->uartConfig.urxe == 1)) {
      	call Usart.enableUart();
      } else if ((config->uartConfig.utxe == 0) && (config->uartConfig.urxe == 1)) {
        call Usart.disableUartTx();
        call Usart.enableUartRx();
      } else if ((config->uartConfig.utxe == 1) && (config->uartConfig.urxe == 0)){
        call Usart.disableUartRx();
        call Usart.enableUartTx();
      } else {
        call Usart.disableUart();
      }
      call Usart.resetUsart(FALSE);
      call Usart.clrIntr();
      call Usart.disableIntr();
    }
    return;
  }

  async command bool Usart.isTxIntrPending(){
    if (U0IFG & UTXIFG0){
      return TRUE;
    }
    return FALSE;
  }

  async command bool Usart.isTxEmpty(){
    if (U0TCTL & TXEPT) {
      return TRUE;
    }
    return FALSE;
  }

  async command bool Usart.isRxIntrPending(){
    if (U0IFG & URXIFG0){
      return TRUE;
    }
    return FALSE;
  }

  async command void Usart.clrTxIntr(){
    U0IFG &= ~UTXIFG0;
  }

  async command void Usart.clrRxIntr() {
    U0IFG &= ~URXIFG0;
  }

  async command void Usart.clrIntr() {
    U0IFG &= ~(UTXIFG0 | URXIFG0);
  }

  async command void Usart.disableRxIntr() {
    U0IE &= ~URXIE0;
  }

  async command void Usart.disableTxIntr() {
    U0IE &= ~UTXIE0;
  }

  async command void Usart.disableIntr() {
      U0IE &= ~(UTXIE0 | URXIE0);
  }

  async command void Usart.enableRxIntr() {
    atomic {
      U0IFG &= ~URXIFG0;
      U0IE |= URXIE0;
    }
  }

  async command void Usart.enableTxIntr() {
    atomic {
      U0IFG &= ~UTXIFG0;
      U0IE |= UTXIE0;
    }
  }

  async command void Usart.enableIntr() {
    atomic {
      U0IFG &= ~(UTXIFG0 | URXIFG0);
      U0IE |= (UTXIE0 | URXIE0);
    }
  }

  async command void Usart.tx(uint8_t data) {
    U0TXBUF = data;
  }

  async command uint8_t Usart.rx() {
    return U0RXBUF;
  }

  default async event void I2CInterrupts.fired() {}
  default async command bool HplI2C.isI2C() { return FALSE; }
  default async command void HplI2C.clearModeI2C() {};
  
}
