#ifndef __UART_X2_CONFIG_H__
#define __UART_X2_CONFIG_H__

const msp430_uart_union_config_t uart_config = { {
  ubr:		UBR_8MIHZ_4800,
  umctl:	UMCTL_8MIHZ_4800,
  ucmode:	0,			// uart
  ucspb:	0,			// one stop
  uc7bit:	0,			// 8 bit
  ucpar:	0,			// odd parity (but no parity)
  ucpen:	0,			// parity disabled
  ucrxeie:	0,			// err int off
  ucssel:	2,			// smclk
  utxe:		1,			// enable tx
  urxe:		1,			// enable rx
} };

#endif	/* __UART_X2_CONFIG_H__ */
