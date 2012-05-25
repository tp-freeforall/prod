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

module PacketTimeStampP {
	provides {
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
	}
	
	uses {
		interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
		interface LocalTime<TMilli> as LocalTimeMilli;
		interface LocalTime<T32khz> as LocalTime32khz;
	}
}

implementation {
	
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
	
	async command bool PacketTimeStampMilli.isValid(message_t* msg) {
		return call PacketTimeStamp32khz.isValid(msg);
	}
	
	async command void PacketTimeStampMilli.clear(message_t* msg) {
		call PacketTimeStamp32khz.clear(msg);
	}
	
	async command uint32_t PacketTimeStampMilli.timestamp(message_t* msg) {
		return jiffies2millis(call PacketTimeStamp32khz.timestamp(msg));
	}
	
	async command void PacketTimeStampMilli.set(message_t* msg, uint32_t value) {
		call PacketTimeStamp32khz.set(msg, millis2jiffies(value));
	}
	
}
