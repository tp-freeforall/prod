import socket
import sys
import getopt
import select
import pty
import os
import fcntl
import struct
import binascii

socket_params = (socket.AF_INET6, socket.SOCK_DGRAM, socket.IPPROTO_UDP)

host_ppp_fqdn = 'host.osian-ppp'
device_ppp_fqdn = 'device.osian-ppp'
osian_device = '/dev/ttyUSB0'
ppp_if = 'ppp0'
pppd_path = '/usr/sbin/pppd'
#pppd_path = './pppd'
pppd_requires_root = True
mcast_address = 'ff12::1'
mcast_port = 65432

def fqdnToIpv6Addr (fqdn, port=0):
    global socket_params
    rv = socket.getaddrinfo(fqdn, port, *socket_params)
    rv = rv[0]
    addr = rv[4]
    return addr

def fqdnToIID (fqdn):
    addrstr = fqdnToIpv6Addr(fqdn)[0]
    if addrstr.startswith('fe80::'):
        return addrstr[4:]
    return None

def ifNameIndex (if_name):
    for line in file('/proc/net/if_inet6').readlines():
        (in6_addr, if_index, prefix_length, scope_value, if_flags, device_name) = line.strip().split()
        if device_name == if_name:
            return int(if_index, 16)
    return None

host_ppp_iid = fqdnToIID(host_ppp_fqdn)
device_ppp_iid = fqdnToIID(device_ppp_fqdn)

if pppd_requires_root and (0 != os.geteuid()):
    print "ERROR: Running pppd requires root, and you aren't."
    sys.exit(1)

pppd_args = [ 'debug',
              'passive',
              'noauth',
              'nodetach',
              'noccp',
              'ipv6', '%s,%s' % (host_ppp_iid, device_ppp_iid),
              'noip',
              osian_device ]

pppd_fd = os.popen('%s %s' % (pppd_path, ' '.join(pppd_args)))
fcntl.fcntl(pppd_fd, fcntl.F_SETFL, os.O_NONBLOCK | fcntl.fcntl(pppd_fd, fcntl.F_GETFL))

poller = select.poll()
poller.register(pppd_fd.fileno(), select.POLLIN)

sfd = None

def tryClientSocket ():
    if_index = ifNameIndex(ppp_if)
    if if_index is None:
        return None

    sfd = socket.socket(*socket_params)

    sfd.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    if_index_packed = struct.pack('I', if_index)
    sfd.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_MULTICAST_IF, if_index_packed)

    mcast_addr = fqdnToIpv6Addr(mcast_address, mcast_port)
    mcast_addr = list(mcast_addr)
    mcast_addr[3] = if_index
    mcast_addr = tuple(mcast_addr)
    mreq_packed = socket.inet_pton(socket.AF_INET6, mcast_addr[0]) + if_index_packed

    sfd.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_JOIN_GROUP, mreq_packed)
    sfd.bind(mcast_addr)
    return sfd

timeout_ms = 1000
while True:
    if sfd is None:
        sfd = tryClientSocket()
        if sfd is not None:
            print 'sfd up'
            poller.register(sfd.fileno(), select.POLLIN)

    for (fd, events) in poller.poll(timeout_ms):
        if pppd_fd.fileno() == fd:
            sys.stdout.write(pppd_fd.read())
        if (sfd is not None) and (sfd.fileno() == fd):
            (msg, remote) = sfd.recvfrom(16384)
            (oid, tx, rx) = struct.unpack('!8sHH', msg)
            print '%s has oid %s : %u tx, %u rx' % (socket.getnameinfo(remote, 0), binascii.hexlify(oid), tx, rx)
    
