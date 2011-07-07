/* Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
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
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

module RadioMonitorP {
  uses {
    interface Led as TxActiveLed;
    interface Alarm<TMilli, uint16_t> as TxAlarmMilli16;
    interface Led as RxActiveLed;
    interface Alarm<TMilli, uint16_t> as RxAlarmMilli16;
    interface Rf1aPhysical[uint8_t client];
  }
} implementation {

#ifndef RADIO_MONITOR_INTERVAL_BMS
#define RADIO_MONITOR_INTERVAL_BMS 32
#endif /* RADIO_MONITOR_INTERVAL_BMS */

  default async command void TxActiveLed.toggle () { }
  default async command void TxActiveLed.off () { }
  default async command void RxActiveLed.toggle () { }
  default async command void RxActiveLed.off () { }

  async event void TxAlarmMilli16.fired () { call TxActiveLed.off(); }
  async event void RxAlarmMilli16.fired () { call RxActiveLed.off(); }

  async event void Rf1aPhysical.sendDone[ uint8_t client ] (int result)
  {
    call TxActiveLed.toggle();
    call TxAlarmMilli16.start(RADIO_MONITOR_INTERVAL_BMS);
  }
  async event void Rf1aPhysical.receiveDone[ uint8_t client ] (uint8_t* buffer,
                                                               unsigned int count,
                                                               int result)
  {
    call RxActiveLed.toggle();
    call RxAlarmMilli16.start(RADIO_MONITOR_INTERVAL_BMS);
  }

  /* Irrelevant events */
  async event void Rf1aPhysical.receiveStarted[ uint8_t client ] (unsigned int length) { }
  async event void Rf1aPhysical.receiveBufferFilled[ uint8_t client ] (uint8_t* buffer,
                                                                       unsigned int count) { }
  async event void Rf1aPhysical.frameStarted[ uint8_t client ] () { }
  async event void Rf1aPhysical.clearChannel[ uint8_t client ] () { }
  async event void Rf1aPhysical.carrierSense[ uint8_t client ] () { }
  async event void Rf1aPhysical.released[ uint8_t client ] () { }

}
