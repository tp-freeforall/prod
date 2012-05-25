/*
 * Copyright (c) 2012 Eric B. Decker
 * Copyright (c) 2011 John Hopkins University
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
 *
 *
 * Implement the I2C-related interfaces for a MSP430 USCI module
 * instance.
 *
 * port of usci gen 1 (john hopkins) implementation of i2c
 *
 * @author Doug Carlson   <carlson@cs.jhu.edu>
 * @author Marcus Chang   <marcus.chang@gmail.com>
 * @author Peter A. Bigot <pab@peoplepowerco.com> 
 * @author Derek Baker    <derek@red-slate.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include <stdio.h>
#include "msp430usci.h"
#include <I2C.h>

generic module Msp430UsciI2CP () @safe() {
  provides {
    interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr[uint8_t client];
    interface I2CSlave[uint8_t client];
    interface ResourceConfigure[uint8_t client];
    interface Msp430UsciError[uint8_t client];
  }
  uses {
    interface HplMsp430Usci as Usci;
    interface HplMsp430UsciInterrupts as Interrupts;
    interface HplMsp430GeneralIO as SDA;
    interface HplMsp430GeneralIO as SCL;
    interface Msp430UsciConfigure[uint8_t client];
    interface ArbiterInfo;
    interface LocalTime<TMilli> as LocalTime_bms;
  }
}

implementation {
  enum{
    SLAVE = 0,
    MASTER_READ = 1,
    MASTER_WRITE = 2,
  };

  norace uint8_t* m_buf;
  norace uint8_t m_len;
  norace uint8_t m_pos;
  norace uint8_t m_action;
  norace i2c_flags_t m_flags;

  void showRegisters(); 
  void nextRead();
  void nextWrite();
  void signalDone( error_t error );

  void printRegisters(){
    printf("---\n\r");
    printf(" CTL0: %x\n\r", call Usci.getCtl0());
    printf(" CTL1: %x\n\r", call Usci.getCtl1());

    //printf(" CTLW: %x\n\r", call Usci.getCtlw0());
    //printf(" BRw:  %x\n\r", call Usci.getBrw());

    printf(" OA:   %x\n\r", call Usci.getI2coa());
    printf(" SA:   %x\n\r", call Usci.getI2csa());
    printf(" IE:   %x\n\r", call Usci.getIe());
    printf(" IFG:  %x\n\r", call Usci.getIfg());
    printf("---\n\r");
  }

  error_t configure_(const msp430_usci_config_t* config){
    if(! config){
      return FAIL;
    }

    //basic config (leave in reset)
    call Usci.configure(config, TRUE);

    //direction is don't-care in datasheet
    call SCL.selectModuleFunc();
    call SDA.selectModuleFunc();

    //i2c-specific config
    call Usci.setI2coa(config->i2coa);
    call Usci.leaveResetMode_();

    //enable slave-start interrupt, clear the rest
    call Usci.setIe((call Usci.getIe() & (BIT7|BIT6)) | UCSTTIE);
    return SUCCESS;
  }


  error_t slaveIdle(){

    //only reset if we are master: if we are already slave we don't
    //want to clear any state flags by accident.
    if (call Usci.getCtl0() & UCMST){
      call Usci.enterResetMode_();
      call Usci.setCtl0(call Usci.getCtl0() & ~UCMST);
      call Usci.leaveResetMode_();
    }

    //enable slave-start, clear the rest
    call Usci.setIe((call Usci.getIe() & (BIT7|BIT6)) | UCSTTIE);
    m_action = SLAVE;
    return SUCCESS;
  }

  error_t unconfigure_(){
    call Usci.enterResetMode_();
    call SCL.selectIOFunc();
    call SDA.selectIOFunc();
    return SUCCESS;
  }

  async command void ResourceConfigure.configure[ uint8_t client ]() {
    configure_(call Msp430UsciConfigure.getConfiguration[client]());
  }
  
  async command void ResourceConfigure.unconfigure[ uint8_t client ]() {
    unconfigure_();
  }
  
  /*************************************************************************/

  async command error_t I2CBasicAddr.read[uint8_t client]( i2c_flags_t flags,
					   uint16_t addr, uint8_t len, 
					   uint8_t* buf ) {

    //According to TI, we can just poll until the start condition
    //clears.  But we're nervous and want to bail out if it doesn't
    //clear fast enough.  This is how many times we loop before we
    //bail out.

    uint16_t counter = I2C_ONE_BYTE_READ_COUNTER;

    m_buf = buf;
    m_len = len;
    m_flags = flags;
    m_pos = 0;
    m_action = MASTER_READ;

    /* check if this is a new connection or a continuation */
    if (m_flags & I2C_START) {
      //TODO: if reset can be removed, can we consolidate this with
      //the repeated-start?
      call Usci.enterResetMode_();
      call Usci.setCtl0(call Usci.getCtl0() | UCMST);
      call Usci.leaveResetMode_();

      // set slave address 
      call Usci.setI2csa(addr);

      //check bus status at the latest point possible.
      if ( call Usci.getStat() & UCBBUSY ){
        //if the bus is busy, bail out real quick
        slaveIdle();
        return EBUSY;
      }
      //clear TR bit, set start condition
      call Usci.setCtl1( (call Usci.getCtl1()&(~UCTR))  | UCTXSTT);

      //enable i2c arbitration interrupts, rx, clear the rest
      call Usci.setIe( (call Usci.getIe() & (BIT7|BIT6)) | UCNACKIE |UCALIE |UCRXIE);

      /*
       * if only reading 1 byte, STOP bit must be set right after
       * START condition is triggered
       */
      if ( (m_len == 1) && (m_flags & I2C_STOP) ) {
        //this logic seems to work fine
        /* wait until START bit has been transmitted */
        while ((call Usci.getCtl1() & UCTXSTT) && (counter > 0x01)){
          counter--;
        }
        /* set stop bit */
        //UCB0CTL1 |= UCTXSTP;
        call Usci.setCtl1(call Usci.getCtl1() | UCTXSTP);
      }
    } else if (m_flags & I2C_RESTART) {
      /* set slave address */
      call Usci.setI2Csa(addr);

      //clear TR bit, start
      /* UCTXSTT - generate START condition */
      //UCB0CTL1 |= UCTXSTT;
      call Usci.setCtl1((call Usci.getCtl1() & ~UCTR) | UCTXSTT);

      //enable i2c arbitration interrupts, rx, clear the rest
      call Usci.setIe( (call Usci.getIe() & (BIT7|BIT6)) | UCNACKIE |UCALIE |UCRXIE);

      /* if only reading 1 byte, STOP bit must be set right after START bit */
      if ( (m_len == 1) && (m_flags & I2C_STOP) ) {
        /* wait until START bit has been transmitted */
        while ((call Usci.getCtl1() & UCTXSTT) && (counter > 0x01)){
          counter--;
        }
        /* set stop bit */
        //UCB0CTL1 |= UCTXSTP;
        call Usci.setCtl1(call Usci.getCtl1() | UCTXSTP);
      }
    } else {
      //TODO: test
      nextRead();
    }
    if (counter > 0x01){
      return SUCCESS;    
    } else {
      return FAIL;
    }
  }

  void nextRead() {
    uint16_t counter = 0xFFFF;

    if ((m_pos == (m_len - 2)) && m_len > 1) {
      //we want to send NACK + STOP in response to the last byte.
      //if m_pos == m_len-2 and we get the RX interrupt, that means
      //  that the slave has already written the next-to-last byte
      //  and we have acknowledged it--BUT we have not yet read it.
      //By setting the stop condition here, we say "send STOP after
      //the next byte," which will actually be the last byte.
      //
      //it is more intuitive to say "read the next-to-last byte and
      //set the STOP condition real quick before the last byte gets
      //sent so that we can NACK+STOP it". Maybe this would work if
      //you slowed down the I2C clock enough?
      call Usci.setCtl1(call Usci.getCtl1() | UCTXSTP);
    }
    /* read byte from RX buffer */
    m_buf[ m_pos++ ] = call Usci.getRxbuf();

    //TODO: this should check m_flags: if RESTART flag is present, we
    //should not send stop condition
    if (m_pos == m_len) {

      //when we receive the last byte, wait until STP condition is
      //cleared, then return.
      while( (call Usci.getCtl1() & UCTXSTP) && (counter > 0x01)) {
        counter --;
      }
      //switch back to slave mode, we're done
      slaveIdle();

      //disable the rx interrupt 
      call Usci.setIe(call Usci.getIe() & ~UCRXIE);
      if (counter > 0x01) {
        signal I2CBasicAddr.readDone[call ArbiterInfo.userId()]( SUCCESS, call Usci.getI2csa(), m_pos, m_buf );
      } else {
        signal I2CBasicAddr.readDone[call ArbiterInfo.userId()]( FAIL, call Usci.getI2csa() , m_pos, m_buf );
      }
    }
  }
  
  async command error_t I2CBasicAddr.write[uint8_t client]( i2c_flags_t flags,
					    uint16_t addr, uint8_t len,
					    uint8_t* buf ) {
    m_buf = buf;
    m_len = len;
    m_flags = flags;
    m_pos = 0;
    m_action = MASTER_WRITE;

    /* check if this is a new connection or a continuation */
    if (m_flags & I2C_START) {
      //sequence as described in 17.3.4.2.1 of slau144h is:
      // - set sa
      // - set UCTR
      // - set UCTXSTT
      // (start/address written, then we get an interrupt)
      // no reset should be necessary for this process. however, when
      // I did it in a different sequence, the first write worked OK
      // but the second one began with the UCSTPIFG set, and the first
      // character was dropped. I have no explanation for why this
      // would be the case.

      //need to enter master mode
      call Usci.enterResetMode_();
      call Usci.setCtl0(call Usci.getCtl0() | UCMST);
      call Usci.leaveResetMode_();

      // set slave address 
      call Usci.setI2csa(addr);

      //check bus status at the latest point possible.
      if ( call Usci.getStat() & UCBBUSY ){
        //if the bus is busy, bail out real quick
        slaveIdle();
        return EBUSY;
      }

      // UCTXSTT - generate START condition 
      call Usci.setCtl1(call Usci.getCtl1() | UCTR | UCTXSTT);

      //enable relevant state interrupts and TX, clear the rest
      //while ( call Usci.getCtl1() & UCTXSTT){}
      call Usci.setIe((call Usci.getIe() & (BIT7|BIT6)) | UCNACKIE | UCALIE | UCTXIE);
    } 
    /* is this a restart or a direct continuation */
    else if (m_flags & I2C_RESTART) {
      // set slave address 
      call Usci.setI2csa(addr);

      /* UCTR - set transmit */
      /* UCTXSTT - generate START condition */
      call Usci.setCtl1(call Usci.getCtl1() | UCTR | UCTXSTT);
      //do we not need to enable any interrupts here?
    } else {
      // continue writing next byte 
      nextWrite();
    }
    return SUCCESS;    
  }

  void nextWrite() {
    uint16_t counter = 0xFFFF;

    //Hey, now here's a fun thing to do:
    //  It seems like if two masters set START at almost the same
    //  time, they both get the TX interrupt, so both write their 0th
    //  byte into the TX buffer. However, only one of them actually
    //  writes it out, and no arbitration-loss interrupt is raised for
    //  the "slow" one. When the "fast" one finishes its transaction,
    //  the slow one gets a second TX interrupt, which would cause us
    //  to skip over the first byte by accident. This checks for the
    //  issue and rewinds the buffer position to 0 if it applies.  I
    //  make no guarantees about how stable this behavior is.

    if ( call Usci.getCtl1() & UCTXSTT) {
      m_pos = 0;
    }

    /* all bytes sent */
    if ( m_pos == m_len ) {
      /* not setting STOP bit allows restarting transfer */
      if ( m_flags & I2C_STOP ) {
        /* set stop bit */
        call Usci.setCtl1(call Usci.getCtl1() | UCTXSTP);

        /* wait until STOP bit has been transmitted */
        while ((call Usci.getCtl1() & UCTXSTP) && (counter > 0x01)) {
          counter--;
        }

        //STOPping and just finished last send, so we should go back
        //to slave mode.

        slaveIdle();
      } else {
        //so, we just don't send the STOP bit.
      }

      //disable tx interrupt, we're DONE 
      call Usci.setIe(call Usci.getIe() & ~UCTXIE );
      /* fail gracefully */      
      if (counter > 0x01) {
        signal I2CBasicAddr.writeDone[call ArbiterInfo.userId()]( SUCCESS, call Usci.getI2csa(), m_len, m_buf );
      } else{
        signal I2CBasicAddr.writeDone[call ArbiterInfo.userId()]( FAIL, call Usci.getI2csa(), m_len, m_buf );
      }
    } else {
      //send the next char
      call Usci.setTxbuf(m_buf[ m_pos++ ]);
    }
  }


  async command void I2CSlave.slaveTransmit[uint8_t clientId](uint8_t data) {
    //TODO: safety
    //write it, reenable interrupt (if it was disabled)
    call Usci.setTxbuf(data);
    call Usci.setIe(call Usci.getIe() | UCTXIE);
  }


  async command uint8_t I2CSlave.slaveReceive[uint8_t client]() {
    //re-enable rx interrupt, read the byte
    call Usci.setIe(call Usci.getIe() | UCRXIE);
    return call Usci.getRxbuf();
  }
  

  //defaults
  default async event void I2CBasicAddr.readDone[uint8_t client](error_t error, uint16_t addr, uint8_t length, uint8_t* data)  {}
  default async event void I2CBasicAddr.writeDone[uint8_t client](error_t error, uint16_t addr, uint8_t length, uint8_t* data) {}
  default async command const msp430_usci_config_t* Msp430UsciConfigure.getConfiguration[uint8_t client]() {
    return &msp430_usci_i2c_default_config;
  }

  /***** Slave-mode functions ***/
  command error_t I2CSlave.setOwnAddress[uint8_t client](uint16_t addr) {
    //retain UCGCEN bit
    call Usci.setI2coa( (call Usci.getI2coa() & UCGCEN) | addr);
    return SUCCESS;
  }

  command error_t I2CSlave.enableGeneralCall[uint8_t client]() {
    if (UCGCEN & (call Usci.getI2coa())) {
      return EALREADY;
    } else {
      call Usci.setI2coa(UCGCEN | (call Usci.getI2coa()));
      return SUCCESS;
    }
  }

  command error_t I2CSlave.disableGeneralCall[uint8_t client]() {
    if (UCGCEN & ~(call Usci.getI2coa())) {
      return EALREADY;
    } else {
      call Usci.setI2coa(~UCGCEN & (call Usci.getI2coa()));
      return SUCCESS;
    }
  }

  //END USCI_GEN1 PORTED CODE
  default async event bool I2CSlave.slaveReceiveRequested[uint8_t client]()  { return FALSE; }
  default async event bool I2CSlave.slaveTransmitRequested[uint8_t client]() { return FALSE; }

  default async event void I2CSlave.slaveStart[uint8_t client](bool isGeneralCall) { ; }
  default async event void I2CSlave.slaveStop[uint8_t client]() { ; }

  /***************************************************************************/

  void TXInterrupts_interrupted(uint8_t iv);
  void RXInterrupts_interrupted(uint8_t iv);
  void StateInterrupts_interrupted(uint8_t iv);
  void NACK_interrupt();
  void AL_interrupt();
  void STP_interrupt();
  void STT_interrupt();

  async event void Interrupts.interrupted(uint8_t iv) {
    switch(iv) {
      case USCI_I2C_UCALIFG:
        AL_interrupt();
        break;
      case USCI_I2C_UCNACKIFG:
        NACK_interrupt();
        break;
      case USCI_I2C_UCSTTIFG:
        STT_interrupt();
        break;
      case USCI_I2C_UCSTPIFG:
        STP_interrupt();
        break;
      case USCI_I2C_UCRXIFG:
        RXInterrupts_interrupted(call Usci.getIfg());
        break;
      case USCI_I2C_UCTXIFG:
        TXInterrupts_interrupted(call Usci.getIfg());
        break;
      default:
        //error
        break;
    }
  }

  void TXInterrupts_interrupted(uint8_t iv) {
    /* if master mode */
    if (call Usci.getCtl0() & UCMST) {
      nextWrite();
    } else {
      if (signal I2CSlave.slaveTransmitRequested[call ArbiterInfo.userId()]()) {
        //true= "I'm responding RIGHT NOW"
        // note that when this interrupt context ends, txinterrupt
        // will be raised again.
      } else {
        //false= "I need to pause for a second"
        //disable TX interrupt.
        call Usci.setIe(call Usci.getIe() & ~UCTXIE);
      }
    }
  }

  void RXInterrupts_interrupted(uint8_t iv) {
    /* if master mode */
    if (call Usci.getCtl0() & UCMST) {
      nextRead();
    } else {
      if (signal I2CSlave.slaveReceiveRequested[call ArbiterInfo.userId()]()) {
        //TRUE: they're responding immediately (should have actually
        //already responded at this point). 
      } else {
        //FALSE: disable the RX interrupt, since the client needs to
        //do some work
        call Usci.setIe(call Usci.getIe() & ~UCRXIE);
      }
    }
  }


  void NACK_interrupt() {
    uint8_t counter = 0xff;

    //This occurs during write and read when no ack is received.
    /* set stop bit */
    call Usci.setCtl1(call Usci.getCtl1() | UCTXSTP);

    /* wait until STOP bit has been transmitted */
    while ((call Usci.getCtl1() & UCTXSTP) && (counter > 0x01)) {
      counter--;
    }
    call Usci.enterResetMode_();
    call Usci.leaveResetMode_();
    //back to slave idle mode
    slaveIdle();

    //signal appropriate event depending on whether we were
    //transmitting or receiving
    //Note that TR will be cleared if we lost MM arbitration because
    //another master addressed us as a slave. However, this should
    //manifest as an AL interrupt, not a NACK interrupt.
    if (call Usci.getCtl1() & UCTR) {
      signal I2CBasicAddr.writeDone[call ArbiterInfo.userId()]( ENOACK, call Usci.getI2csa(), m_len, m_buf );
    } else {
      signal I2CBasicAddr.readDone[call ArbiterInfo.userId()]( ENOACK, call Usci.getI2csa(), m_len, m_buf );
    }
  }

  void AL_interrupt() {
    uint8_t lastAction = m_action;

    slaveIdle();

    //clear AL flag
    call Usci.setStat(call Usci.getStat() & ~(UCALIFG));

    //TODO: more descriptive error? I guess EBUSY is fair.
    if(lastAction == MASTER_WRITE) {
      signal I2CBasicAddr.writeDone[call ArbiterInfo.userId()]( EBUSY, call Usci.getI2csa(), m_len, m_buf );
    } else if(lastAction == MASTER_READ) {
      signal I2CBasicAddr.readDone[call ArbiterInfo.userId()]( EBUSY, call Usci.getI2csa(), m_len, m_buf);
    }

    //once this returns, we should get another interrupt for STT
    //if we are addressed. Otherwise, we're just chillin' in idle
    //slave mode as per usual.
  }

  void STP_interrupt() {

    /* disable STOP interrupt, enable START interrupt */
    call Usci.setIe((call Usci.getIe() | UCSTTIE) & ~UCSTPIE);

    //this is ugly: the stop interrupt has higher priority than RX.
    //It appears to be the case that since we get the RX interrupt as
    //soon as the byte is received, and the STP interrupt as soon as
    //the stop condition is received, there is a very short window
    //where we have the RX but not the STP, and we tend to see the
    //stop interrupt first.  This will surely confound upper-level
    //logic (it would see a stop, then another byte), so we reverse
    //the priority for this case in software.

    if (call Usci.getIfg() & UCRXIFG & call Usci.getIe()) {
      RXInterrupts_interrupted(call Usci.getIfg());
    }
    signal I2CSlave.slaveStop[call ArbiterInfo.userId()]();
  }
  
  void STT_interrupt() {

    //clear start flag, but leave enabled (repeated start)
    //enable stop interrupt
    //enable RX/TX interrupts

    call Usci.setStat(call Usci.getStat() &~ UCSTTIFG);

    //This is the same issue as noted in the STP_interrupt above, but
    //applied to repeated start conditions.

    if (call Usci.getIfg() & UCRXIFG & call Usci.getIe() ) {
      RXInterrupts_interrupted(call Usci.getIfg());
    }
    call Usci.setIe(call Usci.getIe() | UCSTPIE | UCRXIE | UCTXIE);
    signal I2CSlave.slaveStart[call ArbiterInfo.userId()]( call Usci.getStat() & UCGC);
  }
}
