
#ifndef __SYSREBOOT_H__
#define __SYSREBOOT_H__

typedef enum {
  SYSREBOOT_REBOOT = 0,
  SYSREBOOT_POR,
  SYSREBOOT_HARD,
  SYSREBOOT_SOFT,
  SYSREBOOT_EXTEND = 0x10,
} sysreboot_t;

#endif  /* __SYSREBOOT_H__ */
