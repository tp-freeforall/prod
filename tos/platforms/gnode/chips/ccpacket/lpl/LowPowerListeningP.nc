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
 * Provides duty cycling/low power listening.
 */
module LowPowerListeningP {
	provides {
		interface StdControl;
		interface Send;
		interface Receive;
		interface LowPowerListening;
		interface SendNotify;
	}
	
	uses {
		interface Send as SubSend;
		interface Receive as SubReceive;
		interface StdControl as SubControl;
		interface HalChipconControl;
		interface ChipconPacket;
		interface Timer<TMilli> as DutyCycleTimer;
		interface Timer<TMilli> as CcaSampleTimer;
		interface Timer<TMilli> as ReceiveTimer;
		interface BusyWait<TMicro, uint16_t>;
	}
}

implementation {
	
	// because the default value for the rxInterval field is zero when a packet is cleared,
	// and we take that as a sign to use the default LPL interval, i.e. our own,
	// we need a separate marker for when a client explicitly requests an interval of zero
	#define EXPLICIT_ZERO 0xFFFF
	
	bool componentOn = FALSE;	// is this component running, i.e. is the radio on or duty cycling?
	bool radioOn = FALSE;		// is the actual radio on, i.e. in its active duty cycle?
	bool sending = FALSE;		// outgoing packet pending?
	uint16_t wakeupInterval = LPL_DEFAULT_INTERVAL;	// time between receive checks; 0 means always on
	uint16_t calibrationCounter;	// when duty cycling, calibrate the radio when this hits zero
	uint8_t ccaCounter;		// counts channel-not-clear detections
	
	void on() {
		error_t error = call SubControl.start();
		assert(error == SUCCESS || error == EALREADY, ASSERT_CC_LPL_START);
		radioOn = TRUE;
	}
	
	void off() {
		error_t error = call SubControl.stop();
		if (error == SUCCESS) {
			radioOn = FALSE;
		} else {
			// we only expect one kind of error, if AckP is busy
			// in which case we'll get a receive() which will result in turning off the radio
			assert(error == EBUSY, ASSERT_CC_LPL_STOP);
		}
	}
	
	/**
	 * Start the radio, either duty cycling or always on.
	 * @return SUCCESS 
	 */
	command error_t StdControl.start() {
		componentOn = TRUE;
		
		// set desired calibration mode
		// if we're always on, let the radio calibrate automatically on every RX/TX
		// if we are duty cycling, this introduces too much overhead so we calibrate manually every CALIBRATION_INTERVAL
		on();
		call HalChipconControl.autoCalibrate(wakeupInterval == 0);
		
		if (wakeupInterval > 0) {
			calibrationCounter = 0;
			call DutyCycleTimer.startPeriodic(wakeupInterval);
			off();
		}
		
		return SUCCESS;
	}
	
	/**
	 * Stop duty cycling and turn the radio off.
	 */
	command error_t StdControl.stop() {
		call DutyCycleTimer.stop();
		call CcaSampleTimer.stop();
		call ReceiveTimer.stop();
		
		componentOn = FALSE;
		if (radioOn) off();
		
		return SUCCESS;
	}
	
	command error_t Send.send(message_t* m, uint8_t len) {
		error_t error;
		chipcon_metadata_t* metadata = call ChipconPacket.getMetadata(m);
		
		if (sending) return EBUSY;
		sending = TRUE;
		
		// stop any current receive checks
		call CcaSampleTimer.stop();
		call ReceiveTimer.stop();
		
		// if the receiver sleep interval is not set, use our own
		if (call LowPowerListening.getRemoteWakeupInterval(m) == 0) {
			metadata->rxInterval = wakeupInterval;
		}
		
		// if the sender explicitly requested a zero interval, set that now
		if (call LowPowerListening.getRemoteWakeupInterval(m) == EXPLICIT_ZERO) {
			// can't go through LowPowerListening.setRemoteWakeupInterval(),
			// because it would just set it to EXPLICIT_ZERO again
			metadata->rxInterval = 0;
		}
		
		// if the radio is not on already, turn it on now
		if (!radioOn) on();
		
		// hook for others to make last minute adjustments,
		// especially to the preamble duration
		signal SendNotify.sending(m);

		// lower layers should never fail at this point,
		// since we are not busy (we checked) and we just
		// turned the radio on
		error = call SubSend.send(m, len);
		assertSuccess(error, ASSERT_CC_LPL_SEND);
		return SUCCESS;
	}
	
	event void SubSend.sendDone(message_t* msg, error_t error) {
		// turn the radio off if we're duty cycling and not busy
		if (wakeupInterval > 0) {
			// We may be slow to get here and another packet, like an ack or reply, could already be in the air,
			// so do a receive check before turning off the radio.
			// Testing shows we should wait a little longer after transmitting than after just waking up
			// to prevent false positives, so add 1 ms.
			call CcaSampleTimer.startOneShot(CCA_SETTLING_TIME + 1);
		}
		
		sending = FALSE;
		signal Send.sendDone(msg, error);
	}
	
	command error_t Send.cancel(message_t* msg) {
		return call SubSend.cancel(msg);
	}
	
	command uint8_t Send.maxPayloadLength() {
		return call SubSend.maxPayloadLength();
	}
	
	command void* Send.getPayload(message_t* msg, uint8_t len) {
		return call SubSend.getPayload(msg, len);
	}
	
	/**
	 * Turn the radio on, set to receive and see if there's anyone out there.
	 * If there is, leave the radio on to receive. If not, turn the radio off again.
	 */
	event void DutyCycleTimer.fired() {
		// skip receive check if radio already on (either we're sending or still listening (ReceiveTimer))
		if (radioOn) return;
		
		on();
		
		// calibrate the radio when the counter hits zero, then reset the counter
		// so we calibrate approximately once a minute
		if (calibrationCounter == 0) {
			call HalChipconControl.calibrate();
			calibrationCounter = CALIBRATION_INTERVAL / wakeupInterval;
		} else {
			calibrationCounter--;
		}
		
		ccaCounter = 0;
		call CcaSampleTimer.startOneShot(CCA_SETTLING_TIME);
	}
	
	bool clear() {
		return !call HalChipconControl.isBusy() && call HalChipconControl.isChannelClear();
	}
	
	/**
	 * Radio is now ready to check for a clear channel.
	 */
	event void CcaSampleTimer.fired() {
		if (clear()) {
			// assume we don't get false negatives and go back to sleep
			off();
		} else {
			// 1 ms may be just a bit too fast for reliable CCA and can give us a false positive,
			// so check again after the first "hit"
			ccaCounter++;
			if (ccaCounter < 2) {
				// check again in another millisecond
				call CcaSampleTimer.startOneShot(1);
			} else {
				// stay awake
				call ReceiveTimer.startOneShot(wakeupInterval + LPL_PREAMBLE_OVERLAP);
			}
		}
	}
	
	/**
	 * If something is being received, or there is still a carrier,
	 * stay awake and check again after another interval.
	 * Else, go back to sleep.
	 */
	event void ReceiveTimer.fired() {
		if (clear()) {
			off();
		} else {
			call ReceiveTimer.startOneShot(wakeupInterval + LPL_PREAMBLE_OVERLAP);
		}
	}
	
	/**
	 * A message has arrived. Stop the receive timer, go back to sleep and deliver the message.
	 */
	event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
		assert(radioOn, ASSERT_CC_LPL_OFF);
		
		call CcaSampleTimer.stop();
		call ReceiveTimer.stop();
		
		// turn the radio off if we're duty cycling and not trying to send a message
		// TODO: stay awake for a bit?
		if (wakeupInterval > 0 && !sending) {
			// see SubSend.sendDone() - do a receive check before turning off the radio
			call CcaSampleTimer.startOneShot(CCA_SETTLING_TIME);
		}
		
		return signal Receive.receive(msg, payload, len);
	}
	
	command void LowPowerListening.setLocalWakeupInterval(uint16_t intervalMs) {
		uint16_t oldInterval = wakeupInterval;
		wakeupInterval = intervalMs;
		calibrationCounter = 0;
		
		if (wakeupInterval == 0) {
			// always on, so stop the timers
			call DutyCycleTimer.stop();
			call CcaSampleTimer.stop();
			call ReceiveTimer.stop();
		}
		
		// if we've been started, set the desired calibration mode while the radio is on
		// else, it'll be done from StdControl.start()
		if (componentOn && oldInterval == 0 && wakeupInterval != 0) {
			// the radio was always on and should now start duty cycling
			// turn off automatic calibration before turning the radio off,
			// we'll manually calibrate every CALIBRATION_INTERVAL
			call HalChipconControl.autoCalibrate(FALSE);
			off();
			call DutyCycleTimer.startPeriodic(wakeupInterval);
		}
		
		if (componentOn && wakeupInterval == 0 && !radioOn) {
			// we're supposed to be always on and the radio is currently turned off, so turn it on
			on();
			
			// turn on automatic calibration
			call HalChipconControl.autoCalibrate(TRUE);
		}
	}
	
	command uint16_t LowPowerListening.getLocalWakeupInterval() {
		return wakeupInterval;
	}
	
	command void LowPowerListening.setRemoteWakeupInterval(message_t *msg, uint16_t intervalMs) {
		// Since zero is interpreted as "use the default interval", we use a separate marker value
		// for an explicitly requested zero interval. This means you can't set a 65535 ms preamble,
		// but the HAL won't send one longer than a minute anyway.
		if (intervalMs == 0) intervalMs = EXPLICIT_ZERO;
		(call ChipconPacket.getMetadata(msg))->rxInterval = intervalMs;
	}
	
	command uint16_t LowPowerListening.getRemoteWakeupInterval(message_t *msg) {
		// this returns the actual field value, so EXPLICIT_ZERO is not converted back to zero!
		return (call ChipconPacket.getMetadata(msg))->rxInterval;
	}
	
	event void HalChipconControl.rxWaiting(uint32_t timestamp) {}
	event void HalChipconControl.txStart(uint32_t timestamp) {}
	event void HalChipconControl.txDone(uint32_t timestamp, error_t error) {}

	default event void SendNotify.sending(message_t* msg) {}
}
