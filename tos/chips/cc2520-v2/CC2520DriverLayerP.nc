/*
 * Copyright (c) 2013, Eric B. Decker
 * Copyright (c) 2010, Vanderbilt University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:  
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * CC2520-v2
 *
 * Differences from original CC2520 driver....
 *
 * o The original CC2520 driver made minimal changes from the CC2420x driver.
 *   But this was inappropriate because the state machines are different.
 *   In particular power states while similar, are different enough.  This
 *   driver fully implements LPM2 (full power down, OFF), LPM1 (STANDBY),
 *   and Active Mode (all the rest).  The CC2420 driver didn't implement
 *   full power down just the equivalent of LPM1.
 *
 * o This drivers supports a stand-alone CC2520 as well as the dual-chip
 *   CC2520-CC2591 range extender combination.
 *
 * o SPI via immediateRequest (arbitration is still supported).  Written for
 *   X5 msp430 processors that have lots of ports.   Assumes dedicated port.
 *   Uses immediateRequest.
 *
 * o Power transitions use PlatformCC2520 methods.   This is because various
 *   manipulations of CC2520 chip pins must be done and on the MSP430 processors
 *   and this is very platform/mcu dependent.  The MCU also has on board pull up,
 *   pull down resistors which we use to hold select i/o lines low to prevent
 *   meta-stable states.
 *
 * o Full LPM2/AM (active mode) support.  Handled by PlatformCC2520
 *   (power{Up,Down} and {sleep,wakeup}).  LPM2 corresponds to the OFF
 *   state and LPM1 STANDBY state.  The CC2420X driver calls STANDBY PD
 *   (for PowerDown) but it isn't really power down but rather
 *   simply has the oscillator turned off.
 *
 *   . Careful attention to powering and depowering CC2520.  Full support
 *     for LPM2/AM transitioning and reinitializing on return to service.
 *     See PlatformCC2520.  After being in OFF/LPM2, the chip will have lost
 *     any configuration information that was previously set.  This includes
 *     any modifications made to gpio programming.  The configuration is
 *     also lost when the chip is reset.
 *
 *   . Keep CC2520 in RESET when powered down, avoids digital glitches as
 *     spec'd in the CC2520 datasheet.  See PlatformCC2520.
 *
 *   . XOSC turn on.  Sets CSN/0 then watches SO.  When SO goes to 1, XOSC
 *     is stable as documented in the CC2520 datasheet.  Only use busy waits
 *     when absolutely necessary.  See PlatformCC2520.  Busy waits also
 *     have hard limits and will Panic if violated.   This prevents a failure
 *     during a busy wait from hanging the system without being visible.
 *
 *   . Properly handle SO becoming an input when RESET or LPM2.  See
 *     PlatformCC2520.   A pull down is used to keep the pin from going
 *     metastable.
 *
 * o SFD timing queueing.  The signal SFD is used to timestamp outgoing and
 *   incoming packets.  There can be one outgoing and possibly several
 *   incoming packets.  As these packets are TX'd or RX'd, the SFD will
 *   cause the SFD pin to rise.  It falls at the end of the packet.  Bottom
 *   line is there can be multiple packets in the system and we need to keep
 *   track of what time stamps are associated with which packets as these
 *   packets move through the system.  As there can only be a TX or RX active
 *   at any one time, the same signal is used to denote the status of the
 *   current packet.  Timestamps come in via time capture h/w.   We capture
 *   both rising and falling edges.  For time capture, only the rising edge
 *   is needed.  The SFD edges are also used to switch driver states.
 *   The FRM_DONE completion exception also approximately indicates the end
 *   of the packet.
 *
 *   We handle this by recording the time when SFD rises and falls for each
 *   packet.  TX/RX status is detemined by current chip state (from status
 *   byte).   The time stamps are inserted into a FIFO queue as the SFD
 *   signal is seen so the stamps are seen in order.  If we miss a time
 *   stamp (because things are taking too long) the h/w will set the
 *   overflow (overwrite) bit.  Timestamping stops until the transmit fifo
 *   and rxfifo are empty.   This can fail depending on packet interarrival
 *   rate.  If too many packets are coming in we never get empty and never
 *   resync.  A timeout can be used to limit how long we go without timestamps.
 *   If that occurs we would "nuke2rxon" to shut the radio down and reset
 *   back to a reasonable state.
 *
 *   The SFDCapture interrupt should be a higher priority than other radio
 *   interrupts.   This is a good thing.  This is so on the msp430 processors
 *   (or can be if the Platform is designed correctly).
 *
 *   A simpler approach would be to simply flush the queues and increment
 *   a counter so we can see if the condition actually happens.  More
 *   complexity can be added later if it is a problem.
 *
 *   You can't just keep going because you don't know when if at all the
 *   SFD edge and time capture will resyncronize.  Depends on traffic
 *   load and whether or not the rxfifo empties.
 *
 *   The reason this works is because we get individual exceptions generated
 *   for each packet (ie. TX_FRM_DONE/RX_FRM_DONE).  As long as we don't take
 *   too long or lose an exception.   It is possible to get out of sync if
 *   we lose an exception.
 *
 * o Full support for CCA.  Use of STXON and STXONCCA as requested by the
 *   outgoing packet.
 *
 * o Support for the 2591 range extender.  Requires modification from the
 *   default (power up default, cc2420 compatability) GPIO setup.  Depending
 *   on the h/w design, GP3-GP5 (at least GP4 and GP5) are used to control
 *   the the 2591 range extender.  The CC2591 HGM pin must either be
 *   connected to the CC2520 or to an MCU pin.
 *
 * o Same driver used for both 2520 standalone and 2520/2591 combination.
 *   Easier to support.
 *
 * o Make better use of exception signalling from the chip.  Both errors and
 *   completion exceptions show up on Exception_A.  We tried seperating them
 *   out but needed the pin for TX_A.
 *
 * o Another signal that is brought out on the GPIO pins is TXA (tx_a),
 *   which indicates the cc2520 state machine is in tx_active.
 *   This is used in the SFDCapture code to determine if the current
 *   packet (SFD rising) is a tx or rx packet.  Part of the proper
 *   functioning of TXONCCA.
 *
 * o Add support for PANIC and PLATFORM timing hooks.
 *
 * Required H/W pins.   The Platform is required to have the following
 * physically wired.  The Platform is responsible for correctly initializing
 * these pins on boot up of the MCU.   (Why?   Because it makes sure that
 * the CC2520 h/w is in a reasonable state as early as possible.   It also
 * allows the Platform code to set blocks of pins (in the I/O registers)
 * rather than doing it piecemeal, which takes a bunch more instructions
 * because it would be done one bit at a time rather than the full byte).
 *
 *  CC2520 pins available:  (directions are relative to the MCU)  The naming
 *  is the default (POR) values for the CC2520.
 *
 *    CSN       chip select, low true   (initially high, output)
 *    VREN      Voltage Reg Enable, high true.  (initially low, output)
 *    RSTN      Reset, low true (initially low, hold chip in reset, output)
 *
 *    GPIO0     GPIO0 by default outputs a 1 MHz clock.  (switched to SFD)
 *
 *    GPIO1     FIFO, (input, default, switched to TXA).
 *    GPIO2     FIFOP, (input, default, switched to EXCA).
 *
 *    gpio3-5 are not used by the driver directly.  PlatformCC2520 is
 *    responsible for dealing with the gp5 default being input.
 *
 *    GPIO3     (defaults to CCA, reserved for 2591, HGM)
 *    GPIO4     (defaults to SFD, reserved for 2591, EN, !lna_pd[1]
 *    GPIO5     (defaults to CC2520 input, reserved for PAEN, !pa_pd) in LPM2
 *              needs to be driven to avoid excessive power consumption.
 *    SO        MISO (master in, slave out).  Data from CC2520 to the MCU.
 *              When the CC2520 XOSC is running, dropping CSN (asserted CS)
 *              has the status of XOSC stable.  1 for stable.   This is
 *              used when turning the oscillators on, see powerUp and wakeup.
 *              See PlatformCC2520.
 *
 *              SO is also monitored for XOSC stabilization.
 *
 *    SI, SCLK  other SPI pins.
 *
 * HGM (2591 configuration) may be wired directly or via the CC2520 via
 *     GPIO3.  TI in their examples, use the CC2520 to set or clear this
 *     signal, but this is stupid because it takes SPI traffic to do this.
 *     But if you don't have the pins, it lets you still take care of it
 *     but shouldn't be the default design.  The eval boards, EXP430F5438
 *     with the CC2520-2591EM module, uses GPIO3 from the CC2520 to control
 *     HGM on the 2591.
 *
 *     setHighGain encapsulates how this is actually implemented.
 *
 * On page 34, "section 10.4, SO" of the CC2520 Datasheet, it states that when
 * "SO is configured as an input when CSn is high or RESETn is low."   When
 * normally being used (Active Mode) but idle CSn will be high, the port will
 * be in SPI mode and the SO pin will be an input to the MCU.   Is this a
 * problem or do we need to play games with driving SO when CSn is high?
 * Which would be a royal pain in the ass.
 *
 *
 * H/W reconfiguration:  (supports both single and dual chip implementations)
 *
 * 1) RESETN, VREG, CSN, SO, SI, and SCLK on individual pins.
 * 2) gp0 -> SFD.  It must be on a capture capable pin
 * 3) gp1 -> tx_active for SFD capture
 * 4) gp2 -> EXCEP_A (completions and errors)
 * 5) gp3 -> not used.   reserved for HGM
 * 6) gp4 -> not used.   reserved for EN
 * 7) gp5 -> not used.   reserved for PA_EN
 * 7) FIFO, FIFOP, SFD, and CCA, are available in FSMSTAT1.
 * 8) Current size of the rxfifo is determined from RXFIFOCNT.
 *
 *
 * Basic Packet operations:
 *
 * The radio chip can actively be doing only one thing at a time, either
 * transmitting or receiving.  It is not Hear-Self.
 *
 * TX:
 *
 * 1) Transmit.   Single packet transmit only.  No pipeline support
 *    (another packet is not sent until the first has been signalled
 *    complete).   Only one packet may be in the TxFifo at a time
 *    (pg 67, CC2520 data sheet).  If another TX attempt is made while
 *    a transmit is still active, it is rejected with EBUSY.
 *
 * 2) Typically, tx packets are ack'd and reception of the ack (rx cycle)
 *    must complete before the next packet gets transmitted.  This is
 *    because the ACK is part of the Channel assignment.   ACK's don't
 *    do CCA but assume the channel is available.  The timing budget for
 *    the transmitted packet is supposed to include the time it takes for
 *    the ACK as well.  This sequencing is handled by the upper layers (not
 *    the driver).
 *
 * 3) Transmission begins by copying the MAC header down to the FIFO.
 *
 * 4) A STXON or STXONCCA is done depending on packet settings.
 *
 * 5) It is possible that the transmission is deferred because the channel
 *    is busy.   This is detected by checking what state the chip is in via
 *    the Status byte or the TX_A signal.
 *
 * 6) Deferred TX packets may be tried again by the upper layer.  A deferred
 *    packet is indicated by an EBUSY return.
 *
 * 7) Timestamping.  If the transmission has started, the rising edge of SFD
 *    will indicate the start of the TX packet, TX status indicates that the
 *    timestamp corresponds to the TX packet.
 *
 *
 * RX:
 *
 * 1) Normal chip state when on is RX_ON and the chipset is waiting for an
 *    incoming frame.
 *
 * 2) The first indication that a receive is happening is a rising edge on
 *    SFD which indicates completion of SFD and start of FrameLength.  CCA
 *    will go low when the Preamble has started to be transmitted.  A
 *    timestamp is taken and RX status indicates the receive.
 *
 * 3) The rising RX_sfd transitions the state machine into RX_ACTIVE state.
 *
 * 4) The falling edge of SFD transitions to RX_ON.
 
 * 5) completion of the packet is indicated by a RX_FRM_DONE exception.  This
 *    causes the packet to be copied out of the RXFIFO and when complete a
 *    RadioReceive.receive signal is generated.
 *
 * Note: There can be multiple RX packets in the fifo and the RX_FRM_DONE
 * exception is a single indicator.  If it is cleared, it won't be asserted
 * again until a new frame is received.
 *
 * Define CC2520_2591 if using 2591 h/w.
 */

/**
 *
 * Author: Janos Sallai, Miklos Maroti
 * Author: Eric B. Decker <cire831@gmail.com>
 *
 * complete rewrite: Eric B. Decker (2013)
 */

#define CC2520_ATOMIC_SPI
#define CC2520_NO_ARB

#ifdef CC2520_ATOMIC_SPI
#define CC2520_ATOMIC     atomic
#else
#define CC2520_ATOMIC
#endif

#ifndef PANIC_RADIO

enum {
  __panic_radio = unique(UQ_PANIC_SUBSYS)
};

#define PANIC_RADIO __panic_radio
#endif

#include <CC2520DriverLayer.h>
#include <Tasklet.h>
#include <RadioAssert.h>
#include <TimeSyncMessageLayer.h>
#include <RadioConfig.h>

norace bool takeAlarm;
norace bool do_dump;                    /* defaults to FALSE */

typedef struct {
  uint8_t p1;
  uint8_t p1ie;
  uint8_t p1ifg;
  uint8_t p3;
  uint8_t p8;
  uint8_t ta0ccr3;
  uint8_t ta0cctl3;
  uint8_t CSN_pin;
  uint8_t RSTN_pin;
  uint8_t VREN_pin;
  uint8_t SFD_pin;
  uint8_t TXA_pin;
  uint8_t EXCA_pin;
} rd_hw_t;


typedef struct {
  uint16_t timestamp;
  uint8_t  status;
  uint8_t  excflag0;
  uint8_t  excflag1;
  uint8_t  excflag2;
  uint8_t  rxfirst;
  uint8_t  rxfifocnt;
  uint8_t  txfifocnt;
  uint8_t  fsmstat0;
  uint8_t  fsmstat1;
} rd_short_t;

