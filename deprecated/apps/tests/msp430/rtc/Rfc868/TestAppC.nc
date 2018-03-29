configuration TestAppC {
} implementation {
  components TestP;
  components MainC;

  TestP.Boot -> MainC;

  components Rfc868P;
  TestP.Rfc868 -> Rfc868P;
  
#include <unittest/config_impl.h>
}
