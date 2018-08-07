/*
 * Copyright (c) 2010-2011 Eric B. Decker
 * Copyright (c) 2009 DEXMA SENSORS SL
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * @author Jonathan Hui <jhui@archedrock.com>
 * @author Mark Hays
 * @author Xavier Orduna <xorduna@dexmatech.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include "Msp430Dma.h"

configuration Msp430SpiA0DmaP {
  provides {
    interface Resource[uint8_t id];
    interface ResourceConfigure[uint8_t id];
    interface SpiByte;
    interface SpiPacket[uint8_t id];
  }
  uses {
    interface Resource as UsciResource[uint8_t id];
    interface Msp430SpiConfigure[uint8_t id];
    interface HplMsp430UsciInterrupts as UsciInterrupts;
  }
}

implementation {
  components new Msp430SpiDmaP(IFG2_,
			       UCA0TXBUF_,
			       UCA0TXIFG,
			       DMA_TRIGGER_UCA0TXIFG,	// USCI_A0 TX on x2
			       UCA0RXBUF_,
			       UCA0RXIFG,
			       DMA_TRIGGER_UCA0RXIFG)	// USCI_A0 RX on x2
    as SpiP;

  Resource = SpiP.Resource;
  ResourceConfigure = SpiP.ResourceConfigure;
  Msp430SpiConfigure = SpiP.Msp430SpiConfigure;
  SpiByte = SpiP.SpiByte;
  SpiPacket = SpiP.SpiPacket;
  UsciResource = SpiP.UsciResource;
  UsciInterrupts = SpiP.UsciInterrupts;

  components HplMsp430UsciA0C as UsciC;
  SpiP.Usci -> UsciC;
  SpiP.Spi -> UsciC;

  components Msp430DmaC as DmaC;
  SpiP.DmaChannel1 -> DmaC.Channel1;
  SpiP.DmaChannel2 -> DmaC.Channel2;
#ifdef DMA_VERBOSE
#warning Msp430SpiA0DmaP: using dma channels 1 and 2
#endif
}
