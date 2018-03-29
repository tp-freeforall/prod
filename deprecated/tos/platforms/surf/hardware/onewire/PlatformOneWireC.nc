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
 * Platform hardware presentation layer for the DS24xx one-wire chip
 * @author David Moss
 */

configuration PlatformOneWireC {
  provides {
    interface OneWire as PrimaryOneWire;
    interface Read<int16_t> as TemperatureCC;
  }
}

implementation {
  components PlatformOneWireInitC;

  /* SuRF boards use a DS1825 as the primary one-wire device.  This
   * happens to also provide the ambient temperature. */

  components new OneWireMasterC() as Ds1825MasterC;
  components new Msp430GpioC() as Ds1825PinC;
  Ds1825MasterC.Pin -> Ds1825PinC;
  Ds1825PinC -> PlatformOneWireInitC.Ds1825IO;

  components new Ds1825OneWireImplementationC() as Ds1825ImplC;
  PrimaryOneWire = Ds1825ImplC;
  TemperatureCC = Ds1825ImplC;
  Ds1825ImplC.OneWireMaster -> Ds1825MasterC;
}
