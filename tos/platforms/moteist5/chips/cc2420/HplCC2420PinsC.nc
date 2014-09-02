/*
 * Copyright (c) 2011 João Gonçalves
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

/**
 * HPL implementation of general-purpose I/O for the ChipCon CC2420
 * radio connected to a TI MSP430 processor.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 */

/**
 * Adapted for MSP430f5438 TestBoard - Moteist++s5 prototype
 *
 * @author João Gonçalves <joao.m.goncalves@ist.utl.pt>
 * Thesis: PowerEmb; http://gems.leme.org.pt/PmWiki/index.php/Projects/PowerEmb
 * www.ist.utl.pt
 * $Date: 2011/05/26 17:15:00 $
*/

configuration HplCC2420PinsC {
  provides {
    interface GeneralIO as CCA;
    interface GeneralIO as CSN;
    interface GeneralIO as FIFO;
    interface GeneralIO as FIFOP;
    interface GeneralIO as RSTN;
    interface GeneralIO as SFD;
    interface GeneralIO as VREN;
  }
}
implementation {
  components HplMsp430GeneralIOC as GeneralIOC;
  components new Msp430GpioC() as CCAM;
  components new Msp430GpioC() as CSNM;
  components new Msp430GpioC() as FIFOM;
  components new Msp430GpioC() as FIFOPM;
  components new Msp430GpioC() as RSTNM;
  components new Msp430GpioC() as SFDM;
  components new Msp430GpioC() as VRENM;

#ifdef notdef
//  Zoul
  CCAM -> GeneralIOC.Port14;
  CSNM -> GeneralIOC.Port42;
  FIFOM -> GeneralIOC.Port13;
  FIFOPM -> GeneralIOC.Port10;
  RSTNM -> GeneralIOC.Port46;
  SFDM -> GeneralIOC.Port41;
  VRENM -> GeneralIOC.Port45;
#endif

#ifdef notdef
// moteist++s2
  CCAM -> GeneralIOC.Port85;
  CSNM -> GeneralIOC.Port30;
  FIFOM -> GeneralIOC.Port34;
  FIFOPM -> GeneralIOC.Port35;
  RSTNM -> GeneralIOC.Port83;
  SFDM -> GeneralIOC.Port84;
  VRENM -> GeneralIOC.Port82;
#endif

//moteist++s5 testboard
  SFDM -> GeneralIOC.Port21;
  FIFOM -> GeneralIOC.Port22;
  FIFOPM -> GeneralIOC.Port23;
  CCAM -> GeneralIOC.Port24;
  RSTNM -> GeneralIOC.Port25;
  VRENM -> GeneralIOC.Port26;
  CSNM -> GeneralIOC.Port30;

  CCA = CCAM;
  CSN = CSNM;
  FIFO = FIFOM;
  FIFOP = FIFOPM;
  RSTN = RSTNM;
  SFD = SFDM;
  VREN = VRENM;
}
