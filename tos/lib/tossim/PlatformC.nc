/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
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
 * The default simulation platform, which does nothing.
 *
 * @author Phil Levis
 * @date   November 22 2005
 */

module PlatformC {
  provides interface Init;
  provides interface Platform;
}
implementation {
  command error_t Init.init() {
    dbg("PlatformC", "Initialized mote.\n");
    return SUCCESS;
  }

  async command uint32_t Platform.localTime()      { return 0; }
  async command uint32_t Platform.usecsRaw()       { return 0; }
  async command uint32_t Platform.usecsRawSize()   { return 0; }
  async command uint32_t Platform.usecsExpired(uint32_t t_base, uint32_t limit) {
    return (uint32_t) -1;
  }
  async command uint32_t Platform.jiffiesRaw()     { return 0; }
  async command uint32_t Platform.jiffiesRawSize() { return 0; }
  async command uint32_t Platform.jiffiesExpired(uint32_t t_base, uint32_t limit) {
    return (uint32_t) -1;
  }
  async command bool     Platform.set_unaligned_traps(bool on_off) {
    return FALSE;
  }
  async command uint8_t *Platform.node_id(unsigned int *lenp) {
    return NULL;
  }
}
