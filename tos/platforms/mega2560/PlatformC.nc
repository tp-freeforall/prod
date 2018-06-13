/* Copyright (c) 2005-2006 Intel Corporation
 * Copyright (c) 2018 Eric B. Decker
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */

configuration PlatformC {
  provides interface Init;
  provides interface Platform;
}
implementation {
  components PlatformP, HplAtm128GeneralIOC as IO;

  Init     = PlatformP;
  Platform = PlatformP;
  PlatformP.OrangeLedPin -> IO.PortB7;
}
