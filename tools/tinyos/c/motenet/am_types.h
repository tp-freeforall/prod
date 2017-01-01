/*
 * am_types
 *
 */

#ifndef __AM_TYPES_H__
#define __AM_TYPES_H__

/*
 * Well known TinyOS numbers.
 */

enum {
  AM_RESERVED_00		= 0x00,		/* indicates any type */

  AM_PACKET_TIMESYNC		= 0x3D,
  TIMESYNC_AMTYPE		= 0x3D,		/* alias */
  AM_FTSP			= 0x3E,
  AM_TIMESYNCMSG		= 0x3E,		/* alias */
  AM_NALP			= 0x3F,

  AM_IP_MSG			= 0x41,		/* 6lowpan, am encap */

  AM_DELUGEADVMSG		= 0x50,
  AM_DELUGEREQMSG		= 0x51,
  AM_DELUGEDATAMSG		= 0x52,
  AM_DELUGE_FLASH_VOL_MANAGER	= 0x53,
  DELUGE_AM_FLASH_VOL_MANAGER	= 0x53,		/* alias */
  AM_DELUGE_MANAGER		= 0x54,
  DELUGE_AM_DELUGE_MANAGER	= 0x54,		/* alias */

  AM_DISSEMINATION_MESSAGE      = 0x60,
  AM_DISSEMINATION_PROBE_MESSAGE= 0x61,
  AM_DIP			= 0x62,
  AM_DHV			= 0x63,

  AM_PRINTF_MSG			= 0x64,

  AM_CTP_ROUTING		= 0x70,
  AM_CTP_DATA			= 0x71,
  AM_CTP_DEBUG			= 0x72,
  AM_LQI_BEACON_MSG		= 0x73,
  AM_LQI_DATA_MSG		= 0x74,
  AM_LQI_DEBUG			= 0x75,

  AM_SRP			= 0x76,
};

/*
 * MM AM data packets.
 */
enum {
  AM_MM_CONTROL			= 0xA0,
  AM_MM_DT			= 0xA1,		/* data, typed */
  AM_MM_DEBUG			= 0xA2,
};

#endif  /* __AM_TYPES_H__ */
