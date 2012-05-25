/**
 *  @author Eric B. Decker
 *  @date   Mar 6 2010
 *
 * Define USE_X1 if using an x1 family chip, 4 MiHz USART based msp430
 * else assumed x2 8 MiHz 2000 series part.
 *
 * ie.  make debugopt -DUSE_X1 telosb
 **/

#include "hardware.h"

#ifdef USE_X1
#include "msp430usart.h"
#else
#include "msp430usci.h"
#endif

#ifdef USE_X1
#include "uart_x1_config.h"
#elif USE_X2
#include "uart_x2_config.h"
#else
#include "uart_x5_config.h"
#endif

uint16_t rx_ints, tx_ints;
volatile uint16_t start = 1;

module SerialDirectP {
  uses {
#ifdef USE_X1
    interface HplMsp430Usart as Port;
    interface HplMsp430UsartInterrupts as PortInt;
#elif USE_X2
    interface HplMsp430UsciA as Port;
    interface HplMsp430UsciInterrupts as PortInt;
#else
    interface HplMsp430Usci as Port;
    interface HplMsp430UsciInterrupts as PortInt;
#endif
    interface Boot;
  }
}
implementation {
  event void Boot.booted() {
    uint8_t b;

    while (!start)
      nop();
#if defined(USE_X1) || defined(USE_X2)
    call Port.setModeUart((msp430_uart_union_config_t *) &uart_config);
#else
    P5SEL |= BIT7 | BIT6;
    call Port.configure(&uart_config, FALSE);
#endif
    b = 0;
    call Port.setTxbuf(b++);
    while(1) {
      if (call Port.isTxIntrPending())
	call Port.setTxbuf(b++);
    }
  }

#ifdef notdef
  async event void PortInt.txDone() {
    tx_ints++;
  }

  async event void PortInt.rxDone(uint8_t data) {
    uint8_t tmp;

    rx_ints++;
    tmp = call Port.rx();
  }
#endif

  async event void PortInt.interrupted(uint8_t iv) {
  }
}
