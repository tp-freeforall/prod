/**
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

#include "msp430usci.h"
#include <I2C.h>
#include <stdio.h>

/**
 * Implement the I2C-related interfaces for a MSP430 USCI module
 * instance.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author Derek Baker <derek@red-slate.com>
 *   I2C support.
 */

generic module Msp430UsciI2CP () @safe() {
  provides {
    interface I2CPacket<TI2CBasicAddr>[uint8_t client];
    interface Msp430UsciError;
    interface ResourceConfigure[ uint8_t client ];
  }
  uses {
    interface HplMsp430Usci as Usci;
    interface HplMsp430UsciInterrupts as Interrupts;
    interface HplMsp430GeneralIO as SDA;
    interface HplMsp430GeneralIO as SCL;

    interface Msp430UsciConfigure[ uint8_t client ];

    interface ArbiterInfo;
    interface Leds;
  }
}
implementation {

  enum {
    TIMEOUT = 1000,
    WRITETIMEOUT = 100000,
  };

  /**
   * The I2C is busy if it's actively transmitting/receiving, or if
   * there is an active buffered I/O operation.
   */
  bool isBusy () {
    while (UCBUSY & (call Usci.getStat())) {
      ;/* busy-wait */
    }
    return 0;
  }

  /**
   * The given client is the owner if the USCI is in I2C mode and
   * the client is the user stored in the I2C arbiter.
   */
  error_t checkIsOwner (uint8_t client) {
    /* Ensure the USCI is in I2C mode and we're the owning client */
    if (! (call ArbiterInfo.inUse())) {
      return EOFF;
    }
    if ((call ArbiterInfo.userId() != client)) {
      return EBUSY;
    }
    return SUCCESS;
  }

  /**
   * Take the USCI out of I2C mode.
   *
   * Assumes the USCI is currently in I2C mode.  This will busy-wait
   * until any characters being actively transmitted or received are
   * out of their shift register.  It disables the interrupts, puts
   * the USCI into software resent, and returns the I2C-related pins
   * to their IO rather than module role.
   *
   * The USCI is left in software reset mode to avoid power drain per
   * CC430 errata UCS6.
   */
  void unconfigure_ () {
    while (UCBUSY & (call Usci.getStat())) {
      ;/* busy-wait */
    }

    call Usci.setIe(call Usci.getIe() & ~ (UCNACKIE | UCALIE | UCSTPIE | UCSTTIE | UCTXIE | UCRXIE));
    call Usci.enterResetMode_();
    call SDA.makeOutput();
    call SDA.selectIOFunc();
    call SCL.makeOutput();
    call SCL.selectIOFunc();
  }

  /**
   * Configure the USCI for I2C mode.
   *
   * Invoke the USCI configuration to set up the serial speed, but
   * leaves USCI in reset mode on completion.  This function then
   * follows up by setting the I2C-related pins to their module role
   * prior to taking the USCI out of reset mode.  All interrupts are
   * left off.
   */
  error_t configure_ (const msp430_usci_config_t* config) {
    if ( !config )
      return FAIL;

    /* Do basic configuration, leaving USCI in reset mode.  Configure
     * the I2C pins, enable the USCI, and turn off the interrupts.
     */
    call Usci.configure(config, TRUE);
    call SDA.selectModuleFunc();
    call SCL.selectModuleFunc();

    call Usci.leaveResetMode_();
    call Usci.setIe(call Usci.getIe() & ~ (UCNACKIE | UCALIE | UCSTPIE | UCSTTIE | UCTXIE | UCRXIE));
    return SUCCESS;
  }

  /**
   * Perform an I2C read operation
   *
   * @param flags Flags that may be logical ORed and defined by:
   *    I2C_START   - The START condition is transmitted at the beginning 
   *                   of the packet if set.
   *    I2C_STOP    - The STOP condition is transmitted at the end of the 
   *                   packet if set.
   *    I2C_ACK_END - ACK the last byte if set. Otherwise NACK last byte. This
   *                   flag cannot be used with the I2C_STOP flag.
   * @param addr The slave device address. Only used if I2C_START is set.
   * @param length Length, in bytes, to be read
   * @param 'uint8_t* COUNT(length) data' A point to a data buffer to read into
   *
   * @return SUCCESS if bus available and request accepted. 
   */
  async command error_t I2CPacket.read[uint8_t client] (i2c_flags_t flags, uint16_t addr, uint8_t length, uint8_t* data) {
    uint16_t i = 0;
    uint8_t m_rx_len = length;
    uint8_t * m_rx_buf = data;
    uint16_t m_rx_addr = addr;

    if ((flags & I2C_STOP) && (flags & I2C_ACK_END)) {		/*can only set one or the other*/
      m_rx_len = 0;
      signal I2CPacket.readDone[client](FAIL,m_rx_addr,m_rx_len,m_rx_buf);
      return FAIL;
    }

    if (flags & I2C_START) {
      call Usci.setReceiveMode();				/*put the uart into receive mode*/
      call Usci.setI2Csa(addr);					/*Set the Slave Address*/
      i=0;
      while (call Usci.getStopBit()) {
	if (i >= TIMEOUT) {
	  m_rx_len = 0;
	  signal I2CPacket.readDone[client](FAIL,m_rx_addr,m_rx_len,m_rx_buf);
	  return FAIL;
	}
	i++;
      }
      call Usci.setTXStart();					/*Set the uart to generate a repeat/start condition in receive mode*/
      i=0;
      while (call Usci.getStartBit()) {				/*we must test for the start bit, if we issue a stop before this we get an error*/
	if (i >= TIMEOUT) {
	  m_rx_len = 0;
	  signal I2CPacket.readDone[client](FAIL,m_rx_addr,m_rx_len,m_rx_buf);
	  return FAIL;
	}
	i++;
      }
    } else
      call Usci.setReceiveMode();				/*make sure the uart is in receive mode*/

    while (length > 0) {
      if((flags & I2C_STOP) && length == 1) {			/*if we are receiving last byte and we want to end send NACK->STOP*/
	call Usci.setTXStop();					/*Set the uart to generate a NACK->STOP*/
	i=0;
	while (call Usci.getStopBit()) {
	  if (i >= TIMEOUT) {
	    m_rx_len -= length;
	    signal I2CPacket.readDone[client](FAIL,m_rx_addr,m_rx_len,m_rx_buf);
	    return FAIL;
	  }
	  i++;
	}
      }
      i=0;
      while (call Usci.isRxIntrPending()==0) {			/*wait for RX of byte*/
	if (i >= TIMEOUT) {
	  m_rx_len -= length;
	  signal I2CPacket.readDone[client](FAIL,m_rx_addr,m_rx_len,m_rx_buf);
	  return FAIL;
	}
	i++;
      }
      *data++= call Usci.getRxbuf();				/*store in buffer*/
      length--;
    }

    if (flags & I2C_ACK_END) {					/*dont end the receive, we want to receive more*/
      m_rx_len -= length;
      signal I2CPacket.readDone[client](SUCCESS,m_rx_addr,m_rx_len,m_rx_buf);
      return SUCCESS;	
    }

    m_rx_len -= length;
    signal I2CPacket.readDone[client](SUCCESS,m_rx_addr,m_rx_len,m_rx_buf);
    return SUCCESS;						/*if I2C_STOP or I2C_ACK_END not set assume more to receive*/
  }

  /**
   * Perform an I2C write operation
   *
   * @param flags Flags that may be logical ORed and defined by:
   *    I2C_START   - The START condition is transmitted at the beginning 
   *                   of the packet if set.
   *    I2C_STOP    - The STOP condition is transmitted at the end of the 
   *                   packet if set.
   * @param addr The slave device address. Only used if I2C_START is set.
   * @param length Length, in bytes, to be read
   * @param 'uint8_t* COUNT(length) data' A point to a data buffer to read from
   *
   * @return SUCCESS if bus available and request accepted. 
   */
  async command error_t I2CPacket.write[uint8_t client] (i2c_flags_t flags, uint16_t addr, uint8_t length, uint8_t* data) {
    uint32_t i = 0;
    uint8_t m_tx_len = length;
    uint8_t * m_tx_buf = data;
    uint16_t m_tx_addr = addr;

    if(flags & I2C_START) {
      call Usci.setTransmitMode();				/*set transmit mode on i2c*/
      call Usci.setI2Csa(addr);					/*Set the Slave Address*/
      i=0;
      while (call Usci.getStopBit()) {
	if (i >= TIMEOUT) {
	  m_tx_len = 0;
	  signal I2CPacket.writeDone[client](FAIL,m_tx_addr,m_tx_len,m_tx_buf);
	  return FAIL;
	}
	i++;
      }
      call Usci.setTXStart();					/*Set the uart to generate a repeat/start condition in transmit mode*/
      while (call Usci.getStopBit()) {				/*the STOP bit is cleared when the slave acks the address*/
	if(i >= TIMEOUT+WRITETIMEOUT) {				/*Some devices use a start with no data to test if the device is ready for write*/
	  m_tx_len -= length;
	  signal I2CPacket.writeDone[client](FAIL,m_tx_addr,m_tx_len,m_tx_buf);
	  return FAIL;
	}
	i++;
      }
    } else
      call Usci.setTransmitMode();				/*Make sure the uart is in transmit mode*/

    while (length > 0) {
      call Usci.setTxbuf(*data++);				/*load byte to send*/
      i=0;
      while (call Usci.isTxIntrPending()==0) { 			/*wait for the Byte to be transmitted*/
	if (i >= TIMEOUT) {
	  m_tx_len -= length;
	  signal I2CPacket.writeDone[client](FAIL,m_tx_addr,m_tx_len,m_tx_buf);
	  return FAIL;
	}
	if ((call Usci.getIe()) == UCNACKIFG) {
	  m_tx_len -= length;
	  signal I2CPacket.writeDone[client](FAIL,m_tx_addr,m_tx_len,m_tx_buf);
	  return FAIL;
	}
	i++;
      }
      if((flags & I2C_STOP) && length == 1) {			/*if we are sending the last byte and we want to end send STOP*/
	call Usci.setTXStop();					/*Set the uart to generate a STOP*/
	i=0;
	while (call Usci.getStopBit()) {
	  if (i >= TIMEOUT) {
	    m_tx_len -= length;
	    signal I2CPacket.readDone[client](FAIL,m_tx_addr,m_tx_len,m_tx_buf);
	    return FAIL;
	  }
	  i++;
	}
      }
      length--;
    }

    m_tx_len -= length;
    signal I2CPacket.writeDone[client](SUCCESS,m_tx_addr,m_tx_len,m_tx_buf);

    return SUCCESS;
  }

  default async event void I2CPacket.readDone[uint8_t client] (error_t error, uint16_t addr, uint8_t length, uint8_t* data) { }

  default async event void I2CPacket.writeDone[uint8_t client] (error_t error, uint16_t addr, uint8_t length, uint8_t* data) { }

  /*
   * Interrupts currently not implemented.
   */
  async event void Interrupts.interrupted (uint8_t iv) {
    if ( !call ArbiterInfo.inUse())
      return;
    return;
  }

  default async command const msp430_usci_config_t*
      Msp430UsciConfigure.getConfiguration[uint8_t client]() {
    return &msp430_usci_i2c_default_config;
  }

  async command void ResourceConfigure.configure[uint8_t client]() {
    configure_(call Msp430UsciConfigure.getConfiguration[client]());
  }

  async command void ResourceConfigure.unconfigure[uint8_t client]() {
    unconfigure_();
  }

  default async event void Msp430UsciError.condition(unsigned int errors) { }
}
