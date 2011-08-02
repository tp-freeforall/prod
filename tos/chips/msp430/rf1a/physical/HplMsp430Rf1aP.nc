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

#include "Rf1aPacket.h"

/** Implement the physical layer of the radio stack.
 *
 * This module follows TEP108-style resource management.  Each client
 * of the radio is entitled to use a different configuration
 * (including frequencies and data rates), and to manage the
 * higher-level packet content.  Hooks are added so that message
 * payload can be dynamically created on transmission, and stored in
 * arbitrary locations on reception.  There is no interface limit on
 * the physical message size, though the current implementation
 * supports only packets no more than 255 octets.
 *
 * Several assumptions are made about the radio configuration.
 * Signals are configured for specific FIFO status,
 * transmission/reception events, and signal state.  Radio state
 * transition is fixed: if no client is active, the radio is reset
 * (SLEEP); if a client is active but has no receive buffer prepared
 * it is IDLE; if a receive buffer is available it is RX.  The
 * CCA_MODE and TX-if-CCA features are enabled, but can be bypassed if
 * necessary through judicious use of the Rf1aPhysical methods.
 */

generic module HplMsp430Rf1aP () @safe() {
  provides {
    interface ResourceConfigure[uint8_t client];
    interface Rf1aPhysical[uint8_t client];
    interface Rf1aStatus;
    interface Rf1aPhysicalMetadata;
  }
  uses {
    interface ArbiterInfo;
    interface HplMsp430Rf1aIf as Rf1aIf;
    interface Rf1aConfigure[uint8_t client];
    interface Rf1aTransmitFragment[uint8_t client];
    interface Rf1aInterrupts[uint8_t client];
    interface Leds;
  }
} implementation {

  /* See configure_ for details. on how these signals are used. */
  enum {
    // IFG4 positive to detect RX data available
    IFG_rxFifoAboveThreshold = (1 << 4),
    // IFG5 negative to detect RX data available
    IFG_txFifoAboveThreshold = (1 << 5),
    // IFG7 positive to detect RX FIFO overflow
    IFG_rxOverflow = (1 << 7), // positive
    // IFG8 positive to detect TX FIFO underflow
    IFG_txUnderflow = (1 << 8),
    // IFG9 positive to detect sync word
    IFG_syncWordEvent = (1 << 9),
    // IFG12 positive to perform clear channel assessment
    IFG_clearChannel = (1 << 12),
    // IFG13 positive to detect signal presence
    IFG_carrierSense = (1 << 13),
    IFG_INTERRUPT = IFG_rxFifoAboveThreshold | IFG_txFifoAboveThreshold
      | IFG_rxOverflow | IFG_txUnderflow
      | IFG_syncWordEvent
      | IFG_clearChannel | IFG_carrierSense,
    IFG_EDGE_Negative = IFG_txFifoAboveThreshold,
    IFG_EDGE_Positive = IFG_rxFifoAboveThreshold
      | IFG_rxOverflow | IFG_txUnderflow
      | IFG_syncWordEvent
      | IFG_clearChannel | IFG_carrierSense,
  };

  enum {
    /** Limit on iterations for loops awaiting a particular radio
     * state.  This is used to avoid an unbreakable loop when the
     * radio spontaneously enters IDLE mode, or fails to complete a
     * requested transition in an unanticipated way.  The number is
     * rather arbitrary, and is based on experience showing a maximum
     * of perhaps 1200 iterations before success in the normal
     * situation for at least one such loop.  It should not be too
     * large, to prevent long hangs.  It's somewhat safe to make it
     * "too small", since it should be used in situations where the
     * failure is propagated to allow the upper layers to retry the
     * operation. */
    RADIO_LOOP_LIMIT = 2000,
  };

  /** Constants defining the main radio control state machine state.
   * This is a high-resolution insight into what's going on, provided
   * by the MARCSTATE register.  It must be consulted sometimes to
   * work around radio bugs.
   */
  enum {
    MRCSM_SLEEP = 0,             // SLEEP substate of SLEEP
    MRCSM_IDLE = 1,              // IDLE substate of IDLE
    MRCSM_XOFF = 2,              // XOFF substate of XOFF
    MRCSM_VCOON_MC = 3,          // VCOON_MC substate of MANCAL,
    MRCSM_REGON_MC = 4,          // REGON_MC substate of MANCAL
    MRCSM_MANCAL = 5,            // MANCAL substate of MANCAL
    MRCSM_VCOON = 6,             // VCOON substate of FS_WAKEUP
    MRCSM_REGON = 7,             // REGON substate of FS_WAKEUP,
    MRCSM_STARTCAL = 8,          // STARTCAL substate of CALIBRATE
    MRCSM_BWBOOST = 9,           // BWBOOST substate of SETTLING
    MRCSM_FS_LOCK = 10,          // FS_LOCK substate of SETTLING
    MRCSM_IFADCON = 11,          // IFADCON substate of SETTLING,
    MRCSM_ENDCAL = 12,           // ENDCAL substate of CALIBRATE
    MRCSM_RX = 13,               // RX substate of RX
    MRCSM_RX_END = 14,           // RX_END substate of RX
    MRCSM_RX_RST = 15,           // RX_RST substate of RX,
    MRCSM_TXRX_SWITCH = 16,      // TXRX_SWITCH substate of TXRX_SETTLING
    MRCSM_RXFIFO_OVERFLOW = 17,  // RXFIFO_OVERFLOW substate of RXFIFO_OVERFLOW
    MRCSM_FSTXON = 18,           // FSTXON substate of FSTXON
    MRCSM_TX = 19,               // TX substate of TX,
    MRCSM_TX_END = 20,           // TX_END substate of TX
    MRCSM_RXTX_SWITCH = 21,      // RXTX_SWITCH substate of RXTX_SETTLING
    MRCSM_TXFIFO_UNDERFLOW = 22, // TXFIFO_UNDERFLOW substate of TXFIFO_UNDERFLOW
  };

  /* Reception state transitions.  The state is inactive when there is
   * no receive buffer and the API has not been used to force entry to
   * reception mode anyway: when the state is inactive, the radio will
   * not be in receive mode.  When the radio is in receive mode and is
   * not transmitting, it is in listening mode.  Upon receipt of data
   * beginning a message, it transitions to active, where it remains
   * until cancelled or the complete message has been received, at
   * which point it returns to inactive of listening depending on
   * availability of receive buffer space.
   */
  enum {
    /** Disabled when there is no receive buffer and no message
     * actively being received. */
    RX_S_inactive,
    /** Waiting for start of a new message.  This is not an active
     * state, as there is no commitment to do anything yet.  */
    RX_S_listening,
    /** The first data associated with an incoming message has been
     * received.  At this point we assume there is an active
     * reception.  However, the task that manages the reception has
     * not yet been queued. */
    RX_S_synchronized,
    /** Actively receiving a message. */
    RX_S_active,
  };

  /** Current state of the reception automaton. */
  uint8_t rx_state;

  /** Where the next data should be written.  Null if there is no
   * available reception buffer.  Set to null in receiveData_ when
   * last byte filled; set to non-null in setReceiveBuffer().
   */
  uint8_t* rx_pos;

  /** End of the available receive buffer. */
  uint8_t* rx_pos_end;

  /** Where in the current receive buffer data from the currently
   * received message begins.  Null when buffer has been filled.
   */
  uint8_t* rx_start;

  /** TRUE iff only a single message should be stored in the given buffer. */
  bool rx_single_use;

  /** Number of bytes expected for the current message.  Valid only
   * when actively receiving a message. */
  unsigned int rx_expected;

  /** Number of bytes received so far in the current message.  Valid
   * only when actively receiving a message. */
  unsigned int rx_received;

  /** The success/failure result of the current reception.  Will be
   * SUCCESS unless something bad happens (reception cancelled or RX
   * overflow)
   */
  int rx_result;

  /** The RSSI provided via APPEND_STATUS at the last successful
   * receive.  This is the raw value provided by APPEND_STATUS, not
   * the dBm one. */
  uint8_t rx_rssi_raw;

  /** The LQI+CRC provided via APPEND_STATUS at the last successful
   * receive */
  uint8_t rx_lqi_raw;

  /* Transmission state transitions.  When no send is in progress, the
   * state is inactive.  Upon validation of a send request, the state
   * moves to preparing, and the sendFragment_() code is queued to
   * run.  Within sendFragment_(), as soon as message data has become
   * available, as much available data as fits is placed into the
   * transmit fifo, the STX strobe is executed, and the state
   * transitions to active.  As soon as the last octet of the message
   * has been queued, the state transitions to flushing, and the
   * FIFOTHR is reprogrammed to detect when the queue empties.  Once
   * the last byte has been transmitted, the state returns to inactive
   * and the sendDone event is signaled.
   *
   * Be aware that the radio will spontaneously transition out of
   * FSTXON if TX-if-CCA is enabled.  There is evidence as well that
   * this can also happen after a successful transition to TX.  Code
   * processing transmissions must be prepared to find itself with a
   * radio that is no longer in transmit mode, and to cancel the
   * transmission accordingly.
   *
   * Also note: Explicit invocations of startTransmission, e.g. for
   * preamble signalling or jamming, are not reflected in tx_state.
   */
  enum {
    /** No transmission active */
    TX_S_inactive,
    /** A transmission has been queued, but data has not yet been
     * supplied and the radio is still in FSTXON.  This is an active
     * state. */
    TX_S_preparing,
    /** A transmission is active.  This is an active state. */
    TX_S_active,
    /** All data has been queued for transmission, but has not yet
     * left the TXFIFO.  This is an active state. */
    TX_S_flushing,
  };

  /** Current state of the transmission automaton */
  uint8_t tx_state;

  /** The success or failure value for the current transmission */
  int tx_result;

  /** Pointer to the current position within a send()-provided
   * outgoing message.  Null if no active transmission or the sender
   * did not provide a buffer (is doing gather transmission).  Used by
   * the default TransmitFragment implementation.
   */
  uint8_t* tx_pos;

  /** The end of the send()-provided outgoing message.  Used by the
   * default TransmitFragment implementation. */
  uint8_t* tx_end;

  /** The number of octets remaining to be transmitted.  This is the
   * value provided through the send() method, and does not include
   * octets introduced at this layer such as the length when using
   * variable packet length. */
  unsigned int tx_remain;

  enum {
    /** Maximum number of bytes we can put in the TX FIFO */
    FIFO_FILL_LIMIT = 63,
  };

  /** Cached value of FIFOTHR, overwritten during TX_S_flushing to
   * detect completion of transmission.  Only valid during
   * TX_S_flushing; must be rewritten to FIFOTHR if that state is
   * left.
   */
  uint8_t tx_cached_fifothr;

  /** Place the radio back into whatever state it belongs in when not
   * actively transmitting or receiving.  This is either RX or IDLE.
   * This method is capable of rousing the radio from sleep mode, as
   * well as simply returning it from some other active mode.  It is
   * not responsible for dealing with errors like RX or TX FIFO
   * over/underflows.
   *
   * @param rx_if_enabled If TRUE, will transition to RX if
   * appropriate.  If FALSE, will only transition to IDLE.
   */

  void resumeIdleMode_ (bool rx_if_enabled) {
    atomic {
      uint8_t strobe = RF_SIDLE;
      uint8_t state = RF1A_S_IDLE;
      uint8_t rc;

      /* Maybe wake radio from deep sleep */
      rc = call Rf1aIf.strobe(RF_SNOP);
      if (0x80 & rc) {
        while (0x80 & rc) {
          atomic rc = call Rf1aIf.strobe(RF_SIDLE);
        }
        while (RF1A_S_IDLE != (RF1A_S_MASK & rc)) {
          rc = call Rf1aIf.strobe(RF_SNOP);
        }
      }
      if (rx_if_enabled && (!! rx_pos)) {
        strobe = RF_SRX;
        state = RF1A_S_RX;
      }
      (void)call Rf1aIf.strobe(strobe);
      do {
        rc = call Rf1aIf.strobe(RF_SNOP);
      } while (state != (RF1A_S_MASK & rc));
    }
  }

  /** Return TRUE iff transitioning the radio to a new state will not
   * corrupt an in-progress transmission.
   */
  bool transmitIsInactive_atomic_ () {
    return (TX_S_inactive == tx_state) && (0 == call Rf1aIf.readRegister(TXBYTES));
  }

  /** Configure the radio for a specific client.  This includes
   * client-specific registers and the overrides necessary to ensure
   * the physical-layer assumptions are maintained.
   */
  void configure_ (const rf1a_config_t* config) {
    atomic {
      const uint8_t* cp = (const uint8_t*)config;

      /* Reset the core.  Should be unnecessary, but a BOR might leave
       * the radio with garbage in its TXFIFO, which won't get cleared
       * with a standard wake. */
      call Rf1aIf.resetRadioCore();

      /* Wake the radio into idle mode */
      resumeIdleMode_(FALSE);

      /* Write the basic configuration registers.  PATABLE first, so
       * that the subsequent non-PATABLE instruction resets the table
       * index.
       */
      call Rf1aIf.writeBurstRegister(PATABLE, config->patable, sizeof(config->patable));
      call Rf1aIf.writeBurstRegister(0, cp, RF1A_CONFIG_BURST_WRITE_LENGTH);

      /* Regardless of the configuration, the core functionality here
       * requires that the interrupts be configured a certain way.
       * IFG signals 4, 5, 7, 8, 9, and 12 are all used.  All but 5
       * are positive edge.  All but 12 are interrupt enabled.  Clear
       * the interrupt vector then configure these interrupts.
       */
      call Rf1aIf.setIfg(0);
      call Rf1aIf.setIes(IFG_EDGE_Negative | ((~ IFG_EDGE_Positive) & call Rf1aIf.getIes()));
      call Rf1aIf.setIe(IFG_INTERRUPT | call Rf1aIf.getIe());

      /* Again regardless of configuration, the control flow in this
       * module assumes that the radio returns to IDLE mode after
       * receiving a packet, and IDLE mode after transmitting a
       * packet.  The presence of a receive buffer, and whether that
       * buffer is marked for single-use, affects subsequent
       * configuration of this register.
       */
      call Rf1aIf.writeRegister(MCSM1, (0xf0 & call Rf1aIf.readRegister(MCSM1)));

      /* Reset all the packet the packet-related pointers and counters */
      rx_state = RX_S_inactive;
      rx_pos = rx_pos_end = rx_start = 0;
      rx_expected = rx_received = 0;
      tx_state = TX_S_inactive;
      tx_pos = tx_end = 0;
      tx_remain = 0;
      rx_result = tx_result = SUCCESS;
    }
  }

  async command void Rf1aPhysical.readConfiguration[uint8_t client] (rf1a_config_t* config) {
    /* NB: We intentionally ignore the client here. */
    memset(config, 0, sizeof(config));
    atomic {
      call Rf1aIf.readBurstRegister(PATABLE, config->patable, sizeof(config->patable));
      call Rf1aIf.readBurstRegister(0, (uint8_t*)config, RF1A_CONFIG_BURST_READ_LENGTH);
      config->partnum = call Rf1aIf.readRegister(PARTNUM);
      config->version = call Rf1aIf.readRegister(VERSION);
    }
  }

  /** Unconfigure.  Disable all interrupts and reset the radio core. */
  void unconfigure_ () {
    atomic {
      call Rf1aIf.setIe((~ IFG_INTERRUPT) & call Rf1aIf.getIe());
      call Rf1aIf.resetRadioCore();
    }
  }

  default async command const rf1a_config_t*
    Rf1aConfigure.getConfiguration[uint8_t client] () {
	return &rf1a_default_config;
  }

  default async command void Rf1aConfigure.preConfigure[ uint8_t client ] () { }
  default async command void Rf1aConfigure.postConfigure[ uint8_t client ] () { }
  default async command void Rf1aConfigure.preUnconfigure[ uint8_t client ] () { }
  default async command void Rf1aConfigure.postUnconfigure[ uint8_t client ] () { }

  async command void ResourceConfigure.configure[uint8_t client] () {
    const rf1a_config_t* cp = call Rf1aConfigure.getConfiguration[client]();
    if (0 == cp) {
      cp = &rf1a_default_config;
    }
    call Rf1aConfigure.preConfigure[client]();
    configure_(cp);
    call Rf1aConfigure.postConfigure[client]();
  }

  async command void ResourceConfigure.unconfigure[uint8_t client] () {
    call Rf1aConfigure.preUnconfigure[client]();
    unconfigure_();
    call Rf1aConfigure.postUnconfigure[client]();
    signal Rf1aPhysical.released[client]();
  }

  /* @TODO@ Prevent release of resource when transmission in progress */

  /** Default implementation of transmitReadyCount_ just returns a
   * value based on the number of bytes left in the buffer provided
   * through send.
   */
  unsigned int transmitReadyCount_ (uint8_t client,
                                    unsigned int count) {
    unsigned int rv = count;
    atomic {
      if (tx_pos) {
        unsigned int remaining = (tx_end - tx_pos);
        if (remaining < rv) {
          rv = remaining;
        }
      } else {
        rv = 0;
      }
    }
    return rv;
  }

  /** Default implementation of transmitData_ just returns a pointer
   * to a region of the buffer provided through send.
   */
  uint8_t* transmitData_ (uint8_t client,
                          unsigned int count) {
    uint8_t* rp;

    atomic {
      rp = tx_pos;
      if (rp) {
        unsigned int remaining = (tx_end - tx_pos);
        if (remaining >= count) {
          /* Have enough to handle the request.  Increment the position for
           * a following transfer; if this will be the last transfer, mark
           * it complete by zeroing the position pointer. */
          tx_pos += count;
          if (tx_pos == tx_end) {
            tx_pos = 0;
          }
        } else {
          /* Being asked for more than is available, which is an interface
           * violation, which aborts the transfer. */
          rp = tx_pos = 0;
        }
      }
    }
    return rp;
  }

  // Forward declaration
  void sendFragment_ ();

  // Forward declaration
  void receiveData_ ();

  /** Task used to do the work of transmitting a fragment of a message. */
  task void sendFragment_task () { sendFragment_(); }

  /** Task used to do the work of consuming a fragment of a message. */
  task void receiveData_task () { receiveData_(); }

  /** Clear the transmission fifo.  The radio is left in idle mode. */
  void resetAndFlushTxFifo_ () {
    uint8_t rc;

    /* Reset the radio: return to IDLE mode, then flush the TX buffer.
     * Radio should end in IDLE mode. */
    rc = call Rf1aIf.strobe(RF_SIDLE);
    while (RF1A_S_IDLE != (RF1A_S_MASK & rc)) {
      rc = call Rf1aIf.strobe(RF_SNOP);
    }
    rc = call Rf1aIf.strobe(RF_SFTX);
    while (RF1A_S_IDLE != (RF1A_S_MASK & rc)) {
      rc = call Rf1aIf.strobe(RF_SNOP);
    }
    resumeIdleMode_(TRUE);
  }

  /**
   * Reset the radio and update state so the inner code of
   * sendFragment_ will abort the transmission.  This method should
   * only be called from within sendFragment_.
   */
  void cancelTransmit_ () {
    /* Clearing the remainder count and updating the state to "active"
     * will cause the epilog of the sendFragment_ code to clean up the
     * transmission. */
    tx_remain = 0;
    tx_state = TX_S_active;

    resetAndFlushTxFifo_();
  }

  /**
   * Invoke this to ensure the radio has been in RX mode long enough
   * to generate a valid RSSI measurement.
   *
   * The return value allows the caller to determine whether the radio
   * is still in RX mode; if not, RSSI/CCA/CarrierSense are not
   * guaranteed to be accurate.
   *
   * @return the latest radio status byte.
   */
  uint8_t spinForValidRssi__ () {
    uint8_t rc;
    uint8_t mcsm1 = call Rf1aIf.readRegister(MCSM1);

    /* Delay until we're sure the RSSI measurement is valid.
     *
     * Trick: The clearChannel signal says RSSI is below threshold;
     * when CCA_MODE is set to generate a valid CCA the carrierSense
     * signal says that it's above threshold.  When one of those
     * signals is asserted, RSSI is valid.  Note that we do not touch
     * MCSM1.RX_OFF, lest doing so cause the RF1A state to stay in RX
     * after a reception when it should instead have gone to IDLE.
     *
     * If MCSM1.RX_OFF is 0 (e.g., single-use buffers) and the
     * radio is actively receiving a packet, we might end up in
     * IDLE mode before the RSSI check passes.  In that case, or
     * if anything else kicks us out of RX, break out and let
     * the state machine recover normally.
     */
    call Rf1aIf.writeRegister(MCSM1, 0x10 | (0x0f & mcsm1));
    do {
      rc = call Rf1aIf.strobe(RF_SNOP);
    } while ((RF1A_S_RX == (RF1A_S_MASK & rc))
             && (! ((IFG_clearChannel | IFG_carrierSense) & call Rf1aIf.getIn())));

    // Restore standard CCA configuration
    call Rf1aIf.writeRegister(MCSM1, mcsm1);
    return rc;
  }

  /** Activity invoked to request data from the client and stuff it
   * into the transmission fifo.
   */
  void sendFragment_ () {
    uint8_t client = call ArbiterInfo.userId();
    int result = SUCCESS;
    bool need_to_write_length = FALSE;
    bool wrote_data = FALSE;
    bool send_done = FALSE;
    bool need_repost = FALSE;
    uint8_t rc;

    atomic {
      do {
        const uint8_t* data;
        unsigned int count;
        unsigned int inuse;

        /* Did somebody cancel the transmit? */
        if (SUCCESS != tx_result) {
          cancelTransmit_();
          break;
        }

        /* If nothing left to do, exit */
        if (0 >= tx_remain) {
          break;
        }

        /* How much room do we have available?  If none, give up for
         * now.
	 */
        inuse = 0x7f & call Rf1aIf.readRegister(TXBYTES);
        if (inuse >= FIFO_FILL_LIMIT) {
          break;
        }

        /* If we're using variable packet lengths, and we haven't
         * written anything yet, we've got to reserve room for (and
         * send) the length byte.
	 */
        need_to_write_length = (TX_S_preparing == tx_state) && (0x01 == (0x03 & call Rf1aIf.readRegister(PKTCTRL0)));

        /* Calculate the headroom, adjust for the length byte if we
         * need to write it, and adjust down to no more than we
         * need
	 */
        count = FIFO_FILL_LIMIT - inuse;
        if (need_to_write_length) {
          count -= 1;
        }
        if (count > tx_remain) {
          count = tx_remain;
        }

        /* Is there any data ready?  If not, try again later. */
        count = call Rf1aTransmitFragment.transmitReadyCount[client](count);
        if (0 == count) {
          break;
        }

        /* Get the data to be written.  If the callee returns a null
         * pointer, the transmission is canceled; otherwise, stuff it
         * into the transmit buffer.
	 */
        data = call Rf1aTransmitFragment.transmitData[client](count);
        if (0 == data) {
          cancelTransmit_();
          break;
        }

        /* We're committed to the write: tell the radio how long the
         * packet is, if we haven't already.
	 */
        if (need_to_write_length) {
          uint8_t len8 = tx_remain;
          call Rf1aIf.writeBurstRegister(RF_TXFIFOWR, &len8, sizeof(len8));
        }
        call Rf1aIf.writeBurstRegister (RF_TXFIFOWR, data, count);
        tx_state = TX_S_active;
        wrote_data = TRUE;

        /* Account for what we just queued. */
        tx_remain -= count;
      } while (0);

      /* Request task repost if we have more data and the fifo is not
       * already above the threshold at which we'll be re-posted.
       */
      need_repost = (0 < tx_remain) && ! (IFG_txFifoAboveThreshold & call Rf1aIf.getIn());

      /* If we've queued data but haven't already started the
       * transmission, do so now.
       */
      if (wrote_data && (RF1A_S_TX != (RF1A_S_MASK & call Rf1aIf.strobe(RF_SNOP)))) {
        register int loop_limit = RADIO_LOOP_LIMIT;
        /* We're *supposed* to be in FSTXON here, so this strobe can't
         * be rejected.  In fact, it appears that if we're in FSTXON
         * and CCA fails, the radio transitions to RX mode.  In other
         * cases, it somehow ends up in IDLE.  Try anyway, and if it
         * doesn't work, fail the transmission. */
        rc = call Rf1aIf.strobe(RF_STX);
        while ((RF1A_S_TX != (RF1A_S_MASK & rc))
               && (RF1A_S_RX != (RF1A_S_MASK & rc))
               && (RF1A_S_IDLE != (RF1A_S_MASK & rc))
               && (0 <= --loop_limit)) {
          rc = call Rf1aIf.strobe(RF_SNOP);
        }
        if (RF1A_S_TX != (RF1A_S_MASK & rc)) {
          tx_result = ERETRY;
          cancelTransmit_();
        }
      }

      /* If we've started transmitting, see if we're done yet. */
      if (TX_S_active <= tx_state) {
        /* If there's no more data to be transmitted, the task is
         * done.  However, there's an end-game: we don't really want
         * to signal sendDone until it's actually in the air.
	 */
        if (0 == tx_remain) {
          if (TX_S_active == tx_state) {
            tx_state = TX_S_flushing;
            tx_cached_fifothr = call Rf1aIf.readRegister(FIFOTHR);
            call Rf1aIf.writeRegister(FIFOTHR, (0x0F | tx_cached_fifothr));
          }
          if (0 == call Rf1aIf.readRegister(TXBYTES)) {
            result = tx_result;
            call Rf1aIf.writeRegister(FIFOTHR, tx_cached_fifothr);

            /* This might be an erratum, but I think it's really that
             * the fact the TXFIFO has flushed still doesn't mean the
             * transmission is done: that last character still needs
             * to be spat out the antenna.  Unfortunately, I don't
             * know of another way to detect that the transmission has
             * really-and-fortrue completed.
             *
             * Without this check, we can return to main program
             * control and proceed to initiate a second send before
             * the MRCSM finishes cleaning up from the previous
             * transmit.  When this happens, the radio appears to
             * accept the subsequent command but never actually
             * transmits it.
             *
             * What this does is busy-wait until MARCSTATE gets out of
             * TX; this appears to be sufficient (in the test
             * configuration, it reaches TX_END).  Instrumentation
             * indicates this loop runs about 350 times before MRCSM
             * transitions out of TX.  I'm not going to put a limit on
             * it, because if this ever stops working I want it to
             * hang here, where inspection via the debugger will find
             * it and the poor maintainer will at least have this
             * comment to provide a clue as to what might be going on.
             *
             * When that happens, consider checking whether TX_OFF is
             * set to "stay in TX", since in that case I don't know
             * MRCSM ever transitions to TX_END.  I would expect it
             * does, but then I'd expect the radio to work better than
             * it does....
	     */
            {
              uint8_t ms;
              do {
                ms = call Rf1aIf.readRegister(MARCSTATE);
              } while (MRCSM_TX == ms);
            }

            tx_state = TX_S_inactive;
            send_done = TRUE;
          }
        }
      }
    } // atomic

    if (need_repost) {
      post sendFragment_task();
    }
    if (send_done) {
      signal Rf1aPhysical.sendDone[client](result);
    }
  }

  /** Place the radio into FSTXON or TX, with or without a
   * clear-channel-assessment gate check.
   *
   * @param with_cca If TRUE, radio should check for a clear channel
   * before proceeding with the transition.  If false, use only the
   * normal radio CCA actions like TX-if-CCA.
   *
   * @param target_fstxon If TRUE, transition to FSTXON; if FALSE,
   * transition to TX.
   */
  int startTransmission_ (bool with_cca,
                          bool target_fstxon) {
    int rv = SUCCESS;
    atomic {
      uint8_t strobe = RF_STX;
      uint8_t state = RF1A_S_TX;
      uint8_t rc;
      bool entered_rx = FALSE;
      register int16_t loop_limit = RADIO_LOOP_LIMIT;

      if (target_fstxon) {
        strobe = RF_SFSTXON;
        state = RF1A_S_FSTXON;
      }

      rc = call Rf1aIf.strobe(RF_SNOP);
      if (with_cca) {
        /* CCA test is valid only if in RX mode.  If necessary, enter it. */
        if (RF1A_S_RX != (RF1A_S_MASK & rc)) {
          entered_rx = TRUE;
          rc = call Rf1aIf.strobe(RF_SRX);
          // Wait until in RX mode, or failed to enter RX
          while ((RF1A_S_RX != (RF1A_S_MASK & rc))
                 && (0 <= --loop_limit)) {
            rc = call Rf1aIf.strobe(RF_SNOP);
          }
        }

        if (RF1A_S_RX == (RF1A_S_MASK & rc)) {
          rc = spinForValidRssi__();
        }

        /* If we didn't successfully stay in RX mode through all that,
         * something went wrong. */
        if (RF1A_S_RX != (RF1A_S_MASK & rc)) {
          rv = ERETRY;
        }
      }

      if (SUCCESS == rv) {
        /* Enter the appropriate TX mode.  When things settle, the
         * state should be RX or IDLE (CCA check failed, or
         * in-progress RX completed) or the target state (good to
         * transmit).  May be in CALIBRATE and SETTLING in between, so
         * loop. */
        (void)call Rf1aIf.strobe(strobe);
        do {
          rc = call Rf1aIf.strobe(RF_SNOP);
          if (with_cca
              && (RF1A_S_RX == (RF1A_S_MASK & rc))
              && (! (IFG_clearChannel & call Rf1aIf.getIn()))) {
            if (entered_rx) {
              resumeIdleMode_(TRUE);
            }
            break;
          }
        } while ((RF1A_S_RX != (RF1A_S_MASK & rc))
                 && (RF1A_S_IDLE != (RF1A_S_MASK & rc))
                 && (state != (RF1A_S_MASK & rc))
                 && (0 <= --loop_limit));
        if (state != (RF1A_S_MASK & rc)) {
          rv = ERETRY;
        }
      }
    }
    return rv;
  }

  /** Place the radio into RX mode and set the RX state to be prepared
   * for a new message.
   */
  void startReception_ () {
    uint8_t rc;

    atomic {
      rx_state = RX_S_listening;
      // Go to receive mode now, unless in an active transmit mode
      if (transmitIsInactive_atomic_()) {
        rc = call Rf1aIf.strobe(RF_SRX);
        while ((RF1A_S_RX != (RF1A_S_MASK & rc))) {
          rc = call Rf1aIf.strobe(RF_SNOP);
        }
      }
    }
  }

  command error_t Rf1aPhysical.send[uint8_t client] (uint8_t* buffer,
                                                     unsigned int length) {
    uint8_t rc;

    /* Radio must be assigned */
    if (! call ArbiterInfo.inUse()) {
      return EOFF;
    }
    /* This must be the right client */
    if (client != call ArbiterInfo.userId()) {
      return EBUSY;
    }
    /* And the length has to be positive */
    if (0 == length) {
      return EINVAL;
    }
    atomic {
      bool variable_packet_length_mode;

      /* And we can't be actively receiving anything */
      if (RX_S_listening < rx_state) {
	rc = call Rf1aIf.strobe(RF_RXSTAT | RF_SNOP);

	/* Another special case.  If noise on the channel causes a
	 * packet reception to begin, but doesn't last long enough for
	 * the interpreted packet length to be received, the radio
	 * will return to idle mode.  Detect that we're in idle mode
	 * with data required but not available and abort the
	 * receive.
	 */
	if ((RF1A_S_IDLE == (RF1A_S_MASK & rc))
	    && (rx_received < rx_expected)
	    && (0 == (rc & RF1A_S_FIFOMASK))) {
	  rx_result = FAIL;
	  post receiveData_task();
	}
        return EBUSY;
      }

      /* And we can't already be transmitting something. */
      if (0 < tx_remain) {
        return EBUSY;
      }

      /* More weirdness: seems that, even with all we've tried, it's
       * possible to end up in receive mode with pending data in the
       * transmission buffer.  If that happens, just throw it away.
       *
       * @TODO@ This is either a serious radio bug, or an error in the
       * logic of this module. It appears to occur when sendFragment_
       * has placed the complete message into the TXFIFO and
       * successfully transferred to TX mode.  Since resetting the
       * radio here is successful and operation continues, it appears
       * that in this situation the upper level has been notified that
       * the send completed, and it is only the radio that has failed
       * to do its job.  It seems likely that this module still has a
       * situation where it improperly transitions the state to RX
       * even though the transmission has not completed.
       * Experimentation indicates this is independent of CCA_MODE, is
       * observed only when another radio is active, and that this
       * module is not strobing to another state between the
       * successful STX and this point.
       */
      if ((RF1A_S_RX == (RF1A_S_MASK & call Rf1aIf.strobe(RF_SNOP)))
          && (TX_S_inactive == tx_state) // safety check: do not trash active transmissions
          && (0 < call Rf1aIf.readRegister(TXBYTES))) {
        // printf("ERROR: RX mode but %d TXBYTES queued, tx state %d\r\n", call Rf1aIf.readRegister(TXBYTES), tx_state);
        resetAndFlushTxFifo_();
      }

      /* Even if it's being transmitted from the radio, wait until
       * it's gone.
       */
      if (! transmitIsInactive_atomic_()) {
        return ERETRY;
      }

      /* Do we need to tell the radio how long the packet is?  If so,
       * there's a limit on the packet length.
       */
      variable_packet_length_mode = (0x01 == (0x03 & call Rf1aIf.readRegister(PKTCTRL0)));
      if (variable_packet_length_mode) {
        /* Maximum length for VPL is 255 */
        if (255 < length) {
          return EINVAL;
        }
      }

      /* If we aren't in a transmit mode already, go to FSTXON, doing
       * the necessary CCA.  Beware: even if this succeeds, if we land
       * in FSTXON the radio will transition back to RX mode if it CCA
       * fails before we go to STX.  That's handled in
       * sendFragment_task.
       */
      rc = call Rf1aIf.strobe(RF_SNOP);
      if ((RF1A_S_FSTXON != (rc & RF1A_S_MASK)) && (RF1A_S_TX != (rc & RF1A_S_MASK))) {
        int rv = startTransmission_(TRUE, TRUE);
        if (SUCCESS != rv) {
          return rv;
        }
        rc = RF1A_S_MASK & call Rf1aIf.strobe(RF_SNOP);
      }

      tx_remain = length;
      tx_result = SUCCESS;
      tx_state = TX_S_preparing;
      if (buffer) {
        tx_pos = buffer;
        tx_end = buffer + length;
      } else {
        tx_pos = tx_end = 0;
      }
    }
    post sendFragment_task();
    return SUCCESS;
  }

  default async event void Rf1aPhysical.sendDone[uint8_t client] (int result) { }

  async command error_t Rf1aPhysical.startTransmission[uint8_t client] (bool with_cca) {
    /* Radio must be assigned */
    if (! call ArbiterInfo.inUse()) {
      return EOFF;
    }
    /* This must be the right client */
    if (client != call ArbiterInfo.userId()) {
      return EBUSY;
    }
    return startTransmission_(with_cca, FALSE);
  }

  async command error_t Rf1aPhysical.resumeIdleMode[uint8_t client] () {
    /* Radio must be assigned */
    if (! call ArbiterInfo.inUse()) {
      return EOFF;
    }
    /* This must be the right client */
    if (client != call ArbiterInfo.userId()) {
      return EBUSY;
    }
    atomic {
      if (TX_S_inactive != tx_state) { // NB: Not transmitIsInactive
        tx_result = ECANCEL;
        post sendFragment_task();
      } else if (RX_S_listening < rx_state) {
        rx_result = ECANCEL;
        post receiveData_task();
      } else {
        resumeIdleMode_(TRUE);
      }
    }
    return SUCCESS;
  }

  async command error_t Rf1aPhysical.startReception[uint8_t client] () {
    /* Radio must be assigned */
    if (! call ArbiterInfo.inUse()) {
      return EOFF;
    }
    /* This must be the right client */
    if (client != call ArbiterInfo.userId()) {
      return EBUSY;
    }
    atomic {
      if (0 != rx_pos) {
        return EALREADY;
      }
      startReception_();
    }
    return SUCCESS;
  }

  async command error_t Rf1aPhysical.sleep[uint8_t client] () {
    /* Radio must be assigned */
    if (! call ArbiterInfo.inUse()) {
      return EOFF;
    }
    /* This must be the right client */
    if (client != call ArbiterInfo.userId()) {
      return EBUSY;
    }
    atomic {
      uint8_t rc;

      /* Reject sleep if actively receiving or have a transmission
       * queued or going out */
      if ((RX_S_listening < rx_state)
          || (! transmitIsInactive_atomic_())) {
        return ERETRY;
      }

      /* Have to go to idle first */
      resumeIdleMode_(FALSE);

      /* Now go to sleep */
      rc = call Rf1aIf.strobe(RF_SXOFF);
      while (! (0x80 & rc)) {
        rc = call Rf1aIf.strobe(RF_SNOP);
      }
    }
    return SUCCESS;
  }

  /** Determine the number of bytes available in the RX FIFO following
   * the algorithm in 19.3.10.
   */
  unsigned int receiveCountAvailable_ () {
    unsigned int avail;
    unsigned int avail2;

    avail2 = 0x7f & call Rf1aIf.readRegister(RXBYTES);
    avail = ~avail2;
    while (avail != avail2) {
      avail = avail2;
      avail2 = 0x7f & call Rf1aIf.readRegister(RXBYTES);
    }
    return avail;
  }

  /** Reset the radio and update state so the inner code of
   * receiveData_ will abort the reception.  This method should
   * only be called from within receiveData_.
   */
  void cancelReceive_ () {
    uint8_t rc;

    /* Reset the radio */
    rc = call Rf1aIf.strobe(RF_SIDLE);
    while (RF1A_S_IDLE != (RF1A_S_MASK & rc)) {
      rc = call Rf1aIf.strobe(RF_SNOP);
    }
    rc = call Rf1aIf.strobe(RF_SFRX);
    while (RF1A_S_IDLE != (RF1A_S_MASK & rc)) {
      rc = call Rf1aIf.strobe(RF_SNOP);
    }
    resumeIdleMode_(TRUE);
  }

  /** Do the actual work of consuming data from the RX FIFO and
   * storing it in the appropriate location.
   */
  void receiveData_ () {
    unsigned int avail;
    uint8_t client = call ArbiterInfo.userId();
    bool need_post = TRUE;
    bool signal_start = FALSE;
    bool signal_filled = FALSE;
    bool signal_complete = FALSE;
    uint8_t* start;
    unsigned int expected;
    unsigned int received;
    int result;

    atomic {
      do {
        unsigned int need;
        unsigned int consume;

        /* Did somebody cancel the receive?  This would also happen on
         * an RX overrun. */
        if (SUCCESS != rx_result) {
          signal_complete = TRUE;
          cancelReceive_();
          break;
        }

        /* Is there data available?  How much?  If none, stop now. */
        avail = receiveCountAvailable_();
        if (0 == avail) {
          break;
        }

        /* OK, there's data; do we know how much to read? */
        if (RX_S_active > rx_state) {
          bool variable_packet_length_mode = (0x01 == (0x03 & call Rf1aIf.readRegister(PKTCTRL0)));

          if (variable_packet_length_mode) {
            uint8_t len8;
            call Rf1aIf.readBurstRegister(RF_RXFIFORD, &len8, sizeof(len8));
            avail -= 1;
            rx_expected = len8;
          }

          /* @TODO@ set rx_expected when not using variable packet length mode */

          /* Update the state */
          rx_state = RX_S_active;

          /* Discard any previous message start and length */
          rx_start = 0;
          rx_received = 0;

          /* Notify anybody listening that there's a message coming in */
          signal_start = TRUE;
          expected = rx_expected;
        }
        need = rx_expected - rx_received;

        /* Data and we know how much: is there any place to put it? */
        if (0 == rx_pos) {
          signal_filled = TRUE;
          rx_start = 0;
          received = 0;
          break;
        }

        /* If first data into this buffer, record message start (do
         * NOT merge with above clear of rx_start: message may require
         * multiple buffers and we need rx_start to always be within
         * the current one) */
        if (0 == rx_start) {
          rx_start = rx_pos;
        }

        /* Per 19.3.10, don't consume the last byte available unless
         * it's the last byte in the packet.
	 */
        if (avail < need) {
          --avail;
        }

        /* Figure out how much we can and need to consume, then read it. */
        consume = rx_pos_end - rx_pos;
        if (consume > need) {
          consume = need;
        }
        if (consume > avail) {
          consume = avail;
        }
        call Rf1aIf.readBurstRegister(RF_RXFIFORD, rx_pos, consume);
        rx_pos += consume;
        rx_received += consume;
        avail -= consume;

        /* Have we reached the end of the message? */
        if (rx_received == rx_expected) {
          /* If APPEND_STATUS is set, gotta clear out that data. */
          if (0x04 & call Rf1aIf.readRegister(PKTCTRL1)) {
            /* Better be two more octets.  Busy-wait until they show
             * up. */
            while (2 > avail) {
              avail = 0x7f & call Rf1aIf.readRegister(RXBYTES);
            }
            call Rf1aIf.readBurstRegister(RF_RXFIFORD, &rx_rssi_raw, sizeof(rx_rssi_raw));
            call Rf1aIf.readBurstRegister(RF_RXFIFORD, &rx_lqi_raw, sizeof(rx_lqi_raw));
            avail -= 2;
          }

          signal_complete = TRUE;

          /* Note: received is the number of bytes in this packet, not in
           * the total message.  Sorry.
	   */
          received = rx_pos - rx_start;

          /* If in one-shot mode, shift the buffer end down so we signal filled. */
          if (rx_single_use) {
            rx_pos_end = rx_pos;
          }
        }

        /* Have we used up the receive buffer? */
        if (rx_pos_end == rx_pos) {
          signal_filled = TRUE;
          received = rx_pos - rx_start;
          rx_pos = 0;
          /* In one-shot mode, if we didn't get the whole message,
           * mark it failed. */
          if (rx_single_use && (! signal_complete)) {
            rx_result = ENOMEM;
          }
        }
      } while (0);

      /* If there's still data available, we'll have to come back,
       * even if we've finished this message.
       */
      need_post = (0 < receiveCountAvailable_());

      /* Extract the start of any filled buffer (length was set above) */
      if (signal_filled) {
        start = rx_start;
      }

      if (signal_complete) {
        result = rx_result;
        if (SUCCESS == result) {
          start = rx_start;
        } else {
          start = 0;
          received = 0;
        }
        // received must have been set earlier before state was updated

        /* Reset for next message */
        rx_result = SUCCESS;
        if (rx_single_use) {
          rx_pos = 0;
        }
        if (rx_pos) {
          rx_state = RX_S_listening;
        } else {
          rx_state = RX_S_inactive;
        }
      }
    } // atomic

    /* Repost the receive task if there's more work to be done. */
    if (need_post) {
      post receiveData_task();
    }

    /* Announce the start of a message first, then completion of the
     * message, and finally that we need another receive buffer (if
     * any of these events happen to occur at the same time).
     */
    if (signal_start) {
      signal Rf1aPhysical.receiveStarted[client](expected);
    }
    if (signal_complete) {
      signal Rf1aPhysical.receiveDone[client](start, received, result);
    }
    if (signal_filled) {
      signal Rf1aPhysical.receiveBufferFilled[client](start, received);
    }
  }

  async command error_t Rf1aPhysical.setReceiveBuffer[uint8_t client] (uint8_t* buffer,
                                                                       unsigned int length,
                                                                       bool single_use) {
    /* Radio must be assigned */
    if (! call ArbiterInfo.inUse()) {
      return EOFF;
    }
    /* This must be the right client */
    if (client != call ArbiterInfo.userId()) {
      return EBUSY;
    }
    /* Buffer and length must be realistic; if either bogus, clear them both
     * and disable reception. */
    if ((! buffer) || (0 == length)) {
      buffer = 0;
      length = 0;
    }
    atomic {
      /* If there's a buffer in play and we're actively receiving into
       * it, reject the attempt. */
      if (rx_pos && (RX_S_listening < rx_state)) {
        return EBUSY;
      }

      rx_pos = buffer;
      rx_pos_end = buffer + length;
      rx_start = 0;
      rx_single_use = single_use;

      if (0 == rx_pos) {
        // Return to IDLE after RX and TX.
        call Rf1aIf.writeRegister(MCSM1, 0xf0 & call Rf1aIf.readRegister(MCSM1));

        /* Setting a null buffer acts to cancel any in-progress
         * reception. */
        if (RX_S_listening < rx_state) {
          rx_result = ECANCEL;
          post receiveData_task();
        } else {
          rx_state = RX_S_inactive;
          /* Return to IDLE now, if not transmitting */
          if (transmitIsInactive_atomic_()) {
            resumeIdleMode_(TRUE);
          }
        }
      } else if (RX_S_inactive == rx_state) {
        uint8_t off_mode;

        if (rx_single_use) {
          // Return to IDLE after RX, RX after TX
          off_mode = 0x03;
        } else {
          // Return to RX after RX or TX
          off_mode = 0x0F;
        }
        call Rf1aIf.writeRegister(MCSM1, off_mode | (0xf0 & call Rf1aIf.readRegister(MCSM1)));
        startReception_();
      }
    }
    return SUCCESS;
  }

  default async command unsigned int Rf1aTransmitFragment.transmitReadyCount[uint8_t client] (unsigned int count) {
    return call Rf1aPhysical.defaultTransmitReadyCount[client](count);
  }

  async command unsigned int Rf1aPhysical.defaultTransmitReadyCount[uint8_t client] (unsigned int count) {
    atomic {
      return transmitReadyCount_(client, count);
    }
  }

  default async command const uint8_t* Rf1aTransmitFragment.transmitData[uint8_t client] (unsigned int count) {
    return call Rf1aPhysical.defaultTransmitData[client](count);
  }

  async command const uint8_t* Rf1aPhysical.defaultTransmitData[uint8_t client] (unsigned int count) {
    atomic {
      return transmitData_(client, count);
    }
  }

  async event void Rf1aInterrupts.rxFifoAvailable[uint8_t client] () {
    if (RX_S_inactive < rx_state) {
      /* If we have data, and the state doesn't reflect that we're
       * receiving, bump the state so we know to fast-exit out of
       * transmit to allow receiveData_task to run. */
      if ((RX_S_listening == rx_state)
          && (0 < receiveCountAvailable_())) {
        rx_state = RX_S_synchronized;
      }
      post receiveData_task();
    }
  }

  async event void Rf1aInterrupts.txFifoAvailable[uint8_t client] () {
    if (TX_S_inactive != tx_state) {
      uint8_t txbytes = call Rf1aIf.readRegister(TXBYTES);

      /* Remember those other comments warning of an odd behavior
       * where we can pass CCA, put the radio into TX, load up the
       * TXFIFO, then find ourselves in RX with a new tattoo, no
       * memory of the night before, and a full TXFIFO?  This check
       * catches one situation where that happens.  Clearly if the
       * radio's saying there's room, and there isn't, something's
       * wrong. No idea why we get this interrupt in that case, but
       * we're grateful nonetheless.
       */
      if (0x3F <= (0x7F & txbytes)) {
        tx_result = ECANCEL;
      }
      post sendFragment_task();
    }
  }

  async event void Rf1aInterrupts.rxOverflow[uint8_t client] () {
    atomic {
      rx_result = ECANCEL;
      post receiveData_task();
    }
  }

  async event void Rf1aInterrupts.txUnderflow[uint8_t client] () {
    atomic {
      tx_result = FAIL;
      post sendFragment_task();
    }
  }

  async event void Rf1aInterrupts.syncWordEvent[uint8_t client] () {
    signal Rf1aPhysical.frameStarted[call ArbiterInfo.userId()]();
  }

  async event void Rf1aInterrupts.clearChannel[uint8_t client] () {
    signal Rf1aPhysical.clearChannel[call ArbiterInfo.userId()]();
  }

  async event void Rf1aInterrupts.carrierSense[uint8_t client] () {
    signal Rf1aPhysical.carrierSense[call ArbiterInfo.userId()]();
  }

  async event void Rf1aInterrupts.coreInterrupt[uint8_t client] (uint16_t iv) { }

  default async event void Rf1aPhysical.receiveStarted[uint8_t client] (unsigned int length) { }

  default async event void Rf1aPhysical.receiveDone[uint8_t client] (uint8_t* buffer,
                                                                     unsigned int count,
                                                                     int result) { }

  default async event void Rf1aPhysical.receiveBufferFilled[uint8_t client] (uint8_t* buffer,
                                                                             unsigned int count) { }

  default async event void Rf1aPhysical.frameStarted[uint8_t client] () { }
  default async event void Rf1aPhysical.clearChannel[uint8_t client] () { }
  default async event void Rf1aPhysical.carrierSense[uint8_t client] () { }
  default async event void Rf1aPhysical.released[uint8_t client]     () { }

  async command rf1a_status_e Rf1aStatus.get () {
    uint8_t rc = call Rf1aIf.strobe(RF_SNOP);
    if (rc & 0x80) {
      return RF1A_S_OFFLINE;
    }
    return (rf1a_status_e)(RF1A_S_MASK & rc);
  }

  async command int Rf1aPhysical.getChannel[uint8_t client] () {
    /* Radio must be assigned */
    if (! call ArbiterInfo.inUse()) {
      return -EOFF;
    }
    /* This must be the right client */
    if (client != call ArbiterInfo.userId()) {
      return -EBUSY;
    }
    return call Rf1aIf.readRegister(CHANNR);
  }

  async command int Rf1aPhysical.setChannel[uint8_t client] (uint8_t channel) {
    /* Radio must be assigned */
    if (! call ArbiterInfo.inUse()) {
      return -EOFF;
    }
    /* This must be the right client */
    if (client != call ArbiterInfo.userId()) {
      return -EBUSY;
    }
    atomic {
      bool radio_online;
      uint8_t rc = call Rf1aIf.strobe(RF_SNOP);

      /* The radio must not be actively receiving or transmitting. */
      if ((TX_S_inactive != tx_state)
          || (RX_S_listening < rx_state)
          || (RF1A_S_FSTXON == (rc & RF1A_S_MASK))
          || (RF1A_S_TX == (rc & RF1A_S_MASK))) {
        return -ERETRY;
      }

      /* If radio is not asleep, make sure it transitions to IDLE then
       * back to its normal mode.  With MCSM0.FS_AUTOCOL set to 1
       * (normal with our configurations) this ensures recalibration
       * to the new frequency.
       */
      radio_online = (RF1A_S_OFFLINE != call Rf1aStatus.get());
      if (radio_online) {
        resumeIdleMode_(FALSE);
      }
      call Rf1aIf.writeRegister(CHANNR, channel);
      if (radio_online) {
        resumeIdleMode_(TRUE);
      }
    }
    return SUCCESS;
  }

  enum {
    /** SLAU259 table 19-15 provides the RSSI_offset value. */
    RSSI_offset = 74,
  };

  /** Algorithm described in 19.3.8 to convert RSSI from register
   * value to absolute power level.
   */
  int rssiConvert_dBm (uint8_t rssi_dec_) {
    int rssi_dec = rssi_dec_;
    if (rssi_dec >= 128) {
      return ((rssi_dec - 256) / 2) - RSSI_offset;
    }
    return (rssi_dec / 2) - RSSI_offset;
  }

  async command int Rf1aPhysical.rssi_dBm[uint8_t client] () {
    int rv;

    /* Radio must be assigned */
    if (! call ArbiterInfo.inUse()) {
      return EOFF;
    }
    /* This must be the right client */
    if (client != call ArbiterInfo.userId()) {
      return EBUSY;
    }
    atomic {
      uint8_t rc = call Rf1aIf.strobe(RF_SNOP);
      if (RF1A_S_RX == (RF1A_S_MASK & rc)) {
        (void)spinForValidRssi__();
      }
      rv = rssiConvert_dBm(call Rf1aIf.readRegister(RSSI));
    }
    return rv;
  }

  async command int Rf1aPhysical.lqi[uint8_t client] () {
    int rv;

    /* Radio must be assigned */
    if (! call ArbiterInfo.inUse()) {
      return EOFF;
    }
    /* This must be the right client */
    if (client != call ArbiterInfo.userId()) {
      return EBUSY;
    }
    atomic {
      rv = call Rf1aIf.readRegister(LQI);
    }
    return ((rv & 0x7F)*-1);
  }
  async command void Rf1aPhysicalMetadata.store (rf1a_metadata_t* metadatap) {
    atomic {
      metadatap->rssi = rx_rssi_raw;
      metadatap->lqi = rx_lqi_raw;
    }
  }

  async command int Rf1aPhysicalMetadata.rssi (const rf1a_metadata_t* metadatap) {
    return rssiConvert_dBm(metadatap->rssi);
  }

  async command int Rf1aPhysicalMetadata.lqi (const rf1a_metadata_t* metadatap) {
    /* Mask off the CRC check bit */
    return metadatap->lqi & 0x7F;
  }

  async command bool Rf1aPhysicalMetadata.crcPassed (const rf1a_metadata_t* metadatap) {
    /* Return only the CRC check bit */
    return metadatap->lqi & 0x80;
  }
}

/* 
 * Local Variables:
 * mode: c
 * End:
 */
