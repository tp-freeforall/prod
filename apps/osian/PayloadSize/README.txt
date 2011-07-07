This application determines the maximum payload size for an OSIAN UDP
round-trip.

Things that affect this:

* The definition for TOSH_DATA_LENGTH, which can be set by the tdl extra
* The choice of OIP link layer using the oipll extra

Process

The application listens on a multicast port for incoming packets.  Upon
receipt, it returns the incoming packet to the sender.

When button 0 is pressed, the application begins a binary search for the
maximum successfully transmittable packet size between MIN_PAYLOAD_SIZE (16)
and MAX_PAYLOAD_SIZE (1023) inclusive.  For each candidate size it runs
REPETITIONS_PER_PAYLOAD (3) trials where it transmits a packet of the
candidate size.  The contents of the packet are randomly generated.  It then
waits for RESPONSE_BASE_TIMEOUT_BMS (256) plus RESPONSE_PER_BYTE_TIMEOUT_BMS
(1) times the packet size binary milliseconds for responses to dribble in.
A record is made for each packet received which matches the content of the
transmitted packet.

If no responses are received for a particular packet size, or if the
infrastructure fails to transmit the packet, it is assumed the size is too
large.

The process repeats with a new packet size until the largest successfully
transmitted packet length is identified.  The statistics for each packet
size, as well as the final result, are printed to the console.

