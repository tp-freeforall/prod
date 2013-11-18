/*
 * Copyright (c) 2013 Eric B. Decker
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
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include <RadioConfig.h>

configuration HplCC2520C {
  provides {

    interface GeneralIO     as RSTN;
    interface GeneralIO     as VREN;
    interface GeneralIO     as CSN;

    interface GeneralIO     as SFD;             /* gp0 -> sfd   */
    interface GeneralIO     as TXA;             /* gp1 -> tx_active  */
    interface GeneralIO     as EXCA;            /* gp2 -> exca  */

    interface GeneralIO     as CCA;             /* gp3 -> cca   */
    interface GeneralIO     as FIFO;            /* gp4 -> fifo  */
    interface GeneralIO     as FIFOP;           /* gp5 -> fifop */

    interface GenericCapture<uint16_t>
                            as SfdCapture;
    interface GpioInterrupt as ExcAInterrupt;

    interface SpiByte;
    interface FastSpiByte;
    interface SpiPacket;

    interface Resource as SpiResource;

    interface Alarm<TRadio, uint16_t> as Alarm;
    interface LocalTime<TRadio> as LocalTimeRadio;

    /*
     * P_SO and P_GPIO[1-5] are platform specific pins that are used by the
     * platform specific CC2520 code.   When the cc2520 chip gets turned off
     * these pins get handled so that the chip doesn't get powered by a high
     * voltage on the pin.  Basically they get tied to ground through a pull
     * down (as provided by the mcu).  See PlatformCC2520P for details.
     */
    interface HplMsp430GeneralIO as P_SO;
    interface HplMsp430GeneralIO as P_CSN;
    interface HplMsp430GeneralIO as P_RSTN;
    interface HplMsp430GeneralIO as P_VREN;
    interface HplMsp430GeneralIO as P_GPIO0;
    interface HplMsp430GeneralIO as P_GPIO1;
    interface HplMsp430GeneralIO as P_GPIO2;
    interface HplMsp430GeneralIO as P_GPIO3;
    interface HplMsp430GeneralIO as P_GPIO4;
    interface HplMsp430GeneralIO as P_GPIO5;
  }
}
implementation {
  components new Msp430UsciSpiB0C() as SpiC;
  SpiResource = SpiC;
  SpiByte     = SpiC;
  FastSpiByte = SpiC;
  SpiPacket   = SpiC;

  components CC2520SpiConfigP;
  CC2520SpiConfigP.Msp430UsciConfigure <- SpiC;

  /* _G pins are GeneralIO pins that we export */
  components new Msp430GpioC() as RSTN_G;
  components new Msp430GpioC() as VREN_G;
  components new Msp430GpioC() as CSN_G;

  components new Msp430GpioC() as SFD_G;
  components new Msp430GpioC() as TXA_G;
  components new Msp430GpioC() as EXCA_G;

  components new Msp430GpioC() as CCA_G;
  components new Msp430GpioC() as FIFO_G;
  components new Msp430GpioC() as FIFOP_G;

  components HplMsp430GeneralIOC as P_IOC;

  // SO, Port32

  CSN_G   -> P_IOC.Port30;
  RSTN_G  -> P_IOC.Port12;
  VREN_G  -> P_IOC.Port17;

  SFD_G   -> P_IOC.Port14;
  TXA_G   -> P_IOC.Port15;
  EXCA_G  -> P_IOC.Port16;

  CCA_G   -> P_IOC.Port13; 
  FIFO_G  -> P_IOC.Port81; 
  FIFOP_G -> P_IOC.Port82;


  RSTN     = RSTN_G;
  VREN     = VREN_G;
  CSN      = CSN_G;

  SFD      = SFD_G;
  TXA      = TXA_G;
  EXCA     = EXCA_G;

  CCA      = CCA_G;
  FIFO     = FIFO_G;
  FIFOP    = FIFOP_G;

  /* platform specific pins (see PlatformCC2520) */
  P_SO     = P_IOC.Port32;
  P_CSN    = P_IOC.Port30;
  P_RSTN   = P_IOC.Port12;
  P_VREN   = P_IOC.Port17;
  P_GPIO0  = P_IOC.Port14;
  P_GPIO1  = P_IOC.Port15;
  P_GPIO2  = P_IOC.Port16;
  P_GPIO3  = P_IOC.Port13;
  P_GPIO4  = P_IOC.Port81;
  P_GPIO5  = P_IOC.Port82;

  /*
   * The default configuration for timers on x5 processors is
   * TA0 -> 32KiHz and TA1 -> TMicro (1uis).  But we want to
   * use TA0 for uS timestamping of the SFD signal.   So we
   * swap the usage.
   *
   * If the clock being used for SFDcapture goes to sleep, then when
   * we receive a packet there is no clock source for the capture.
   * This makes the capture unreliable.   However, if we are actively
   * using the 1us clock (like for a timer) it doesn't go to sleep and
   * should remain reasonable.
   *
   * We should use Msp430TimerMicro for this except that TimerMicroC
   * doesn't export Capture.
   *
   * ie. component new Msp430TimerMicroC as TM;
   *     SfdCaptureC.Msp430TimerControl = TM.Msp430TimerControl;
   *     SfdCaptureC.Msp430Capture      = TM.Msp430Capture;
   *
   * The SFD pin on the 2520EM module for the 5438A eval board is configured
   * to use P1.4/TA0.3 on the cpu.   This connects to the capture module for
   * TA0 via TA0.CCI3A which requires using TA0CCTL3.   The capture will
   * show up in TA0CCR3 and will set CCIFG in TA0CCTL3.  Units in TA0CCR3
   * will be TMicro ticks.
   *
   * This also requires a modification to Msp430TimerMicroMap so control
   * cells for T0A1 aren't exposed for use by other users.  A custom
   * version is present in tos/platforms/exp5438_2520/hardware/timer.  This
   * directory is also were which timer block is used for what function
   * (TMicro vs. TMilli) live.
   */

  /*
   * uses GenericCapture and Msp430CaptureV2, which export capture overwrite
   * (overflow).
   */
  components new GpioCaptureC() as SfdCaptureC;
  components Msp430TimerC;
  SfdCapture = SfdCaptureC;

  SfdCaptureC.Msp430TimerControl -> Msp430TimerC.Control0_A3;
  SfdCaptureC.MCap2              -> Msp430TimerC.Capture0_A3;
  SfdCaptureC.CaptureBit         -> P_IOC.Port14;

  components HplMsp430InterruptC;
  components new Msp430InterruptC() as InterruptExcAC;
  ExcAInterrupt = InterruptExcAC.Interrupt;
  InterruptExcAC.HplInterrupt -> HplMsp430InterruptC.Port16;

  components new AlarmMicro16C() as AlarmC;
  Alarm = AlarmC;

  components LocalTimeMicroC;
  LocalTimeRadio = LocalTimeMicroC.LocalTime;
}
