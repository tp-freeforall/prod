#ifndef __UART_X5_CONFIG_H__
#define __UART_X5_CONFIG_H__

const msp430_usci_config_t uart_config = {
  /*
   * 8MHz (8,000,000 Hz), 115200 baud
   * UCBR 69, UCBRS 4, UCBRF 0, UCOS16 0
   */
  ctlw0 : (0 << 8) | UCSSEL__SMCLK,	/* SMCLK */
  brw   : 69,
  /*       ucbrf       ucbrs  */
  mctl  : (0 << 4) | (4 << 1)
};

#endif	/* __UART_X5_CONFIG_H__ */
