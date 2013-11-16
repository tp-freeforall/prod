/*
 * TraceP.nc - trace logging
 * Copyright 2008, Eric B. Decker
 * Mam-Mark Project
 *
 * Controlling Defines:
 *
 * TRACE_USE_PLATFORM:  use Platform.usecsRaw to obtain usec time
 *      extended to 32 bit number.  USE_PLATFORM overrides MICRO and Milli
 *
 * TRACE_MICRO: use LocalTimeMicro for usec time.  Has slightly
 *      more overhead (if a straight LocalTimeMicro is used) than
 *      Platform.
 *
 * If neither of the above are defined, uses LocalTimeMilli.
 */

#include "trace.h"
#include "panic.h"

trace_t  trace_buf[TRACE_SIZE];
uint16_t trace_nxt;

module TraceP {
  provides {
    interface Trace;
  }
  uses {

#ifdef TRACE_USE_PLATFORM
    interface Platform;
#define TIMESTAMPAGE ((uint32_t) call Platform.usecsRaw())
#else
#ifdef TRACE_MICRO
    interface LocalTime<TMicro>;
#else
    interface LocalTime<TMilli>;
#endif
#define TIMESTAMPAGE (call LocalTime.get())
#endif  /* TRACE_USE_PLATFORM */

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
      trace_buf[trace_nxt].stamp = TIMESTAMPAGE;
      trace_buf[trace_nxt].where = where;
      trace_buf[trace_nxt].arg0 = arg0;
      trace_buf[trace_nxt].arg1 = arg1;

      trace_nxt++;
      if (trace_nxt >= TRACE_SIZE) {
	trace_nxt = 0;
        nop();
      }
    }
  }


  async event void Panic.hook() { }
}
