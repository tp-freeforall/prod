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
#include "Timer.h"

/**
 * Wraps/renames ChipconActiveMessageC.
 */
configuration ActiveMessageC {
	provides {
		interface StdControl;
		interface SplitControl;

		interface AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];

		interface Packet;
		interface AMPacket;
		interface PacketAcknowledgements;
		interface LowPowerListening;
		
		interface PacketTimeStamp<TMilli, uint32_t>;
		interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
	}
}

implementation {
	
	components ChipconActiveMessageC as AM;
	
	StdControl = AM;
	SplitControl = AM;
	AMSend = AM;
	Receive = AM.Receive;
	Snoop = AM.Snoop;
	Packet = AM;
	AMPacket = AM;
	PacketAcknowledgements = AM;
	LowPowerListening = AM;
	PacketTimeStamp = AM;
	PacketTimeStamp32khz = AM;
	
}
