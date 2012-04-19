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

interface HalChipconControl {
	
	/**
	 * Configure the radio with default settings, then power it down and release the SPI bus.
	 */
	command void init();
	
	/**
	 * Claim the SPI bus, power up the radio chip and go to RX mode.
	 * @pre SPI bus not already owned and immediately available
	 */
	command void on();
	
	/**
	 * Power down and release the SPI bus.
	 */
	command void off();
	
	/**
	 * Switch to TX mode and send the data in the TX FIFO. If the FIFO is empty,
	 * the radio will start sending a continuous preamble until data is written to the FIFO.
	 * It will only switch to TX if the channel is clear and the radio is not currently receiving
	 * a packet.
	 * 
	 * @pre not already transmitting
	 * @pre radio is in receive mode (to do CCA)
	 * @return:
	 *  	SUCCESS if the switch was made (txDone() will be signalled),
	 * 		EOFF if the radio is off,
	 * 		ERETRY if the radio is calibrating,
	 * 		EBUSY if the radio is busy receiving a packet,
	 * 		FAIL if we could not switch because of CCA
	 */
	command error_t tx();
	
	/**
	 * Sync word has been sent or is about to be. Currently, this event
	 * is generated just before writing the data to the FIFO. For accuracy,
	 * it is very important not to do anything lengthy in the event handler!
	 * The time stamp corresponds to the start of the packet.
	 */
	event void txStart(uint32_t timestamp);

	/**
	 * The packet in the buffer was sent or the transmisison was aborted.
	 * The time stamp corresponds to the end of the packet.
	 * @return SUCCESS if the packet was sent, EOFF if the radio was turned off in the middle of a transmission, ERETRY if the TX buffer underflowed.
	 */
	event void txDone(uint32_t timestamp, error_t error);

	/**
	 * A packet was received and is waiting in the RX buffer.
	 * The radio is now IDLE until the FIFO is emptied by calling read().
	 * The time stamp corresponds to the end of the packet.
	 */
	event void rxWaiting(uint32_t timestamp);
	
	/**
	 * Reports whether the channel is clear. Returns TRUE if the radio is not in RX mode.
	 */
	command bool isChannelClear();
	
	/**
	 * Returns the current RSSI if no packet is being received, or the RSSI of the sync word
	 * if a packet is being received.
	 * @pre radio is in RX mode
	 */
	command int16_t getRssi();
	
	/**
	 * @return TRUE iff the radio is currently busy transmitting or receiving a packet.
	 */
	command bool isBusy();
	
	/**
	 * Enable or disable address checking (disabled by default).
	 */
	command void useAddressChecking(bool enable);
	
	/**
	 * Set the channel number.
	 * This sets the frequency to the base frequency + (channel number * channel width).
	 * @pre not currently transmitting
	 */
	command void setChannel(uint8_t channel);
	
	/**
	 * Enable or disable automatic calibration when going from IDLE to RX or TX (on by default).
	 */
	command void autoCalibrate(bool enable);
	
	/**
	 * If not transmitting, go idle, calibrate the radio and resume receiving.
	 * Otherwise, do nothing (keep transmitting).
	 */
	command void calibrate();
	
	/**
	 * Write packet payload into the TX FIFO. If the buffer underflows, this will be detected
	 * by the end-of-packet interrupt, which will signal txDone(ERETRY).
	 * @pre length < FIFO_SIZE (64)
	 */
	command void write(uint8_t* buffer, uint8_t length);
	
	/**
	 * Read a packet and 2 status bytes from the RX FIFO into the buffer.
	 * After emptying the FIFO, the radio returns to RX mode unless it is already transmitting.
	 * @pre there is a packet in the RX FIFO
	 * @pre packet is smaller than MAX_PACKET_LENGTH (should be enforced by the radio)
	 * @return FAIL if the buffer contents were found invalid, SUCCESS otherwise
	 */
	command error_t read(uint8_t* buffer);
	
}
