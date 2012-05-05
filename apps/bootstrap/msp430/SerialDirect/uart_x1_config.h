#ifndef __UART_X1_CONFIG_H__
#define __UART_X1_CONFIG_H__

const msp430_uart_union_config_t uart_config = { {
  ubr    : UBR_4MIHZ_4800,
  umctl  : UMCTL_4MIHZ_4800,
  ssel   : 2,
  pena   : 0,
  pev    : 0,
  spb    : 0,
  clen   : 1,
  listen : 0,
  mm     : 0,
  ckpl   : 0,
  urxse  : 0,
  urxeie : 1,
  urxwie : 0,
  utxe   : 1,
  urxe   : 1
  } };

#endif	/* __UART_X1_CONFIG_H__ */
