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

#include "AM.h"
#include "HalChipconControl.h"

/**
 * Radio control and configuration.
 */
configuration HalChipconControlC {
	provides {
		interface HalChipconControl;
		interface Get<cc_hal_status_t*> as Status;
	}
}

implementation {
	
	components MainC, BusyWaitMicroC, ActiveMessageAddressC, LocalTime32khzC;
	components HalChipconControlP, HplChipconPacketRadioC, new TimerMilliC();

	HalChipconControl =  HalChipconControlP;
	Status =  HalChipconControlP;
	
	MainC.SoftwareInit -> HalChipconControlP;

	HalChipconControlP.ActiveMessageAddress -> ActiveMessageAddressC;
	HalChipconControlP.BusyWait -> BusyWaitMicroC;
	HalChipconControlP.SpiResource-> HplChipconPacketRadioC;
	HalChipconControlP.HplChipconSpi -> HplChipconPacketRadioC;
	HalChipconControlP.SI -> HplChipconPacketRadioC.SI;
	HalChipconControlP.SO -> HplChipconPacketRadioC.SO;
	HalChipconControlP.Clock -> HplChipconPacketRadioC.Clock;
	HalChipconControlP.CSn -> HplChipconPacketRadioC.CSn;
	HalChipconControlP.G0 -> HplChipconPacketRadioC.G0;
	HalChipconControlP.G2 -> HplChipconPacketRadioC.G2;
	HalChipconControlP.G0Interrupt -> HplChipconPacketRadioC.G0Interrupt;
	HalChipconControlP.TxTimer -> TimerMilliC;
	HalChipconControlP.LocalTime -> LocalTime32khzC;
}
