/*
 * Copyright (c) 2011, 2013 Eric B. Decker
 * Copyright (c) 2000-2003 The Regents of the University of California.
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
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @author: Eric B. Decker <cire831@gmail.com>
 *
 * Implements Msp430CaptureV2 which includes support for capture overflow
 * conditions.
 */

#include "Msp430Timer.h"

generic module Msp430TimerCapComP(
    uint16_t TxCCTLx_addr,
    uint16_t TxCCRx_addr
  ) @safe() {
  provides {
    interface Msp430TimerControl as Control;
    interface Msp430Compare      as Compare;
    interface Msp430CaptureV2    as Capture;
  }
  uses {
    interface Msp430Timer      as Timer;
    interface Msp430TimerEvent as Event;
  }
}
implementation {
  #define TxCCTLx (*TCAST(volatile TYPE_TACCTL0* ONE, TxCCTLx_addr))
  #define TxCCRx (*TCAST(volatile TYPE_TACCR0* ONE, TxCCRx_addr))

  typedef msp430_compare_control_t cc_t;

  DEFINE_UNION_CAST(CC2int,uint16_t,cc_t)
  DEFINE_UNION_CAST(int2CC,cc_t,uint16_t)

  /*
   * build a control word for setting up Capture/Compare on the msp430 h/w
   *
   * See Msp430Timer.h for values or the cpu data sheet.
   *
   * l_cm: the capture/compare control mode
   *
   * ccis: cap/compare input select.
   *
   * cap: 0 for compare, 1 for capture
   */
  uint16_t capComControl(uint8_t l_cm, uint8_t ccis, uint8_t cap_val) {
    cc_t x = {
      cm :   l_cm & 0x03,       // capture on none, rising, falling or both edges
      ccis : ccis & 0x3,        // capture/compare input select
      clld : 0,                 // TBCL1 loads on write to TBCCR1
      cap :  cap_val & 1,       // compare or capture mode
      scs :  1,                 // synch capture mode, sync
      ccie : 0,                 // capture compare interrupt enable
    };
    return CC2int(x);
  }

  async command cc_t Control.getControl() {
    return int2CC(TxCCTLx);
  }

  async command bool Control.isInterruptPending() {
    return TxCCTLx & CCIFG;
  }

  async command void Control.clearPendingInterrupt() {
    CLR_FLAG(TxCCTLx,CCIFG);
  }

  async command void Control.setControl( cc_t x ) {
    TxCCTLx = CC2int(x);
  }

  async command void Control.setControlAsCompare() {
    /* defaults to rising edge and CCIS channel A */
    TxCCTLx = capComControl(MSP430TIMER_CM_RISING, MSP430TIMER_CCI_A, 0);
  }

  async command void Control.setControlAsCapture( uint8_t cm, uint8_t ccis) {
    TxCCTLx = capComControl( cm, ccis, 1 );
  }

  async command void Control.enableEvents() {
    SET_FLAG( TxCCTLx, CCIE );
  }

  async command void Control.disableEvents() {
    CLR_FLAG( TxCCTLx, CCIE );
  }

  async command bool Control.areEventsEnabled() {
    return READ_FLAG( TxCCTLx, CCIE );
  }

  async command void Capture.setEdge(uint8_t cm) {
    cc_t t = call Control.getControl();
    t.cm = cm & 0x03;
    TxCCTLx = CC2int(t);
  }

  async command void Capture.setSynchronous( bool sync ) {
    if( sync ) SET_FLAG( TxCCTLx, SCS );
    else       CLR_FLAG( TxCCTLx, SCS );
  }

  async command uint16_t Compare.getEvent() {
    return TxCCRx;
  }

  async command uint16_t Capture.getEvent() {
    return TxCCRx;
  }

  async command void Compare.setEvent( uint16_t x ) {
    TxCCRx = x;
  }

  async command void Compare.setEventFromPrev( uint16_t delta ) {
    TxCCRx += delta;
  }

  async command void Compare.setEventFromNow( uint16_t delta ) {
    TxCCRx = call Timer.get() + delta;
  }

  async command bool Capture.isOverflowPending() {
    return READ_FLAG( TxCCTLx, COV );
  }

  async command void Capture.clearOverflow() {
    CLR_FLAG( TxCCTLx, COV );
  }

  async event void Event.fired() {
    uint16_t time;
    bool     overflow;

    if ((call Control.getControl()).cap) {
      /*
       * The ordering is important.  First read "Time", then grab the
       * Overflow (OV) bit.
       *
       * There is a very small window between the read of time and grabbing
       * the OV bit where another event could occur.  But this will be seen
       * as an overflow.  We return the previous time (which technically is
       * wrong) but its flagged with the OV bit which says we lost a capture.
       * That is close enough to the correct behaviour.
       *
       * We need to clean out the overflow by hand.  It does not get cleared
       * by the h/w but must be cleared by s/w.
       */
      time = call Capture.getEvent();
      overflow = call Capture.isOverflowPending();
      if (overflow)
        call Capture.clearOverflow();
      signal Capture.captured(time, overflow);
    } else
      signal Compare.fired();
  }

  default async event void Capture.captured( uint16_t n, bool overflow ) { }

  default async event void Compare.fired() { }

  async event void Timer.overflow() { }
}
