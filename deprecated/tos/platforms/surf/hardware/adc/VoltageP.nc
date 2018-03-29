/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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

module VoltageP {
  provides {
    interface Read<uint16_t>;
  }
  uses {
    interface Read<uint16_t> as SubRead;
  }
}

implementation {

  /** Warning: These locations are confirmed valid for only CC430Fxxx uC's */
  extern const uint16_t CAL_REF_20VREF_FACTOR asm("0x01a2a");
  extern const uint16_t CAL_ADC_GAIN_FACTOR asm("0x01a16");
  extern const uint16_t CAL_ADC_OFFSET asm("0x1a18");

  /***************** Read Commands ****************/
  command error_t Read.read() {
    /* 
     * Work around the TinyOS deprecated method of setting the reference voltage
     * by enabling it manually.  This is a temporary solution: a full
     * solution will involve upgrading the ADC12 module in chips/msp430/adc12
     * 
     * Due to the broken architecture, this will not work when other components 
     * are also accessing the ADC12. You should not call Resource.request()
     * before attempting to Read, because the system will lock up.
     * 
     * The following line enables 2.0V operation.
     */
    REFCTL0 |= REFMSTR + REFVSEL_1 + REFON;
    return call SubRead.read();
  }
  
  /***************** SubRead Events ****************/
  event void SubRead.readDone( error_t result, uint16_t conversion ) {
    REFCTL0 &= ~(REFON);

    // Calibrate the values for the 2.0V REF and ADC12 gain / offset:
    // First correct for REF
    MPY = (conversion * 2);
    OP2 = CAL_REF_20VREF_FACTOR;

    // Now the result is stored in RESHI
    MPY = (RESHI * 2);
    OP2 = CAL_ADC_GAIN_FACTOR;

    // Now the calibrated ADC12 conversion is stored in (RESHI + CAL_ADC_OFFSET)

    /*
     * Conversion is:  (2.0[V] * val) / 2048 = voltage
     * Return the value in millivolts, so multiply by 1000.
     */
    signal Read.readDone(result, (2000 * (uint32_t) (RESHI + CAL_ADC_OFFSET)) / 2048);
  }
}
