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

  components CC2520SpiConfigP;
  CC2520SpiConfigP.Msp430UsciConfigure <- SpiC;

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

  components P81SfdCaptureC as SfdCaptureC;
  components Msp430TimerC;
  SfdCapture = SfdCaptureC;

  /*
   * We should use Msp430TimerMicro for this except that TimerMicroC
   * doesn't export Capture.
   *
   * ie. component new Msp430TimerMicroC as TM;
   *     SfdCaptureC.Msp430TimerControl = TM.Msp430TimerControl;
   *     SfdCaptureC.Msp430Capture      = TM.Msp430Capture;
   *
   * The SFD pin on the 2520EM module for the 5438A eval board is wired
   * to P8.1/TA0.1 on the cpu.   This connects to the capture module for
   * TA0 via TA0.CCI1B which requires using TA0CCTL1.   The capture will
   * show up in TA0CCR1 and will set CCIFG in TA0CCTL1.  Units in TA0CCR1
   * will be 32KiHz jiffies.
   */
  SfdCaptureC.Msp430TimerControl -> Msp430TimerC.Control0_A1;
  SfdCaptureC.Msp430Capture      -> Msp430TimerC.Capture0_A1;
  SfdCaptureC.GeneralIO          -> GeneralIOC.Port81;

  components HplMsp430InterruptC;
  components new Msp430InterruptC() as InterruptFIFOC;
  components new Msp430InterruptC() as InterruptFIFOPC;
  FifoInterrupt  = InterruptFIFOC.Interrupt;
  FifopInterrupt = InterruptFIFOPC.Interrupt;
  InterruptFIFOC.HplInterrupt  -> HplMsp430InterruptC.Port15;
  InterruptFIFOPC.HplInterrupt -> HplMsp430InterruptC.Port16;

  components new Alarm32khz16C() as AlarmC;
  Alarm = AlarmC;

  components LocalTime32khzC;
  LocalTimeRadio = LocalTime32khzC.LocalTime;
}
