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

/** Component to monitor radio activity without application impact.
 *
 * The implementation of this module on a platform ties directly to
 * the lowest-level physical interface capable of signalling
 * physical-layer RX and TX activity, bypassing all link- and
 * data-layer filters and resource management.  It can be used for
 * visual confirmation of physical transmission and reception activity
 * in the face of potential link/data-layer misconfiguration or
 * problems.
 *
 * To implement this module on a platform, you need an ability to
 * catch an event on radio transmission and reception.  The module
 * connects to those events, and toggles LEDs corresponding to TX and
 * RX activity.  After a build-configurable duration, the LED is
 * turned off.
 *
 * Because this ties directly to the lowest level physical radio
 * interface, the visual behavior is consistent regardless of what
 * application component has control of the radio.
 *
 * The module is useless unless at least one LED is wired, but neither
 * is strictly required if the application has no need to display
 * radio activity of a particular type.
 *
 * The default duration of the LED display is 32 bms, and can be
 * controlled by defining the RADIO_MONITOR_INTERVAL_BMS preprocessor
 * symbol to another non-negative value.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
configuration RadioMonitorC {
  uses {
    interface Led as TxActiveLed;
    interface Led as RxActiveLed;
  }
} implementation {

  components RadioMonitorP;
  TxActiveLed = RadioMonitorP.TxActiveLed;
  RxActiveLed = RadioMonitorP.RxActiveLed;

  components new MuxAlarmMilli16C() as TxAlarmMilli16C;
  components new MuxAlarmMilli16C() as RxAlarmMilli16C;
  RadioMonitorP.TxAlarmMilli16 -> TxAlarmMilli16C;
  RadioMonitorP.RxAlarmMilli16 -> RxAlarmMilli16C;
  
  /* For now, assume that we're using an RF1A.  Really this module
   * needs variant implementations for variant platforms, but it's not
   * clear where it should be stored or whether the necessary
   * information can be made available through preprocessor functional
   * presence identifiers. */
  components Rf1aC;
  RadioMonitorP.Rf1aPhysical -> Rf1aC;
}
