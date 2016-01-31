/*
 * Copyright (c) 2016, Eric B. Decker
 * Copyright (c) 2013-2014 Eric B. Decker
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
 */

/**
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * The bit fields in this header are little endian and are not portable.
 *
 * Memory Map:
 *
 * 0x000 - 0x03f        FREG,     (REGRD/REGWR)
 * 0x040 - 0x07f        SREG,     (MEMRD/MEMWR)
 * 0x100 - 0x17f        TX FIFO   (128 bytes)
 * 0x180 - 0x1ff        RX FIFO   (128 bytes)
 * 0x200 - 0x37f        MEM       (384 bytes)
 * 0x380 - 0x3ff        Addr Info (128 bytes)
 *   0x380 - 0x3df        Src Addr
 *   0x3e0 - 0x3e3        Src Addr Match
 *   0x3e4 - 0x3e9        Src Addr Control
 *   0x3ea - 0x3f5        Local Addr Info
 *   0x3f6 - 0x3ff        Reserved
 */

#ifndef __CC2520_DRIVERLAYER_H__
#define __CC2520_DRIVERLAYER_H__

/*
 * default channel for setting FREQCTRL
 */
#ifndef CC2520_DEF_CHANNEL
#define CC2520_DEF_CHANNEL 25
#endif

/* See Table 17 of the cc2520 data sheet */
#ifndef CC2520_DEF_RFPOWER
#ifdef CC2520_2591
/* -18 dBm */
#define CC2520_DEF_RFPOWER 0x03
#else
/* 0 dBm */
#define CC2520_DEF_RFPOWER 0x32
#endif
#endif


/*
 * cc2520_header_t is the PHR, PHY header
 */
typedef nx_struct cc2520_header_t {
  nxle_uint8_t length;
} cc2520_header_t;


typedef struct cc2520_metadata_t {
  uint8_t lqi;
  uint8_t power;
  uint8_t ack;
  uint8_t rssi;
} cc2520_metadata_t;

enum cc2520_reg_access_enums {
  CC2520_FREG_MASK       = 0x3F,        // highest address in FREG
  CC2520_SREG_MASK       = 0x7F,        // highest address in SREG
};

typedef union cc2520_status {
  uint8_t value;
  struct {                              /* little endian */
    unsigned  rx_active    :1;
    unsigned  tx_active    :1;
    unsigned  dpu_l_active :1;
    unsigned  dpu_h_active :1;

    unsigned  exception_b  :1;
    unsigned  exception_a  :1;
    unsigned  rssi_valid   :1;
    unsigned  xosc_stable  :1;
  } f;
} cc2520_status_t;

typedef union cc2520_fsmstat1 {
  uint8_t value;
  struct {
    unsigned rx_active   : 1;
    unsigned tx_active   : 1;
    unsigned lock_status : 1;
    unsigned sampled_cca : 1;
    unsigned cca         : 1;
    unsigned sfd         : 1;
    unsigned fifop       : 1;
    unsigned fifo        : 1;
  } f;
} cc2520_fsmstat1_t;

/*
 * The following are from pg 103 CC2520 datasheet
 * SWRS068 - Dec 2007, section 28.1
 */
#define CC2520_DEF_CCACTRL0 0xf8
#define CC2520_DEF_MDMCTRL0 0x85
#define CC2520_DEF_MDMCTRL1 0x14

#define CC2520_DEF_RXCTRL   0x3F
#define CC2520_DEF_FSCTRL   0x5a
#define CC2520_DEF_FSCAL1   0x2b
#define CC2520_DEF_AGCCTRL1 0x11
#define CC2520_DEF_ADCTEST0 0x10
#define CC2520_DEF_ADCTEST1 0x0e
#define CC2520_DEF_ADCTEST2 0x03

enum {
  CC2520_TX_PWR_MASK  = 0xFF,
  CC2520_CHANNEL_MASK = 0x1F,

  CC2520_TX_PWR_0     = 0x03,           // -18 dBm
  CC2520_TX_PWR_1     = 0x2C,           //  -7 dBm
  CC2520_TX_PWR_2     = 0x88,           //  -4 dBm
  CC2520_TX_PWR_3     = 0x81,           //  -2 dBm
  CC2520_TX_PWR_4     = 0x32,           //   0 dBm
  CC2520_TX_PWR_5     = 0x13,           //   1 dBm
  CC2520_TX_PWR_6     = 0xAB,           //   2 dBm
  CC2520_TX_PWR_7     = 0xF2,           //   3 dBm
  CC2520_TX_PWR_8     = 0xF7,           //   5 dBm
};

enum cc2520_register_enums {
  /*
   * FREG Registers - 0x00 - 0x3F
   */

