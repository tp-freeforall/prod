#ifndef _H_Msp430Usci_h
#define _H_Msp430Usci_h

#include "msp430hardware.h"

/* MSP430_USCI_RESOURCE is used for USCI_IDs */
#define MSP430_USCI_RESOURCE "Msp430Usci.Resource"

#define MSP430_USCI_A0_RESOURCE "Msp430Usci.A0.Resource"
#define MSP430_USCI_B0_RESOURCE "Msp430Usci.B0.Resource"
#define MSP430_USCI_A1_RESOURCE "Msp430Usci.A1.Resource"
#define MSP430_USCI_B1_RESOURCE "Msp430Usci.B1.Resource"
#define MSP430_USCI_A2_RESOURCE "Msp430Usci.A2.Resource"
#define MSP430_USCI_B2_RESOURCE "Msp430Usci.B2.Resource"
#define MSP430_USCI_A3_RESOURCE "Msp430Usci.A3.Resource"
#define MSP430_USCI_B3_RESOURCE "Msp430Usci.B3.Resource"

enum {
  MSP430_USCI_Inactive,
  MSP430_USCI_UART,
  MSP430_USCI_SPI,
  MSP430_USCI_I2C,
};

/**
 * Aggregates basic configuration registers for an MSP430 USCI.
 * These are specifically the registers common to all configurations.
 * Mode-specific configuration data should be provided elsewise.
 */
typedef struct msp430_usci_config_t {
  uint16_t ctlw0;
  uint16_t brw;
  uint8_t mctl;
} msp430_usci_config_t;

#ifndef TOS_DEFAULT_BAUDRATE
#define TOS_DEFAULT_BAUDRATE 115200
#endif /* TOS_DEFAULT_BAUDRATE */


/*
 * This table assumes UART clock input (SMCLK) is 1MiHz (2^20Hz).
 */

msp430_usci_config_t msp430_usci_uart_default_config = {
  /* N81 UART mode driven by SMCLK */
  ctlw0 : (0 << 8) | UCSSEL__SMCLK,

#if 9600 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 9600: UBR=109, BRS=2, BRF=0 */
  brw : 109, // 9600
  mctl : UCBRF_0 + UCBRS_2
#elif 19200 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 19200: UBR=54, BRS=2, BRF=0 */
  brw : 54, // 19200
  mctl : UCBRF_0 + UCBRS_2
#elif 38400 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 38400: UBR=27, BRS=2, BRF=0 */
  brw : 27, // 38400
  mctl : UCBRF_0 + UCBRS_2
#elif 57600 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 57600: UBR=18, BRS=1, BRF=0 */
  brw : 18, // 57600
  mctl : UCBRF_0 + UCBRS_1
#elif 115200 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 115200: UBR=9, BRS=1, BRF=0 */
  brw : 9, // 115200
  mctl : UCBRF_0 + UCBRS_1
#else
#warning Unrecognized value for TOS_DEFAULT_BAUDRATE, using 115200
  brw : 9, // 115200
  mctl : UCBRF_0 + UCBRS_1
#endif
};

msp430_usci_config_t msp430_usci_spi_default_config = {
  /* Inactive high MSB-first 8-bit 3-pin master driven by SMCLK */
  ctlw0 : ((UCCKPL + UCMSB + UCMST + UCSYNC) << 8) | UCSSEL__SMCLK,
  /* 2x Prescale */
  brw : 2,
  mctl : 0                      /* Always 0 in SPI mode */
};

enum {
  /** Bit set in Msp430UsciError.condition parameter when a framing
   * error (UART) or bus conflict (SPI) has been detected.  Applies in
   * UART mode, and SPI 4-wire master mode. */
  MSP430_USCI_ERR_Framing = UCFE,
  /** Bit set in Msp430UsciError.condition parameter when an overrun
   * error (lost character on input) has been detected.  Applies in
   * UART and SPI modes. */
  MSP430_USCI_ERR_Overrun = UCOE,
  /** Bit set in Msp430UsciError.condition parameter when a parity
   * error has been detected.  Applies in UART mode. */
  MSP430_USCI_ERR_Parity = UCPE,
  /** Mask for all UCxySTAT bits that represent reportable errors. */
  MSP430_USCI_ERR_UCxySTAT = MSP430_USCI_ERR_Framing | MSP430_USCI_ERR_Overrun | MSP430_USCI_ERR_Parity,
};

/*
 * I2C default config, added by Derek Baker (derek@red-slate.com)
 */

msp430_usci_config_t msp430_usci_i2c_default_config = {
  /* 7 bit addressing single I2C master driven by SMCLK */
  ctlw0 : ((UCMST + UCMODE_3 + UCSYNC) << 8) | UCSSEL__SMCLK,
  brw : 10,					/* gives us 103680 hz, slow speed but will work with all devices.*/
  mctl : 0					/* Not used in I2C mode*/
};

#endif // _H_Msp430Usci_h
