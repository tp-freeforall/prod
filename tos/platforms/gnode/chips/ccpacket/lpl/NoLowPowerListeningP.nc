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
 * Disables duty cycling/low power listening, although you can still send to a node which duty cycles.
 */
module NoLowPowerListeningP {
	provides {
		interface LowPowerListening;
	}
	
	uses {
		interface ChipconPacket;
	}
}

implementation {
	
	command void LowPowerListening.setLocalWakeupInterval(uint16_t sleepIntervalMs) {
		// the only valid value is 0
		assertEquals(sleepIntervalMs, 0, ASSERT_CC_LPL_OFF);
	}
	
	/**
	 * @return the local node's sleep interval, in milliseconds
	 */
	command uint16_t LowPowerListening.getLocalWakeupInterval() {
		return 0;
	}
	
	/**
	 * Configure this outgoing message so it can be transmitted to a neighbor mote
	 * with the specified Rx sleep interval.
	 * @param msg Pointer to the message that will be sent
	 * @param sleepInterval The receiving node's sleep interval, in milliseconds
	 */
	command void LowPowerListening.setRemoteWakeupInterval(message_t *msg, uint16_t sleepIntervalMs) {
		(call ChipconPacket.getMetadata(msg))->rxInterval = sleepIntervalMs;
	}
	
	/**
	 * @return the destination node's sleep interval configured in this message
	 */
	command uint16_t LowPowerListening.getRemoteWakeupInterval(message_t *msg) {
		return (call ChipconPacket.getMetadata(msg))->rxInterval;
	}
	
}
