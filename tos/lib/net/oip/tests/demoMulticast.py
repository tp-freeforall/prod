# Example of a Python program that sends or receives multicast information.

import socket
import sys
import getopt
import time
import select
import binascii
import struct

# Set up defaults.  Assumes host name is tied to the interface over which
# we will send data.
port = 49152 + 1972
bind_fqdn = None
mc_fqdn = None
if_fqdn = None
address_family = socket.AF_INET
socket_type = socket.SOCK_DGRAM
socket_proto = socket.IPPROTO_UDP
delay = 3
sender = 0
receiver = 0
loopback = 0

packet_size = 40
try:
    opts, args = getopt.getopt(sys.argv[1:], 'i:p:g:d:slrP:46b:', ['if-address=', 'port=', 'mcast-address=', 'delay=', 'sender', 'loopback', 'packet-size=', 'ipv4', 'ipv6', 'bind=' ])
except getopt.GetoptError:
    print "usage: %s [-i ifaddr] [-g groupaddr] [-p port] [-d delay] [-s] [-l] [-r]" % (sys.argv[0],)
    sys.exit(2)
for (o, a) in opts:
    if o in ('-i', '--if-address'):
        if_fqdn = a
    elif o in ('-p', '--port'):
        port = int(a)
    elif o in ('-b', '--bind'):
        bind_fqdn = a
    elif o in ('-g', '--mcast-address'):
        mc_fqdn = a
    elif o in ('-d', '--delay'):
        delay = int(a)
    elif o in ('-s', '--sender'):
        sender = 1
    elif o in ('-r', '--receiver'):
        receiver = 1
    elif o in ('-l', '--loopback'):
        loopback = 1;
    elif o in ('-P', '--packet-size'):
        packet_size = int(a);
    elif o in ('-4', '--ipv4'):
        address_family = socket.AF_INET
    elif o in ('-6', '--ipv6'):
        address_family = socket.AF_INET6
    
if if_fqdn is None:
    if_fqdn = socket.gethostname()
if socket.AF_INET == address_family:
    if mc_fqdn is None:
        mc_fqdn = '224.0.0.1'
    if bind_fqdn is None:
        bind_fqdn = ''
elif socket.AF_INET6 == address_family:
    if mc_fqdn is None:
        mc_fqdn = 'ff02::1'
    if bind_fqdn is None:
        bind_fqdn = '::'
else:
    raise Exception('Unrecognized address family %d' % (address_family,))

rv = socket.getaddrinfo(if_fqdn, port, address_family, socket_type, socket_proto)
if_sockaddr = rv[0][4]
if_addr = if_sockaddr[0]
if_addr_packed = socket.inet_pton(address_family, if_addr)
rv = socket.getaddrinfo(mc_fqdn, port, address_family, socket_type, socket_proto)
mc_sockaddr = rv[0][4]
mc_addr = mc_sockaddr[0]
mc_addr_packed = socket.inet_pton(address_family, mc_addr)
rv = socket.getaddrinfo(bind_fqdn, port, address_family, socket_type, socket_proto)
bind_sockaddr = rv[0][4]

# Say how we were invoked
print "# %s -i %s -g %s -b %s -p %d -d %s%s" % (sys.argv[0], repr(if_sockaddr[0]), repr(mc_sockaddr[0]), repr(bind_sockaddr[0]), port, delay,
                                          ''.join([('', ' -s')[sender],
                                                   ('', ' -r')[receiver],
                                                   ('', ' -l')[loopback],
                                                    (((socket.AF_INET == address_family) and ' -4') or
                                                     ((socket.AF_INET6 == address_family) and ' -6'))
                                                    ]))
if (not (sender or receiver)):
    print "ERROR: Must specify -s, -r, or both.\n"
    sys.exit(1)

# Create a socket, mark it for address re-use, make it join the specified
# group on the specified interface, and by the way have the kernel deliver
# any multicasts to this machine, too.
sfd = socket.socket(address_family, socket_type, socket_proto)
rc = sfd.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
if socket.AF_INET == address_family:
    sfd.setsockopt(socket.SOL_IP, socket.IP_MULTICAST_IF, if_addr_packed)
    sfd.setsockopt(socket.SOL_IP, socket.IP_ADD_MEMBERSHIP, mc_addr_packed + if_addr_packed)
elif socket.AF_INET6 == address_family:
    if_index = if_sockaddr[3]
    if 0 == if_index:
        # Interface address did not include scope id.  Try to find it.
        # NB: This probably only works on Linux.
        if_hexstr = binascii.hexlify(if_addr_packed)
        for if6 in file('/proc/net/if_inet6').readlines():
            if if6.startswith(if_hexstr):
                if_index = int(if6.split()[1], 16)
                if_sockaddr = if_sockaddr[:3] + (if_index,)
                break
    if 0 == if_index:
        raise Exception('Unable to identify scope_id for address %s' % (if_sockaddr,))
    if_index_packed = struct.pack('I', if_index)
    sfd.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_MULTICAST_IF, if_index_packed)
    mc_sockaddr = mc_sockaddr[:3] + (if_index,)
    mreq_packed = socket.inet_pton(address_family, mc_sockaddr[0]) + if_index_packed
    sfd.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_JOIN_GROUP, mreq_packed)
else:
    raise Exception('Unrecognized address family %d' % (address_family,))
rc = sfd.setsockopt(socket.SOL_IP, socket.IP_MULTICAST_LOOP, loopback)
sfd.bind(bind_sockaddr)

if sender:
    if (receiver):
        # Bind the incoming address so we can receive stuff
        poller = select.poll()
        poller.register(sfd, select.POLLIN)
    else:
        # Set the default destination port for send (so we don't have to use
        # sendto).  You can't do this if you've already invoked bind.
        rc = sfd.connect(mc_sockaddr)

    n = 0
    while 1:
        # If we also support receiving, loop until poll(2) says there's
        # nothing pending to read.
        while receiver:
            rc = poller.poll(0)
            if (not rc):
                break
            rv = sfd.recvfrom(16384)
            print "received: %s" % (rv,)

        print "broadcast %d" % (n,)
        msg = '<tag group="Python" attr="%d" sender="%s"/>' % (n, if_addr)
        if receiver:
            # If we're also a receiver, we couldn't have invoked connect to
            # set a default destination, so we gotta use sendto(2).
            rv = sfd.sendto(msg, mc_sockaddr)
        else:
            # If we're not a receiver, we could have (did) set the default
            # destination.
            if (len(msg) < packet_size):
                msg += (packet_size - len(msg)) * ' '
            rv = sfd.send(msg)
        n += 1
        time.sleep(delay)
else:
    # Specify which address we expect to receive packets on
    while 1:
        rv = sfd.recvfrom(16384)
        print rv
