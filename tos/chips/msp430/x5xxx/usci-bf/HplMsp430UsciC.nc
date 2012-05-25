/*
 * Copyright (c) 2009-2010 People Power Co.
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

#include "msp430usci.h"

/**
 * Core configuration for any USCI module present on an MSP430 chip.
 *
 * There should be exactly one instance of this configuration for each
 * USCI module; e.g., USCI_A0 or USCI_B3.  Each instance provides
 * access to the USCI registers for its module, and maintains the
 * resource management information required to determine which of the
 * module's modes is currently active.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

generic configuration HplMsp430UsciC(

  /**
   * Offset of UCmxCTLW0_ register for m=module_type and x=module_instance
   *
   * UCmxCTLW0 is the base address for the module.
   */
  unsigned int UCmxCTLW0_,

  /** Name of resource used to arbitrate modes of this USCI instance */
  char RESOURCE_NAME[]

) @safe() {
  provides {
    interface HplMsp430Usci as Usci;
    interface HplMsp430UsciInterrupts as Interrupts[ uint8_t mode ];
    interface Resource[uint8_t client];
    interface ResourceRequested[uint8_t client];
    interface ResourceDefaultOwner;
    interface ArbiterInfo;
  }
  uses {
    interface HplMsp430UsciInterrupts as RawInterrupts;
    interface ResourceConfigure[uint8_t client];
  }
}
implementation {

  enum {
    USCI_ID = unique(MSP430_USCI_RESOURCE),
  };

  components new HplMsp430UsciP(USCI_ID, UCmxCTLW0_) as HplUsciP;
  Usci = HplUsciP;
  RawInterrupts = HplUsciP;
  Interrupts = HplUsciP;

  components new FcfsArbiterC( RESOURCE_NAME ) as ArbiterC;
  Resource = ArbiterC;
  ResourceRequested = ArbiterC;
  ResourceConfigure = ArbiterC;
  ResourceDefaultOwner = ArbiterC;
  ArbiterInfo = ArbiterC;
  HplUsciP.ArbiterInfo -> ArbiterC;

  components LedsC;
  HplUsciP.Leds -> LedsC;
}
