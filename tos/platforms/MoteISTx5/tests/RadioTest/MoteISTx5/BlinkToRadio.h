// $Id: BlinkToRadio.h,v 1.4 2006-12-12 18:22:52 vlahan Exp $

#ifndef BLINKTORADIO_H
#define BLINKTORADIO_H

#ifdef TOS_NODE_ID
#undef TOS_NODE_ID
#define TOS_NODE_ID 1
#endif

enum {
  AM_BLINKTORADIO = 6,
  TIMER_PERIOD_MILLI = 1500
};

typedef nx_struct BlinkToRadioMsg {
  nx_uint16_t nodeid;
  nx_uint16_t counter;
  nx_uint16_t teste;
} BlinkToRadioMsg;

#endif
