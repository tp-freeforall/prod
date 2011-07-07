/* Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

/** Standard component used to select a default link layer for the
 * OSIAN IP stack.
 *
 * Control this with the oipll extra, e.g.:
 *
 *   make ... osian oipll,ieee154
 *   make ... osian oipll,barerf1a
 *   make ... osian oipll,tkn154
 *
 * No, not all those are really options, at least not yet.  If
 * unspecified, the Ipv6Ieee154C component based on the Ieee154Message
 * infrastructure will be used.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

configuration OipLinkLayerC {
  provides {
    interface NetworkInterface;
    interface SplitControl;
  }
} implementation {

#include "OipLinkLayer.h"

/* Do the right thing for each possible selection */
#if OIP_LINK_LAYER == OIP_LINK_LAYER_IEEE154
  components Ipv6Ieee154C as Ipv6LinkLayerC;
#elif OIP_LINK_LAYER == OIP_LINK_LAYER_BARERF1A
  components Ipv6BareRf1aC as Ipv6LinkLayerC;
#else
/* Make this an error: if somebody typed something wrong, they probably didn't
 * want the default. */
#error Unrecognized OIP_LINK_LAYER, please check your build parameters
#endif

  NetworkInterface = Ipv6LinkLayerC;
  SplitControl = Ipv6LinkLayerC;
}
