
#include "trace.h"

interface Trace {
  async command void trace(trace_where_t where, uint32_t arg0, uint32_t arg1);
}
