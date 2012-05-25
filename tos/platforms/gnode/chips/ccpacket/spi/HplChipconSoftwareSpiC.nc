/*
 * Copyright (c) 2008-2012, SOWNet Technologies B.V.
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
*/

#include "platform.h"

/**
 * Provides a software implementation of the SPI protocol for use on MSP430 processors
 * that do not have a hardware SPI bus.
 */
configuration HplChipconSoftwareSpiC {
	provides {
		interface Resource;
		interface HplChipconSpi;
	}
}

implementation {
	
	components PlatformP, DedicatedResourceC, HplChipconSpiGenericP, HplChipconSoftwareSpiP as Spi, HplChipconPacketRadioC as Hpl;
	
	Resource = DedicatedResourceC;
	HplChipconSpi = HplChipconSpiGenericP;
	
	HplChipconSpiGenericP.SpiByte -> Spi.SpiByte;
	HplChipconSpiGenericP.WriteOnly -> Spi.WriteOnly;
	HplChipconSpiGenericP.ReadOnly -> Spi.ReadOnly;
	
	Spi.MOSI -> Hpl.SI;
	Spi.MISO -> Hpl.SO;
	Spi.Clock -> Hpl.Clock;
	Spi.Init <- PlatformP.InitLevel[PLATFORM_INIT_GPIO + 1];
	
}
