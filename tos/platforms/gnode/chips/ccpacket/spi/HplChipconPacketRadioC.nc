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

/**
 * Provides the GPIO and SPI interface to a Chipcon radio.
 */
configuration HplChipconPacketRadioC {
	provides {
		interface Resource;
		interface HplChipconSpi;
		interface GeneralIO as SI;
		interface GeneralIO as SO;
		interface GeneralIO as Clock;
		interface GeneralIO as CSn;
		interface GeneralIO as G0;
		interface GeneralIO as G2;
		interface GpioInterrupt as G0Interrupt;
	}
}

implementation {

	#ifdef CHIPCON_SOFTWARE_SPI
		#warning "Falling back to software SPI"
		components HplChipconSoftwareSpiC as SpiC;
	#else
		components HplChipconHardwareSpiC as SpiC;
	#endif
	
	components GeneralIOC;
	
	Resource = SpiC;
	HplChipconSpi = SpiC;
	
	SI = GeneralIOC.GeneralIO[RADIO_SI];
	SO = GeneralIOC.GeneralIO[RADIO_SO];
	Clock = GeneralIOC.GeneralIO[RADIO_CLK];
	CSn = GeneralIOC.GeneralIO[RADIO_CSN];
	G0 = GeneralIOC.GeneralIO[RADIO_G0];
	G2 = GeneralIOC.GeneralIO[RADIO_G2];
	G0Interrupt = GeneralIOC.GpioInterrupt[RADIO_G0];
	
}
