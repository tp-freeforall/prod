/*
 * TraceP.nc - trace logging
 * Copyright 2008, Eric B. Decker
 * Mam-Mark Project
 *
 */

#include "trace.h"
#include "panic.h"

trace_t trace_buf[TRACE_SIZE];
uint8_t trace_nxt;

module TraceP {
  provides {
    interface Trace;
  }
  uses {
    interface LocalTime<TMilli>;
    interface Panic;
  }
}

implementation {
  async command void Trace.trace(trace_where_t where, uint16_t arg0, uint16_t arg1) {
    atomic {
      if (trace_nxt >= TRACE_SIZE) {
	call Panic.warn(PANIC_KERN, 1, trace_nxt, 0, 0, 0);
	trace_nxt = 0;
      }
      trace_buf[trace_nxt].stamp = call LocalTime.get();
      trace_buf[trace_nxt].where = where;
      trace_buf[trace_nxt].arg0 = arg0;
      trace_buf[trace_nxt].arg1 = arg1;

      trace_nxt++;
      if (trace_nxt >= TRACE_SIZE)
	trace_nxt = 0;
    }
  }
}
