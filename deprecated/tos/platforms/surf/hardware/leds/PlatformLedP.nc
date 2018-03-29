/* 
 * Copyright (c) 2009-2010 People Power Company
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

/**
 * Implement the LED-relevant interfaces for the SuRF platform.
 *
 * Traditionally, the PlatformLedsC component has exported named
 * GeneralIO interfaces, which are subsequently used in a LedsP
 * implementation to support the Leds interface.  Whether an LED is
 * active-high or active-low is platform specific, and therefore
 * should not be delegated to a supposedly platform-dependent
 * component.
 *
 * We need to implement the LED functionality here.  But we're in the
 * platform-specific file, so we know we're using an MSP430.  There's
 * no point in trying to use generic GeneralIO interfaces to interact
 * with the registers.  Eliminating them, while using a table to
 * identify LED positions, drops the code size by about 64 bytes and
 * makes the interface cleaner.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

module PlatformLedP {
  provides {
    interface Init;
    interface Leds;
    interface Led[uint8_t led_id];
    interface MultiLed;
  }
} implementation {

#include "PlatformLed.h"

  /**
   * Layout of the relevant portions of an MSP430XV2 digital IO port
   * bank.
   */
  typedef struct port_t {
      uint16_t pxin;            /* 0x00: Input */
      uint16_t pxout;           /* 0x02: Output */
      uint16_t pxdir;           /* 0x04: Direction */
      uint16_t pxren;           /* 0x06: Resistor Enable */
      uint16_t pxds;            /* 0x08: Drive Strength */
      uint16_t pxsel;           /* 0x0A: Port Select */
  } port_t;

  /** Required information to specify a digital pin that controls an LED */
  typedef struct led_t {
    volatile port_t* port;
    uint16_t bit;
  } led_t;

  /*
   * @TODO@ When msp430-libc is corrected, reference PAIN and PBIN, to
   * make it more clear that we're operating on the 16-bit interface
   * to the ports.
   */

  const static led_t leds[] = {
#if defined(SURF_REV_BLOCK_A)
    { (port_t*)P3IN_, 1 << 1 }, // Green
    { (port_t*)P3IN_, 1 << 2 }, // Red
#elif defined(SURF_REV_A)
    { (port_t*)P1IN_, 1 << 0 }, // Blue
    { (port_t*)P1IN_, 1 << 1 }, // White
    { (port_t*)P1IN_, 1 << 2 }, // Red
    { (port_t*)P3IN_, 1 << 6 }, // Yellow
    { (port_t*)P3IN_, 1 << 7 }, // Green
#else
    { (port_t*)P3IN_, 1 << 0 }, // Green
    { (port_t*)P3IN_, 1 << 1 }, // Red
    { (port_t*)P3IN_, 1 << 2 }, // White
    { (port_t*)P3IN_, 1 << 3 }, // Orange
    { (port_t*)P3IN_, 1 << 4 }, // Blue
#endif		/* SURF_REV_BLOCK_A */
  };

  static const int nleds = sizeof(leds) / sizeof(*leds);

  command error_t Init.init() {
    atomic {
      int li;

      for (li = 0; li < nleds; ++li) {
        const led_t* lp = leds + li;
        lp->port->pxout &= ~lp->bit;
        lp->port->pxdir |= lp->bit;
      }
    }
    return SUCCESS;
  }

  void _LEDon (uint8_t led_id) {
    if(led_id < nleds) {
      const led_t* lp = leds + led_id;
      atomic lp->port->pxout |= lp->bit;
    }
  }

  void _LEDoff (uint8_t led_id) {
    if(led_id < nleds) {
      const led_t* lp = leds + led_id;
      atomic lp->port->pxout &= ~lp->bit;
    }
  }

  void _LEDtoggle (uint8_t led_id) {
    if (led_id < nleds) {
      const led_t* lp = leds + led_id;
      atomic lp->port->pxout ^= lp->bit;
    }
  }

  unsigned int _LEDread () {
    unsigned int val = 0;
    int li;

    for (li = 0; li < nleds; ++li) {
      const led_t* lp = leds + li;
      val |= (!! (lp->port->pxout & lp->bit)) << li;
    }
    return val;
  }

  void _LEDwrite (unsigned int value) {
    int li;

    for (li = 0; li < nleds; ++li) {
      if (value & (1 << li)) {
        _LEDon(li);
      } else {
        _LEDoff(li);
      }
    }
  }

  /*
   * I don't think we'd save much space by not implementing the legacy
   * interface always, so rather than complicate compilation let's
   * always support it.
   */
  async command void Leds.led0Off ()      { _LEDoff(0); }
  async command void Leds.led0On ()       { _LEDon(0); }
  async command void Leds.led0Toggle ()   { _LEDtoggle(0); }
  async command void Leds.led1Off ()      { _LEDoff(1); }
  async command void Leds.led1On ()       { _LEDon(1); }
  async command void Leds.led1Toggle ()   { _LEDtoggle(1); }
  async command void Leds.led2Off ()      { _LEDoff(2); }
  async command void Leds.led2On ()       { _LEDon(2); }
  async command void Leds.led2Toggle ()   { _LEDtoggle(2); }
  async command uint8_t Leds.get ()       { return _LEDread(); }
  async command void Leds.set (uint8_t v) { _LEDwrite(v); }

  async command unsigned int MultiLed.get ()            { return _LEDread(); }
  async command void MultiLed.set (unsigned int value)  { _LEDwrite(value); }
  async command void MultiLed.on (unsigned int led_id)  { _LEDon(led_id); }
  async command void MultiLed.off (unsigned int led_id) { _LEDoff(led_id); }

  async command void MultiLed.setSingle (unsigned int led_id, bool on) {
    if (on) { _LEDon(led_id); }
    else    { _LEDoff(led_id); }
  }

  async command void MultiLed.toggle (unsigned int led_id) { _LEDtoggle(led_id); }
  async command void Led.on[uint8_t led_id] ()             { call MultiLed.on(led_id); }
  async command void Led.off[uint8_t led_id] ()            { call MultiLed.off(led_id); }
  async command void Led.set[uint8_t led_id] (bool on)     { call MultiLed.setSingle(led_id, on); }
  async command void Led.toggle[uint8_t led_id] ()         { call MultiLed.toggle(led_id); }
}
