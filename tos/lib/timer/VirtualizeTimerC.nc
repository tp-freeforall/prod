/* Copyright (c) 2018, Eric B. Decker
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
 * VirtualizeTimerC uses a single Timer to create up to 255 virtual timers.
 * See VirtualizeTimerImplC.nc for the details of the implementation.
 *
 * <p>See TEP102 for more details.
 *
 * @param precision_tag A type indicating the precision of the Timer being
 *   virtualized.
 * @param max_timers Number of virtual timers to create.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * TimeSkew is optional.  A Platform will export TimeSkew if it supports
 * updating underlying time h/w.  Advanced topic.
 *
 * If a platform doesn't export TimeSkew, there is no impact on the operation
 * inside VirtualizeTimerImpl.  The Platform is responsible for wiring to
 * TimeSkew.  For example, the exp_msp432 Platform exports TimeSkew which
 * is wired by tos/chips/msp432/timer/HilTimerMilliC.nc.
 */

generic configuration VirtualizeTimerC(typedef precision_tag,
                                       int max_timers) @safe() {
  provides interface Timer<precision_tag> as Timer[uint8_t num];
  uses     interface Timer<precision_tag> as TimerFrom;
  uses     interface TimeSkew;
}
implementation {
  components new VirtualizeTimerImplP(precision_tag, max_timers) as VT;
  Timer     = VT.Timer;
  TimerFrom = VT.TimerFrom;
  TimeSkew  = VT.TimeSkew;

  components PlatformC;
  VT.Platform -> PlatformC;
}
