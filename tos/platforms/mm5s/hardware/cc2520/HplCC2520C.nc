/*
 * Copyright (c) 2013 Eric B. Decker
 * Copyright (c) 2011 University of Utah. 
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
 * @author Thomas Schmid
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include <RadioConfig.h>

configuration HplCC2520C {
  provides {

    interface GeneralIO as CCA;
    interface GeneralIO as CSN;
    interface GeneralIO as FIFO;
    interface GeneralIO as FIFOP;
    interface GeneralIO as RSTN;
    interface GeneralIO as SFD;
    interface GeneralIO as VREN;
    interface GpioCapture as SfdCapture;
    interface GpioInterrupt as FifopInterrupt;
    interface GpioInterrupt as FifoInterrupt;

    interface SpiByte;
    interface SpiPacket;

    interface Resource as SpiResource;

    interface Alarm<TRadio, uint16_t> as Alarm;
    interface LocalTime<TRadio> as LocalTimeRadio;
  }
}
implementation {
  components new Msp430UsciSpiB0C() as SpiC;
  SpiResource = SpiC;
  SpiByte     = SpiC;
  SpiPacket   = SpiC;

/*
  components CC2520SpiConfigC as RadioSpiConfigC;
  RadioSpiConfigC.Init <- SpiC;
  RadioSpiConfigC.ResourceConfigure <- SpiC;
  RadioSpiConfigC.HplSam3SpiChipSelConfig -> SpiC;
*/

  components HplMsp430GeneralIOC as GeneralIOC;
  components new Msp430GpioC() as CCAM;
  components new Msp430GpioC() as CSNM;
  components new Msp430GpioC() as FIFOM;
  components new Msp430GpioC() as FIFOPM;
  components new Msp430GpioC() as RSTNM;
  components new Msp430GpioC() as SFDM;
  components new Msp430GpioC() as VRENM;

  CCAM   -> GeneralIOC.Port13; 
  CSNM   -> GeneralIOC.Port30;
  FIFOM  -> GeneralIOC.Port15; 
  FIFOPM -> GeneralIOC.Port16;
  RSTNM  -> GeneralIOC.Port12;
  SFDM   -> GeneralIOC.Port81;
  VRENM  -> GeneralIOC.Port17;
  
  CCA   = CCAM;
  CSN   = CSNM;
  FIFO  = FIFOM;
  FIFOP = FIFOPM;
  RSTN  = RSTNM;
  SFD   = SFDM;
  VREN  = VRENM;

  components new GpioCaptureC() as SfdCaptureC;
  components Msp430TimerC;
  SfdCapture = SfdCaptureC;
  SfdCaptureC.Msp430TimerControl -> Msp430TimerC.Control0_B0;
  SfdCaptureC.Msp430Capture      -> Msp430TimerC.Capture0_B0;
  SfdCaptureC.GeneralIO          -> GeneralIOC.Port81;

  components HplMsp430InterruptC;
  components new Msp430InterruptC() as InterruptFIFOC;
  components new Msp430InterruptC() as InterruptFIFOPC;
  FifoInterrupt  = InterruptFIFOC.Interrupt;
  FifopInterrupt = InterruptFIFOPC.Interrupt;
  InterruptFIFOC.HplInterrupt  -> HplMsp430InterruptC.Port15;
  InterruptFIFOPC.HplInterrupt -> HplMsp430InterruptC.Port16;

  components new AlarmMicro16C() as AlarmC;
  Alarm = AlarmC;

  components LocalTimeMicroC;
  LocalTimeRadio = LocalTimeMicroC;
}