typedef struct {
  uint8_t frmfilt0;                     /* 0x00 */
  uint8_t frmfilt1;                     /* 0x01 */
  uint8_t srcmatch;                     /* 0x02 */
  uint8_t pad0;
  uint8_t srcshorten0;                  /* 0x04 */
  uint8_t srcshorten1;                  /* 0x05 */
  uint8_t srcshorten2;                  /* 0x06 */
  uint8_t pad1;
  uint8_t srcexten0;                    /* 0x08 */
  uint8_t srcexten1;                    /* 0x09 */
  uint8_t srcexten2;                    /* 0x0A */
  uint8_t pad2;
  uint8_t frmctrl0;                     /* 0x0C */
  uint8_t frmctrl1;                     /* 0x0D */
  uint8_t rxenable0;                    /* 0x0E */
  uint8_t rxenable1;                    /* 0x0F */
  uint8_t excflag0;                     /* 0x10 */
  uint8_t excflag1;                     /* 0x11 */
  uint8_t excflag2;                     /* 0x12 */
  uint8_t pad3;
  uint8_t excmaska0;                    /* 0x14 */
  uint8_t excmaska1;                    /* 0x15 */
  uint8_t excmaska2;                    /* 0x16 */
  uint8_t pad4;
  uint8_t excmaskb0;                    /* 0x18 */
  uint8_t excmaskb1;                    /* 0x19 */
  uint8_t excmaskb2;                    /* 0x1A */
  uint8_t pad5;
  uint8_t excbindx0;                    /* 0x1C */
  uint8_t excbindx1;                    /* 0x1D */
  uint8_t excbindy0;                    /* 0x1E */
  uint8_t excbindy1;                    /* 0x1F */
  uint8_t gpioctrl0;                    /* 0x20 */
  uint8_t gpioctrl1;                    /* 0x21 */
  uint8_t gpioctrl2;                    /* 0x22 */
  uint8_t gpioctrl3;                    /* 0x23 */
  uint8_t gpioctrl4;                    /* 0x24 */
  uint8_t gpioctrl5;                    /* 0x25 */
  uint8_t gpiopolarity;                 /* 0x26 */
  uint8_t pad6;
  uint8_t gpioctrl;                     /* 0x28 */
  uint8_t pad7;
  uint8_t dpucon;                       /* 0x2A */
  uint8_t pad8;
  uint8_t dpustat;                      /* 0x2C */
  uint8_t pad9;
  uint8_t freqctrl;                     /* 0x2E */
  uint8_t freqtune;                     /* 0x2F */
  uint8_t txpower;                      /* 0x30 */
  uint8_t txctrl;                       /* 0x31 */
  uint8_t fsmstat0;                     /* 0x32 */
  uint8_t fsmstat1;                     /* 0x33 */
  uint8_t fifopctrl;                    /* 0x34 */
  uint8_t fsmctrl;                      /* 0x35 */
  uint8_t ccactrl0;                     /* 0x36 */
  uint8_t ccactrl1;                     /* 0x37 */
  uint8_t rssi;                         /* 0x38 */
  uint8_t rssistat;                     /* 0x39 */
  uint8_t pad10[2];
  uint8_t rxfirst;                      /* 0x3C */
  uint8_t pad11;
  uint8_t rxfifocnt;                    /* 0x3E */
  uint8_t txfifocnt;                    /* 0x3F */

  uint8_t chipid;                       /* 0x40 */
  uint8_t pad12;
  uint8_t version;                      /* 0x42 */
  uint8_t pad13;
  uint8_t extclock;                     /* 0x44 */
  uint8_t pad14;
  uint8_t mdmctrl0;                     /* 0x46 */
  uint8_t mdmctrl1;                     /* 0x47 */
  uint8_t freqest;                      /* 0x48 */
  uint8_t pad15;
  uint8_t rxctrl;                       /* 0x4A */
  uint8_t pad16;
  uint8_t fsctrl;                       /* 0x4C */
  uint8_t pad17;
  uint8_t fscal0;                       /* 0x4E */
  uint8_t fscal1;                       /* 0x4F */
  uint8_t fscal2;                       /* 0x50 */
  uint8_t fscal3;                       /* 0x51 */
  uint8_t agcctrl0;                     /* 0x52 */
  uint8_t agcctrl1;                     /* 0x53 */
  uint8_t agcctrl2;                     /* 0x54 */
  uint8_t agcctrl3;                     /* 0x55 */
  uint8_t adctest0;                     /* 0x56 */
  uint8_t adctest1;                     /* 0x57 */
  uint8_t adctest2;                     /* 0x58 */
  uint8_t pad18;
  uint8_t mdmtest0;                     /* 0x5A */
  uint8_t mdmtest1;                     /* 0x5B */
  uint8_t dactest0;                     /* 0x5C */
  uint8_t dactest1;                     /* 0x5D */
  uint8_t atest;                        /* 0x5E */
  uint8_t dactest2;                     /* 0x5F */
  uint8_t ptest0;                       /* 0x60 */
  uint8_t ptest1;                       /* 0x61 */
  uint8_t reserved;                     /* 0x62 */
  uint8_t pad19;
  uint8_t dpubist;                      /* 0x7A */
  uint8_t actbist;                      /* 0x7C */
  uint8_t rambist;                      /* 0x7E */
  uint8_t status;
  uint16_t timestamp;                   /* microsec timestamp */
} radio_dump_t;

/* first 0x64 bytes contiguous, last 3 done by hand. */
#define CC2520_MAIN_DUMP_SIZE   0x64

norace radio_dump_t rd;
norace rd_short_t   rds;
norace rd_hw_t      rd_hw_state;
norace uint8_t      txfifo[128];
norace uint8_t      rxfifo[128];
norace bool         m_hw_configured;


/*
 * SFD timestamps
 */

typedef enum {
  SFD_UP   = 0x0001,
  SFD_DWN  = 0x0002,
  SFD_RX   = 0x0010,
  SFD_TX   = 0x0020,
  SFD_OVW  = 0x0100,
  SFD_BUSY = 0x8000,

  MAX_SFD_STAMPS = 8,
} sfd_status_t;


typedef struct {
  uint32_t local;                       /* rising edge   */
  uint16_t time_up;                     /* rising edge   */
  uint16_t time_down;                   /* falling edge  */
  uint32_t time_finish;                 /* frm_done time */
  uint16_t sfd_status;                  /* sfd_status_t, but hex */
} sfd_stamp_t;


/*
 * Note: The TX SFD entry could be a seperate entry since there can only
 * be one outstanding at a time.   But to avoid strange out of order effects,
 * ie. processing a transmitted packet that was transmitted after a RX packet
 * came in first.   Shouldn't ever happen since the chip is single duplex.
 *
 * But if we have a single SFDQueue that represents the actual time order that
 * packets have happened, then it isn't even an issue.
 *
 * sfd_lost is TRUE if the current set of sfd_stamps has seen an OVR
 * (overwritten), or if we have lost a time stamp for some other reason.
 * We assume they are all crap.
 */

norace bool sfd_lost;
norace uint8_t sfd_fill, sfd_drain, sfd_entries;
      sfd_stamp_t sfd_stamps[MAX_SFD_STAMPS];
sfd_stamp_t * const sfd_ptrs[MAX_SFD_STAMPS] = {
  &sfd_stamps[0], &sfd_stamps[1], &sfd_stamps[2], &sfd_stamps[3],
  &sfd_stamps[4], &sfd_stamps[5], &sfd_stamps[6], &sfd_stamps[7]
};


/*
 * Instrumentation, error counters, etc.
 */

norace uint16_t cc2520_inst_rx_overflows;
norace uint16_t cc2520_inst_rx_toolarge;
norace uint16_t cc2520_inst_rx_toosmall;
norace uint16_t cc2520_inst_pkt_toolarge;
norace uint16_t cc2520_inst_bad_crc;
norace uint16_t cc2520_inst_sfd_overwrites;
norace uint16_t cc2520_inst_nukes;
norace uint16_t cc2520_inst_other;
norace uint16_t cc2520_tx_startup_time_max;


typedef struct {
  uint8_t        reg_start;
  uint8_t        len;
  const uint8_t *vals;
} reg_init_t;


/*
 * Register configuration.
 *
 * Registers that we change are listed in blocks via the various reg_vals
 * structures.  Registers that we don't currently care about are simply
 * listed.  Other registers we care about are listed with the notation
 * "use POR value".
 *
 * Also see SWRS068, December 2007, Section 28.1  (Table 21)
 * CC2520 datasheet/manual
 */

  /*
   * frmfilt0 (00, 0d/08)
   *     fcf_reserved_mask[6:4]  0
   *     max_frame_version[3:2]  2
   *     pan_coord[1]            0
   *     frame_filter_en[0]      0
   *
   * frmfilt1 (01, 78/f8)
   *    ft_4to7_reserved[7]      1
   *    ft_3_mac_cmd[6]          1
   *    ft_2_ack[5]              1
   *    ft_1_data[4]             1
   *    ft_0_beacon[3]           1
   *    modify_ft_filter[2:1]    0
   *
   * srcmatch (02, 07/06)
   *    pend_datareq_only[2]     1
   *    autopend[1]              1
   *    src_match_en[0]          0
   */
static const uint8_t reg_vals_00[] = {
  0x08,                                 /* frmfilt0 */
  0xf8,                                 /* frmfilt1 */
  0x06                                  /* srcmatch */
};

/* srcshorten0    srcshorten1    srcshorten2  */
/* srcexten0      srcexten1      srcexten2    */

/* frmctrl0: (0c, 40)
 * append_data, autocrc, autoack
 *
 * append_data_mode[7]: 0 rssi/crc_ok/7 bit correlation
 *                  0   1 rssi/crc_ok/7 bit srcresindex
 * autocrc[6]:      1
 * autoack[5]:      0
 * energy_scan [4]: 0
 * rx_mode [3:2]:   0, use rxfifo
 * tx_mode [1:0]:   0, use txfifo
 *
 * use POR value.
 */

/* frmctrl1: (0d, 01)
 *
 * Pending_OR[2]:          0
 * ignore_tx_underf [1]:   0
 * set_rxenmask_on_tx [0]: 1
 *
 * use POR value.
 */

/* freqctrl         freqtune        txctrl */

static const uint8_t reg_vals_14[] = {
  /*
   * EXC_A has any exception we are interested in.  This includes
   * completion as well as error conditions.
   *
   * TX_FRM_DONE (1), TX_ACK_DONE (2), RX_FRM_DONE (8), RX_FRM_ABORTED (21).
   * RX_OVERFLOW | RX_UNDERFLOW | TX_OVERFLOW | TX_UNDERFLOW
   */
  0x7e,

  0x01,             /* EXC1_RX_FRM_DONE */

  /* RF_NO_LOCK | SPI_ERROR | OPERAND_ERROR | USAGE_ERROR | MEMADDR_ERROR */
  0x3f              /* and EXC2_RX_FRM_ABORTED */
};

/* fifopctrl: (34, 40/7f)    fifop threshold
 *
 * fsmctrl: (35, 01)
 *    slotted_ack[1]:    0
 *    rx2rx_time_off[0]: 1          12 symbol delay
 *
 * ccactrl0: (36, e0/fc) per TIMAC code
 */
static const uint8_t reg_vals_34[] = {
  0x7f,                                 /* fifopctrl */
  0x01,                                 /* fsmctrl   */
  0xfc                                  /* ccactrl0  */
};

/* POR ccactrl1: (37, 1a), cca_mode 0, cca_hyst: 2 */

/*
 * mdmctrl0: (46, 45/85)
 *    2 zero symbols, demod_avg_mode: lock avg after premable
 *    preamble len 4 leading zeros, extra tx filtering
 *
 * mdmctrl1: (47, 2e/14)
 *    corr_thr_sfd: off, rx setting for preamble zero symbols
 *    corr_thr: 4
 */
static const uint8_t reg_vals_46[] = {
  0x85,                                 /* mdmctrl0 (46) */
  0x14,                                 /* mdmctrl1 (47) */
};


/*
 * Performance Tuning Registers (see table 21)
 *
 * rxctrl   (4a, 29/3f)     fsctrl   (4c, 55/5a)    fscal0   (4e, 24)
 * fscal1   (4f, 29/2b)     fscal2   (50, 20)       fscal3   (51/2a)
 * agcctrl0 (52, 5f)        agcctrl1 (53, 0e/11)    agcctrl2 (54, 00)
 * agcctrl3 (55, 2e)        adctest0 (56, 66/10)    adctest1 (57, 0a/0e)
 * adctest2 (58, 05/03)     mdmtest0 (5a, 05)       mdmtest1 (5b, 08)
 * dactest0 (5c, 00)        dactest1 (5d, 00)       atest    (5e, 00)
 * dactest2 (5f, 00)        ptest0   (60, 00)       ptest1   (61, 00)
 * dpubist  (7a, 00)        actbist  (7c, 00)       rambist  (7e, 02)
 *
 * agcctrl1 may get changed to 16 by Platform dependent code (if the platform
 * has a 2591 it gets changed to 16).  per TIMAC
 */
static const uint8_t reg_vals_4a[] = {
  0x3f,                                 /* rxctrl  (4a) */
  0x00,                                 /* pad     (4b) */
  0x5a                                  /* fsctrl  (4c) */
};


/* adctest{0,1,2} per Table 21 */
static const uint8_t reg_vals_56[] = {
  0x10, 0x0e, 0x03
};


static const reg_init_t reg_config[] = {
  { .reg_start = 0x00, .len = 3, .vals = reg_vals_00 },
  { .reg_start = 0x14, .len = 3, .vals = reg_vals_14 },
  { .reg_start = 0x34, .len = 3, .vals = reg_vals_34 },
  { .reg_start = 0x46, .len = 2, .vals = reg_vals_46 },
  { .reg_start = 0x4a, .len = 3, .vals = reg_vals_4a },
  { .reg_start = 0x56, .len = 3, .vals = reg_vals_56 },
  {                    .len = 0                      }
};


  tasklet_norace message_t  * txMsg;            /* msg driver owns */

  message_t                   rxMsgBuffer;
  tasklet_norace message_t  * rxMsg = &rxMsgBuffer;

  /* needs to be volatile, can be modified at interrupt level */
  norace volatile enum {                /* no race is fine. */
    TXUS_IDLE,                          /* nothing happening */
    TXUS_STARTUP,                       /* starting to write h/w */
    TXUS_PENDING,                       /* waiting to finish */
    TXUS_ABORT                          /* oops */
  } tx_user_state;


module CC2520DriverLayerP {
  provides {
    interface Init as SoftwareInit @exactlyonce();

    interface RadioState;
    interface RadioSend;
    interface RadioReceive;
    interface RadioCCA;
    interface RadioPacket;

    interface PacketField<uint8_t> as PacketTransmitPower;
    interface PacketField<uint8_t> as PacketRSSI;
    interface PacketField<uint8_t> as PacketTimeSyncOffset;
    interface PacketField<uint8_t> as PacketLinkQuality;
//  interface PacketField<uint8_t> as AckReceived;
    interface PacketAcknowledgements;

    interface CC2520BasicAccess;
  }
  uses {
    interface LocalTime<TRadio>;
    interface CC2520DriverConfig as Config;

    interface Resource       as SpiResource;
    interface FastSpiByte;
    interface SpiByte;
    interface SpiPacket;
    interface SpiBlock;

    interface GeneralIO      as RSTN;
    interface GeneralIO      as VREN;
    interface GeneralIO      as CSN;

    interface GeneralIO      as SFD;             /* gp0 -> sfd   */
    interface GeneralIO      as TXA;             /* gp1 -> tx_active  */
    interface GeneralIO      as EXCA;            /* gp2 -> exca  */

    interface GenericCapture<uint16_t>
                             as SfdCapture;
    interface GpioInterrupt  as ExcAInterrupt;

    interface PacketFlag     as TransmitPowerFlag;
    interface PacketFlag     as RSSIFlag;
    interface PacketFlag     as TimeSyncFlag;
    interface PacketFlag     as AckReceivedFlag;

    interface PacketTimeStamp<TRadio, uint32_t>;

    interface Tasklet;
    interface RadioAlarm;

#ifdef RADIO_DEBUG_MESSAGES
    interface DiagMsg;
#endif
    interface CC2520Security;

    interface PlatformCC2520;
    interface Platform;
    interface Panic;
    interface Trace;
  }
}

