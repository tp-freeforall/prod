This directory contains various applications showing OSIAN IP applications.
In a roughly increasing order of complexity, these are summarized below.
For more details, consult the README file in each directory, or (if there is
no README) the introductory comment in TestAppC.nc.

UdpEcho -- A fundamental test of IP networking over PPP to an OSIAN node.
Supports ping and RFC862-conformant echo (UDP only).  See the README in that
directory.

UnicastDirectLed -- Demonstrate monitoring and control of an OSIAN node
using a unicast UDP application protocol from a Python client on the host.

UnicastRadioNet -- Demonstrate a fully connected graph of nodes all
exchanging information over the radio network.  This application does not
provide an IP connection over the USB port; connect to the serial port to
display running text status.

MulticastRadioNet -- Demonstrate multicast discovery of nodes by having each
periodically multicast a sequence number, and recording the history of
receptions from other nodes.  This application does not provide an IP
connection over the USB port; connect to the serial port to display running
text status.

BridgePppRadio -- A key utility, when this application is installed on a
board any IP traffic originating on the radio link and directed to either a
multicast gruop or the link-local address of the host side of the PPP link
will be routed over the PPP link to the host.  Similarly, any traffic
received over the PPP link will be retransmitted over the radio.
Consequently, all nodes on the radio link can be accessed from the host
using their link-local address.

ManualRouting -- Intended to be a demonstration of manual protocol-level
routing between the radio and PPP links, this currently serves best as a
demonstration of how to communicate the controller address to a node that
has just come up on the radio network.

Flood -- Stress-test of multiple nodes transmitting frequent and long
packets to a multicast or unicast destination.

Rdate -- Demonstrate use of RFC868 time protocol and maintenance of the
real-time clock on an OSIAN node.

