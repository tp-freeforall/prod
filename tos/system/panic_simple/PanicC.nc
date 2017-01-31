/*
 * Copyright @ 2008, 2012 Eric B. Decker
 * @author Eric B. Decker
 */

#include "panic.h"

configuration PanicC {
  provides interface Panic;
}

implementation {
  components PanicP, MainC, PlatformC;
  Panic = PanicP;
  PanicP.Platform -> PlatformC;
  MainC.SoftwareInit -> PanicP;
}
