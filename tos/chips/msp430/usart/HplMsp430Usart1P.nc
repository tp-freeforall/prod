/*
 * Copyright (c) 2011 Eric B. Decker
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
 *
 * Implementation of USART1 lowlevel functionality - stateless.
 * Setting a mode will by default disable USART-Interrupts.
 *
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Jonathan Hui <jhui@archedrock.com>
 * @author Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author Joe Polastre
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * Currently only supports x1 processors (msp430f149 and msp430f1611).
 * needs USART1 support, __MSP430_HAS_UART1__ which really is USART1.
 *
 * msp430usart.h checks for __MSP430_HAS_UART0__, and we check explicitly
 * for UART1 here.   We assume that to have USART1 one must also have UART0.
 * The header files for the 149 and 1611 do have UART0 and UART1 defined.
 */

#include "msp430usart.h"

#if !defined(__MSP430_HAS_UART1__)
#error "HplMsp430Usart1P: USART1/UART1 not supported on this processor"
#endif

module HplMsp430Usart1P {
  provides interface AsyncStdControl;
  provides interface HplMsp430Usart as Usart;
  provides interface HplMsp430UsartInterrupts as Interrupts;

  uses interface HplMsp430GeneralIO as SIMO;
  uses interface HplMsp430GeneralIO as SOMI;
  uses interface HplMsp430GeneralIO as UCLK;
  uses interface HplMsp430GeneralIO as URXD;
  uses interface HplMsp430GeneralIO as UTXD;
}

