/**
 * Copyright 2013-2014 (c) Eric B. Decker
 * All rights reserved.
 *
 * @author Eric B. Decker, <cire831@gmail.com>
 */

#ifndef __PLATFORM_TRACE_H__
#define __PLATFORM_TRACE_H__

#define TRACE_SIZE 256

/*
 * trace values (trace_where_t) are platform dependent
 * and depend on what one is trying to trace.
 */

typedef enum {
  T_REQ			= 1,
  T_GRANT		= 2,
  T_REL			= 3,
  T_SSR			= 4,
  T_SSW			= 5,
  T_GPS			= 6,

  T_GPS_DO_GRANT,
  T_GPS_DO_DEFERRED,
  T_GPS_RELEASING,
  T_GPS_RELEASED,
  T_GPS_DO_REQUESTED,
  T_GPS_HOLD_TIME,
  T_SSW_DELAY_TIME,
  T_SSW_BLK_TIME,
  T_SSW_GRP_TIME,

  T_RS                  = 20,

  T_R_SFD_UP            = 32,
  T_R_SFD_DOWN,
  T_R_SFD_OVW,
  T_R_SFD_FILL,
  T_R_SFD_DRAIN,
  T_R_SFD_FLUSH,

  T_R_EXCEP,
  T_R_EXCEP_1,
  T_R_TX_FD,
  T_R_TX_FD_1,
  T_R_TX_PKT,
  T_R_RX_FD,
  T_R_RX_PKT,
  T_R_RX_RECV,
  T_R_RX_BAD_CRC,
  T_R_RX_OVR,
  T_R_RX_OVR_1,
  T_R_RX_LOOP,
  T_R_RECOVER,

  T_TL                  =64,
  T_INT_OVR,
  T_INT_T0A0,
  T_INT_T0A1,
  T_INT_P1,

  /*
   * For debugging Arbiter 1
   */
  T_A1_REQ		= 1 + 256,
  T_A1_GRANT		= 2 + 256,
  T_A1_REL		= 3 + 256,

} trace_where_t;

#endif	// __PLATFORM_TRACE_H__
