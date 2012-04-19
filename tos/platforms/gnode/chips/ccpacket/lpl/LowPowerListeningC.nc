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

#include "LowPowerListening.h"

/**
 * Provides duty cycling/low power listening.
 */
configuration LowPowerListeningC {
	provides {
		interface StdControl;
		interface Send;
		interface Receive;
		interface LowPowerListening;
	}
	
	uses {
		interface StdControl as SubControl;
		interface Send as SubSend;
		interface Receive as SubReceive;
	}
}

implementation {
	
	components LowPowerListeningP, HalChipconControlC, ChipconPacketC, BusyWaitMicroC;
	components new TimerMilliC() as DutyCycleTimer, new TimerMilliC() as CcaSampleTimer, new TimerMilliC() as ReceiveTimer;
	
	LowPowerListeningP.DutyCycleTimer -> DutyCycleTimer;
	LowPowerListeningP.CcaSampleTimer -> CcaSampleTimer;
	LowPowerListeningP.ReceiveTimer -> ReceiveTimer;
	LowPowerListeningP.BusyWait -> BusyWaitMicroC;
	LowPowerListeningP.HalChipconControl -> HalChipconControlC;
	LowPowerListeningP.ChipconPacket -> ChipconPacketC;
	
	LowPowerListeningP.SubControl = SubControl;
	LowPowerListeningP.SubSend = SubSend;
	LowPowerListeningP.SubReceive = SubReceive;
	
	StdControl = LowPowerListeningP;
	Receive = LowPowerListeningP;
	Send = LowPowerListeningP;
	LowPowerListening = LowPowerListeningP;
	
}
