#!/bin/python
#
# Test the performance of an echo service by timing the throughput and
# latency of fixed-sized packets.

import socket
import sys
import getopt
import struct
import signal
import errno
import time
import select

port = 7
listen = '::'
server = 'device.ppp.osian'
tx_length = 100
rx_length = None
summary_interval_sec = 10
wait_msec = 50

try:
    opts, args = getopt.getopt(sys.argv[1:], 'rs:p:l:i:w:', ('receive-only', 'server=', 'port=', 'tx-length=', 'rx-length=', 'summary-interval-sec=', 'wait-msec='))
except getopt.GetoptError:
    sys.exit(1)
for opt, arg in opts:
    if opt in ('-r', '--receive-only'):
        server = None
    elif opt in ('-s', '--server'):
        server = arg
    elif opt in ('-p', '--port'):
        port = int(arg)
    elif opt in ('-l', '--tx-length'):
        tx_length = int(arg)
    elif opt in ('--rx-length',):
        rx_length = int(arg)
    elif opt in ('-i', '--sumary-interval-sec'):
        summary_interval_sec = int(arg)
    elif opt in ('-w', '--wait-msec'):
        wait_msec = int(arg)

if rx_length is None:
    rx_length = tx_length

tx_bytes = 0
rx_bytes = 0
tx_packets = 0
rx_packets = 0
rx_lost = 0
rx_nosync = 0
summary_last_now = time.time()

socket_params = (socket.AF_INET6, socket.SOCK_DGRAM, socket.IPPROTO_UDP)

sfd = socket.socket(*socket_params)
rc = sfd.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

layout = '!HH'
layout_length = struct.calcsize(layout)

def handler (sugnum, frame):
    global do_summary
    do_summary = True

signal.signal(signal.SIGALRM, handler)

if server is not None:
    tx_seq = 0
    rv = socket.getaddrinfo(server, port, *socket_params)
    connect_addr = rv[0][4]
    print 'Sending %u-octet packets to to %s' % (tx_length, connect_addr,)
    payload_fill = ''
    if tx_length > layout_length:
        payload_fill = ' ' * (tx_length - layout_length)
    do_summary = True
    poller = select.poll()
    poller.register(sfd, select.POLLIN)
    while True:
        if do_summary:
            do_summary = False
            now = time.time()
            if summary_last_now is not None:
                interval = now - summary_last_now
                print 'tx_bytes=%u tx_packets=%u rx_bytes=%u rx_packets=%u rx_lost=%u' % (tx_bytes, tx_packets, rx_bytes, rx_packets, rx_lost)
                if ((0 != interval) and (0 != rx_packets)):
                    tx_rate = tx_bytes / interval
                    rtt = interval / tx_packets
                    print 'tx_rate=%g rtt=%g loss_perc=%.3g interval=%g' % (tx_rate, rtt, (100.0 * rx_lost) / tx_packets, interval) 
            tx_bytes = rx_bytes = 0
            tx_packets = rx_packets = 0
            rx_lost = 0
            summary_last_now = now
            signal.alarm(summary_interval_sec)
        tx_seq = 0xFFFF & (tx_seq + 1)
        payload = struct.pack('!HH', rx_length, tx_seq) + payload_fill
        while True:
            try:
                tx_bytes += sfd.sendto(payload, connect_addr)
                tx_packets += 1
                break
            except socket.error, e:
                if errno.EINTR != e.errno:
                    raise
        while True:
            try:
                rc = poller.poll(wait_msec)
                if rc:
                    (payload, sender) = sfd.recvfrom(16384)
                    rx_packets += 1
                    rx_bytes += len(payload)
                else:
                    rx_lost += 1
                break
            except (socket.error, select.error), e:
                if isinstance(e, socket.error) and (errno.EINTR != e.errno):
                    raise
        (_, rx_seq) = struct.unpack(layout, payload[:layout_length])
        if rx_seq != tx_seq:
            rx_nosync += 1
else:
    rv = socket.getaddrinfo(listen, port, *socket_params)
    bind_addr = rv[0][4]
    rc = sfd.bind(bind_addr)
    print 'Receiving'
    while True:
        (payload, sender) = sfd.recvfrom(16384)
        (rx_length, tx_seq) = struct.unpack(layout, payload[:layout_length]);
        if (len(payload) < rx_length):
            payload += '@' * (rx_length - len(payload))
        else:
            payload = payload[:rx_length]
        rc = sfd.sendto(payload, sender)

        
