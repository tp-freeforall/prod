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
#include "ChipconAssert.h"

// the radio stack uses platform_printf debug statements which can be redirected to printf,
// but the default is to turn them into no-ops
#ifndef platform_printf
#define platform_printf(...);
#endif

/**
 * The Active Message layer for the Chipcon packet radio.
 * In addition to the required SplitControl, it also offers StdControl.
 */
configuration ChipconActiveMessageC {
	provides {
		interface StdControl;
		interface SplitControl;
		interface AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];
		interface AMPacket;
		interface Packet;
		interface LowPowerListening;
		interface PacketAcknowledgements;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
		interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
	}
}

implementation {
	components ActiveMessageAddressC, ChipconPacketC, PacketMetadataC, ChipconActiveMessageP as AM, CrcC;
	
	components PacketTimeStampC;

#ifdef LOW_POWER_LISTENING
	components LowPowerListeningC as LPL;
#else
	components NoLowPowerListeningC as LPL;
#endif
	
	components AckC;
	components SendReceiveC;

	StdControl = AM;
	SplitControl = AM;
	AMSend = AM;
	Receive = AM.Receive;
	Snoop = AM.Snoop;
	
	Packet = ChipconPacketC;
	AMPacket = ChipconPacketC;
	PacketAcknowledgements = ChipconPacketC;
	LowPowerListening = LPL;
	PacketTimeStampMilli = PacketTimeStampC;
	PacketTimeStamp32khz = PacketTimeStampC;
	
	AM.AMPacket -> ChipconPacketC;
	AM.PacketMetadata -> PacketMetadataC;
	AM.SubControl -> LPL;
	AM.SubSend -> LPL;
	AM.SubReceive -> LPL;
	AM.Crc -> CrcC;
	
	LPL.SubControl -> AckC;
	LPL.SubSend -> AckC;
	LPL.SubReceive -> AckC;
	
	AckC.SubControl -> SendReceiveC;
	AckC.SubSend -> SendReceiveC;
	AckC.SubReceive -> SendReceiveC;
		
}
