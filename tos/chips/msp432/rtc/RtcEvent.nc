/*
 * Copyright (c) 2018 Eric B. Decker
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

#include <rtc.h>
#include <rtctime.h>

interface RtcEvent {
  /**
   * Set the Rtc subsystem to generate the requested event.
   */

  /**
   * Configure a specific rtc event.
   *
   * Prior to reconfiguring, any current event is disabled,
   * meaning that if you provide an invalid argument, your previous
   * configuration gets wiped.
   *
   * @param event_mode the type of event that should be signaled.  One
   * one event is allowed due to h/w restrictions
   *
   * always works or panics
   */
  async command void setEventMode(rtcevent_t event_mode);


  /** Read the current rtc event mode. */
  async command rtcevent_t getEventMode();


  /**
   * Notification of a rtcEvent
   *
   * The request event has triggered.
   *
   * @param timep:      pointer to the current time
   * @param rtc_event:  the original requested event.
   */
  async event void rtcEvent(rtctime_t *timep, rtcevent_t rtc_event);
}
