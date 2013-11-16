/**
 * Copyright 2008, 2013 (c) Eric B. Decker
 * All rights reserved.
 *
 * @author Eric B. Decker, <cire831@gmail.com>
 */

#ifndef __TRACE_H__
#define __TRACE_H__

#include "platform_trace.h"

typedef struct {
  uint32_t stamp;
  trace_where_t where;
  uint16_t arg0;
  uint16_t arg1;
} trace_t;

#endif	// __TRACE_H__