  CC2520_FRMFILT0     = 0x00,
  CC2520_FRMFILT1     = 0x01,
  CC2520_SRCMATCH     = 0x02,
  CC2520_SRCSHORTEN0  = 0x04,
  CC2520_SRCSHORTEN1  = 0x05,
  CC2520_SRCSHORTEN2  = 0x06,
  CC2520_SRCEXTEN0    = 0x08,
  CC2520_SRCEXTEN1    = 0x09,
  CC2520_SRCEXTEN2    = 0x0A,
  CC2520_FRMCTRL0     = 0x0C,
  CC2520_FRMCTRL1     = 0x0D,
  CC2520_RXENABLE0    = 0x0E,
  CC2520_RXENABLE1    = 0x0F,
  CC2520_EXCFLAG0     = 0x10,
  CC2520_EXCFLAG1     = 0x11,
  CC2520_EXCFLAG2     = 0x12,
  CC2520_EXCMASKA0    = 0x14,
  CC2520_EXCMASKA1    = 0x15,
  CC2520_EXCMASKA2    = 0x16,
  CC2520_EXCMASKB0    = 0x18,
  CC2520_EXCMASKB1    = 0x19,
  CC2520_EXCMASKB2    = 0x1A,
  CC2520_EXCBINDX0    = 0x1C,
  CC2520_EXCBINDX1    = 0x1D,
  CC2520_EXCBINDY0    = 0x1E,
  CC2520_EXCBINDY1    = 0x1F,
  CC2520_GPIOCTRL0    = 0x20,
  CC2520_GPIOCTRL1    = 0x21,
  CC2520_GPIOCTRL2    = 0x22,
  CC2520_GPIOCTRL3    = 0x23,
  CC2520_GPIOCTRL4    = 0x24,
  CC2520_GPIOCTRL5    = 0x25,
  CC2520_GPIOPOLARITY = 0x26,
  CC2520_GPIOCTRL     = 0x28,
  CC2520_DPUCON       = 0x2A,
  CC2520_DPUSTAT      = 0x2C,
  CC2520_FREQCTRL     = 0x2E,
  CC2520_FREQTUNE     = 0x2F,
  CC2520_TXPOWER      = 0x30,
  CC2520_TXCTRL       = 0x31,           /* ??? */
  CC2520_FSMSTAT0     = 0x32,
  CC2520_FSMSTAT1     = 0x33,
  CC2520_FIFOPCTRL    = 0x34,
  CC2520_FSMCTRL      = 0x35,
  CC2520_CCACTRL0     = 0x36,
  CC2520_CCACTRL1     = 0x37,
  CC2520_RSSI         = 0x38,
  CC2520_RSSISTAT     = 0x39,
  CC2520_RXFIRST      = 0x3C,
  CC2520_RXFIFOCNT    = 0x3E,
  CC2520_TXFIFOCNT    = 0x3F,

  /*
   * SREG registers - 0x40 - 0x7f
   */

  CC2520_CHIPID       = 0x40,
  CC2520_VERSION      = 0x42,
  CC2520_EXTCLOCK     = 0x44,
  CC2520_MDMCTRL0     = 0x46,
  CC2520_MDMCTRL1     = 0x47,
  CC2520_FREQEST      = 0x48,
  CC2520_RXCTRL       = 0x4A,
  CC2520_FSCTRL       = 0x4C,
  CC2520_FSCAL0       = 0x4E,
  CC2520_FSCAL1       = 0x4F,
  CC2520_FSCAL2       = 0x50,
  CC2520_FSCAL3       = 0x51,
  CC2520_AGCCTRL0     = 0x52,
  CC2520_AGCCTRL1     = 0x53,
  CC2520_AGCCTRL2     = 0x54,
  CC2520_AGCCTRL3     = 0x55,
  CC2520_ADCTEST0     = 0x56,
  CC2520_ADCTEST1     = 0x57,
  CC2520_ADCTEST2     = 0x58,
  CC2520_MDMTEST0     = 0x5A,
  CC2520_MDMTEST1     = 0x5B,
  CC2520_DACTEST0     = 0x5C,
  CC2520_DACTEST1     = 0x5D,
  CC2520_ATEST        = 0x5E,
  CC2520_DACTEST2     = 0x5F,
  CC2520_PTEST0       = 0x60,
  CC2520_PTEST1       = 0x61,
  CC2520_RESERVED     = 0x62,
  CC2520_DPUBIST      = 0x7A,
  CC2520_ACTBIST      = 0x7C,
  CC2520_RAMBIST      = 0x7E,
};

