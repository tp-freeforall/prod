/*
 * Copyright (c) 2011 Eric B. Decker
 * Copyright (c) 2000-2005 The Regents of the University of California.  
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
 *
 * @author Ben Greenstein <ben@cs.ucla.edu>
 * @author Joe Polastre <info@moteiv.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include "Msp430Dma.h"

interface Msp430DmaChannel {

  async command error_t setupTransfer(uint16_t control,
				      dma_trigger_t trigger, 
				      uint16_t src_addr, 
				      uint16_t dst_addr, 
				      uint16_t size);

  /**
   * Enable the DMA module.  Equivalent to setting the DMA enable bit.
   * This function does not force a transfer.
   */
  async command error_t enableDma();

  /**
   * Repeat a DMA transfer using previous settings but new pointers
   * and transfer size.  Also sets the enable bit but doesn't
   * necessarily start the transfer (depends on the dma settings.
   */
  async command error_t repeatDma(uint16_t src_addr,
				  uint16_t dst_addr,
				  uint16_t size);

  /**
   * Trigger a DMA transfer using software
   */
  async command error_t softwareTrigger();

  /**
   * Stop a DMA transfer in progress
   */
  async command error_t stopDma();

  /**
   * Notification that the transfer has completed
   *
   * Used to have an error return but this could only fail
   * because of an ABORT.  This has been nuked.
   */
  async event void transferDone();

  /**
   * Poll to see if the transfer has completed.
   *
   */
  async command bool dmaComplete();
}
