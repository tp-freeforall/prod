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

module PacketTimeSyncP {
	provides {
		interface TimeSyncAMSend<T32khz, uint32_t> as TimeSyncAMSend32khz[am_id_t id];
		interface TimeSyncPacket<T32khz, uint32_t> as TimeSyncPacket32khz;
		
		interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];
		interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
		
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];
		interface Packet;
		interface AMPacket;
	}
	
	uses {
		interface AMSend as SubSend;
		interface Receive as SubReceive;
		interface Receive as SubSnoop;
		interface Packet as SubPacket;
		interface AMPacket as SubAMPacket;
		interface SendNotify;
		interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
		interface LocalTime<TMilli> as LocalTimeMilli;
		interface LocalTime<T32khz> as LocalTime32khz;
	}
}

implementation {
	
	#define HEADER_SIZE sizeof(chipcon_timesync_header_t)
	
	bool busy;
	message_t* sending;
	uint32_t txTime;
	
	chipcon_timesync_header_t* getHeader(message_t* msg) {
		return (chipcon_timesync_header_t*) call SubPacket.getPayload(msg, call SubPacket.maxPayloadLength());
	}
	
	// convert a timestamp (not a duration) in milliseconds to a time in 32khz ticks based on the local clocks
	uint32_t millis2jiffies(uint32_t timestamp) {
		uint32_t dtMilli = call LocalTimeMilli.get() - timestamp;
		uint32_t dt32khz = dtMilli * 32;
		return call LocalTime32khz.get() - dt32khz;
	}
	
	// convert a timestamp (not a duration) in 32khz ticks to a time in milliseconds based on the local clocks
	uint32_t jiffies2millis(uint32_t timestamp) {
		uint32_t dt32khz = call LocalTime32khz.get() - timestamp;
		uint32_t dtMilli = dt32khz / 32;
		return call LocalTimeMilli.get() - dtMilli;
	}
	
	command error_t TimeSyncAMSend32khz.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len, uint32_t eventTime) {
		chipcon_timesync_header_t* header;
		error_t error;
		
		if (busy) return EBUSY;
		
		header = getHeader(msg);
		header->type = id;
		header->eventTime = TIMESTAMP_INVALID;
		sending = msg;
		txTime = eventTime;
		error = call SubSend.send(addr, msg, len + HEADER_SIZE);
		
		if (error == SUCCESS) {
			busy = TRUE;
		}
		
		return error;
	}
	
	command error_t TimeSyncAMSend32khz.cancel[am_id_t](message_t* msg) {
		return call SubSend.cancel(msg);
	}
	
	event void SubSend.sendDone(message_t* msg, error_t error) {
		busy = FALSE;
		
		// we can't distinguish whether the message was sent through the T32khz or TMilli interface, so signal on both
		signal TimeSyncAMSend32khz.sendDone[getHeader(msg)->type](msg, error);
		signal TimeSyncAMSendMilli.sendDone[getHeader(msg)->type](msg, error);
	}
	
	command uint8_t TimeSyncAMSend32khz.maxPayloadLength[am_id_t]() {
		return call SubSend.maxPayloadLength() - HEADER_SIZE;
	}
	
	command void* TimeSyncAMSend32khz.getPayload[am_id_t](message_t* msg, uint8_t len) {
		return call SubSend.getPayload(msg, len + HEADER_SIZE) + HEADER_SIZE;
	}
	
	command error_t TimeSyncAMSendMilli.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len, uint32_t eventTime) {
		return call TimeSyncAMSend32khz.send[id](addr, msg, len, millis2jiffies(eventTime));
	}
	
	command error_t TimeSyncAMSendMilli.cancel[am_id_t id](message_t* msg) {
		return call TimeSyncAMSend32khz.cancel[id](msg);
	}
	
	command uint8_t TimeSyncAMSendMilli.maxPayloadLength[am_id_t id]() {
		return call TimeSyncAMSend32khz.maxPayloadLength[id]();
	}
	
	command void* TimeSyncAMSendMilli.getPayload[am_id_t id](message_t* msg, uint8_t len) {
		return call TimeSyncAMSend32khz.getPayload[id](msg, len);
	}
	
	command bool TimeSyncPacket32khz.isValid(message_t* msg) {
		return call SubAMPacket.type(msg) == AM_TIMESYNCMSG &&
			call TimeSyncPacket32khz.eventTime(msg) != TIMESTAMP_INVALID;
	}
	
	command uint32_t TimeSyncPacket32khz.eventTime(message_t* msg) {
		chipcon_timesync_header_t* header = getHeader(msg);
		return header->eventTime;
	}
	
	command bool TimeSyncPacketMilli.isValid(message_t* msg) {
		return call TimeSyncPacket32khz.isValid(msg);
	}
	
	command uint32_t TimeSyncPacketMilli.eventTime(message_t* msg) {
		return jiffies2millis(call TimeSyncPacket32khz.eventTime(msg));
	}
	
	am_id_t received(message_t* msg) {
		// convert "air time" to local time
		chipcon_timesync_header_t* header = getHeader(msg);
		header->eventTime = call PacketTimeStamp32khz.timestamp(msg) - header->eventTime;
		return header->type;
	}
	
	event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
		am_id_t type = received(msg);
		return signal Receive.receive[type](msg, payload + HEADER_SIZE, len - HEADER_SIZE);
	}
	
	event message_t* SubSnoop.receive(message_t* msg, void* payload, uint8_t len) {
		am_id_t type = received(msg);
		return signal Snoop.receive[type](msg, payload + HEADER_SIZE, len - HEADER_SIZE);
	}
	
	event void SendNotify.sending(message_t* msg) {
		// if it is our message being sent, put in the event time now that it is timestamped
		if (msg == sending) {
			chipcon_timesync_header_t* header = getHeader(sending);
			header->eventTime = call PacketTimeStamp32khz.timestamp(sending) - txTime;
		}
	}
	
	// mostly wire-through of the Packet and AMPacket interfaces
	command void Packet.clear(message_t* msg) {
		call SubPacket.clear(msg);
	}

	command void Packet.setPayloadLength(message_t* msg, uint8_t len) 	{
		call SubPacket.setPayloadLength(msg, len + HEADER_SIZE);
	}

	command uint8_t Packet.payloadLength(message_t* msg) 	{
		return call SubPacket.payloadLength(msg) - HEADER_SIZE;
	}

	command uint8_t Packet.maxPayloadLength() 	{
		return call SubPacket.maxPayloadLength() - HEADER_SIZE;
	}

	command void* Packet.getPayload(message_t* msg, uint8_t len) {
		return call SubPacket.getPayload(msg, len + HEADER_SIZE);
	}

	command am_addr_t AMPacket.address() {
		return call SubAMPacket.address();
	}
 
	command am_group_t AMPacket.localGroup() {
		return call SubAMPacket.localGroup();
	}

	command bool AMPacket.isForMe(message_t* msg) {
		return call SubAMPacket.isForMe(msg) && call SubAMPacket.type(msg) == AM_TIMESYNCMSG;
	}

	command am_addr_t AMPacket.destination(message_t* msg) {
		return call SubAMPacket.destination(msg);
	}
 
	command void AMPacket.setDestination(message_t* msg, am_addr_t addr) {
		call SubAMPacket.setDestination(msg, addr);
	}

	command am_addr_t AMPacket.source(message_t* msg) {
		return call SubAMPacket.source(msg);
	}

	command void AMPacket.setSource(message_t* msg, am_addr_t addr) {
		call SubAMPacket.setSource(msg, addr);
	}

	command am_id_t AMPacket.type(message_t* msg) {
		return getHeader(msg)->type;
	}

	command void AMPacket.setType(message_t* msg, am_id_t type) {
		getHeader(msg)->type = type;
	}
  
	command am_group_t AMPacket.group(message_t* msg) {
		return call SubAMPacket.group(msg);
	}

	command void AMPacket.setGroup(message_t* msg, am_group_t grp) {
		call SubAMPacket.setGroup(msg, grp);
	}
	
	default event message_t* Snoop.receive[am_id_t](message_t* msg, void* payload, uint8_t len) {
		return msg;
	}
	
	default event message_t* Receive.receive[am_id_t](message_t* msg, void* payload, uint8_t len) {
		return msg;
	}
	
	default event void TimeSyncAMSend32khz.sendDone[am_id_t](message_t* msg, error_t error) {}
	default event void TimeSyncAMSendMilli.sendDone[am_id_t](message_t* msg, error_t error) {}
}
