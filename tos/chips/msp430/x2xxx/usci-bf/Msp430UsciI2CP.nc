/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Marcus Chang <marcus.chang@cs.jhu.edu>
 * @author Doug Carlson <carlson@cs.jhu.edu>
 * @version $Revision$ $Date$
 */

#include <I2C.h>
#include <stdio.h>

generic module Msp430UsciI2CP(uint8_t TXIE_MASK, uint8_t RXIE_MASK, uint8_t TXIFG_MASK, uint8_t RXIFG_MASK) {

  provides interface ResourceConfigure[ uint8_t client ];
  provides interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr[uint8_t client];
  provides interface I2CSlave[uint8_t client];
  provides interface Msp430UsciError[uint8_t client];

  uses interface HplMsp430UsciInterrupts as StateInterrupts;
  uses interface HplMsp430UsciInterrupts as RXInterrupts;
  uses interface HplMsp430UsciInterrupts as TXInterrupts;

  uses interface HplMsp430GeneralIO as SDA;
  uses interface HplMsp430GeneralIO as SCL;

  uses interface HplMsp430Usci as Usci;
  uses interface HplMsp430UsciB as UsciB;
  uses interface Msp430UsciConfigure[ uint8_t client ];
  uses interface ArbiterInfo;
  uses interface LocalTime<TMilli> as LocalTime_bms;
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


  void pdbg(uint8_t v){
    atomic{
      P6OUT = 0x00;
      P6OUT = v;
    }
  }


  error_t configure_(const msp430_usci_config_t* config){
    if(! config){
      return FAIL;
    }
    // basic config (leave in reset)
    call Usci.configure(config, TRUE);

    /*
     * direction is don't-care in datasheet
     * That is because the pins are assigned to the Module
     */
    call SCL.selectModuleFunc();
    call SDA.selectModuleFunc();

    //i2c-specific config
    call UsciB.setI2Coa(config->i2coa);
    call Usci.leaveResetMode_();

    //enable slave-start interrupt
    call UsciB.setI2Cie(UCSTTIE);
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
    call UsciB.setI2Cie(UCSTTIE);
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
    uint16_t counter;
    //TODO: should be address length-dependent
    if (addr & 0xff80){
      return EINVAL;
    }

    //TODO: check for resource ownership and fail if it's not valid!
    //According to TI, we can just poll until the start condition
    //clears.  But we're nervous and want to bail out if it doesn't
    //clear fast enough.  This is how many times we loop before we
    //bail out.
    counter = I2C_ONE_BYTE_READ_COUNTER;
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
      call UsciB.setI2Csa(addr);
      //check bus status at the latest point possible.
      if ( call Usci.getStat() & UCBBUSY ){
        //if the bus is busy, bail out real quick
        slaveIdle();
        return EBUSY;
      }
       //clear TR bit, set start condition
      call Usci.setCtl1( (call Usci.getCtl1()&(~UCTR))  | UCTXSTT);

      //enable i2c arbitration interrupts, rx 
      call UsciB.setI2Cie((call UsciB.getI2Cie() & 0xf0) | UCNACKIE | UCALIE);
      call Usci.setIe( call Usci.getIe() | RXIE_MASK );

      /* if only reading 1 byte, STOP bit must be set right after
       * START condition is triggered */
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
      call UsciB.setI2Csa(addr);

      //clear TR bit, start
      /* UCTXSTT - generate START condition */
      //UCB0CTL1 |= UCTXSTT;
      call Usci.setCtl1((call Usci.getCtl1() & ~UCTR) | UCTXSTT);

      //enable i2c arbitration interrupts, rx 
      call UsciB.setI2Cie((call UsciB.getI2Cie() & 0xf0) | UCNACKIE | UCALIE);
      call Usci.setIe( call Usci.getIe() | RXIE_MASK );

      /* if only reading 1 byte, STOP bit must be set right after START bit */
      if ( (m_len == 1) && (m_flags & I2C_STOP) ) {
        /* wait until START bit has been transmitted */
        while ((call Usci.getCtl1() & UCTXSTT) && (counter > 0x01)){
          counter--;
        }
        /* set stop bit */
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
      while( (call Usci.getCtl1() & UCTXSTP) && (counter > 0x01)){
        counter --;
      }
      //switch back to slave mode, we're done
      slaveIdle();

      //disable the rx interrupt 
      call Usci.setIe(call Usci.getIe() & ~RXIE_MASK);
      if (counter > 0x01){
        signal I2CBasicAddr.readDone[call ArbiterInfo.userId()]( SUCCESS, call UsciB.getI2Csa(), m_pos, m_buf );
      } else {
        signal I2CBasicAddr.readDone[call ArbiterInfo.userId()]( FAIL, call UsciB.getI2Csa() , m_pos, m_buf );
      }
    }
  }


  async command error_t I2CBasicAddr.write[uint8_t client]( i2c_flags_t flags,
					    uint16_t addr, uint8_t len,
					    uint8_t* buf ) {
    //TODO: should be address length-dependent
    if (addr & 0xff80){
      return EINVAL;
    }

    //TODO: check for resource ownership and fail if it's not valid!
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
      call UsciB.setI2Csa(addr);

      //check bus status at the latest point possible.
      if ( call Usci.getStat() & UCBBUSY ){
        //if the bus is busy, bail out real quick
        slaveIdle();
        return EBUSY;
      }
      // UCTXSTT - generate START condition 
      call Usci.setCtl1(call Usci.getCtl1() | UCTR | UCTXSTT);
      //enable relevant state interrupts
      call UsciB.setI2Cie((call UsciB.getI2Cie() & 0xf0) | UCNACKIE | UCALIE);
      //enable tx interrupts 
      call Usci.setIe( call Usci.getIe() | TXIE_MASK);
    } 
    /* is this a restart or a direct continuation */
    else if (m_flags & I2C_RESTART) {
      // set slave address 
      call UsciB.setI2Csa(addr);

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
    if ( call Usci.getCtl1() & UCTXSTT){
      m_pos = 0;
    }
    /* all bytes sent */
    if ( m_pos == m_len ) {
      /* not setting STOP bit allows restarting transfer */
      if ( m_flags & I2C_STOP ) {
        /* set stop bit */
        call Usci.setCtl1(call Usci.getCtl1() | UCTXSTP);

        /* wait until STOP bit has been transmitted */
        while ((call Usci.getCtl1() & UCTXSTP) && (counter > 0x01)){
          counter--;
        }
        //STOPping and just finished last send, so we should go back
        //to slave mode.
        slaveIdle();
      } else {
        //so, we just don't send the STOP bit.
      }

      //disable tx interrupt, we're DONE 
      call Usci.setIe(call Usci.getIe() & ~TXIE_MASK );
      /* fail gracefully */      
      if (counter > 0x01){
        signal I2CBasicAddr.writeDone[call ArbiterInfo.userId()]( SUCCESS, call UsciB.getI2Csa(), m_len, m_buf );
      } else{
        signal I2CBasicAddr.writeDone[call ArbiterInfo.userId()]( FAIL, call UsciB.getI2Csa(), m_len, m_buf );
      }
    } else {
      //send the next char
      call Usci.setTxbuf(m_buf[ m_pos++ ]);
    }
  }


  /***************************************************************************/

  async event void TXInterrupts.interrupted(uint8_t iv) {
    /* if master mode */
    if (call Usci.getCtl0() & UCMST){
      nextWrite();
    } else {
      if(signal I2CSlave.slaveTransmitRequested[call ArbiterInfo.userId()]()){
        //true= "I'm responding RIGHT NOW"
        // note that when this interrupt context ends, txinterrupt
        // will be raised again.
      } else {
        //false= "I need to pause for a second"
        //disable TX interrupt.
        call Usci.setIe(call Usci.getIe() & ~TXIE_MASK);
      }
    }
  }


  async command void I2CSlave.slaveTransmit[uint8_t clientId](uint8_t data) {
    //TODO: safety
    //write it, reenable interrupt (if it was disabled)
    call Usci.setTxbuf(data);
    call Usci.setIe(call Usci.getIe() | TXIE_MASK);
  }


  async event void RXInterrupts.interrupted(uint8_t iv) {
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
        call Usci.setIe(call Usci.getIe() & ~RXIE_MASK);
      }
    }
  }


  async command uint8_t I2CSlave.slaveReceive[uint8_t client]() {
    //re-enable rx interrupt, read the byte
    call Usci.setIe(call Usci.getIe() | RXIE_MASK);
    return call Usci.getRxbuf();
  }

  
  async event void StateInterrupts.interrupted(uint8_t iv) {
    uint8_t counter = 0xFF;
//    if(call Usci.getStat() & UCALIFG) {
//      printf("AL!");
//    }
    if (call Usci.getCtl0() & UCMST) {
      /* no acknowledgement */
      if (call Usci.getStat() & UCNACKIFG) {
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
          signal I2CBasicAddr.writeDone[call ArbiterInfo.userId()]( ENOACK, call UsciB.getI2Csa(), m_len, m_buf );
        } else {
          signal I2CBasicAddr.readDone[call ArbiterInfo.userId()]( ENOACK, call UsciB.getI2Csa(), m_len, m_buf );
        }
      } 
    } else {
      //slave-specific
      /* arbitration lost (we USED TO be master)*/
      if (call Usci.getStat() & UCALIFG) {
        uint8_t lastAction = m_action;

        slaveIdle();
        //clear AL flag
        call Usci.setStat(call Usci.getStat() & ~(UCALIFG));
        //TODO: more descriptive error? I guess EBUSY is fair.
        if(lastAction == MASTER_WRITE) {
          signal I2CBasicAddr.writeDone[call ArbiterInfo.userId()]( EBUSY, call UsciB.getI2Csa(), m_len, m_buf );
        } else if(lastAction == MASTER_READ) {
          signal I2CBasicAddr.readDone[call ArbiterInfo.userId()]( EBUSY, call UsciB.getI2Csa(), m_len, m_buf);
        }
        //once this returns, we should get another interrupt for STT
        //if we are addressed. Otherwise, we're just chillin' in idle
        //slave mode as per usual.
      }
      /* STOP condition */
      else if (call Usci.getStat() & UCSTPIFG) {
        /* disable STOP interrupt, enable START interrupt */
        call UsciB.setI2Cie((call UsciB.getI2Cie() | UCSTTIE) & ~UCSTPIE);
        signal I2CSlave.slaveStop[call ArbiterInfo.userId()]();
        //TODO: should this not just call slaveIdle?
      }
      /* START condition */
      else if (call Usci.getStat() & UCSTTIFG) {

        //clear start flag, but leave enabled (repeated start)
        //enable stop interrupt
        call Usci.setStat(call Usci.getStat() &~ UCSTTIFG);
        call UsciB.setI2Cie(call UsciB.getI2Cie() | UCSTPIE);
        //enable RX/TX interrupts
        call Usci.setIe(call Usci.getIe() | RXIE_MASK | TXIE_MASK);
        signal I2CSlave.slaveStart[call ArbiterInfo.userId()]( call Usci.getStat() & UCGC);
      }
    }
  }

  //defaults
  default async event void I2CBasicAddr.readDone[uint8_t client](error_t error, uint16_t addr, uint8_t length, uint8_t* data){}
  default async event void I2CBasicAddr.writeDone[uint8_t client](error_t error, uint16_t addr, uint8_t length, uint8_t* data){}
  default async command const msp430_usci_config_t* Msp430UsciConfigure.getConfiguration[uint8_t client]() {
    return &msp430_usci_i2c_default_config;
  }


  /***** Slave-mode functions ***/
  command error_t I2CSlave.setOwnAddress[uint8_t client](uint16_t addr) {
    //TODO: check addr length for this mask
    if (addr & 0xff80) {
      return EINVAL;
    } else {
      //retain UCGCEN bit
      call UsciB.setI2Coa( (call UsciB.getI2Coa() & UCGCEN) | addr);
      return SUCCESS;
    }
  }

  command error_t I2CSlave.enableGeneralCall[uint8_t client]() {
    if (UCGCEN & (call UsciB.getI2Coa())){
      return EALREADY;
    } else {
      call UsciB.setI2Coa(UCGCEN | (call UsciB.getI2Coa()));
      return SUCCESS;
    }
  }

  command error_t I2CSlave.disableGeneralCall[uint8_t client]() {
    if (UCGCEN & ~(call UsciB.getI2Coa())) {
      return EALREADY;
    } else {
      call UsciB.setI2Coa(~UCGCEN & (call UsciB.getI2Coa()));
      return SUCCESS;
    }
  }


  default async event bool I2CSlave.slaveReceiveRequested[uint8_t client]()  { return FALSE; }
  default async event bool I2CSlave.slaveTransmitRequested[uint8_t client]() { return FALSE; }

  default async event void I2CSlave.slaveStart[uint8_t client](bool isGeneralCall) { ; }
  default async event void I2CSlave.slaveStop[uint8_t client]() { ; }

#ifdef notdef
  void showRegisters() {
    atomic{
      P6OUT = 0x00;
      P6OUT = 0xff;
      P6OUT = UCB0CTL0;
      P6OUT = 0xff;
      P6OUT = UCB0CTL1;
      P6OUT = 0xff;
      P6OUT = UCB0BR0;
      P6OUT = 0xff;
      P6OUT = UCB0BR1;
      P6OUT = 0xff;
      P6OUT = UCB0I2CIE;
      P6OUT = 0xff;
      P6OUT = UCB0STAT;
      P6OUT = 0xff;
      P6OUT = UCB0I2COA >> 8;
      P6OUT = 0xff;
      P6OUT = UCB0I2COA & 0xff;
      P6OUT = 0xff;
      P6OUT = UCB0I2CSA >> 8;
      P6OUT = 0xff;
      P6OUT = UCB0I2CSA & 0xff;
      P6OUT = 0xff;
      P6OUT = IE2;
      P6OUT = 0xff;
      P6OUT = 0x00;
    }
  }
#endif

}