implementation {

#define HI_UINT16(val) (((val) >> 8) & 0xFF)
#define LO_UINT16(val) ((val) & 0xFF)

#define HIGH_PRIORITY 1
#define LOW_PRIORITY 0

#define __PANIC_RADIO(where, w, x, y, z) do {               \
	call Panic.panic(PANIC_RADIO, where, w, x, y, z);   \
  } while (0)


  /*----------------- STATE -----------------*/

  /*
   * order matters:
   *
   * RX:  RX_ON    to RX_ACTIVE
   * TX:  TX_START to TX_ACTIVE
   */
  typedef enum {
    STATE_OFF                   = 0,    /* LPM2, VREN is off, XOSC is off */
    STATE_OFF_2_LOAD            = 1,    /* waiting for h/w to come up, need RadioAlarm */
    STATE_LOAD_CONFIG           = 2,    /* loading conifg at task level, then goto to IDLE */
    STATE_STANDBY               = 3,    /* LPM1, VREN is on,  XOSC is off */
    STATE_STANDBY_2_LOAD        = 4,    /* waiting for h/w to come up, need RadioAlarm */
    STATE_IDLE                  = 5,    /* Active, TX off, RX off */
    STATE_RX_ON                 = 6,    /* Waiting to Receive */
    STATE_RX_ACTIVE             = 7,    /* Actively receiving */
    STATE_TX_START              = 9,    /* Attempting to Send */
    STATE_TX_ACTIVE             = 10,   /* TX took */
  } cc2520_driver_state_t;

  /*
   * on boot, initilized to STATE_OFF (0)
   *
   * Also, on boot, platform initialization is responsible for setting
   * the pins on the CC2520 so it is effectively turned off.
   *
   * Platform initialization occurs shortly after boot.  On the MSP430
   * platforms, reset forces all of the digital I/O in to input mode
   * which will effectively power down the CC2520.  Platform code then
   * initializes pin state so the chip is held in the OFF state until
   * commanded otherwise.
   */

  norace cc2520_driver_state_t dvr_state;

  /*
   * tx_user_state is used for handshaking with the interrupt level
   * when doing a transmit.  The TX startup code will set this
   * datum to tell the interrupt level that TX start up code has been
   * doing something.   If a catastrophic error occurs, it will be
   * switched to TXUS_ABORT, which tells the TX code to fail.
   *
   * when tx_user_state is STARTUP or PENDING, txMsg holds a pointer the the
   * msg buffer that the upper layers want to transmit.   The driver owns
   * this buffer while it is working on it.
   */
//  norace enum {                         /* no race is fine. */
//    TXUS_IDLE,                          /* nothing happening */
//    TXUS_STARTUP,                       /* starting to write h/w */
//    TXUS_PENDING,                       /* waiting to finish */
//    TXUS_ABORT                          /* oops */
//  } tx_user_state;


  /*
   * if transmitting a timesync message, the original absolute timestamp
   * is kept in timesync_absolute.  0 is stored if not doing a timesync
   * message.
   */

  norace uint32_t timesync_absolute;

  enum {
    FCS_SIZE     = 2,
    TXA_MAX_WAIT = 50,                  /* in uS */
  };


  typedef enum {
    CMD_NONE        = 0,     // no command pending.
    CMD_TURNOFF     = 1,     // goto lowest power state.
    CMD_STANDBY     = 2,     // goto low power state
    CMD_TURNON      = 3,     // goto RX_ON state
    CMD_TRANSMIT    = 4,     // transmit a message
    CMD_RECEIVE     = 5,     // receive a message
    CMD_CCA         = 6,     // perform a clear chanel assesment
    CMD_CHANNEL     = 7,     // change the channel
    CMD_SIGNAL_DONE = 8,     // signal the end of the state transition
  } cc2520_cmd_t;

  tasklet_norace cc2520_cmd_t dvr_cmd;        /* gets initialized to 0, CMD_NONE  */
  tasklet_norace bool         radioIrq;       /* gets initialized to 0 */

  tasklet_norace uint8_t      txPower;        /* current power setting   */
  tasklet_norace uint8_t      channel;        /* current channel setting */

//  tasklet_norace message_t  * txMsg;          /* msg driver owns */

