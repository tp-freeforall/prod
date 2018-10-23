/*
 * Copyright (c) 2018, Eric B. Decker
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
 * The TinyOS timing system is based on various layers, ultimately
 * tying to the underlying timing h/w.  Under various circumstances
 * adjustments may be made by this underlying timing that can result
 * in time skew.
 *
 * Typically this can occur when the RTC (Real Time Clock) subsystem
 * has had its time adjusted for example via a GPS providing synchronized
 * time.  If this skew is below a reasonable threshold (platform dependent)
 * TimeSkew.skew(skew_val) will be signalled.  Beyond that threshold
 * it might be better to reboot and reestablish reasonable time via
 * those mechanisms.
 *
 * @author Eric B.Decker <cire831@gmail.com>
 */

interface TimeSkew {
  /**
   * Signaled when the underlying timing system has detected timing
   * skew.
   *
   * @param skew    estimated skew computed.  in millisecs (units platform
   *                dependent, typically binary millisecs).
   *                > 0, time has been moved into the future (we were slow).
   *                < 0, time has been shifted backwards, (we were fast).
   *                = 0, skew is beyond platform limits.
   */
  async event void skew(int32_t skew);
}
