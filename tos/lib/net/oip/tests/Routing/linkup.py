import socket
import sys
import getopt
import select
import pty
import os
import fcntl

socket_params = (socket.AF_INET6, socket.SOCK_DGRAM, socket.IPPROTO_UDP)

host_ppp_fqdn = 'host.osian-ppp'
device_ppp_fqdn = 'device.osian-ppp'
osian_device = '/dev/ttyUSB0'
#pppd_path = '/usr/sbin/pppd'
pppd_path = '/usr/local/ppp-osian/sbin/pppd'
pppd_requires_root = True

def fqdnToIpv6Addr (fqdn):
    global socket_params
    rv = socket.getaddrinfo(fqdn, 0, *socket_params)
    rv = rv[0]
    addr = rv[4]
    return addr

def fqdnToIID (fqdn):
    addrstr = fqdnToIpv6Addr(fqdn)[0]
    if addrstr.startswith('fe80::'):
        return addrstr[4:]
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

timeout_ms = 1000
while True:
    for (_, events) in poller.poll(timeout_ms):
        sys.stdout.write(pppd_fd.read())
    