//  message_t                   rxMsgBuffer;
//  tasklet_norace message_t  * rxMsg = &rxMsgBuffer;

  /*
   * When powering up/down and changing state we use the rfxlink
   * utilities and the TRadio alarm for timing.   We flag this
   * using stateAlarm_active.  This allows for bailing out from
   * the main state control tasklet while we are waiting for
   * the RadioAlarm to fire.
   */
  norace bool stateAlarm_active   = FALSE;

  cc2520_status_t getStatus();


  cc2520_header_t *getPhyHeader(message_t *msg) {
    return ((void *) msg) + call Config.headerOffset(msg);
  }


  cc2520_metadata_t *getMeta(message_t *msg) {
    return ((void *) msg) + sizeof(message_t) - call RadioPacket.metadataLength(msg);
  }


  void bad_state() {
    __PANIC_RADIO(1, dvr_state, dvr_cmd, 0, 0);
  }


  void next_state(cc2520_driver_state_t s) {
    call Trace.trace(T_RS, dvr_state, s);
    dvr_state = s;
  }


  /*
   * resets the Sfd queue back to an empty state.
   *
   * must be called when the h/w is shutdown.  Or
   * interrupts disabled.
   */
  void flushSfdQueue() {
    uint16_t i;

    call Trace.trace(T_R_SFD_FLUSH, 0xffff, 0xff00 | READ_SR);
    for (i = 0; i < MAX_SFD_STAMPS; i++)
      sfd_ptrs[i]->sfd_status = 0;
    sfd_fill    = 0;
    sfd_drain   = 0;
    sfd_entries = 0;
    sfd_lost = FALSE;
  }


  /*
   * advance the SfdQueue from the drain point after verifying we
   * are looking at the expected entry.
   *
   * returns TRUE if recovery should be invoked.
   *
   * drainOneSfd shouldn't ever get called if sfd_lost is set.
   */
  bool drainOneSfd(sfd_stamp_t *sfd_p, uint8_t sfd_lookfor) {
    if (sfd_lost)                       /* paranoid */
      return TRUE;

    /* check for out of order, what are we expecting */
    if ((sfd_p->sfd_status & (SFD_BUSY | sfd_lookfor))
                          != (SFD_BUSY | sfd_lookfor)) {
      __PANIC_RADIO(35, sfd_fill, sfd_drain, sfd_entries,
                    sfd_p->sfd_status);
      return TRUE;
    }
    sfd_p->sfd_status &= ~SFD_BUSY;
    if (++sfd_drain >= MAX_SFD_STAMPS)
      sfd_drain = 0;
    sfd_entries--;
    call Trace.trace(T_R_SFD_DRAIN, (sfd_fill << 8) | sfd_drain,
                     (sfd_lost ? 0x8000 : 0) | sfd_entries);
    return FALSE;
  }


  /* ----------------- Basic Access ----------------- */

  /* read from the SPI, putting bytes in buf */
  void readBlock(uint8_t *buf, uint8_t count) {
    uint8_t i;

    for (i = 1; i < count; i++)
      buf[i-1] = call FastSpiByte.splitReadWrite(0);
    buf[i-1] = call FastSpiByte.splitRead();
  }


  /* pull bytes from the SPI, throwing them away */
  void pullBlock(uint8_t count) {
    uint8_t i;

    for (i = 1; i < count; i++)
      call FastSpiByte.splitReadWrite(0);
    call FastSpiByte.splitRead();
  }


  /* write bytes from buf to the SPI */
  void writeBlock(uint8_t *buf, uint8_t count) {
    uint8_t i;

    for (i = 0; i < count; i++)
      call FastSpiByte.splitReadWrite(buf[i]);
    call FastSpiByte.splitRead();
  }


  /*
   * strobe: write a single byte command byte to the radio chip.
   *
   * input:     cmd     command byte to send to the chip
   *
   * return:    status  status byte returned from the chip.
   */

  cc2520_status_t strobe(uint8_t cmd) {
    cc2520_status_t status;

    CC2520_ATOMIC {
      call CSN.set();
      call CSN.clr();
      call FastSpiByte.splitWrite(cmd);
      status.value = call FastSpiByte.splitRead();
      call CSN.set();
    }
    return status;
  }


  /*
   * writeReg
   *
   * input:     reg     addr to write
   *            value   data to write
   * return:    status
   *
   * "reg" is assumed to be < 0x0100.  If < 0x040 REGWR will be used
   * otherwise MEMWR is used.
   *
   * returns cc2520 status (from returned byte on command write).
   */

  cc2520_status_t writeReg(uint8_t reg, uint8_t value) {
    cc2520_status_t status;

    CC2520_ATOMIC {
      call CSN.set();
      call CSN.clr();                     /* assert CSN, need the falling edge */
      if (reg <= CC2520_FREG_MASK) {
        /*
         * uses one less byte to write the register using REGWR
         */
        call FastSpiByte.splitWrite(CC2520_CMD_REGWR | reg);
        status.value = call FastSpiByte.splitReadWrite(value);
      } else {
        /*
         * Use larger command (MEMWR), addr in SREG area
         * This is a register write which means the address is < 0x100 which
         * means we don't need to OR in the high addr bits into the MEMWR
         * command.
         */
        call FastSpiByte.splitWrite(CC2520_CMD_MEMWR);
        status.value = call FastSpiByte.splitReadWrite(reg);
        call FastSpiByte.splitReadWrite(value);
      }
      call FastSpiByte.splitRead();
      call CSN.set();                     /* deassert */
    }
    return status;
  }


  /*
   * writeRegBlock (REGWR)
   *
   * input:     reg             starting address
   *           *buf             pointer to src buffer
   *            count           how many bytes to write
   *
   * output:    none
   *
   * write a block of data into the register block starting at
   * address "reg".
   *
   * This can be used to write registers during initilization
   * with less overhead.
   */

  void writeRegBlock(uint8_t reg_addr, uint8_t *buf, uint8_t count) {

    CC2520_ATOMIC {
      call CSN.set();
      call CSN.clr();
      call FastSpiByte.splitWrite(CC2520_CMD_MEMWR);
      call FastSpiByte.splitReadWrite(reg_addr);
      writeBlock(buf, count);
      call CSN.set();
    }
    return;
  }


  /*
   * writeMem (MEMWR function)
   *
   * input:     mem_addr        starting address
   *           *buf             pointer to buffer
   *            count           how many bytes to write
   *
   * output:    return          status from command byte
   *
   * Writes a block of data to memory above 0x0200
   * FIFO memory is 0x0100 to 0x01ff.   General memory along
   * with local address info is above 0x0200
   */

  cc2520_status_t writeMem(uint16_t mem_addr, uint8_t *buf, uint8_t count) {
    cc2520_status_t status;
    uint8_t i;

    CC2520_ATOMIC {
      call CSN.set();
      call CSN.clr();
      call FastSpiByte.splitWrite(CC2520_CMD_MEMWR | HI_UINT16(mem_addr));
      status.value = call FastSpiByte.splitReadWrite(LO_UINT16(mem_addr));
      writeBlock(buf, count);
      call CSN.set();
    }
    return status;
  }


  /*
   * readReg
   *
   * input:     reg     addr to write
   * output:    val     data read from the reg addr
   *
   * "reg" is assumed to be < 0x0100.  If < 0x040 REGRD will be used
   * otherwise MEMRD is used.
   */

  uint8_t readReg(uint8_t reg) {
    uint8_t value;

    CC2520_ATOMIC {
      call CSN.set();
      call CSN.clr();
      if (reg <= CC2520_FREG_MASK) {
        call FastSpiByte.splitWrite(CC2520_CMD_REGRD | reg);
      } else {
        call FastSpiByte.splitWrite(CC2520_CMD_MEMRD);
        call FastSpiByte.splitReadWrite(reg);
      }
      call FastSpiByte.splitReadWrite(0);
      value = call FastSpiByte.splitRead();
      call CSN.set();
    }
    return value;
  }


  /*
   * readMem (MEMRD function)
   *
   * input:     mem_addr        starting address
   *           *buf             pointer to buffer
   *            count           how many bytes to read
   *
   * output:    return          status from command byte
   *
   * Reads a block of data from memory above 0x0200
   * FIFO memory is 0x0100 to 0x01ff.   General memory along
   * with local address info is above 0x0200
   */

  cc2520_status_t readMem(uint16_t mem_addr, uint8_t *buf, uint8_t count) {
    cc2520_status_t status;

    CC2520_ATOMIC {
      call CSN.set();
      call CSN.clr();
      call FastSpiByte.splitWrite(CC2520_CMD_MEMRD | HI_UINT16(mem_addr));
      status.value = call FastSpiByte.splitReadWrite(LO_UINT16(mem_addr));
      call FastSpiByte.splitReadWrite(0);
      readBlock(buf, count);
      call CSN.set();
    }
    return status;
  }


  void dr_hw_state() {
    rd_hw_state.p1          = P1IN;
    rd_hw_state.p1ie        = P1IE;
    rd_hw_state.p1ifg       = P1IFG;
    rd_hw_state.p3          = P3IN;
    rd_hw_state.p8          = P8IN;
    rd_hw_state.ta0ccr3     = TA0CCR3;
    rd_hw_state.ta0cctl3    = TA0CCTL3;
    rd_hw_state.CSN_pin     = call CSN.get();
    rd_hw_state.RSTN_pin    = call RSTN.get();
    rd_hw_state.VREN_pin    = call VREN.get();
    rd_hw_state.SFD_pin     = call SFD.get();
    rd_hw_state.TXA_pin     = call TXA.get();
    rd_hw_state.EXCA_pin    = call EXCA.get();
  }


  void dump_radio_txfifo() {
    readMem(0x100, (void *) &txfifo, 128);
  }


  void dump_radio_rxfifo() {
    readMem(0x180, (void *) &rxfifo, 128);
  }


  bool checkCCA() {
    cc2520_fsmstat1_t fsmstat1;

    fsmstat1.value  = readReg(CC2520_FSMSTAT1);
    if (fsmstat1.f.cca)
      return TRUE;
    return FALSE;
  }


  /* drs: dump_radio_short */
  void drs(bool with_fifos) __attribute__((noinline)) {

    rds.timestamp = call Platform.usecsRaw();
    call CSN.set();                     /* reset SPI on chip */
    call CSN.clr();
    call CSN.set();
    rds.status    = getStatus().value;
    rds.excflag0  = readReg(CC2520_EXCFLAG0);
    rds.excflag1  = readReg(CC2520_EXCFLAG1);
    rds.excflag2  = readReg(CC2520_EXCFLAG2);
    rds.rxfirst   = readReg(CC2520_RXFIRST);
    rds.rxfifocnt = readReg(CC2520_RXFIFOCNT);
    rds.txfifocnt = readReg(CC2520_TXFIFOCNT);
    rds.fsmstat0  = readReg(CC2520_FSMSTAT0);
    rds.fsmstat1  = readReg(CC2520_FSMSTAT1);

    if (with_fifos)
      dump_radio_txfifo();
      dump_radio_rxfifo();
  }


  /* drf: dump_radio_full */
  void drf() __attribute__((noinline)) {

    call CSN.set();                     /* reset SPI on chip */
    call CSN.clr();
    call CSN.set();

    rd.timestamp = call Platform.usecsRaw();
    rd.status    = getStatus().value;
    readMem(0, (void *) &rd, CC2520_MAIN_DUMP_SIZE);
    readMem(CC2520_DPUBIST,  &rd.dpubist, 1);
    readMem(CC2520_ACTBIST,  &rd.actbist, 1);
    readMem(CC2520_RAMBIST,  &rd.rambist, 1);

    readMem(0x100, (void *) &txfifo, 128);
    readMem(0x180, (void *) &rxfifo, 128);
  }


  void dump_radio() __attribute__((noinline)) {
    atomic {
      dr_hw_state();
      drs(FALSE);
      drf();
    }
  }


  async command uint8_t CC2520BasicAccess.strobe(uint8_t reg) {
    cc2520_status_t t;

    t = strobe(reg);
    return t.value;
  }

  async command uint8_t CC2520BasicAccess.readReg(uint8_t reg) {
    return readReg(reg);
  }

  async command uint8_t CC2520BasicAccess.writeReg(uint8_t reg, uint8_t value) {
    cc2520_status_t t;

    t = writeReg(reg, value);
    return t.value;
  }

  async command void CC2520BasicAccess.writeRegBlock(uint8_t reg_addr, 
        uint8_t *buf, uint8_t count) {
    writeRegBlock(reg_addr, buf, count);
  }

  async command uint8_t CC2520BasicAccess.readMem(uint16_t mem_addr,
        uint8_t *buf, uint8_t count) {
    cc2520_status_t t;

    t = readMem(mem_addr, buf, count);
    return t.value;
  }

  async command uint8_t CC2520BasicAccess.writeMem(uint16_t mem_addr, 
        uint8_t *buf, uint8_t count) {
    cc2520_status_t t;

    t = writeMem(mem_addr, buf, count);;

    return t.value;
  }


  cc2520_status_t getStatus() {
    return strobe(CC2520_CMD_SNOP);
  }


  void writeTxFifo(uint8_t *data, uint8_t length) {

    CC2520_ATOMIC {
      call CSN.set();                     /* reset chip SPI */
      call CSN.clr();
      call FastSpiByte.splitWrite(CC2520_CMD_TXBUF);
      writeBlock(data, length);
      call CSN.set();
    }
  }


  void resetExc() {
    writeReg(CC2520_EXCFLAG0, 0);
    writeReg(CC2520_EXCFLAG1, 0);
    writeReg(CC2520_EXCFLAG2, 0);
  }


  /*
   * flush RxFifo: resets internal chip fifo data structures
   *
   * The user of this routine needs to also consider the effect on the
   * sfd queue.   Typically, it gets flushed.  see flushSfdQueue().
   */
  void flushRxFifo() {
    uint8_t rxfifo_cnt;

    /*
     * According to the CC2520 errata (pg 2), if receiving RX bytes and
     * for any reason we need to flush or restart using SRXON, SRFOFF,
     * STXON, or SFLUSHRX, an extra byte can be left in the RXFIFO.
     *
     * The workaround is to issue back to back SFLUSHRXs.
     */

    strobe(CC2520_CMD_SFLUSHRX);
    strobe(CC2520_CMD_SFLUSHRX);
    rxfifo_cnt = readReg(CC2520_RXFIFOCNT);
    if (rxfifo_cnt) {
      /*
       * It has been observed that sometimes dual SFLUSHRXs doesn't
       * actually clear the fifo out.  This is rare.  There is also
       * a known bug involving command strobes.
       *
       * Sometimes bytes are left over, we check for non-zero fifo length
       * and repeat.  Cycling the fifo seems to help and then the clear
       * works.
       *
       * SFLUSHRX also causes RX recalibration (it shouldn't but it does)
       * so you want to minimize usage of the flushRxFifo code.
       */
      __PANIC_RADIO(2, rxfifo_cnt, 0, 0, 0);   /* flag it */
      CC2520_ATOMIC {
        call CSN.clr();
        call SpiByte.write(CC2520_CMD_RXBUF);     /* cycle the fifo */
        call SpiByte.write(0);                    /* read one byte  */
        call CSN.set();
      }
      strobe(CC2520_CMD_SFLUSHRX);
      strobe(CC2520_CMD_SFLUSHRX);
      rxfifo_cnt = readReg(CC2520_RXFIFOCNT);
      if (rxfifo_cnt) {
        __PANIC_RADIO(3, rxfifo_cnt, 0, 0, 0);
      }
    }
  }


  /*----------------- INIT -----------------*/

  command error_t SoftwareInit.init() {
    error_t err;

    /*
     * We need the SPI bus for initialization and SoftwareInit
     * is called early in the boot up process.  Because of this
     * only immediateRequest should be used.  Other pieces of the
     * system (like the arbiter fifos) have not been initialized
     * yet.  immediateRequest does not use those pieces.
     *
     * If one has minimal ports available full arbitration can be used
     * to share the port.  If no arbitration is needed simple changes
     * can be made to eliminate the overhead of arbitration.
     *
     * Since this is init called from boot, we also call PlatformCC2520.powerDown
     * to make sure everything is in the right state.  The SPI initilization
     * plays with the pin state of P_SO.  Simplest thing is to just call
     * powerDown which does the right thing.   Rather than trying to export
     * a mcu specific bit of code to tweak the mcu specifc port.
     */
    err = call SpiResource.immediateRequest();
    if (err) {
      __PANIC_RADIO(4, err, 0, 0, 0);
      return err;
    }
    call CSN.set();
    call PlatformCC2520.powerDown();
    m_hw_configured = FALSE;
    rxMsg = &rxMsgBuffer;
    return SUCCESS;
  }


  /*----------------- SPI -----------------*/

  event void SpiResource.granted() {
    call Tasklet.schedule();
  }


  bool isSpiAcquired() {
#ifdef CC2520_NO_ARB
    return TRUE;
#else
    if (call SpiResource.isOwner())
      return TRUE;
    if (call SpiResource.immediateRequest() == SUCCESS)
      return TRUE;
    call SpiResource.request();
    return FALSE;
#endif
  }


  void releaseSpi() {
#ifdef CC2520_NO_ARB
    return;
#else
    call SpiResource.release();
#endif
  }


  async event void SpiPacket.sendDone(uint8_t* txBuf, uint8_t* rxBuf,
                                      uint16_t len, error_t error) { };


  void loadRadioConfig() {
    uint16_t i;

     for (i = 0; reg_config[i].len; i++)
      writeRegBlock(reg_config[i].reg_start, (void *) reg_config[i].vals,
                    reg_config[i].len);

    /* Manual register settings.  See Table 21 */
    writeReg(CC2520_TXPOWER,  0x32);
    writeReg(CC2520_FSCAL1,   0x2B);
    m_hw_configured = TRUE;
  }


  void disableInterrupts() {
    atomic {
      call ExcAInterrupt.disable();
      call SfdCapture.disable();
    }
  }


  /*
   * enableInterrupts: turn on interrupts we are interested in.
   *
   * Clears out anything pending
   */
  void enableInterrupts() {
    atomic {
      call ExcAInterrupt.enableRisingEdge();
      call SfdCapture.captureBothEdges();
      call SfdCapture.clearOverflow();
      call SfdCapture.enableInterrupt();
    }
  }


  /*
   * resetRadio: kick the radio
   *
   * Reset always sets the chip's registers back to the Reset
   * configuration.   So we need to reload any changes we've
   * made.
   *
   * resetRadio has to disableInterrupts because it tweaks how
   * the gpio pins are connected which can easily cause them
   * to glitch and cause an interrupt or capture to occur.
   *
   * So anytime the radio is reset, radio interrupts are disabled.
   * The caller of resetRadio needs to figure out when it is reasonable
   * to reenable interrupts.  (most likely when we go back into RX_ON).
   */
  void resetRadio() {
    disableInterrupts();
    m_hw_configured = FALSE;
    call PlatformCC2520.reset();
    loadRadioConfig();                          /* reload registers */
    txPower = CC2520_DEF_RFPOWER & CC2520_TX_PWR_MASK;
    channel = CC2520_DEF_CHANNEL & CC2520_CHANNEL_MASK;
  }


  /*
   * standbyInitRadio: radio power already on, assume config is correct
   *
   * on exit make sure exceptions cleared.  Assumed still
   * configured correctly.
   *
   * Do not call resetRadio, that will reset internal registers
   * requiring them to be reload which defeats the purpose
   * of going into standby.
   */
  void standbyInitRadio() {
    /*
     * do not reset!  Exceptions were cleared out when going into
     * STANDBY.  Interrupts get cleared out when they get enabled.
     */
    txPower = CC2520_DEF_RFPOWER & CC2520_TX_PWR_MASK;
    channel = CC2520_DEF_CHANNEL & CC2520_CHANNEL_MASK;
  }


  /*
   * fullInitRadio: radio was off full initilization
   *
   * needs to download config (loadRadioConfig).
   * on exit exceptions cleared and configured.
   */
  void fullInitRadio() {
    /*
     * reset the radio which also reloads the configuration
     * because reset sets the config back to POR values.
     */
    disableInterrupts();
    m_hw_configured = FALSE;
    loadRadioConfig();                          /* load registers */
    txPower = CC2520_DEF_RFPOWER & CC2520_TX_PWR_MASK;
    channel = CC2520_DEF_CHANNEL & CC2520_CHANNEL_MASK;
  }


  /*----------------- CHANNEL -----------------*/

  tasklet_async command uint8_t RadioState.getChannel() {
    return channel;
  }


  tasklet_async command error_t RadioState.setChannel(uint8_t c) {

    c &= CC2520_CHANNEL_MASK;
    if (dvr_cmd != CMD_NONE)
      return EBUSY;
    else if (channel == c)
      return EALREADY;

    channel = c;
    dvr_cmd = CMD_CHANNEL;
    call Tasklet.schedule();
    return SUCCESS;
  }


  void setChannel() {
    uint8_t tmp;

    tmp = (11 + 5 * (channel - 11));
    writeReg(CC2520_FREQCTRL, tmp);
  }


  void changeChannel() {
    if (isSpiAcquired()) {
      /*
       * changing channels requires recalibration etc.
       */
      setChannel();
      if (dvr_state == STATE_RX_ON) {
        disableInterrupts();
        resetExc();                                     /* clean out exceptions */
        strobe(CC2520_CMD_SRXON);                       /* force a calibration cycle */
        enableInterrupts();
        dvr_cmd = CMD_SIGNAL_DONE;
        return;
      }
    }
  }


  /*----------------- TURN_OFF, STANDBY, TURN_ON -----------------*/

  /*
   * task to actually load any configuration information into
   * the radio chip.   Done at task level because it takes a while
   * (up to 2ms) and we don't want to do this at interrupt level
   *
   * state will be LOAD_CONFIG or STANDBY_2_LOAD.
   *
   * We don't use a suspend/resume block because the radio won't
   * be generating any interrupt level events so Tasklet.schedule
   * should be fine.
   */
  task void CC2520_Load_Config() {
    call Tasklet.suspend();
    if (dvr_state == STATE_LOAD_CONFIG)
      fullInitRadio();                /* in LOAD_CONFIG */
    else
      standbyInitRadio();             /* one of the STANDBYs */
    next_state(STATE_IDLE);
    call Tasklet.schedule();
    call Tasklet.resume();
}


  void cs_off() {
    uint16_t wait_time;

    /*
     * we need the spi, if not available we will
     * try again when the grant happens.
     */
    if (!isSpiAcquired())
      return;

    /*
     * the only command currently allowed is TURNON
     * if someone trys something different we will
     * bitch in an obvious way.
     */
    if (dvr_cmd != CMD_TURNON) {
      bad_state();
      return;
    }

    wait_time = call PlatformCC2520.powerUp();
    if (wait_time) {
      /*
       * we are going to need the RadioAlarm, if not
       * free bail.  We stay in STATE_OFF with a
       * pending CMD_TRUE.   When the RadioAlarm does
       * trip, it will run Tasklet.schedule() which
       * will cause the Driver state machine to run
       * again and we will execute this code again.
       */
      if (!call RadioAlarm.isFree())
        return;
      next_state(STATE_OFF_2_LOAD);
      stateAlarm_active = TRUE;
      call RadioAlarm.wait(wait_time);
      return;
    }

    /* powerUp has already finished (wait_time 0),
     * have the main state machine load the configuration.
     */
    next_state(STATE_OFF_2_LOAD);
    call Tasklet.schedule();            /* more transitions */
  }


  void cs_xxx_2_load() {
    /*
     * This can be invoked when in OFF_2_LOAD or STANDBY_2_LOAD
     *
     * This doesn't run if the RadioAlarm is still active
     * stateAlarm_active is 1.
     */

    /*
     * check for SPI ownership.  No ownership -> stay in current state
     */
    if (!isSpiAcquired())               /* if no SPI */
      return;

    if (dvr_cmd != CMD_TURNON) {
      bad_state();
      return;
    }

    /*
     * OFF_2_LOAD -> LOAD_CONFIG to force full config.
     * STANDBY_2_LOAD only does StandbyInit
     */
    if (dvr_state == STATE_OFF_2_LOAD)
      next_state(STATE_LOAD_CONFIG);
    post CC2520_Load_Config();
  }


  void cs_standby() {
    uint16_t wait_time;

    if (!isSpiAcquired())
      return;

    if ((dvr_cmd == CMD_TURNOFF)) {
      call PlatformCC2520.powerDown();
      m_hw_configured = FALSE;
      next_state(STATE_OFF);
      dvr_cmd = CMD_SIGNAL_DONE;
      return;
    }

    if (dvr_cmd == CMD_TURNON) {
      wait_time = call PlatformCC2520.wakeup();
      if (wait_time) {
        if (!call RadioAlarm.isFree())
          return;
        next_state(STATE_STANDBY_2_LOAD);
        stateAlarm_active = TRUE;
        call RadioAlarm.wait(wait_time);
        return;
      }
      next_state(STATE_STANDBY_2_LOAD);
      post CC2520_Load_Config();
      return;
    }

    bad_state();
  }


  void cs_idle() {
    /*
     * IDLE always transitions to RX_ON.
     */
    if (!isSpiAcquired())
      return;

    if (dvr_cmd == CMD_TURNON) {
      next_state(STATE_RX_ON);
      dvr_cmd = CMD_SIGNAL_DONE;
      setChannel();
      enableInterrupts();

      /*
       * all the majik starts to happen after the RXON is issued.
       * The chip will first go into RX Calibration (state 2) and
       * 192us later will enter SFDWait (3-6).  A preamble coming in
       * (after the 192us calibration) and SFD is another 160us.
       * So the minimum time before the 1st SFD interrupt is 192 + 160 us
       * (352 us, decimal).
       */
      strobe(CC2520_CMD_SRXON);         /* (192+160)us before 1st SFD int.  */
      return;
    }

    /*
     * IDLE is a transitory state.  Other commands can't happen
     */

    bad_state();
  }


  void cs_rx_on() {
    if (!isSpiAcquired())
      return;

    if (dvr_cmd == CMD_STANDBY) {
      /*
       * going into standby, kill the radio.  But killing the radio
       * doesn't clean everything we need out.  So we need to kill any
       * pending exceptions and nuke the fifos.
       *
       * Interrupts are disabled here but cleaned out when they are
       * reenabled.
       *
       * We also need to clean out and reset any data structures associated
       * with the radio, like the SFD queue etc.       
       */
      disableInterrupts();
      strobe(CC2520_CMD_SRFOFF);
      strobe(CC2520_CMD_SFLUSHTX);      /* nuke  txfifo            */
      flushRxFifo();                    /* nuke rxfifo             */
      flushSfdQueue();                  /* reset sfd queue         */
      resetExc();                       /* blow out exceptions     */
      timesync_absolute = 0;          /* no timesync in progress */
      strobe(CC2520_CMD_SXOSCOFF);
      strobe(CC2520_CMD_SNOP);
      call PlatformCC2520.sleep();      /* tell PlatformCC2520 we are in standby */
      next_state(STATE_STANDBY);        /* no need to idle first */
      dvr_cmd = CMD_SIGNAL_DONE;
      return;
    }

    if (dvr_cmd == CMD_TURNOFF) {
      disableInterrupts();
      call PlatformCC2520.powerDown();  /* rips power */
      m_hw_configured = FALSE;
      next_state(STATE_OFF);
      dvr_cmd = CMD_SIGNAL_DONE;
      return;
    }

    bad_state();
  }

  void changeState() {
    /*
     * these only get called from the Main State Machine Sequencer (MSMS)
     * RadioAlarm has some other transitions
     */
    switch (dvr_state) {
      case STATE_OFF:           cs_off();        break;
      case STATE_OFF_2_LOAD:
      case STATE_STANDBY_2_LOAD:
                                cs_xxx_2_load(); break;
      case STATE_STANDBY:       cs_standby();    break;
      case STATE_IDLE:          cs_idle();       break;
      case STATE_RX_ON:         cs_rx_on();      break;

      case STATE_TX_START:
      default:
        bad_state();
        break;
    }


#ifdef notdef
    else if( (dvr_cmd == CMD_TURNOFF || dvr_cmd == CMD_STANDBY)
        && dvr_state == STATE_RX_ON && isSpiAcquired() ){
      // stop receiving
      strobe(CC2520_CMD_SRFOFF);

      next_state(STATE_IDLE);
    }

    if( dvr_cmd == CMD_TURNOFF && dvr_state == STATE_IDLE  && isSpiAcquired() ){
      // stop oscillator
      strobe(CC2520_CMD_SXOSCOFF);

      resetRadio();
      next_state(STATE_PD);
      dvr_cmd = CMD_SIGNAL_DONE;
    }
    else if( dvr_cmd == CMD_STANDBY && dvr_state == STATE_IDLE )
      dvr_cmd = CMD_SIGNAL_DONE;
#endif
  }


  tasklet_async command error_t RadioState.turnOff() {
    if (dvr_cmd != CMD_NONE)
      return EBUSY;
    else if (dvr_state == STATE_OFF)
      return EALREADY;

    dvr_cmd = CMD_TURNOFF;
    call Tasklet.schedule();
    return SUCCESS;
  }


  tasklet_async command error_t RadioState.standby() {
    if (dvr_cmd != CMD_NONE)
      return EBUSY;
    if (dvr_state == STATE_STANDBY)
      return EALREADY;

    dvr_cmd = CMD_STANDBY;
    call Tasklet.schedule();
    return SUCCESS;
  }


  tasklet_async command error_t RadioState.turnOn() {
    if (dvr_cmd != CMD_NONE)
      return EBUSY;
    if (dvr_state >= STATE_RX_ON)
      return EALREADY;

    dvr_cmd = CMD_TURNON;
    call Tasklet.schedule();
    return SUCCESS;
  }


  default tasklet_async event void RadioState.done() { }


  /*----------------- TRANSMIT -----------------*/

  tasklet_async command error_t RadioSend.send(message_t *msg) {
    uint8_t     tmp;
    bool        needs_CCA;
    uint16_t    t0, t1;

    uint8_t     length, preload_len;
    uint8_t   * dp;                     /* data pointer */
    void      * timesync;

    call PacketTimeStamp.clear(msg);
    if (txMsg) {
      /*
       * oops.   should be null.   Otherwise means we are trying to
       * have > 1 in flight.
       */
      __PANIC_RADIO(5, (uint16_t) txMsg, 0, 0, 0);
      txMsg = NULL;
    }
      
    /*
     * There is a handshake with the interrupt level that we use
     * to a) detect when a h/w abort has occurred.   And b) allows
     * us to tell the interrupt level when a signal send.sendDone is
     * needed.
     */
    tx_user_state = TXUS_STARTUP;

    /*
     * If something is going on cmdwise (dvr_cmd not CMD_NONE), bail.
     *
     * We only allow a transmit to start if we are in rx idle (RX_ON).
     * If currently receiving, tell the upper layer we are busy.
     */
    if (dvr_cmd != CMD_NONE       ||
        !isSpiAcquired()          ||
        dvr_state != STATE_RX_ON  ||
        radioIrq                  ||
        tx_user_state != TXUS_STARTUP) {
      tx_user_state = TXUS_IDLE;
      return EBUSY;
    }

    dp     = (void *) getPhyHeader(msg);
    length = *dp;                       /* length is first byte. */

    /*
     *  dp[0]   dp[1]   d[2]   dp[3] ...   dp[length - 2]   FCS (2)
     * length | fcf     fcf    dsn   ... 
     *
     * Start by sending PreloadLength to buy us some time on slow mcus.
     * (length, fcf, dsn, dpan, daddr  (7 bytes + len byte (1)))
     *
     * Note we could be sending an ACK, in which case we have:
     *
     *  dp[0]   dp[1]   dp[2]   dp[3]
     * length | fcf_0 | fcf_1 | dsn   | fcs_0 | fcs_1   (length of 5)
     * fcs is auto generated so we don't need to send it to the txfifo.
     */

    preload_len = call Config.headerPreloadLength();
    if (preload_len > length)
      preload_len = length;

    length -= preload_len;

    tmp =
      (call PacketTransmitPower.isSet(msg)
        ? call PacketTransmitPower.get(msg) : CC2520_DEF_RFPOWER)
      & CC2520_TX_PWR_MASK;

    if (tmp != txPower) {
      txPower = tmp;
      writeReg(CC2520_TXPOWER, txPower);
    }

    /*
     * On the msp430, ISRs run by default with interrupts off but we have
     * some interrupt sensative issues.  For instance we really want the
     * SFDCapture interrupt to go off if a receive is happening.  Same is
     * true if there is an exception that is pending or about to go off.
     *
     * Once could try to manipulate the interrupts manually but that breaks
     * nesc's atomic analysis and it stops doing the right thing.  In other
     * words it does atomic elimination based on what it thinks is the known
     * interrupt status, but we've manipulated that status out from underneath
     * it.   This breaks things.   Don't do that.
     *
     * So we need to turn interrupts on in the appropriate place in the entry
     * routines on the msp430.
     */

    /*
     * We start with most of the 15.4 header loaded to the fifo, but
     * first we have to write the length byte.  This is why we send
     * preload_len + 1 bytes to the fifo, the +1 is to account for the
     * length.
     */
    preload_len++;                      /* account for the len byte */
    writeTxFifo(dp, preload_len);
    dp += preload_len;                  /* move to where to continue from */

    /*
     * Critical Region!
     *
     * First, the current state must be checked in an atomic block. We want to hold
     * off the SFD interrupt which can cause a change in dvr_state.
     *
     * Second, once we issue the strobe, we want to look for the TXA coming up
     * in a tight loop.  It should come up fast and we only look for about 30uS
     * or so (TXA_MAX_WAIT).  So don't let anything else in either.
     */

    atomic {
      /*
       * while we were sending stuff to the fifo, something may have happened
       * that changed our state.   Check again.
       */
      if (dvr_cmd != CMD_NONE        ||
          dvr_state != STATE_RX_ON   ||
          radioIrq                   ||
          tx_user_state != TXUS_STARTUP) {
        tx_user_state = TXUS_IDLE;
        strobe(CC2520_CMD_SFLUSHTX);          /* discard header */
        return EBUSY;
      }

      txMsg = msg;                            /* driver now has the msg */
      next_state(STATE_TX_START);
      dvr_cmd = CMD_TRANSMIT;                 /* prevents other commands */

      needs_CCA = (call Config.requiresRssiCca(msg) ? 1 : 0);
      if (needs_CCA)
        strobe(CC2520_CMD_STXONCCA);
      else
        strobe(CC2520_CMD_STXON);

      /*
       * To avoid cpu dependent majik values for how long to wait, we
       * require Platform.usecsRaw to be properly working.   A reasonable
       * trade off to get non-cpu dependent timing values.
       *
       * If we are going to get the chip, TXA (tx_active) happens almost
       * immediately, but to be on the safe side we wait for up to TXA_MAX_WAIT
       * before giving up.  This only costs us in the case where we don't get
       * the channel.
       *
       * We can't use BusyWait because we dump out of the middle with
       * a check for TXA being up.
       */

      t0 = call Platform.usecsRaw();
      while (!call TXA.get()) {
        t1 = call Platform.usecsRaw();
        if ((t1 - t0) > TXA_MAX_WAIT)
          break;
      }
      if (call TXA.get() == 0) {
        /*
         * the TX didn't start up.  flush the txfifo and bail
         *
         * We could be actively receiving, in which case our state will be
         * RX_ACTIVE (done by SfdCapture).  An RX SFD was seen.
         *
         * or ...  not receiving but enough energy to trip the CCA check.
         * In which case we will still be in TX_START.  So transition back
         * to RX_ON which indicates idle receive.
         */
        txMsg = NULL;
        tx_user_state = TXUS_IDLE;
        if (dvr_cmd == CMD_TRANSMIT)
          dvr_cmd = CMD_NONE;
        strobe(CC2520_CMD_SFLUSHTX);
        if (dvr_state == STATE_TX_START)  /* must be protected */
          next_state(STATE_RX_ON);        /* with atomic       */
        return EBUSY;
      }
    } /* end atomic */

    timesync = call PacketTimeSyncOffset.isSet(msg) ? ((void*)msg) + call PacketTimeSyncOffset.get(msg) : 0;
    if (timesync) {
      /*
       * if we have a pointer into the packet, (timesync non-NULL), then
       * it points to where the absolute time of the event is stored.
       *
       * grab the absolute time and store in m_timesync_absolute.   This also
       * tells SfdCapture that we need to finish the timesync writing.
       *
       * Write all the payload to the txfifo except the last 4 bytes which is
       * the relative timesync value.  This will be done from the SfdCapture
       * interrupt.
       */
      writeTxFifo(dp, length - sizeof(timesync_relative_t) - FCS_SIZE);
      timesync_absolute = (*(timesync_absolute_t *) timesync);
    } else {
      /* no timesync, write full packet */
      if (length > 0)
        writeTxFifo(dp, length - FCS_SIZE);
    }

    /*
     * If something catastrophic, we may have let the interrupt handler
     * deal with it.  This will cause the driver to reset.  The interrupt
     * level will change tx_user_state to ABORT.
     */
    atomic {              /* protect tx_user_state access */
      if (tx_user_state == TXUS_ABORT) {
        txMsg = NULL;
        tx_user_state = TXUS_IDLE;
        if (dvr_cmd == CMD_TRANSMIT)
          dvr_cmd = CMD_NONE;
        return FAIL;
      }
      tx_user_state = TXUS_PENDING;
    }
    return SUCCESS;
  }


  default tasklet_async event void RadioSend.sendDone(error_t error) { }
  default tasklet_async event void RadioSend.ready() { }


  /*----------------- CCA -----------------*/

  tasklet_async command error_t RadioCCA.request() {
    if (dvr_cmd != CMD_NONE || dvr_state != STATE_RX_ON)
      return EBUSY;

    dvr_cmd = CMD_CCA;
    call Tasklet.schedule();        /* still can signal out of here */
    return SUCCESS;
  }

  default tasklet_async event void RadioCCA.done(error_t error) { }


  /*----------------- RECEIVE -----------------*/

  /*
   * nuke2rxon: reset the chip back to RX_ON
   *
   * o disables interrupts
   * o turns off RX and TX -> forces to IDLE state (on chip)
   * o flush both rx and tx fifos
   * o cleans out any exceptions
   * o restart the chip ==> RX_ON.
   *
   * We do not need to protect against interrupts because the very first
   * thing we do is disable interrupts which turns off both the exception
   * and SFD interrupts.  This protects us against any critical region
   * violations.
   */
  void nuke2rxon() {
    disableInterrupts();
    strobe(CC2520_CMD_SRFOFF);
    strobe(CC2520_CMD_SFLUSHTX);
    flushRxFifo();
    flushSfdQueue();
    resetExc();
    setChannel();
    timesync_absolute = 0;
    next_state(STATE_RX_ON);            /* before enableInts and RXON */
    strobe(CC2520_CMD_SRXON);
    cc2520_inst_nukes++;
    enableInterrupts();                 /* clears all ints out too */
  }


  /*
   * process an incoming packet.
   *
   * o check lengths (RXFIRST, first byte of packet, passed in)
   * o account for SFD stamp entry.
   * o sfd_stamp (at sfd_drain) has been checked for reasonableness
   *
   * Interrupts disabled on the way in.  When we copy the packet out of
   * the rxfifo, we reenable interrupts to allow SFDCapture interrupts
   * to minimize losing edges.  After the copy is complete we disable
   * interrupts again.
   *
   * return TRUE   to force a recovery
   * return FALSE, no problems.
   */
  bool snarfMsg(uint8_t length) {       /* snag message from rxfifo */
    uint8_t     * dp;                   /* data pointer */
    uint8_t       tmp, rssi;
    uint8_t       crc_lqi;
    sfd_stamp_t * sfd_p;

    /*
     * start pulling data from the rxfifo
     * length was checked outside.  Looks reasonable.
     *
     * we haven't pulled anything from the fifo yet so
     * we still have the length byte at the front of the fifo.
     *
     * We are guaranteed at least 5 bytes so we use FastSpi to
     * be reasonable with the pipeline.
     */

    call Trace.trace(T_R_RX_PKT, length, 0xff00 | READ_SR);
    __nesc_enable_interrupt();      /* let SFD interrupts in, and others */
    call CSN.clr();
    call FastSpiByte.splitWrite(CC2520_CMD_RXBUF);      /* start pipe up */
    call FastSpiByte.splitReadWrite(0);                 /* return status */
    tmp = call FastSpiByte.splitReadWrite(0);           /* pull length   */
    if (tmp != length) {
      /* weird.  better match or something is very weird */
      __PANIC_RADIO(32, tmp, length, 0, 0);
       /* no recovery, don't know how to tweak it, believe the value read */
      length = tmp;
    }

    /*
     * FIXME
     * i don't think this is right, isn't maxPayload referring to the data area?
     * while length refers to entire 802.15.4 frame.  shouldn't we subtract
     * off the header size as well.
     */
    if ((length - FCS_SIZE) > call RadioPacket.maxPayloadLength()) {
      cc2520_inst_pkt_toolarge++;
      pullBlock(length);                /* length is number of spi reads to do */
      call CSN.set();
      __nesc_disable_interrupt();

      /*
       * We need to account for the SFD entry too.  See below for the details
       * but this is a subset of what is done below.
       *
       * interrupts need to be off, SfdQueue gets manipulated at interrupt level
       * so it needs to be protected.
       */
      if (sfd_lost || sfd_entries == 0)
        return FALSE;

      sfd_p  = sfd_ptrs[sfd_drain];
      return drainOneSfd(sfd_p, SFD_RX);
    }

    if (!rxMsg) {                       /* never should be null */
      __PANIC_RADIO(33, (uint16_t) rxMsg, 0, 0, 0);
      /* just plain ugly.   bail.   no null pointer dereferences */
      __nesc_disable_interrupt();
      return TRUE;                      /* force recovery */
    }
    dp = (void *) getPhyHeader(rxMsg);
    *dp++ = length;
    length -= FCS_SIZE;                 /* lose fcs bytes */
    readBlock(dp, length);              /* read packet data */

    /*
     * last two bytes aren't the actual FCS but have been replaced
     * by the radio chip with RSSI (8), CRC_OK(1) + LQI(7)
     */
    call FastSpiByte.splitWrite(0);
    rssi    = call FastSpiByte.splitReadWrite(0);
    crc_lqi = call FastSpiByte.splitRead();
    call CSN.set();

    /*
     * SFD handling.
     *
     * Overflow/Overwrite (sfd_lost TRUE) causes the entire sfdqueue to be
     * ignored until both fifos are emptied.  Overwrite, sets sfd_lost and
     * sets sfd_entries to 0.  sfd_entries will stay 0 until the
     * sfd_lost condition is cleared.
     *
     * If we are receiving packets, we process the sfdqueue for only rx
     * packets.  We assume that there are no tx packets in the way.  The
     * single TX packet should have been taken care of before any other rx
     * packets could get in the way.
     */
    if (sfd_lost || sfd_entries == 0)
      call PacketTimeStamp.clear(rxMsg);
    else {
      sfd_p  = sfd_ptrs[sfd_drain];
      if ((sfd_p->sfd_status & (SFD_BUSY | SFD_RX))
                            == (SFD_BUSY | SFD_RX)) {
        call PacketTimeStamp.set(rxMsg, sfd_p->local);
        sfd_p->time_finish = call LocalTime.get();
      } else
        call PacketTimeStamp.clear(rxMsg);
      if (drainOneSfd(sfd_p, SFD_RX))
        return TRUE;                    /* oops */
    }

    /* see if we should accept the packet */
    if (signal RadioReceive.header(rxMsg)) {
      call PacketRSSI.set(rxMsg, rssi);         /* set only if accepting */
      call PacketLinkQuality.set(rxMsg, crc_lqi & 0x7f);
    }

    nop();
    if (crc_lqi & 0x80) {              /* upper bit set says crc ok */
      call Trace.trace(T_R_RX_RECV, 0, 0);
      rxMsg = signal RadioReceive.receive(rxMsg);
    } else {
      cc2520_inst_bad_crc++;
      call Trace.trace(T_R_RX_BAD_CRC, 0, 0);
    }
    nop();
    __nesc_disable_interrupt();
    return FALSE;
  }


  /*----------------- IRQs -----------------*/

  /*
   * We use SFD capture interrupts to denote packet edges and to sequence the
   * state machine as packets are transmitted and received.
   *
   * SFD timing values are stored in the SFDQueue along with what radio state
   * we are in (tx or rx).  The SFDQueue is a strict FIFO queue.
   *
   * The SFD capture interrupt should be a higher priority than the exception
   * interrupt.  While on the exception interrupt, interrupts should be
   * reenabled to allow the SFDCapture interrupt to come in if we are being
   * slammed with incoming RX packets.
   *
   * RX sequencing:
   *
   * When the chip is put into RX_ON, RX calibration occurs and the chip is
   * ready to accept packets.  The following is what happens:
   *
   *     SFD rises, SFD capture, SFD interrupt
   *         SFD up, RX mode, insert into SFD queue
   *         -> STATE_RX_ACTIVE
   *
   *     packet completes
   *
   *     SFD falls, SFD capture, SFD interrupt, EXCA (RX_FRM_DONE) interrupt
   *         SFD down, RX mode, complete SFD queue entry.
   *         -> STATE_RX_ON
   *
   * how to handle multiple packets in the rxfifo.
   *
   * Timing:
   *
   * Preamble(4), SFD(1), len(1) -> (6).
   * MPDU(len).  Minimum is FC(2) DSN(1) FCS(2) -> (5).
   *     addressing adds (4)
   *
   * no addressing:
   *   <sfd up> len(1) MPDU(5) <sfd down> preamble(4) sfd(1) <sfd up>
   *     min time: sfd_up to sfd_down: 192us
   *     min time: sfd_down to sfd_up: 160us   (b2b happens?)
   *     min time: sfd_up to sfd_up:   352us
   *
   * short addressing:
   *   <sfd up> len(1) MPDU(9) <sfd down> preamble(4) sfd(1) <sfd up>
   *     min time: sfd_up to sfd_down: 320us
   *     min time: sfd_down to sfd_up: 160us
   *     min time: sfd_up to sfd_up:   480us
   *
   * Performance issues:
   *
   * 1) TX doesn't have an issue (but it can effect RX timing).   TXfifo can
   *    only have one packet so isn't a gating issue.
   *
   * 2) RX packets don't get copied out until RX_FRM_DONE.   This is to
   *    minimize complexity.  However with back to back packets we only
   *    have 160us to handle the sfd_down and RX_FRM_DONE which includes
   *    coping the packet out.
   *
   *    ==> need the SFD interrupt to preempt any frame processing being
   *    done at a lower level.
   *
   *    ==> under load this means multiple packets in the rxfifo.
   *
   * TimeSync messages:
   *   TimeSync messages require that an absolute time that is embedded
   *   in the TX packet be modified to a time relative to the start of
   *   the packet's SFD.  We want this to be as accurate as possible which
   *   requires a good SFD timing value for the TX packet on the way out.
   *   This is done if the TX took.
   *
   *   A timesync message is defined to have the last 4 bytes of its
   *   data as the absolute time value (32 bits) of some event that
   *   occurred.   When transmitted it is converted to a time relative
   *   to the SFD rising edge of timesync packet.   Time of the event
   *   at the receiving end is then T_sfd + T_rel + T_transit.
   *
   *   When a timesync message is being sent, the full message minus the
   *   last 4 bytes is written to txfifo.  The original absolute time
   *   is stored in m_timesync_absolute, which if set to non-zero
   *   indicates to SFDCapture that a timesync is being done.   This
   *   value is initilized by RadioSend.send.   This keeps the overhead
   *   down to a minimum in the capture interrupt code.
   *
   *   If for some reason we have taken too long to get to actually
   *   processing the SfdCapture interrupt it is possible for the
   *   timesync transmit to generate a TX_UNDERFLOW/Exception.  Note,
   *   The SFD_up will occur first because it is a higher priority than
   *   the exception interrupt.   SFD processing is run to completion.
   *
   *   TX_UNDERFLOW gets caught in exception interrupt processing and
   *   generates a Panic which then resets the radio h/w back to RX_ON.
   *   This will also reset the SfdQueue.
   *
   * Edge Lossage:
   *
   * It is possible to lose an SFD edge.  The code is explicitly written
   * to recover from this situation.  The state machine always returns
   * to RX_ON (it may take another SFD edge, which is guaranteed to happen
   * if we either transmit or if a RX starts to occur).
   *
   * When in an Overwritten state, time stamps are crap until resync'd.
   * This happens after the rxfifo has been drained.   Either flushed or
   * packet processing.
   *
   * We don't try to keep any sequencing after the SfdQueue becomes crap.
   * there really isn't any point, since we lost an edge.  We no longer
   * even know where we are.
   *
   * Normal operation:
   *
   * 1) Rising edge of SFD.  Gets new entry at sfd_fill.
   * 2) marked SFD_BUSY | SFD_UP
   * 3) sfd_entries++, one more active entry.
   * 4) state goes to {RX,TX}_ACTIVE.
   *
   * 5) falling edge of SFD.  uses same sfd_fill entry.
   * 6) marked SFD_DOWN
   * 7) sfd_fill gets incremented.
   *
   * 8) {RX,TX}_FD (frame done) exception processes entry from
   *    sfd_drain side of queue.  FIFO.
   * 9) entry marked ~SFD_BUSY.
   * 10) sfd_entries--
   *
   *
   * Overwritten Operation:
   *
   * When in an SFD overwritten state (1 or more SFD edges have been lost), we
   * ignore all timestamps in the queue.  We don't try to figure out which
   * edge (timestamp) got lost.
   *
   * We can resync the SFDQueue, when both TX and RX are quiescent.  This will
   * occur when the RXFIFO has been drained and the number of sfd_entries is 0.
   * When in overwrite status, sfd_entries at most will be 1, when a new RX
   * frame has been seen (SFD rising).
   *
   * While in overwrite, we only care about being in the middle of an RX packet,
   * in which case we have an active SFD entry being worked on.   We don't want
   * to yank that entry out by processing an exception and then trying to
   * resync the SfdQueue.  So we need to keep try of this state.  (this is
   * denoted by sfd_entries being 1).
   *
   * We also don't want to run out of SFDQueue entries if we continue to be
   * hammered.  New entries keep getting assigned, but we haven't been able
   * to resync yet because we have stayed busy.  We just make sure we
   * can use the next entry.  (SFDDown logic takes care of this).
   */

  bool in_sfdcapture_captured;

  async event void SfdCapture.captured(uint16_t cap_time, bool overwritten)  {
    sfd_stamp_t         *sfd_p;
    uint8_t              sfd_up;
    uint32_t             local;
    uint16_t             upper, lower;
    timesync_relative_t  event_rel;
    uint8_t              tx_active;

    if (in_sfdcapture_captured) {
      __PANIC_RADIO(6, cap_time, overwritten, 0, 0);
      /* no recovery */
    }
    in_sfdcapture_captured = TRUE;

    sfd_up    = call SFD.get();
    tx_active = call TXA.get();
    sfd_p     = sfd_ptrs[sfd_fill];

    if (overwritten) {
      call Trace.trace(T_R_SFD_OVW, (sfd_fill << 8) | sfd_drain, sfd_entries);
      sfd_lost = TRUE;
      cc2520_inst_sfd_overwrites++;
    }

    if (sfd_up) {
      /*
       * SFD is up, must be a rising edge
       *
       * rising edges always get a new SFD timing entry.  If none
       * available puke.  sfd_fill is the entry to use.
       */

      call Trace.trace(T_R_SFD_UP, (sfd_fill << 8) | sfd_drain,
                       (overwritten ? 0x8000 : 0) |
                       (tx_active   ? 0x4000 : 0) |
                       sfd_entries);
      if (sfd_lost) {
        /*
         * When sfd_lost is active, we could be looping around (because we
         * are getting hammered or got busy (long interrupt latency) and never
         * have time to clear out the mungled SfdQueue.  So we always make the
         * current fill entry available so we don't blow up.
         *
         * Also if we lost the previous falling edge, we will be filling into
         * a previously busy entry.  Back to back rising edges.  Make sure to
         * reuse current entry.
         */
        sfd_p->sfd_status = 0;          /* clear busy, if there. */
        sfd_entries = 0;                /* never more than 1, goes to 1 below */
      }

      if (sfd_p->sfd_status & SFD_BUSY) {
        /*
         * If BUSY is set, we must have lost an edge (trailing), and the
         * state machine got wedged Panic, then reset the entry to 0 which
         * will restart us.
         *
         * Can this happen?  Possibly a wild memory writer.  Doesn't
         * hurt to leave it in.  Other possibility is we've wrapped because
         * too many packets are in flight.  1 tx possible and multiple
         * receives that aren't getting processed.
         *
         * We also set sfd_lost, indicating that the timestamps are out of
         * sync again.  This lets the exceptionProcessor at least cycle
         * the queues and will eventually resync.
         */
        __PANIC_RADIO(35, sfd_fill, sfd_drain, sfd_entries, sfd_p->sfd_status);
        sfd_lost = TRUE;
        sfd_p->sfd_status = 0;
        sfd_entries--;                  /* made one go away. */
      }
      sfd_entries++;                    /* we are using this entry       */
      sfd_p->sfd_status = SFD_BUSY;     /* also clear out previous state */
      if (overwritten)
        sfd_p->sfd_status |= SFD_OVW;   /* remember what happened        */

      /*
       * Combine current time stamp (16 bits, uS, from h/w capture) with the
       * 32 bit localtime (TMicro) that the system is using.
       *
       * Note, if we have overwritten the captured timestamp we won't use
       * these timestamp results, because we've lost sync.
       *
       * However, that said, we want to adjust the localtime we've gotten
       * above to reflect the captured time of the SFD_up event.
       *
       * From observations, the captured time is around 15 uS later
       * then the actual observed event.   But this can vary because of
       * possible interrupt latency.  The capture time is done in h/w while
       * the localtime call happens in the interrupt handler so can be
       * delayed for various reasons.
       *
       * We want to back localtime up to reflect when the capture actually
       * occured.  This must take into account corner cases involving what
       * LocalTime can do.
       */
      local = call LocalTime.get();
      upper = local >> 16;
      lower = local & 0xffff;
      if (lower < cap_time) {           /* cap_time should be < lower */
        /*
         * if the low 16 of local are less than cap_time, it means the local
         * time has wrapped (16 bit wrap).  So we need to back local up
         * appropriately.
         */
        upper--;
      }
      sfd_p->time_up = cap_time;
      sfd_p->local   = ((uint32_t) upper << 16) | cap_time;

      if (tx_active) {
        /* tx sfd */
        sfd_p->sfd_status |= (SFD_UP | SFD_TX) ;
        if (dvr_state == STATE_TX_START) {      /* at interrupt level */
          next_state(STATE_TX_ACTIVE);          /* already protected  */
          if (timesync_absolute) {
            /*
             * compute relative time of the event from sfd_up.
             *
             * we need to adjust sfd_p->local to take into account when
             * sfd_up was captured, ie.  sfd_p->time_up
             */
            event_rel = timesync_absolute - sfd_p->local;
            writeTxFifo((uint8_t *) &event_rel, sizeof(timesync_relative_t));
            timesync_absolute = 0;
          }
        }
      } else {
        /* rx sfd */
        sfd_p->sfd_status |= (SFD_UP | SFD_RX);
        if (dvr_state == STATE_TX_START) {        /* protected */
          /*
           * race condition between send.send (tx_start) and an
           * rx coming in and winning.   TX actually issued the strobe
           * but tx didn't win.
           *
           * if debugging, note the if jumps directly into the next condition
           * because they both do the same thing.
           */
          next_state(STATE_RX_ACTIVE);
        } else if (dvr_state == STATE_RX_ON) {    /* protected */
          /*
           * Normal condition for rx coming in.  Also handles the
           * race condition where TX is starting up, but the RX sfd_up
           * happens prior to the TX send critical region (where the
           * strobe happens.  ie.  dvr_state != TX_START.   Setting
           * state to RX_ACTIVE will cause the transmit to abort.
           */
          next_state(STATE_RX_ACTIVE);
        }
      }
      in_sfdcapture_captured = FALSE;
      return;
    }

    /*
     * SFD is down, falling edge.  This tells us the radio is back to RX_ON.
     */
    call Trace.trace(T_R_SFD_DOWN, (sfd_fill << 8) | sfd_drain,
                     (overwritten ? 0x8000 : 0) |
                     (tx_active   ? 0x4000 : 0) |
                     sfd_entries);
    if (overwritten) {
      /*
       * Missed something, most likely it was the rising edge.  We want
       * to make sure to mark as BUSY so it shows as something happened
       * (valid state).  But also signal that things  are SNAFU'd.  Note that
       * if we did lose the rising edge, this entry won't have RX or TX set so
       * it will look weird.   That is yet another cookie crumb that might tell
       * us something about what happened.
       */
      sfd_p->sfd_status = (SFD_BUSY | SFD_OVW);         /* flag it */
    }
    if (sfd_lost) {
      /*
       * if sfd_lost is active, we throw all entries away except for the
       * partial.  We can't have a partial here (sfd is down) so zero entries
       */
      sfd_entries = 0;                 /* this lets resync happen */
    }

    if ((sfd_p->sfd_status & SFD_BUSY) == 0) {
      /*
       * oht oh.   really should have been busy from the rising edge
       * If we got overwritten, this got fixed above.  So must be a strange
       * situation.   Flag it, something is going really weird.
       */
        __PANIC_RADIO(36, sfd_fill, sfd_drain, sfd_entries, sfd_p->sfd_status);
        sfd_p->sfd_status |= SFD_BUSY;
    }

    sfd_p->sfd_status |= SFD_DWN;
    sfd_p->time_down = cap_time;
    if ((++sfd_fill) >= MAX_SFD_STAMPS)
      sfd_fill = 0;
    call Trace.trace(T_R_SFD_FILL, (sfd_fill << 8) | sfd_drain,
                     (overwritten ? 0x8000 : 0) |
                     (tx_active   ? 0x4000 : 0) |
                     sfd_entries);

    if (dvr_state == STATE_RX_ACTIVE) {           /* protected */
      /*
       * packet fully in rxfifo, rx_frm_done will kick pulling it
       * in the meantime, say back in rx_on (rx idle).
       */
      next_state(STATE_RX_ON);
    } else if (dvr_state == STATE_TX_ACTIVE) {
      /*
       * transmit is complete.  final processing is handled by the
       * tx_frm_done exception processing.   Different interrupt.
       *
       * switch back into RX_ON.
       */
      next_state(STATE_RX_ON);
    }

    in_sfdcapture_captured= FALSE;
  }


  async event void ExcAInterrupt.fired() {
    radioIrq = TRUE;
    call Tasklet.schedule();
  }


  /*
   * Process a TX_FRM_DONE
   *
   * the sfd entry pointed to by drain is guaranteed to be pointing at
   * the TX entry.
   *
   * interrupts assumed off.  Assumed head of the sfdQueue is the TX
   * entry.  This is checked prior to getting here.
   *
   * The txMsg packet has had its timestamp cleared on the way in, only
   * set it if we have something reasonable to set it to.
   *
   * returns TRUE if we want recovery.
   */
  bool process_tx_frm_done() {
    sfd_stamp_t         *sfd_p;

    call Trace.trace(T_R_TX_PKT, (sfd_fill << 8) | sfd_drain,
                     (sfd_lost ? 0x8000 : 0) | sfd_entries);
    if (!sfd_lost && sfd_entries) {
      sfd_p  = sfd_ptrs[sfd_drain];
      call PacketTimeStamp.set(txMsg, sfd_p->local);
      sfd_p->time_finish = call LocalTime.get();
      if (drainOneSfd(sfd_p, SFD_TX))   /* we should be pointing at a SFD_TX */
        return TRUE;                    /* so shouldn't ever happen */
    }
    writeReg(CC2520_EXCFLAG0, ~CC2520_EXC0_TX_FRM_DONE);
    writeReg(CC2520_EXCFLAG1, ~CC2520_EXC1_CLR_OTHERS);
    if (dvr_cmd == CMD_TRANSMIT)
      dvr_cmd = CMD_NONE;                     /* must happen before signal */
    else
      __PANIC_RADIO(37, dvr_cmd, tx_user_state, (uint16_t) txMsg, 0);

    if (tx_user_state == TXUS_PENDING) {
      txMsg = NULL;
      tx_user_state = TXUS_IDLE;            /* needs to happen prior to signal */
      if (dvr_cmd == CMD_TRANSMIT)
        dvr_cmd = CMD_NONE;
      signal RadioSend.sendDone(SUCCESS);   /* this is from interrupt level    */
    } else {
      /*
       * strange, why isn't a transmit waiting?
       * we will eventually, ignore silently.
       */
      __PANIC_RADIO(38, tx_user_state, (uint16_t) txMsg, 0, 0);
      txMsg = NULL;
      tx_user_state = TXUS_IDLE;
      if (dvr_cmd == CMD_TRANSMIT)
        dvr_cmd = CMD_NONE;
    }
    return FALSE;
  }


  /*
   * make a pass at processing any ExcA exceptions that are up.  We only
   * process exceptions that are connected to excA.
   *
   * On entry, interrupts need to be disabled.  snarfMsg will reenable
   * interrupts while it is draining the rxfifo.
   *
   * NASTY: RF_NO_LOCK, SPI_ERROR, OPERAND_ERROR, USAGE_ERROR, MEMADDR_ERROR
   * TX_{UNDER,OVER}FLOW: These should happen.   Something went wrong.
   * RX_UNDERFLOW: shouldn't happen.
   *
   * RX_OVERFLOW: In the presence of outside packets, we need to deal with
   *     this.  Outside sources can send packets that we will receive that
   *     can cause the rxfifo to fill up.
   *
   *     We have observed large unknown packets in our testing.  From
   *     Smart Meters?  When decoded the packet's fcf field doesn't make
   *     sense but we still receive the packet (we can mess with filtering).
   *
   *     Also by handling RX_Overflow in a reasonable fashion we can
   *     cut down on DNS attacks.
   *
   * TX_ACK_DONE: h/w acking?   not implemented.
   *
   * RX_FRM_ABORTED: frame being received when SXOSCOFF, SFLUSHRX, SRXON,
   *     STXON, SRFOFF, etc.
   */

  void processExceptions() {
    uint8_t       exc0, exc1, exc2;
    uint8_t       length, fifocnt;
    sfd_stamp_t * sfd_p;
    bool          recover,    rx_overflow;
    bool          tx_pending, rx_pending;

    /*
     * bailing out of the do {} while(0) structure after an exception has been
     * processed.  Additional per exception checks are done, ie. recovery and
     * overwrite resyncing.
     */

    do {
      exc0 = readReg(CC2520_EXCFLAG0);
      exc1 = readReg(CC2520_EXCFLAG1);
      exc2 = readReg(CC2520_EXCFLAG2);
      recover = FALSE;
      call Trace.trace(T_R_EXCEP, (exc0 << 8) | exc1, exc2);

      /*
       * First check for nasty uglyness.
       *   EXC2_RF_NO_LOCK   EXC2_SPI_ERROR      EXC2_OPERAND_ERROR
       *   EXC2_USAGE_ERROR  EXC2_MEMADDR_ERROR
       */
      if (exc2 & CC2520_FATAL_NASTY) {
        drs(FALSE);
        __PANIC_RADIO(38, exc0, exc1, exc2, 0);
        recover = TRUE;
        break;
      }

      if (exc0 & (CC2520_EXC0_TX_UNDERFLOW | CC2520_EXC0_TX_OVERFLOW)) {
        drs(FALSE);
        __PANIC_RADIO(39, exc0, exc1, exc2, 0);
        recover = TRUE;
        break;                          /* bail out, recover */
      }

      if (exc0 & CC2520_EXC0_RX_UNDERFLOW) {
        drs(FALSE);
        __PANIC_RADIO(40, exc0, exc1, exc2, 0);
        recover = TRUE;
        break;                          /* bail out, recover */
      }

      /*
       * Other strange stuff.  Currently not implemented.
       *
       * Just look and bitch.
       *
       * h/w ack processing:
       *   TX_ACK_DONE: (currently not implemented)
       *
       * RX_FRM_ABORTED: (shouldn't happen)
       */

      if ((exc0 & CC2520_EXC0_TX_ACK_DONE) ||
          (exc2 & CC2520_EXC2_RX_FRM_ABORTED)) {
        __PANIC_RADIO(41, exc0, exc1, exc2, 0);

        /* shouldn't ever happen, just looking for now */
        if (exc0 & CC2520_EXC0_TX_ACK_DONE)
          writeReg(CC2520_EXCFLAG0, ~CC2520_EXC0_TX_ACK_DONE);
        if (exc2 & CC2520_EXC2_RX_FRM_ABORTED)
          writeReg(CC2520_EXCFLAG2, ~CC2520_EXC2_RX_FRM_ABORTED);

        /* doesn't force a recovery */
      }

      /*
       * Normal handling: (packet processing)
       *   TX_FRM_DONE:
       *   RX_FRM_DONE:
       *
       * We need to process in the order that they have been seen.  This
       * is reflected in the SfdQueue.  We don't want any strange timing
       * effects if we start finishing packets out of order.
       *
       * That gets blown up if the SFDQueue gets blown up (out of sync)
       * and then we just do our best to get rid of what we have.
       *
       *******************************************************************
       *
       * Normal TX frame completion
       *
       * o clean out TX_FRM_DONE exception
       * o time stamp the packet.
       * o clean out the SFD entry.
       * o respond to tx_user_state (ie. PENDING -> signal upper layer)
       *
       * To actually start processing the TX_FRM_DONE we need a valid TX entry
       * at the start of the SfdQueue (or the queue is in an overwritten
       * condition).
       */
      sfd_p  = sfd_ptrs[sfd_drain];
      rx_pending = tx_pending = rx_overflow = FALSE;
      if (exc0 & CC2520_EXC0_TX_FRM_DONE) {
        tx_pending = TRUE;
        call Trace.trace(T_R_TX_FD, (sfd_lost ? 0x8000 : 0) | sfd_drain,
                         sfd_p->sfd_status);
        if (sfd_lost ||               /* no timestamps */
            ((sfd_p->sfd_status & (SFD_BUSY | SFD_TX))
                               == (SFD_BUSY | SFD_TX))) {
          tx_pending = FALSE;
          if (process_tx_frm_done()) {
            recover = TRUE;
            break;
          }

          /*
           * We can return from here (unlike RX_FRM_DONE) because we can have
           * one and only one TX outstanding at a time.  Any other exceptions
           * will still be up and need to be checked for anyway.  So exit out
           * and then come right back in.
           */
          return;
        }

        /*
         * Can't process the TX_FRM just yet, something else at the start
         * of the SfdQueue.  Hopefully there is an RX_FRM_DONE pending but
         * if we end up at the end we will bitch like hell.
         */

      }

      if (exc0 & CC2520_EXC0_RX_OVERFLOW) {
        /*
         * The rxfifo has overflowed.  Last (incomplete) packet can't be
         * recovered (incomplete, last byte thrown away).  When done
         * processing any packets in the rxfifo (to minimize DNS), we
         * need to flush the last packet, and then restart the RX up
         * again.
         */
        writeReg(CC2520_EXCFLAG0, ~CC2520_EXC0_RX_OVERFLOW);
        rx_overflow = TRUE;
        cc2520_inst_rx_overflows++;
        call Trace.trace(T_R_RX_OVR, (sfd_fill << 8) | sfd_drain, sfd_entries);
      }

      if (exc1 & CC2520_EXC1_RX_FRM_DONE) {
        rx_pending = TRUE;
        call Trace.trace(T_R_RX_FD, (sfd_lost ? 0x8000 : 0) | sfd_drain,
                         sfd_p->sfd_status);
        if (sfd_lost ||               /* no timestamps */
            ((sfd_p->sfd_status & (SFD_BUSY | SFD_RX))
                               == (SFD_BUSY | SFD_RX))) {
          rx_pending = FALSE;
          while (TRUE) {
            /*
             * Process all packets that have been fully received into the
             * RxFifo.  We have to process all of them, because there is
             * only one RX_FRM_DONE indication for however many packets are
             * in the rxfifo.  It would be nice if it was something like
             * RX_PACKETS_AVAIL instead and stays up until all complete
             * packets have been pulled.   But wishful thinking.
             *
             * Once we start to receive we want to continue until the rxfifo
             * is empty enough (length >= fifocnt, left with the currently
             * active RX packet or we have overflowed).  We also have to
             * check for a potentially interspersed TX_FRM that might have
             * gotten interleaved with the incoming rx packets.  I would think
             * that the TX would either be at the front or the back.  There is
             * at least 192us + 160us after the TX completes before a RX
             * packet can start coming in (rising SFD).  So there should be
             * enough time for the driver to finish dealing with the TX packet.
             *
             * We won't start a TX until the receiver is quiescent (has to be
             * in RX_ON and CCA).  However, once an rx packet is done (signaled
             * by sfd_down), we go back to RX_ON and a transmit potentially
             * can be started up.
             *
             * Note: RXFIRST may or may not have a valid byte.  If it is valid
             * it will typically be the length byte of the next packet (but
             * only if it is the first byte).  At all other times it is simply
             * left over from whatever previous data was in the rxfifo.
             *
             * If we are in a sfd_lost state, we will reset the SfdQueue once
             * the chip goes quiesent.  Ordinarily, we would have to protect
             * the SfdQueue access because the SfdCapture code (interrupt
             * level) also manipulates the SfdQueue.  But not a problem
             * because this routine only gets called with interrupts disabled.
             *
             * While processing a RX packet, another RX packet may have completed.
             * First, we will process this packet, but we also need to clear out
             * any new RX_FRM_DONE exceptions.  We won't have a new RX_FRM_DONE
             * exception if length < fifocnt, which says the packet hasn't been
             * completed yet, and will eventually generate the RX_FRM_DONE
             * exception.
             */
            writeReg(CC2520_EXCFLAG1, ~CC2520_EXC1_RX_CLR);
            length  = readReg(CC2520_RXFIRST);
            fifocnt = readReg(CC2520_RXFIFOCNT);
            call Trace.trace(T_R_RX_LOOP, length, fifocnt);

            /*
             * nothing in the fifo?  no further checks, RXFIRST is nonsense
             */
            if (fifocnt == 0)
              break;

            /*
             * check for rxfifo being in a weird state, too short, or too long
             * indicates out of sync.   It may be a partial packet but if we
             * abort (via recover), the SfdQueue and the chip will get reset
             * by the recovery code.
             *
             * Minimum packet is...    LEN FC_0 FC_1 DSN FCS_0 FCS_1
             */
            if (length < 5) {
              /* below minimum size, must be out of sync */
              cc2520_inst_rx_toosmall++;
              recover = TRUE;
              break;
            }

            if (length > 127) {
              cc2520_inst_rx_toolarge++;
              recover = TRUE;
              break;
            }

            if (length >= fifocnt)              /* verify that rx_overflow and normal completion still works. */
              break;

            if (snarfMsg(length)) {       /* true says recover */
              recover = TRUE;
              break;
            }

            /***********************************************************
             *
             * All of this needs to be here.   We want to process tx and
             * rx packets in order.  So we have to be looking for what's
             * next in the SFDQueue.  But it is really driven off the
             * exception bits from the chip (RX_FRM_DONE and TX_FRM_DONE).
             * The SFDQueue is advisory for timestamps.
             *
             * Since we have to check in order to see of we have a pending
             * TX, we also need to be checking for nasty bits and
             * rx_overflow.
             *
             * Pain in the ass but its the architecture of the chip
             * coupled with being pedantic for keeping packets properly
             * ordered.
             *
             * You have been warned :-)
             *
             ***********************************************************/

            /*
             * see if anything nasty happened
             *
             * We could just let the rx machine continue to cycle, pulling
             * packets.   eventually, we will run off the end of the fifo
             * and stop.
             *
             * But it seems more expedient to blow the chip up when something
             * strange happens.  This also makes the RX_OVERFLOW behave the
             * same when we have it on entry or when it happens while we are
             * pulling packets.  In other words always throw the entire
             * rxfifo away when an RX OVERFLOW happens.
             *
             * And we have to at least fetch an updated value for exc0 to
             * check for TX_FRM_DONE.  So it didn't seem that hard to
             * check for other crap while we are here.
             */
            exc0 = readReg(CC2520_EXCFLAG0);
            exc1 = readReg(CC2520_EXCFLAG1);
            exc2 = readReg(CC2520_EXCFLAG2);

            /*
             * if no exception bits, do another loop from the head
             * we have to keep processing packets in the rxfifo
             * until its empty.  There is only one rx_frm_done for
             * any rx packets that are already in the rxfifo.
             */
            if ((exc0 | exc1 | exc2) == 0)
              continue;

            /* more exception bits, see what we've got */
            call Trace.trace(T_R_EXCEP_1, (exc0 << 8) | exc1, exc2);
            if ((exc2 & CC2520_FATAL_NASTY) ||
                (exc0 & (CC2520_EXC0_TX_UNDERFLOW | CC2520_EXC0_TX_OVERFLOW)) ||
                (exc0 & CC2520_EXC0_RX_UNDERFLOW)) {
              __PANIC_RADIO(42, exc0, exc1, exc2, 0);
              recover = TRUE;
              break;
            }

            if (exc0 & CC2520_EXC0_RX_OVERFLOW) {
              writeReg(CC2520_EXCFLAG0, ~CC2520_EXC0_RX_OVERFLOW);
              rx_overflow = TRUE;
              cc2520_inst_rx_overflows++;
              call Trace.trace(T_R_RX_OVR_1, (sfd_fill << 8) | sfd_drain,
                               sfd_entries);
            }

            /* snarfMsg advanced sfd_drain, we need to refetch. */
            sfd_p  = sfd_ptrs[sfd_drain];
            if (exc0 & CC2520_EXC0_TX_FRM_DONE) {
              call Trace.trace(T_R_TX_FD_1, (sfd_lost ? 0x8000 : 0) | sfd_drain,
                               sfd_p->sfd_status);
              if (sfd_lost ||
                  ((sfd_p->sfd_status & (SFD_BUSY | SFD_TX))
                                     == (SFD_BUSY | SFD_TX))) {
                tx_pending = FALSE;
                if (process_tx_frm_done()) {
                  recover = TRUE;
                  break;
                }
              }
            }
          }
        }

        /*
         * Can't process the RX_FRM just yet, something else at the start
         * of the SfdQueue.  Hopefully a TX_FRM_DONE was present and got
         * processed, but if it didn't we'll exit out and will bitch.
         */
      }

      if (rx_overflow) {
        /*
         * RX_OVERFLOW processing.
         *
         * rx_overflow can be standalone or part of a rx stream.  Either way
         * when we get here we have length > rxfifocnt and the receiver is turned
         * off.  Chip will be in state 17 (rx_overflow).  We should have seen
         * a sfd_up and a sfd_down.  When we overflow, sfd is lowered.  The driver
         * state really should be RX_ON.  Nothing else makes sense.
         *
         * To start up the receiver again, we need to flush the rxfifo, clean up
         * the SFD entry for this packet start, and restart the receiver.
         */
        call Trace.trace(T_R_RX_OVR_1, (sfd_fill << 8) | sfd_drain,
                         (sfd_lost ? 0x8000 : 0) | sfd_entries);
        if (sfd_lost) {
          recover = TRUE;
          break;
        }
        if (dvr_state != STATE_RX_ON) {         /* really should be RX_ON */
          __PANIC_RADIO(43, exc0, exc1, exc2, dvr_state);
          recover = TRUE;
          break;
        }
        sfd_p  = sfd_ptrs[sfd_drain];
        if (drainOneSfd(sfd_p, SFD_RX)) {
          recover = TRUE;
          break;
        }
        flushRxFifo();
        next_state(STATE_RX_ON);
        strobe(CC2520_CMD_SRXON);
        rx_overflow = FALSE;
      }
    } while (0);

    /*
     * Additional Processing:
     *
     * First check for out of order sfdqueue.
     */

    if (!recover && (tx_pending || rx_pending)) {
      /*
       * if recover is set we will blow up the machine.  If we are here
       * and either tx_pending or rx_pending is set that means that we have
       * a unprocessed FRM_DONE and the SfdQueue doesn't match.  Something
       * really bent out of sorts.
       *
       * We will also cause a recovery after Panicing.
       */
      __PANIC_RADIO(45, exc0, exc1, exc2, (recover ? 0x4 : 0) |
                    (tx_pending ? 0x2 : 0) | (rx_pending ? 0x1 : 0));
      recover = TRUE;
    }
    if (recover) {
      call Trace.trace(T_R_RECOVER, 0xffff, 0xff00 | READ_SR);
      /*
       * nuke2rxon blows the h/w up and sets it back up to initial RX_ON state.
       *
       * We don't worry about more interrupts coming in because when running
       * at full speed, the radio takes 192us to do a rx_calibration and then
       * there will be another 160 uS before the first SFD can be recognized.
       * (4 bytes preamble and 1 byte SFD).
       *
       * We should be well out of here before that happens.  But single
       * stepping is a different story.
       */
      nuke2rxon();

      /*
       * if TXUS_STARTUP, tell the TX code we aborted and the h/w
       *    state has been reset.
       * if TXUS_PENDING  tell the waiting higher level, we blew up
       */
      if (tx_user_state == TXUS_STARTUP)
        tx_user_state = TXUS_ABORT;
      else if (tx_user_state == TXUS_PENDING) {
        txMsg = NULL;
        tx_user_state = TXUS_IDLE;        /* do this before signalling    */
        if (dvr_cmd == CMD_TRANSMIT)
          dvr_cmd = CMD_NONE;
        signal RadioSend.sendDone(FAIL);  /* this is from interrupt level */
      }                                   /* be careful                   */
    }

    /*
     * if we get this far, check for sfd_lost being active and try to do a resync
     * interrupts are off here.
     */
    if (sfd_lost) {
      if (dvr_state == STATE_RX_ON) {
        /*
         * the chip is only quiescent if in RX_ON.  Otherwise we have
         * something going on.  Don't rip the SfdQueue state out from
         * under any of that.
         */
        if (sfd_entries == 0) {
          /*
           * when sfd_lost is active, sfd_entries can be 0 or 1.  It will
           * be 1 if we've seen a rising edge and are using an entry.
           * don't yank the Queue.  This should already be protected by the
           * check for RX_ON above.
           */
          fifocnt = readReg(CC2520_RXFIFOCNT);
          if (fifocnt) {
            /*
             * Only yank if the rxfifo is completely empty.
             * it is odd to have fifocnt > 0 and be in RX_ON.
             */
            __PANIC_RADIO(46, exc0, exc1, exc2, fifocnt);
          }
          flushSfdQueue();
        }
      }
    }
  }


  void serviceRadio() {
    /*
     * what happens if Spi isn't owned?  How does this work?
     * leave radioIrq up.   And then when we get scheduled
     * from the grant, serviceRadio will get invoked again.
     *
     * What to do with existing interrupts?   Already cleared?
     */

    /* ******************************************************************** */

    /*
     * Normally, serviceRadio is an interrupt service routine and interrupts
     * are by default disabled.  However, in the presence of arbitration it is
     * possible that execution can be delayed until after granted is signalled.
     * When this happens we get called from Task(Sync) context and we need to
     * make sure interrupts are disabled.  Hence the atomic block.
     *
     * Later, in processExceptions, we reenable interrupts while copying bytes
     * out of the rxfifo.  We want to allow the SfdCapture interrupt to get
     * in for Sfd edges.  This has a higher priority than copying bytes out of
     * the rxfifo.
     */
    if (isSpiAcquired()) {
      atomic {
        radioIrq = FALSE;

        /*
         * Typically, a set of exception bits will be set for a single packet
         * that needs to be processed.  These bits get cleared by software as
         * the packet is processed.
         *
         * If all excA bits are down, excA will drop.  The next rising edge of
         * excA will generate another interrupt.
         *
         * But, there are corner cases where events can overlap.  So if an
         * exception bit gets raised after we have read the exception registers
         * during exception processing, then it won't be processed by the current
         * interation.  But because it is already up, it won't result in another
         * edge on excA so another interrupt won't be generated.
         *
         * Bottom line, is we need to continue to process exception bits as long
         * as excA is still up.   We may want to add a check for doing too many
         * loops.
         *
         * Spurious interrupts can occur and EXCA can be 0 because of this.  Do
         * nothing, if no EXCA.
         */

        while (call EXCA.get())
          processExceptions();
      }
    }
  }


  default tasklet_async event bool RadioReceive.header(message_t *msg) {
    return TRUE;
  }


  default tasklet_async event message_t* RadioReceive.receive(message_t *msg) {
    return msg;
  }


  /* ----------------- TASKLET ----------------- */
  /* -------------- State Machine -------------- */

  tasklet_async event void RadioAlarm.fired() {
    uint16_t wait_time;

    nop();
    nop();
    if (takeAlarm) {
      takeAlarm = 0;
      call Tasklet.schedule();
      return;
    }

    stateAlarm_active = FALSE;
    switch (dvr_state) {
      case STATE_OFF_2_LOAD:
        wait_time = call PlatformCC2520.powerUp();
        if (wait_time) {                /* more waiting needed */
          stateAlarm_active = TRUE;
          call RadioAlarm.wait(wait_time);

          /*
           * we return rather than break.  Breaking drops out and causes
           * the Tasklet group to run again.  (sequence the state machine).
           * Returning won't sequence the state machine but will wait for
           * the timer to fire.
           *
           * Note: we just launched a RadioAlarm.wait which should take
           * non-zero time to trip.   While that is active (stateAlarm_active)
           * the state machine Tasklet will bail (assumes the alarm has
           * to trip before another state transiton is needed).
           *
           * If the above assumption is violated then we will have
           * to revisit the stateAlarm_active lock out.
           */
          return;
        }
        break;

      case STATE_STANDBY_2_LOAD:
        wait_time = call PlatformCC2520.wakeup();
        if (wait_time) {                /* more waiting needed */
          stateAlarm_active = TRUE;
          call RadioAlarm.wait(wait_time);

          /*
           * we return rather than break which drops out and causes the
           * Tasklet group to run again.  (sequence the state machine)
           *
           * See note above about mutual exclusion of RadioAlarm and
           * the main state machine tasklet.
           */
          return;
        }
        break;

      default:                          /* shouldn't be here */
        bad_state();
        break;
    }
    call Tasklet.schedule();            /* process additional work */

    /*
     * Note: we could post CC2520_Load_Config here but we would still need
     * to have some kind of processing in the main state runner (Tasklet.run) too.
     * It would be empty but it still needs to be handled because we don't know
     * the order that the Tasklets get linked together.
     *
     * So just let the Main State Machine Sequencer handle it.
     */

    if (takeAlarm)
      call RadioAlarm.wait(100);
  }


  /*
   * Main State Machine Sequencer
   */
  tasklet_async event void Tasklet.run() {
    nop();
    nop();
    if (takeAlarm)
      call RadioAlarm.wait(100);

    if (radioIrq)
      serviceRadio();

    if (stateAlarm_active)
      return;

    switch (dvr_cmd) {
      case CMD_NONE:
        break;

      case CMD_TURNOFF:
      case CMD_STANDBY:
      case CMD_TURNON:
        changeState();
        break;

      case CMD_TRANSMIT:
      case CMD_RECEIVE:
        break;

      case CMD_CCA:
        signal RadioCCA.done(checkCCA() ? SUCCESS : EBUSY);
        dvr_cmd = CMD_NONE;
        break;

      case CMD_CHANNEL:
        changeChannel();
        break;

      case CMD_SIGNAL_DONE:
        break;

      default:
        break;
    }

    if (dvr_cmd == CMD_SIGNAL_DONE) {
      dvr_cmd = CMD_NONE;
      signal RadioState.done();
    }

    if (dvr_cmd == CMD_NONE && dvr_state == STATE_RX_ON && ! radioIrq)
      signal RadioSend.ready();

    if (dvr_cmd == CMD_NONE) {
      releaseSpi();
    }
  }


  /*----------------- RadioPacket -----------------*/

  /*
   * this returns the total offset from the start of the message buffer
   * to the MPDU header.
   */
  async command uint8_t RadioPacket.headerLength(message_t *msg) {
    return call Config.headerOffset(msg) + sizeof(cc2520_header_t);
  }


  async command uint8_t RadioPacket.payloadLength(message_t *msg) {
    return getPhyHeader(msg)->length - FCS_SIZE;
  }


  async command void RadioPacket.setPayloadLength(message_t *msg, uint8_t length) {
    RADIO_ASSERT( 1 <= length && length <= 125 );
    RADIO_ASSERT( call RadioPacket.headerLength(msg) + length + call RadioPacket.metadataLength(msg) <= sizeof(message_t) );

    // we add the length of the CRC, which is automatically generated
    getPhyHeader(msg)->length = length + FCS_SIZE;
  }


  async command uint8_t RadioPacket.maxPayloadLength() {
    RADIO_ASSERT( call Config.maxPayloadLength() - sizeof(cc2520_header_t) <= 125 );

    return call Config.maxPayloadLength() - sizeof(cc2520_header_t);
  }


  async command uint8_t RadioPacket.metadataLength(message_t *msg) {
    return call Config.metadataLength(msg) + sizeof(cc2520_metadata_t);
  }


  async command void RadioPacket.clear(message_t *msg) {
    // all flags are automatically cleared
  }


  /*----------------- PacketTransmitPower -----------------*/

  async command bool PacketTransmitPower.isSet(message_t *msg) {
    return call TransmitPowerFlag.get(msg);
  }


  async command uint8_t PacketTransmitPower.get(message_t *msg) {
    return getMeta(msg)->power;
  }


  async command void PacketTransmitPower.clear(message_t *msg) {
    call TransmitPowerFlag.clear(msg);
  }


  async command void PacketTransmitPower.set(message_t *msg, uint8_t value) {
    call TransmitPowerFlag.set(msg);
    getMeta(msg)->power = value;
  }


  /*----------------- PacketRSSI -----------------*/

  async command bool PacketRSSI.isSet(message_t *msg) {
    return call RSSIFlag.get(msg);
  }


  async command uint8_t PacketRSSI.get(message_t *msg) {
    return getMeta(msg)->rssi;
  }


  async command void PacketRSSI.clear(message_t *msg) {
    call RSSIFlag.clear(msg);
  }


  async command void PacketRSSI.set(message_t *msg, uint8_t value) {
    // just to be safe if the user fails to clear the packet
    call TransmitPowerFlag.clear(msg);

    call RSSIFlag.set(msg);
    getMeta(msg)->rssi = value;
  }


  /*----------------- PacketTimeSyncOffset -----------------*/

  async command bool PacketTimeSyncOffset.isSet(message_t *msg) {
    return call TimeSyncFlag.get(msg);
  }


  async command uint8_t PacketTimeSyncOffset.get(message_t *msg) {
    return call RadioPacket.headerLength(msg) + call RadioPacket.payloadLength(msg) - sizeof(timesync_absolute_t);
  }


  async command void PacketTimeSyncOffset.clear(message_t *msg) {
    call TimeSyncFlag.clear(msg);
  }


  async command void PacketTimeSyncOffset.set(message_t *msg, uint8_t value) {
    // we do not store the value, the time sync field is always the last 4 bytes
    RADIO_ASSERT( call PacketTimeSyncOffset.get(msg) == value );
    call TimeSyncFlag.set(msg);
  }


  /*----------------- PacketLinkQuality -----------------*/

  async command bool PacketLinkQuality.isSet(message_t *msg) {
    return TRUE;
  }


  async command uint8_t PacketLinkQuality.get(message_t *msg) {
    return getMeta(msg)->lqi;
  }


  async command void PacketLinkQuality.clear(message_t *msg) { }


  async command void PacketLinkQuality.set(message_t *msg, uint8_t value) {
    getMeta(msg)->lqi = value;
  }


  ieee154_simple_header_t* getIeeeHeader(message_t* msg) {
    return (ieee154_simple_header_t *) msg;
  }


  async command error_t PacketAcknowledgements.requestAck(message_t *msg) {
    //call SoftwareAckConfig.setAckRequired(msg, TRUE);
    getIeeeHeader(msg)->fcf |= (1 << IEEE154_FCF_ACK_REQ);
    return SUCCESS;
  }


  async command error_t PacketAcknowledgements.noAck(message_t* msg) {
    getIeeeHeader(msg)->fcf &= ~(uint16_t)(1 << IEEE154_FCF_ACK_REQ);
    return SUCCESS;
  }


  async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
#ifdef CC2520_HARDWARE_ACK
    return call AckReceivedFlag.get(msg);
#else
    return FALSE;
#endif
  }


  async event void Panic.hook() {
    dump_radio();
#ifdef notdef
    call CSN.set();                     /* make sure CC2520 SPI is reset */
    call CSN.clr();
    call CSN.set();
    drs(TRUE);
    nop();
#endif
  }


#ifndef REQUIRE_PLATFORM
  /*
   * We always require Platform.usecsRaw to be working.
   *
   *  default async command uint16_t Platform.usecsRaw()   { return 0; }
   */

  default async command uint16_t Platform.jiffiesRaw() { return 0; }
#endif

#ifndef REQUIRE_PANIC
  default async command void Panic.panic(uint8_t pcode, uint8_t where, uint16_t arg0,
					 uint16_t arg1, uint16_t arg2, uint16_t arg3) { }
  default async command void  Panic.warn(uint8_t pcode, uint8_t where, uint16_t arg0,
					 uint16_t arg1, uint16_t arg2, uint16_t arg3) { }
#endif
}
