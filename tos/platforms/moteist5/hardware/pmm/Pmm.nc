/*
 * Copyright (c) 2011 João Gonçalves
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

interface Pmm {
  /**
   * Set the voltage level of the MSP430x core
   *  0x0 => DVcc > 1.8V
   *  0x1 => DVcc > 2.0V
   *  0x2 => DVcc > 2.2V
   *  0x3 => DVcc > 2.4V
   */

//====================================================================
/**
  * Set the minimum Vcore level for the desired frequency*/
  command error_t setMinRequiredVCore(uint32_t freq);


//====================================================================
/**
  * Set the VCore to a new level if it is possible*/

  command error_t SetVCore (uint8_t level);

//====================================================================
/**
  * Set the VCore to a higher level, if it is possible.
  * Return a 1 if voltage at highside (Vcc) is to low
  * for the selected Level (level).*/

  command error_t SetVCoreUp (uint8_t level);

//====================================================================
/**
  * Set the VCore to a lower level.
  * Return a 1 if voltage at highside (Vcc) is still to low
  * for the selected Level (level).*/

  command error_t SetVCoreDown (uint8_t level);
}


