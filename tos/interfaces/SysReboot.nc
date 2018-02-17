/*
 * Copyright (c) 2017-2018 Eric B. Decker
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

/*
 * SysReboot: interfaces for resetting/rebooting the system.
 *
 * reboot(sysreboot_type): reboot the system.  The sysreboot_param indicates
 * the kind of reboot to perform.
 *
 * soft_reboot(sysreboot_type): reboot the system under software control.
 * typically this will get used when we need to reboot but don't want to
 * use a hardware reset.  For example, if the processor when reset resets
 * all i/o pins to input (a reasonable thing to do), this can effect power
 * regulators and power switches that are under processor control.  If
 * instead the software is responsible for reseting any necessary h/w,
 * we can avoid changing any pin state (at the risk of not starting up
 * in a presumed (reset) state).  At least that is one example of why it
 * would be used.  The software can basically do anything reasonable that
 * the software can pull off.
 *
 * shutdown_flush: is a signal used to tell any components we are about
 * to shutdown (and reboot).  Any actions the component may want to
 * perform before the shutdown should be performed now.
 *
 * Note: all such actions should be strictly run to completion.  Upon
 * return from all codes executed via the shutdown_flush event, the
 * system will be shutdown and possibly rebooted.  No task code is
 * allowed to run.
 *
 * SysReboot is inherently a Platform/processor type of thing.  As
 * such it must be implemented by the Platform layer or beyond.
 */

#include <sysreboot.h>

interface SysReboot {

  /*
   * SysReboot.reboot(sysreboot_type): reboot the system according to
   * the type of reboot asked for by sysreboot_type.
   *
   * SysReboot.clear(sysreboot_type): clear out any reboot carry over for
   * the type of reboot asked for by sysreboot_type.
   *
   * input: sysreboot_type
   *    SYSREBOOT_REBOOT always just reboot the system.
   *
   *    SYSREBOOT_POR   full Power On Reset.  Simulate if possible that a full
   *                    POR reset has occured via software.
   *
   *                    o Full device reset.
   *                    o debugger (jtag) loses connection and control of device
   *                    o full reboot
   *                    o SRAM may not be retained.
   *
   *    SYSREBOOT_HARD  o resets the processor and various peripherals in the system
   *                    o Abort any pending bus transactions.
   *                    o returns to user code.
   *                    o SRAM retained.
   *                    o does not reboot the device.
   *
   *    SYSREBOOT_SOFT  o resets execution-related components of the system.
   *                    o Peripheral state is maintained
   *                    o system-level bus transactions maintained.
   *                    o returns to user-code
   *                    o does not reboot the device.
   *
   *    SYSREBOOT_EXTEND what values to use to extend the sysreboot functionality.
   *
   * SysReboot.flush(): is called when the callee wants to tell any components that cares
   * about a pending SysReset/Reboot.  This gives those components the opportunity to
   * flush any pertinent information prior to the Reboot/Reset.  Must run to completion.
   *
   * Shutdown_flush is used to signal to any components wired in that a reboot/reset
   * is pending and the component should write out any data is maybe cacheing.  Must
   * run to completion.  No invoking tasks etc.  These will not run.
   */
  async command error_t reboot(sysreboot_t reboot_type);
  async command error_t soft_reboot(sysreboot_t reboot_type);
  async command void    clear(sysreboot_t reboot_type);
  async command void    flush();

  async event void shutdown_flush();
}
