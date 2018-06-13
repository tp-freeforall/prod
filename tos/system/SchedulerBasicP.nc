/*
 * Copyright (c) 2000-2003 The Regents of the University  of California.
 * Copyright (c) 2018, Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * SchedulerBasicP implements the default TinyOS scheduler sequence, as
 * documented in TEP 106.
 *
 * @author Philip Levis
 * @author Cory Sharp
 * @date   January 19 2005
 */

#include <hardware.h>

module SchedulerBasicP @safe() {
  provides interface Scheduler;
  provides interface TaskBasic[uint8_t id];
  uses interface McuSleep;
}
implementation {
  enum {
    NUM_TASKS = uniqueCount("TinySchedulerC.TaskBasic"),
    NO_TASK = 255,
  };

  uint8_t m_head;
  uint8_t m_tail;
  uint8_t m_next[NUM_TASKS];
  uint8_t lastTask;

#ifdef  TRACE_TASKS
  /*
   * Task Tracing.
   *
   * trace buffer that logs the following events:
   *
   * POST       task postage, with low level uSec stamp
   * RUN:       when the task actually starts to run (usecs)
   * END:       when the task completes.  (usecs)
   * DELTA:     how long in usecs the task ran.
   *
   * Tasks are too low level to plumb in using Platform
   * timing routines.  It tickles a problem on some platforms
   * (in particular the ARM based platforms).
   *
   * If a platform wants to use task tracing, ie. TRACE_TASKS
   * is defined, it must also supply TRACE_TASK_USECS.  This
   * define supplies a linkage to a platform provided routine
   * that yields a usec time stamp for tracing functions.
   */

#if !defined(TRACE_TASKS_USECS)
#error TRACE_TASKS defined but _USECS missing.
#define TRACE_TASKS_USECS 0
#endif

#ifndef TRACE_TASKS_ENTRIES
#define TRACE_TASKS_ENTRIES (NUM_TASKS * 4)
#endif

  typedef enum {
    TT_POST = 1,                        /* usecs  */
    TT_RUN,                             /* usecs  */
    TT_END,                             /* usecs  */
    TT_DELTA,                           /* delta usecs */
    TT_16 = 0xffff,                     /* make sure 2 bytes */
  } tt_t;

  typedef struct {
    uint16_t num;
    tt_t     ttype;
    uint32_t val;
  } trace_task_t;

  trace_task_t task_trace[TRACE_TASKS_ENTRIES];
  uint32_t     task_trace_max[NUM_TASKS];
  norace uint16_t nxt_tt;

  uint32_t trace_usecsRaw() {
    return TRACE_TASKS_USECS;
  }

  void trace_add_entry(uint16_t num, tt_t ttype, uint32_t val) {
    trace_task_t *ttp;

    ttp = &task_trace[nxt_tt++];
    if (nxt_tt >= TRACE_TASKS_ENTRIES)
      nxt_tt   = 0;
    ttp->num   = num;
    ttp->ttype = ttype;
    ttp->val   = val;
  }

  void trace_post_task(uint16_t num) {
    trace_add_entry(num, TT_POST, trace_usecsRaw());
  }

  void trace_task_start(uint16_t num) {
    trace_add_entry(num, TT_RUN, trace_usecsRaw());
  }

  void trace_task_end(uint16_t num, uint32_t delta) {
    trace_add_entry(num, TT_END,   trace_usecsRaw());
    trace_add_entry(num, TT_DELTA, delta);
    if (delta > task_trace_max[num])
      task_trace_max[num] = delta;
  }

#else

  uint32_t trace_usecsRaw() { return 0; }
  void trace_post_task(uint16_t num)  { }
  void trace_task_start(uint16_t num) { }
  void trace_task_end(uint16_t num, uint32_t delta) { }

#endif

  // Helper functions (internal functions) intentionally do not have atomic
  // sections.  It is left as the duty of the exported interface functions to
  // manage atomicity to minimize chances for binary code bloat.

  // move the head forward
  // if the head is at the end, mark the tail at the end, too
  // mark the task as not in the queue
  inline uint8_t popTask() {
    if (m_head != NO_TASK) {
      uint8_t id = m_head;

      m_head = m_next[m_head];
      if( m_head == NO_TASK ) {
	m_tail = NO_TASK;
      }
      m_next[id] = NO_TASK;
      return id;
    } else
      return NO_TASK;
  }

  bool isWaiting( uint8_t id ) {
    return (m_next[id] != NO_TASK) || (m_tail == id);
  }

  bool pushTask( uint8_t id ) {
    if (!isWaiting(id)) {
      if (m_head == NO_TASK) {
	m_head = id;
	m_tail = id;
      } else {
	m_next[m_tail] = id;
	m_tail = id;
      }
      return TRUE;
    } else {
      return FALSE;
    }
  }

  command void Scheduler.init() {
    atomic {
      memset( (void *)m_next, NO_TASK, sizeof(m_next) );
      m_head = NO_TASK;
      m_tail = NO_TASK;
    }
  }

  command bool Scheduler.runNextTask() {
    atomic {
      lastTask = popTask();
      if (lastTask == NO_TASK)
	return FALSE;
    }
    signal TaskBasic.runTask[lastTask]();
    return TRUE;
  }


  command void Scheduler.taskLoop() {
    uint32_t delta;

    for (;;) {
      atomic {
	while ((lastTask = popTask()) == NO_TASK) {
//          nop();                        /* BRK */
	  call McuSleep.sleep();
	}
      }
      trace_task_start(lastTask);
      delta = trace_usecsRaw();
//      nop();                            /* BRK */
      signal TaskBasic.runTask[lastTask]();
      delta = trace_usecsRaw() - delta;
      trace_task_end(lastTask, delta);
    }
  }

  /**
   * Return SUCCESS if the post succeeded, EBUSY if it was already posted.
   */

  async command error_t TaskBasic.postTask[uint8_t id]() {
    atomic {
      if (pushTask(id)) {
        trace_post_task(id);
        return SUCCESS;
      } else
        return EBUSY;
    }
  }

  default event void TaskBasic.runTask[uint8_t id]() { }
}
