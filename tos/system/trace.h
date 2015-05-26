/**
 * Copyright 2008, 2013, 2015 (c) Eric B. Decker
 * All rights reserved.
 *
 * @author Eric B. Decker, <cire831@gmail.com>
 */

#ifndef __TRACE_H__
#define __TRACE_H__

#include "platform_trace.h"

#ifndef TRACE_SIZE
#warning TRACE_SIZE not defined by platform_trace, defaulting to 1
#define TRACE_SIZE 1
#endif

typedef struct {
  uint32_t stamp;
  trace_where_t where;
  uint16_t arg0;
  uint16_t arg1;
} trace_t;

#endif	// __TRACE_H__
