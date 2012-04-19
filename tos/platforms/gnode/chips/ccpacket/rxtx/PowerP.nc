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

module PowerP {
	provides interface StdControl;
	uses interface HalChipconControl;
}

implementation {

	bool on = FALSE;
	
	/**
	 * Power up the radio, go into RX mode, unless the radio
	 * is already on, in which case this does nothing (leaves radio in current state).
	 * @return SUCCESS
	 */
	command error_t StdControl.start() {
		if (!on) {
			call HalChipconControl.on();
			on = TRUE;
		}
		
		return SUCCESS;
	}
	
	/**
	 * Power down the radio if it is not already off.
	 * @return SUCCESS
	 */
	command error_t StdControl.stop() {
		if (on) {
			call HalChipconControl.off();
			on = FALSE;
		}
		
		return SUCCESS;
	}
	
	event void HalChipconControl.txStart(uint32_t timestamp) {}
	event void HalChipconControl.txDone(uint32_t timestamp, error_t error) {}
	event void HalChipconControl.rxWaiting(uint32_t timestamp) {}
}
