
#include "trace.h"

interface Trace {
  async command void trace(trace_where_t where, uint16_t arg0, uint16_t arg1);
}
