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

generic module LplAMSenderP()
{
	provides interface AMSend;
	uses {
		interface AMSend as SubAMSend;
		interface LowPowerListening as Lpl;
		interface SystemLowPowerListening;
	}
}

implementation
{
	command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
		// if the interval was not set, use the system default
		// otherwise, leave it unchanged
		if (call Lpl.getRemoteWakeupInterval(msg) == 0) {
//			printf("LPLAM: setting default interval: %u ms\n", call SystemLowPowerListening.getDefaultRemoteWakeupInterval());
			call Lpl.setRemoteWakeupInterval(msg, call SystemLowPowerListening.getDefaultRemoteWakeupInterval());
		} else {
//			printf("LPLAM: interval already set: %u ms\n", call Lpl.getRemoteWakeupInterval(msg));
		}
		return call SubAMSend.send(addr, msg, len);
	}

	event void SubAMSend.sendDone(message_t* msg, error_t error) { signal AMSend.sendDone(msg, error); }
	command error_t AMSend.cancel(message_t* msg) { return call SubAMSend.cancel(msg); }
	command uint8_t AMSend.maxPayloadLength() { return call SubAMSend.maxPayloadLength(); }
	command void* AMSend.getPayload(message_t* msg, uint8_t len) { return call SubAMSend.getPayload(msg, len); }
}
