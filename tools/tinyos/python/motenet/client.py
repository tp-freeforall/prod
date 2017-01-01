#!/usr/bin/env python3

import pdb
import socket
import dspsock
import sys

sys.path.insert(0, '../misc')
from hexdump import *

AF_INET    = socket.AF_INET
SOCK_DGRAM = socket.SOCK_DGRAM

port = 8081
host = "192.168.1.7"

s = socket.socket(AF_INET, SOCK_DGRAM)
pdb.set_trace()
sa = s.getsockname()
da = (host, port)

s.connect(da)

out = ' '.join([repr(da), repr(sa)]).encode() + b' : cmd'
print(b2str(out))
#s.send(out)

data, addr = s.recvfrom(1024)
#data = s.recv(1024)
print("{:s}  <{:s}>".format(b2str(data), addr))

s.send(out)
data = s.recv(1024)
print(data, "+", addr, "+")

print
print(sys.version)
