/*
 * Copyright (c) 2012-2013, Eric B. Decker
 * Copyright (c) 2011-2012 João Gonçalves
 * Copyright (c) 2009-2010 People Power Co.
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

/**
 * Implement the SPI-related interfaces for a MSP430 USCI module
 * instance.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author João Gonçalves <joao.m.goncalves@ist.utl.pt>
 * @author Eric B. Decker <cire831@gmail.com>
 */

generic module Msp430UsciSpiP () @safe() {
  provides {
    interface SpiPacket[ uint8_t client ];
    interface SpiBlock;
    interface SpiByte;
    interface Msp430UsciError;
    interface ResourceConfigure[ uint8_t client ];
  }
  uses {
    interface HplMsp430Usci as Usci;
    interface HplMsp430UsciInterrupts as Interrupts;
    interface HplMsp430GeneralIO as SIMO;
    interface HplMsp430GeneralIO as SOMI;
    interface HplMsp430GeneralIO as CLK;

    interface Msp430UsciConfigure[ uint8_t client ];
    interface ArbiterInfo;
  }
}
implementation {
  
  enum {
    SPI_ATOMIC_SIZE = 2,
  };

  norace uint16_t m_len;
  norace uint8_t* COUNT_NOK(m_len) m_tx_buf;
  norace uint8_t* COUNT_NOK(m_len) m_rx_buf;
  norace uint16_t m_pos;
  norace uint8_t m_client;
  
  void signalDone();
  
  task void signalDone_task() {
    atomic signalDone();
  }
  
  /** The SPI is busy if it's actively transmitting/receiving, or if
   * there is an active buffered I/O operation.
   */
  bool isBusy () {
    while (UCBUSY & (call Usci.getStat())) {
      ;/* busy-wait */
    }
    return 0;
  }

  /** The given client is the owner if the USCI is in SPI mode and
   * the client is the user stored in the SPI arbiter.
   */
  error_t checkIsOwner (uint8_t client) {
    /* Ensure the USCI is in SPI mode and we're the owning client */
    if (! (call ArbiterInfo.inUse())) {
      return EOFF;
    }
    if ((call ArbiterInfo.userId() != client)) {
      return EBUSY;
    }
    return SUCCESS;
  }

  /** Take the USCI out of SPI mode.
   *
   * Assumes the USCI is currently in SPI mode.  This will busy-wait
   * until any characters being actively transmitted or received are
   * out of their shift register.  The USCI is reset (which also
   * disables interrupts) and returns the SPI-related pins to their
   * IO function rather than module role.
   *
   * The USCI is left in software reset mode to avoid power drain.
   * Errata UCS6 doesn't apply as UCS6 only hits when in UART mode.
   */
  void unconfigure_ () {
    while (UCBUSY & (call Usci.getStat())) {
      ;/* busy-wait */
    }

    /* going into reset, clears all interrupt enables */
    call Usci.enterResetMode_();
    call SIMO.makeOutput();
    call SIMO.selectIOFunc();
    call SOMI.makeOutput();
    call SOMI.selectIOFunc();
    call CLK.makeOutput();
    call CLK.selectIOFunc();
  }

  /** Configure the USCI for SPI mode.
   *
   * Invoke the USCI configuration to set up the serial speed, but
   * leaves USCI in reset mode on completion.  This function then
   * follows up by setting the SPI-related pins to their module role
   * prior to taking the USCI out of reset mode.  All interrupts are
   * left off.
   */
  error_t configure_ (const msp430_usci_config_t* config) {
    if (! config) {
      return FAIL;
    }

    /*
     * Do basic configuration, leaving USCI in reset mode.  Configure
     * the SPI pins, enable the USCI, and leave interrupts off.
     */
    atomic {
      call Usci.configure(config, TRUE);
      call SIMO.makeOutput();
      call SIMO.selectModuleFunc();
      call SOMI.makeInput();
      call SOMI.selectModuleFunc();
      call CLK.makeOutput();
      call CLK.selectModuleFunc();

      /*
       * The IE bits are cleared when the USCI is reset, so there is no need
       * to clear the IE bits.
       */
      call Usci.leaveResetMode_();
    }
    return SUCCESS;
  }

  async command uint8_t SpiByte.write (uint8_t data) {
    uint8_t stat;

    while (! (UCTXIFG & call Usci.getIfg())) {
      ; /* busywait */
    }
    call Usci.setTxbuf(data);

    while (! (UCRXIFG & call Usci.getIfg())) {
      ; /* busywait */
    }
    stat = call Usci.getStat();
    data = call Usci.getRxbuf();
    stat = MSP430_USCI_ERR_UCxySTAT & (stat | (call Usci.getStat()));
    if (stat) {
      signal Msp430UsciError.condition(stat);
    }
    return data;
  }


  async command void SpiBlock.transfer(uint8_t* txBuf, uint8_t* rxBuf, uint16_t len) {
    uint8_t byt;

    while (len) {
      while (!call Usci.isTxIntrPending())
	;				/* busy wait */
      byt = 0;
      if (txBuf)
	byt = *txBuf++;
      call Usci.setTxbuf(byt);
      while (!call Usci.isRxIntrPending())
	;				/* busy wait */
      byt = call Usci.getRxbuf();
      if (rxBuf)
	*rxBuf++ = byt;
      len--;
    }
  }

  void continueOp() {
    uint8_t end;
    uint8_t tmp;

    atomic {
      call Usci.setTxbuf( m_tx_buf ? m_tx_buf[ m_pos ] : 0 );

      end = m_pos + SPI_ATOMIC_SIZE;
      if ( end > m_len )
	    end = m_len;

      while ( ++m_pos < end ) {
        while( !call Usci.isRxIntrPending() );
          tmp = call Usci.getRxbuf();
          if ( m_rx_buf )
            m_rx_buf[ m_pos - 1 ] = tmp;
          call Usci.setTxbuf( m_tx_buf ? m_tx_buf[ m_pos ] : 0 );
      }
    }
  }
   /** Split phase SpiPacket send
   * Implemented just as in the x2 usci Msp430SpiNoDmaP
   */
  
  async command error_t SpiPacket.send[uint8_t client] (uint8_t* txBuf, uint8_t* rxBuf, uint16_t len) {
    m_client = client;
    m_tx_buf = txBuf;
    m_rx_buf = rxBuf;
    m_len = len;
    m_pos = 0;

    if ( len ) {
      call Usci.enableRxIntr();
      continueOp();
    } else
      post signalDone_task();
    return SUCCESS;
  }


  void signalDone() {
    signal SpiPacket.sendDone[ m_client ]( m_tx_buf, m_rx_buf, m_len, SUCCESS );
  }


  async event void Interrupts.interrupted (uint8_t iv) {
    uint8_t data;

    if (! call ArbiterInfo.inUse()) {
      return;
    }
    if (USCI_UCRXIFG == iv) {
      data = call Usci.getRxbuf();
      if ( m_rx_buf )
        m_rx_buf[ m_pos-1 ] = data;
      if ( m_pos < m_len )
        continueOp();
      else {
        call Usci.disableRxIntr();
        signalDone();
      }
    } else if (USCI_UCTXIFG == iv) {
    }
  }


  default async event void SpiPacket.sendDone[uint8_t client] (uint8_t* txBuf,
			uint8_t* rxBuf, uint16_t len, error_t error ) { }

  default async command const msp430_usci_config_t*
    Msp430UsciConfigure.getConfiguration[uint8_t client] () {
      return &msp430_usci_spi_default_config;
  }

  async command void ResourceConfigure.configure[uint8_t client] () {
    configure_(call Msp430UsciConfigure.getConfiguration[client]());
  }

  async command void ResourceConfigure.unconfigure[uint8_t client] () {
    unconfigure_();
  }

  default async event void Msp430UsciError.condition(unsigned int errors) { }
  default async event void Msp430UsciError.timeout() { }
}
