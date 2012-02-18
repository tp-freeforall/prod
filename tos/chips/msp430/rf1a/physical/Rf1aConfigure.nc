/*
 * Copyright (c) 2010 People Power Co.
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

#include <Rf1aConfigure.h>

/** Enable an RF1A client to control its radio configuration.
 *
 * You can either completely replace a radio configuration structure,
 * by implementing the getConfiguration() method, or you can use
 * higher-level operations to inspect or mutate the configuration
 * immediately before and after it's changed by the infrastructure.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

interface Rf1aConfigure {
  /** Return a pointer to the configuration that should be used for a
   * particular RF1A client.
   *
   * @note Only the patable0 register and the part of the
   * rf1a_config_t structure covered by RF1A_CONFIG_BURST_WRITE_LENGTH
   * are written.  The remaining registers, including some test
   * registers, are ignored during configuration.
   *
   * If the implementation returns a null pointer, the compiled-in
   * default configuration shall be used.
   */
  async command const rf1a_config_t* getConfiguration ();

  /** Invoked just prior to radio configuration.
   *
   * Not sure what you'd use this for, but it's here if you need
   * it.
   */
  async command void preConfigure ();

  /** Invoked immediately following radio configuration.
   *
   * This would be an appropriate place to do things like set the
   * channel and control other parameters that are accessible through
   * the Rf1aPhysical interface, before the radio has a change to
   * start receiving packets or otherwise make itself difficult to
   * change.
   */
  async command void postConfigure ();

  /** Invoked immediately prior to unconfiguring the radio.
   *
   * Might want to use this to cache values read from Rf1aPhysical,
   * e.g. to restore a locally modified radio configuration that can
   * subsequently be provided through getConfiguration().
   */
  async command void preUnconfigure ();

  /** Invoked immediately following unconfiguring the radio.
   *
   * Here if you need it; ignore it if you don't.
   */
  async command void postUnconfigure ();
}

/* 
 * Local Variables:
 * mode: c
 * End:
 */
