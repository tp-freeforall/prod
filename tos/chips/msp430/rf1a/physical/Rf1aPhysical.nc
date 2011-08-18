/*
 * Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "Rf1aConfigure.h"

/** The physical-layer interface for the RF1A radio.
 *
 * This interface abstracts from the RF1A hardware implementation
 * while retaining features that are supported by that radio.  It
 * should be possible to implement on other radios, with varying
 * degrees of effort.
 *
 * Message transmission is initiated by providing a message length.
 * The data for the message can be supplied at the start, or on demand
 * during transmission, depending on user need.  Transmission is
 * interrupt-driven, and additional data will be requested as needed
 * using events.
 *
 * Message reception is normally initiated by providing a target
 * buffer, though for special cases it can be initiated without such a
 * buffer.  Additional buffer space is requested automatically as more
 * data is aggregated.
 *
 * The following code can be used to stub the events that this interface
 * provides, when most of them are unneeded:

  async event void Rf1aPhysical.sendDone (int result) { }
  async event void Rf1aPhysical.receiveStarted (unsigned int length) { }
  async event void Rf1aPhysical.receiveDone (uint8_t* buffer,
                                             unsigned int count,
                                             int result) { }
  async event void Rf1aPhysical.receiveBufferFilled (uint8_t* buffer,
                                                     unsigned int count) { }
  async event void Rf1aPhysical.frameStarted () { }
  async event void Rf1aPhysical.clearChannel () { }
  async event void Rf1aPhysical.carrierSense () { }
  async event void Rf1aPhysical.released () { }

 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

interface Rf1aPhysical {
  /** Initiate transmission of a message.
   *
   * This places the radio into transmit mode.  The
   * Rf1aTransmitFragment interface is used by the radio to collect
   * the data for transmission.  Upon failure or successful completion
   * of the transmission, the sendDone() event will be signalled.  At
   * that point, the radio returns to its default mode.
   *
   * @note Normally the radio performs clear-channel assessment prior
   * to sending data.  However, if reception is disabled (because no
   * receive buffer has been registered and no startReception() has
   * been invoked), the radio is not in RX mode.  CCA requires the
   * radio be put into RX mode, but the CCA results will not be
   * immediately available.  Consequently, CCA is bypassed in this
   * situation, and TX will occur without regard for other channel
   * traffic.
   *
   * @param buffer The address of the data to be written.  May be 0 if
   * a non-default Rf1aTransmitFragment implementation is used.
   *
   * @param length The total number of octets in the message.  Note
   * that this does not include the encoding of the length.  Must be a
   * positive integer.
   *
   * @return SUCCESS if the transmission will begin.  EOFF if the
   * radio is turned off.  EBUSY if another client owns the radio, or
   * if this client is already sending a packet.  ERETRY if the radio
   * is still transmitting the remainder of a previous packet or if
   * clear-channel assessment fails.  EINVAL if the length is not
   * valid.
   */
  command error_t send (uint8_t* buffer, unsigned int length);

  /* @TODO@ provide a mechanism to delay transition to STX until a
   * specific number of bytes are available in the FIFO */

  /** Indicate completion of a send() operation.
   *
   * @note That the send operation completed does not mean that the
   * transmission has completed.  It only means that the physical
   * layer has either encountered an error or has successfully handed
   * off the complete message to the radio.  Transmission may still be
   * in progress.  Subsequent send() invocations may fail with ERETRY
   * until the previous transmission completes.
   *
   * @param result An indication of the success or failure of the send.
   */
  async event void sendDone (int result);

  /** Place the radio into transmit mode.
   *
   * This method is used for low-power-lossy configurations where a
   * long preamble is required to ensure the recipient is ready to
   * receive the message.  It can also be used to create a radio
   * jammer for testing purposes.  For other situations, this method
   * can be ignored, since the radio will be placed into transmit mode
   * when data is ready to be sent.
   *
   * Note that if this invocation is followed by a send() operation,
   * as would be common for LPL protocols, the radio will return to
   * its normal idle mode after the transmission.  This method can be
   * re-invoked in sendDone() if channel-hogging is desired.  The
   * effect of invoking this can be canceled without a send() by using
   * the resumeIdleMode() method.
   *
   * @param check_cca If TRUE, radio will only enter transmit mode if
   * clear-channel assessment passes.  If FALSE, the check is
   * bypassed.
   *
   * @return SUCCESS if transition to TX succeeded.  EOFF if radio is
   * unassigned; EBUSY if owned by another client; ERETRY if CCA was
   * performed and failed.
   */
  async command error_t startTransmission (bool check_cca);

  /** Place the radio in receive mode even if no receive buffer has
   * been provided.
   *
   * This can be used in a rare case where reception is desired and
   * the protocol cannot provide a default initial buffer.  The
   * standard receiveBufferFilled() and receiveStarted() events allow
   * the caller to provide a receive buffer in time to avoid data
   * loss.  Upon completion of the reception, the radio returns to its
   * idle mode.  This method can be invoked in receiveDone() to
   * allow continued reception in this mode.
   *
   * @return SUCCESS if transition to RX succeeded.  EOFF if radio is
   * unassigned; EBUSY if owned by another client; EALREADY if a
   * receive buffer is present (so the radio is already in receive
   * mode).
   */
  async command error_t startReception ();

  /** Return the radio to its standard idle mode.
   *
   * This is used to counteract the effects of startTransmission() or
   * startReception() in a situation where no subsequent send() or
   * receive occurs, and to wake the radio up after telling it to
   * sleep().  Invoking this will cancel any in-progress receive or
   * transmission.
   * 
   * @return SUCCESS if transition to RX or IDLE succeeded.  EOFF if
   * radio is unassigned; EBUSY if owned by another client.
   */
  async command error_t resumeIdleMode ();

  /** Put the radio to sleep.
   *
   * This turns off the radio and releases its oscillator.  Bring it
   * back online with the resumeIdleMode() method.
   *
   * @return SUCCESS if radio left in sleep mode.  EOFF if unassigned,
   * EBUSY if owned by another.  ERETRY if radio is actively receiving
   * or transmitting.
   */
  async command error_t sleep ();

  /** Indicate that a new message of the given length is being received.
   *
   * It is guaranteed that this event will eventually be followed by a
   * receiveDone() event which provides the disposition of the
   * message.
   *
   * @param length The number of octets expected to be in the message.
   */
  async event void receiveStarted (unsigned int length);

  /** Indicate that message reception has completed.
   *
   * @note If the receive buffer provided at the start of reception
   * was inadequate to hold the complete message, the buffer and count
   * supplied in this call will reflect only that portion of the
   * message held in the current receive buffer.  Earlier portions
   * were provided through the receiveBufferFilled() event, and you
   * should have captured them then.
   *
   * @param buffer A pointer to the last block of data received as part of the message.
   *
   * @param count The number of valid octets starting at the buffer location.
   *
   * @param result An indication of whether the reception was successful or failed.
   */
  async event void receiveDone (uint8_t* buffer,
                                unsigned int count,
                                int result);

  /** Provide the radio with a location to store incoming data.
   *
   * Several use patterns are supported.  The first provides the radio
   * with a large buffer into which messages are incrementally
   * received, each one starting at the end of the first.  Upon
   * completion of a message, or reaching the end of the pre-allocated
   * space, signals are raised so the caller can extract the data
   * and/or provide a new storage location.
   *
   * The second pattern enables scatter receives, by enabling radio
   * reception without a buffer pre-allocated.  Upon receipt of data,
   * the receiveBufferFilled() event will be raised indicating that
   * there is no data; the client must then invoke this to tell the
   * radio where to store the incoming data.
   *
   * The third ("single-use") provides a single buffer ahead of time
   * for the next incoming message, but will only place a single
   * complete message in that buffer.  If a messages exceeds the
   * buffer length, the received prefix is signaled but the receive
   * operation fails.  Upon completion (successful or failed) of the
   * message, the buffer is discarded within the radio, but the radio
   * will remain in receive mode and subsequent packet reception will
   * signal to request a new buffer.
   *
   * Best practice in the normal situation is to re-invoke this method
   * within the receiveDone() event, so that each message can begin at
   * the start of a buffer that is big enough to hold the entire
   * message.
   *
   * @param buffer Where the data should be stored.  If passed a null
   * pointer, any in-progress receive is canceled and the radio will
   * revert to idle mode.
   *
   * @param length The number of octets available for radio message
   * storage.  If zero, this is treated as if a null buffer were
   * passed.
   *
   * @param single_use If TRUE, then the buffer will only be used for
   * one message.  If the incoming message is too large for the
   * buffer, it is dropped with an error.
   *
   * @return SUCCESS if the buffer was installed.  EOFF if the radio
   * is off.  EBUSY if the radio belongs to another client or there is
   * a message currently being received into an existing buffer.
   */
  async command error_t setReceiveBuffer (uint8_t* buffer,
                                          unsigned int length,
                                          bool single_use);

  /** Indication that the current receive buffer has been filled.
   *
   * This event is signalled at most once for every setReceiveBuffer()
   * invocation, at the point where the buffer is completely full.
   * Normally, during the event processing, setReceiveBuffer() is
   * invoked to provide additional storage.  Failure to do so may
   * result in loss of incoming data if no other buffer is provided by
   * the time the radio's internal receive buffer overflows.  The
   * radio may periodically re-issue this event in an attempt to
   * solicit a buffer; it will do so passing a null buffer value to
   * indicate there is no unreceived data available for consumption.
   *
   * @param buffer A pointer to the most recently filled buffer.  Will
   * be null if there is no currently configured receive buffer.
   *
   * @param count The number of octets of data in the buffer, or 0 if
   * there is no receive buffer.
   */
  async event void receiveBufferFilled (uint8_t* buffer,
                                        unsigned int count);

  /** Signal the start of message transmission or reception.
   *
   * This signal can be used to determine the exact point at which the
   * message was transmitted or received, which is useful when
   * propagating times between unsynchronized devices.
   */
  async event void frameStarted ();

  /** Signal that the radio frequency is open for transmission.
   *
   * This signal can be used by devices to detect that an active
   * transmitter has shut down, allowing a new transmission to
   * begin.
   */
  async event void clearChannel ();

  /** Signal that a carrier is detected on the channel.
   *
   * This signal can be used by devices for low-power listening, where
   * transmitters use a long preamble to give receivers an opportunity
   * to detect the message and be prepared for it.  Applications would
   * place the radio in receive mode, then return to sleep if no
   * carrier is detected for some interval.
   */
  async event void carrierSense ();

  /** A base implementation of Rf1aTransmitFragment.transmitReadyCount.
   *
   * The expectation is that this implementation will handle the
   * buffers provided through the send() interface, while additional
   * link- and physical-layer data can be prepended or appended by a
   * Rf1aTransmitFragment implementation that uses this.
   */
  async command unsigned int defaultTransmitReadyCount (unsigned int count);

  /** A base implementation of Rf1aTransmitFragment.transmitData.
   *
   * The expectation is that this implementation will handle the
   * buffers provided through the send() interface, while additional
   * link- and physical-layer data can be prepended or appended by a
   * Rf1aTransmitFragment implementation that uses this.
   */
  async command const uint8_t* defaultTransmitData (unsigned int count);

  /** Notification that the radio has been unconfigured.  A feature
   * missing from TEP108 but that enables the SplitControl.stopDone()
   * signal to be called at the appropriate time.  Maybe.
   */
  async event void released ();

  /** Get the current radio channel.
   *
   * @return A non-negative value represents a valid RF1A channel from
   * 0 through 255.  -EOFF indicates that the radio is not on; -EBUSY
   * indicates that another client owns the radio.
   */
  async command int getChannel ();

  /** Set the radio channel.
   *
   * @return SUCCESS if the channel was set; -EOFF if the radio is not
   * on; -EBUSY if another client owns the radio; -ERETRY if the radio
   * is actively transmitting or receiving a packet.
   *
   * @note This does not return an error_t, values are in sync with
   * getChannel.
   */
  async command int setChannel (uint8_t channel);

  /** Read the RSSI value.
   *
   * Returns the RSSI value from the RSSI status register as an
   * absolute power level.  For the RF1A module, valid values are
   * between -11 and -138.  Non-negative values indicate TinyOS
   * errors.
   *
   * @note Limited effort is made to validate the RSSI register
   * contents.  If the radio is not in RX mode, the setting may be out
   * of date.  If the radio is in RX mode, the call will busy-wait
   * until the RSSI signal is valid; however, there is insufficient
   * context to determine whether the register contains a live sample
   * or the value latched at the start of the most recent receive
   * action.
   *
   * @return EOFF if radio is off; EBUSY if assigned to another
   * client.  A negative value indicates a valid RSSI measurement.
   * @note This is not an error_t.
   */
  async command int rssi_dBm ();

  /** Read the LQI value.
   *
   * Returns the LQI value from the LQI status register
   * the lower the number indicates a better link quality.
   * the CRC OK bit(7) is mask off in the return result and the 
   * value is made negative.
   *
   * @return EOFF if radio is off; EBUSY if assigned to another
   * client.  A negative value indicates a valid LQI measurement.
   * @note This is not an error_t.
   */

  async command int lqi ();
  /** Read the current radio configuration.
   *
   * @note This command always succeeds and returns the current
   * physical radio configuration, even if the interface that is
   * invoked is from a client that does not have control of the radio.
   *
   * @param config where the configuration should be stored.
   */
  async command void readConfiguration (rf1a_config_t* config);
}

/* 
 * Local Variables:
 * mode: c
 * End:
 */
