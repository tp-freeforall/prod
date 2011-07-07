#!/bin/python
#
# Test program paired with Unicast
import socket
import select
import struct
import binascii

ServicePort = 60102
LocalHost = 'host.ppp.osian'
ServiceHost = 'device.ppp.osian'
NicDevice = 'ppp0'
Timeout_ms = 10000

def ifNameIndex (if_name):
    """Determine the interface identifier for a NIC device.

    Required so that we have the correct scope id for addresses."""

    for line in file('/proc/net/if_inet6').readlines():
        (in6_addr, if_index, prefix_length, scope_value, if_flags, device_name) = line.strip().split()
        if device_name == if_name:
            return int(if_index, 16)
    return None


# Create a UDP socket.
sfd = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM, socket.IPPROTO_UDP)

# Bind the address to the local interface and the port on which we
# communicate.
#
# Note: The address tuple for IPv6 comprises IP address, port,
# flowinfo(ignored), scope id.  Scope id can be zero for unicast
# addresses, but must be set correctly for link-local and wildcard
# addresses.
addr = ( '::', ServicePort, 0, ifNameIndex(NicDevice))
sfd.bind(addr)

# For this application we only talk to one device, so connect the
# socket to the remote end of the link.
addr = (ServiceHost, ServicePort, 0, ifNameIndex(NicDevice))
sfd.connect(addr)

CMD_Hello = 0
EVT_Status = 0
EVT_Rollover = 1
EVT_Button = 2
CMD_ResetCounter = 3
EVT_ResetCounter = 3

# MSP430 is little-endian.  Events comprise a 32-bit local time in
# milliseconds, a 16-bit counter, and an 8-bit event code.  Commands
# comprise a 16-bit payload and a command code.
evt_layout = '<IHBx'
cmd_layout = '<HBx'

# Kick the application so we know it's there
print 'Sending hello to %s' % (addr,)
sfd.send(struct.pack(cmd_layout, 0, CMD_Hello))

poller = select.poll()
poller.register(sfd, select.POLLIN)

iter = 0
while True:
    for (fd, revt) in poller.poll(Timeout_ms):
        msg = sfd.recv(8192)
        (time_msec, counter, event_tag) = struct.unpack(evt_layout, msg)
        print '%8.3f evt=%d ctr=%d' % (time_msec / 1000.0, event_tag, counter)
    iter += 1
    if 0 == (iter & 0x03):
        new_counter = iter >> 2
        msg = struct.pack(cmd_layout, new_counter, CMD_ResetCounter)
        print 'Reset counter to %d cmd len %u body %s' % (new_counter, len(msg), binascii.hexlify(msg))
        sfd.send(msg)
        
