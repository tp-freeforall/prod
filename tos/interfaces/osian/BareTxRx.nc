/* Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

/** Crude interface to send and receive data without message
 * structures, source or destination addresses, or any other data
 * overhead.  Chain these together to add message headers and footers,
 * like address information and CRCs.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface BareTxRx {
  /** Obtain access to the transmission buffer.
   *
   * This can be used to avoid the need for copying data from a user
   * buffer, at the cost of disallowing modification of the buffer
   * between the time the send is invoked and the sendDone is
   * signalled.
   *
   * It is expected that the same transmission buffer will be re-used,
   * so a cached value should remain valid as long as the underlying
   * implementation remains started.
   *
   * It is the user's responsibility not to write beyond the address
   * transmitBufferLength into the buffer. */
  command void* transmitBuffer ();

  /** The number of octets in the transmitBuffer that are available
   * for user data. */
  command unsigned int transmitBufferLength ();

  /** Transmit length bytes of data.
   *
   *
   * The implementing component may support message verification
   * (e.g., a CRC check).
   *
   * @param data The address from which the data to be transmitted
   * will be read.  If the value is a null pointer, it defaults to
   * transmitBuffer().  Otherwise, the provided data is copied into
   * the transmit buffer, and the caller may re-use the buffer it
   * passed in as soon as this function returns without waiting for
   * the companion sendDone event.
   * 
   * @return SUCCESS if the transmission was successfully initiated.
   * In this case, there will soon be a sendDone event that provides
   * the final success/failure of the transmission.  Returns EBUSY if
   * a send is already in progress.  May return other errors (e.g.,
   * ERETRY) if the transport medium cannot be used.
   */
  command error_t send (const void* data,
                        unsigned int length);

  /** Indicates completion of a previous successfully-started send operation.
   *
   * Generally this simply indicates that the caller may proceed to
   * the next system state. */
  event void sendDone (error_t rc);
  
  /** Notification that a message has been received.
   *
   * This notification will not be signalled if any underlying message
   * verification performed by the implementing component does not
   * pass.
   *
   * @param data The payload of the message.
   * @param length The length of the message.
   */
  event void receive (const void* data,
                      unsigned int length);
}