enum cc2520_spi_command_enums {
  CC2520_CMD_SNOP           = 0x00,
  CC2520_CMD_IBUFLD         = 0x02,
  CC2520_CMD_SIBUFEX        = 0x03,
  CC2520_CMD_SSAMPLECCA     = 0x04,
  CC2520_CMD_SRES           = 0x0f,
  CC2520_CMD_MEMRD          = 0x10,
  CC2520_CMD_MEMWR          = 0x20,
  CC2520_CMD_RXBUF          = 0x30,
  CC2520_CMD_RXBUFCP        = 0x38,
  CC2520_CMD_RXBUFMOV       = 0x32,
  CC2520_CMD_TXBUF          = 0x3A,
  CC2520_CMD_TXBUFCP        = 0x3E,
  CC2520_CMD_RANDOM         = 0x3C,
  CC2520_CMD_SXOSCON        = 0x40,
  CC2520_CMD_STXCAL         = 0x41,
  CC2520_CMD_SRXON          = 0x42,
  CC2520_CMD_STXON          = 0x43,
  CC2520_CMD_STXONCCA       = 0x44,
  CC2520_CMD_SRFOFF         = 0x45,
  CC2520_CMD_SXOSCOFF       = 0x46,
  CC2520_CMD_SFLUSHRX       = 0x47,
  CC2520_CMD_SFLUSHTX       = 0x48,
  CC2520_CMD_SACK           = 0x49,
  CC2520_CMD_SACKPEND       = 0x4A,
  CC2520_CMD_SNACK          = 0x4B,
  CC2520_CMD_SRXMASKBITSET  = 0x4C,
  CC2520_CMD_SRXMASKBITCLR  = 0x4D,
  CC2520_CMD_RXMASKAND      = 0x4E,
  CC2520_CMD_RXMASKOR       = 0x4F,
  CC2520_CMD_MEMCP          = 0x50,
  CC2520_CMD_MEMCPR         = 0x52,
  CC2520_CMD_MEMXCP         = 0x54,
  CC2520_CMD_MEMXWR         = 0x56,
  CC2520_CMD_BCLR           = 0x58,
  CC2520_CMD_BSET           = 0x59,
  CC2520_CMD_CTR_UCTR       = 0x60,
  CC2520_CMD_CBCMAC         = 0x64,
  CC2520_CMD_UCBCMAC        = 0x66,
  CC2520_CMD_CCM            = 0x68,
  CC2520_CMD_UCCM           = 0x6A,
  CC2520_CMD_ECB            = 0x70,
  CC2520_CMD_ECBO           = 0x72,
  CC2520_CMD_ECBX           = 0x74,
  CC2520_CMD_INC            = 0x78,
  CC2520_CMD_ABORT          = 0x7F,
  CC2520_CMD_REGRD          = 0x80,
  CC2520_CMD_REGWR          = 0xC0,
};

/*
 * Exceptions.
 *
 * Exceptions are bits held in 3 bytes EXCFLAG0-2.
 */

enum cc2520_exceptions_enums {

  /* excflag0 */
  CC2520_EXC0_RF_IDLE           = 0x01,
  CC2520_EXC0_TX_FRM_DONE       = 0x02,
  CC2520_EXC0_TX_ACK_DONE       = 0x04,
  CC2520_EXC0_TX_UNDERFLOW      = 0x08,
  CC2520_EXC0_TX_OVERFLOW       = 0x10,
  CC2520_EXC0_RX_UNDERFLOW      = 0x20,
  CC2520_EXC0_RX_OVERFLOW       = 0x40,
  CC2520_EXC0_RXENABLE_ZERO     = 0x80,

  /* excflag1 */
  CC2520_EXC1_RX_FRM_DONE       = 0x01,
  CC2520_EXC1_RX_FRM_ACCEPTED   = 0x02,
  CC2520_EXC1_SRC_MATCH_DONE    = 0x04,
  CC2520_EXC1_SRC_MATCH_FOUND   = 0x08,
  CC2520_EXC1_FIFOP             = 0x10,
  CC2520_EXC1_SFD               = 0x20,
  CC2520_EXC1_DPU_DONE_L        = 0x40,
  CC2520_EXC1_DPU_DONE_H        = 0x80,

  /* excflag2 */
  CC2520_EXC2_MEMADDR_ERROR     = 0x01,
  CC2520_EXC2_USAGE_ERROR       = 0x02,
  CC2520_EXC2_OPERAND_ERROR     = 0x04,
  CC2520_EXC2_SPI_ERROR         = 0x08,
  CC2520_EXC2_RF_NO_LOCK        = 0x10,
  CC2520_EXC2_RX_FRM_ABORTED    = 0x20,
  CC2520_EXC2_RXBUFMOV_TO       = 0x40,
  CC2520_EXC2_UNUSED            = 0x80,
};

#define CC2520_FATAL_NASTY \
    (CC2520_EXC2_MEMADDR_ERROR | CC2520_EXC2_USAGE_ERROR     \
   | CC2520_EXC2_OPERAND_ERROR | CC2520_EXC2_SPI_ERROR       \
   | CC2520_EXC2_RF_NO_LOCK)

#define CC2520_EXC1_CLR_OTHERS \
    (CC2520_EXC1_FIFOP | CC2520_EXC1_SFD)

#define CC2520_EXC1_RX_CLR \
    (CC2520_EXC1_RX_FRM_DONE | CC2520_EXC1_FIFOP | CC2520_EXC1_SFD)

#endif // __CC2520_DRIVERLAYER_H__
