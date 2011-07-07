configuration TestAppC {
} implementation {
  components TestP;
  components MainC;

  TestP.Boot -> MainC;
  
  /* Checksum extern implementations live in this module */
  components IpSocketsC;

#include <unittest/config_impl.h>
}