implementation
{
  MSP430REG_NORACE(IE2);
  MSP430REG_NORACE(ME2);
  MSP430REG_NORACE(IFG2);
  MSP430REG_NORACE(U1TCTL);
  MSP430REG_NORACE(U1RCTL);
  MSP430REG_NORACE(U1TXBUF);



  TOSH_SIGNAL(USART1RX_VECTOR) {
    uint8_t temp = U1RXBUF;
    signal Interrupts.rxDone(temp);
  }

  TOSH_SIGNAL(USART1TX_VECTOR) {
    signal Interrupts.txDone();
  }

  async command error_t AsyncStdControl.start() {
    return SUCCESS;
  }

  async command error_t AsyncStdControl.stop() {
    call Usart.disableSpi();
    call Usart.disableUart();
    return SUCCESS;
  }


  async command void Usart.setUctl(msp430_uctl_t control) {
    U1CTL=uctl2int(control);
  }

  async command msp430_uctl_t Usart.getUctl() {
    return int2uctl(U1CTL);
  }

  async command void Usart.setUtctl(msp430_utctl_t control) {
    U1TCTL=utctl2int(control);
  }

  async command msp430_utctl_t Usart.getUtctl() {
    return int2utctl(U1TCTL);
  }

  async command void Usart.setUrctl(msp430_urctl_t control) {
    U1RCTL=urctl2int(control);
  }

  async command msp430_urctl_t Usart.getUrctl() {
    return int2urctl(U1RCTL);
  }

  async command void Usart.setUbr(uint16_t control) {
    atomic {
      U1BR0 = control & 0x00FF;
      U1BR1 = (control >> 8) & 0x00FF;
    }
  }

  async command uint16_t Usart.getUbr() {
    return (U1BR1 << 8) + U1BR0;
  }

  async command void Usart.setUmctl(uint8_t control) {
    U1MCTL=control;
  }

  async command uint8_t Usart.getUmctl() {
    return U1MCTL;
  }

  async command void Usart.resetUsart(bool reset) {
    if (reset)
      U1CTL = SWRST;
    else
      CLR_FLAG(U1CTL, SWRST);
  }

  async command bool Usart.isSpi() {
    atomic {
      return (U1CTL & SYNC) && (U1ME & USPIE1);
    }
  }

  async command bool Usart.isUart() {
    atomic {
      return !(U1CTL & SYNC) && ((U1ME & UTXE1) && (U1ME & URXE1));
    }
  }

  async command bool Usart.isUartTx() {
    atomic {
      return !(U1CTL & SYNC) && (U1ME & UTXE1);
    }
  }

  async command bool Usart.isUartRx() {
    atomic {
      return !(U1CTL & SYNC) && (U1ME & URXE1);
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
    else
      return USART_NONE;
  }

  async command void Usart.enableUart() {
    atomic{
      call UTXD.selectModuleFunc();
      call URXD.selectModuleFunc();
    }
    U1ME |= (UTXE1 | URXE1);   // USART1 UART module enable
  }

  async command void Usart.disableUart() {
    atomic {
      U1ME &= ~(UTXE1 | URXE1);   // USART1 UART module enable
      call UTXD.selectIOFunc();
      call URXD.selectIOFunc();
    }

  }

  async command void Usart.enableUartTx() {
    call UTXD.selectModuleFunc();
    U1ME |= UTXE1;   // USART1 UART Tx module enable
  }

  async command void Usart.disableUartTx() {
    U1ME &= ~UTXE1;   // USART1 UART Tx module enable
    call UTXD.selectIOFunc();

  }

  async command void Usart.enableUartRx() {
    call URXD.selectModuleFunc();
    U1ME |= URXE1;   // USART1 UART Rx module enable
  }

  async command void Usart.disableUartRx() {
    U1ME &= ~URXE1;  // USART1 UART Rx module disable
    call URXD.selectIOFunc();

  }

  async command void Usart.enableSpi() {
    atomic {
      call SIMO.selectModuleFunc();
      call SOMI.selectModuleFunc();
      call UCLK.selectModuleFunc();
    }
    U1ME |= USPIE1;   // USART1 SPI module enable
  }

  async command void Usart.disableSpi() {
    atomic {
      U1ME &= ~USPIE1;   // USART1 SPI module disable
      call SIMO.selectIOFunc();
      call SOMI.selectIOFunc();
      call UCLK.selectIOFunc();
    }
  }

  void configSpi(const msp430_spi_union_config_t* config) {
    U1CTL = (config->spiRegisters.uctl) | SYNC | SWRST;  
    U1TCTL = config->spiRegisters.utctl;

    call Usart.setUbr(config->spiRegisters.ubr);
    call Usart.setUmctl(0x00);
  }


  async command void Usart.setModeSpi(const msp430_spi_union_config_t* config) {    
    atomic {
      call Usart.resetUsart(TRUE);
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

    U1CTL = (config->uartRegisters.uctl & ~SYNC) | SWRST;
    U1TCTL = config->uartRegisters.utctl;
    U1RCTL = config->uartRegisters.urctl;        
    
    call Usart.setUbr(config->uartRegisters.ubr);
    call Usart.setUmctl(config->uartRegisters.umctl);
  }

  async command void Usart.setModeUart(const msp430_uart_union_config_t* config) {
    atomic { 
      call Usart.resetUsart(TRUE);
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
      call Usart.disableIntr();
      call Usart.clrIntr();		/* clear after taking out of reset */
    }
    return;
  }

  async command bool Usart.isTxIntrPending(){
    if (U1IFG & UTXIFG1){
      return TRUE;
    }
    return FALSE;
  }

  async command bool Usart.isTxEmpty(){
    if (U1TCTL & TXEPT) {
      return TRUE;
    }
    return FALSE;
  }

  async command bool Usart.isRxIntrPending(){
    if (U1IFG & URXIFG1){
      return TRUE;
    }
    return FALSE;
  }

  async command void Usart.clrTxIntr(){
    U1IFG &= ~UTXIFG1;
  }

  async command void Usart.clrRxIntr() {
    U1IFG &= ~URXIFG1;
  }

  async command void Usart.clrIntr() {
    U1IFG &= ~(UTXIFG1 | URXIFG1);
  }

  async command void Usart.disableRxIntr() {
    U1IE &= ~URXIE1;
  }

  async command void Usart.disableTxIntr() {
    U1IE &= ~UTXIE1;
  }

  async command void Usart.disableIntr() {
      U1IE &= ~(UTXIE1 | URXIE1);
  }

  async command void Usart.enableRxIntr() {
    atomic {
      U1IFG &= ~URXIFG1;
      U1IE |= URXIE1;
    }
  }

  async command void Usart.enableTxIntr() {
    atomic {
      U1IFG &= ~UTXIFG1;
      U1IE |= UTXIE1;
    }
  }

  async command void Usart.enableIntr() {
    atomic {
      U1IFG &= ~(UTXIFG1 | URXIFG1);
      U1IE |= (UTXIE1 | URXIE1);
    }
  }

  async command void Usart.tx(uint8_t data) {
    U1TXBUF = data;
  }

  async command uint8_t Usart.rx() {
    return U1RXBUF;
  }

}
