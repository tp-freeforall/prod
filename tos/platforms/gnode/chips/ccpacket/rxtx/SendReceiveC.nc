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
 * Wire up Send, Receive and Power modules to provide a minimal HIL stack.
 */ 
configuration SendReceiveC {
	provides {
		interface StdControl;
		interface Receive;
		interface Send;
		interface SendNotify;
	}
}

implementation {
	
	components HalChipconControlC, ChipconPacketC;
	
	components SendP, RandomC, new TimerMilliC() as BackoffTimer, new TimerMilliC() as PreambleTimer;
	SendP.Random -> RandomC;
	SendP.BackoffTimer -> BackoffTimer;
	SendP.PreambleTimer -> PreambleTimer;
	SendP.ChipconPacket -> ChipconPacketC;
	SendP.PacketTimeStamp -> ChipconPacketC;
	SendP.HalChipconControl -> HalChipconControlC;
	
	components ReceiveP;
	ReceiveP.Packet -> ChipconPacketC;
	ReceiveP.ChipconPacket -> ChipconPacketC;
	ReceiveP.PacketTimeStamp -> ChipconPacketC;
	ReceiveP.HalChipconControl -> HalChipconControlC;
	
	components PowerP;
	PowerP.HalChipconControl -> HalChipconControlC;
	
	components SendReceiveP;
	SendReceiveP.SubControl -> PowerP;
	SendReceiveP.SubControl -> SendP;
	SendReceiveP.SubSend -> SendP;
	SendReceiveP.SubReceive -> ReceiveP;
	SendReceiveP.ChipconPacket -> ChipconPacketC;
	
	StdControl = SendReceiveP;
	Receive = SendReceiveP;
	Send = SendReceiveP;
	SendNotify = SendP;
	
}
