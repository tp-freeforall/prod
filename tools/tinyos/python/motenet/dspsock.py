#!/usr/bin/env python3

import pdb
from   socket import *

AF_AM = 20

af_dict    = { AF_INET   : 'ipv4',    \
               AF_INET6  : 'ipv6',    \
               AF_UNIX   : 'unix',    \
               AF_AM     : 'am',      \
               AF_UNSPEC : 'unspec'   \
             }

sock_dict  = { SOCK_STREAM : 'stream', \
               SOCK_DGRAM  : 'dgram',  \
               SOCK_RAW    : 'raw'     \
             }

proto_dict = { IPPROTO_UDP : 'udp', \
               IPPROTO_TCP : 'tcp', \
               IPPROTO_RAW : 'raw'  \
             }


def dsp_af(af):
    fam = af_dict.get(af, 'af_none')
    return fam

def dsp_type(st):
    t = sock_dict.get(st, 'sock_none')
    return t

def dsp_proto(sp):
    p = proto_dict.get(sp, 'proto_none')
    return p

def dsp_addrinfo(ai):
    af, st, p, cn, sa = ai
    return "({:s}, {:s}, {:s}, '{:s}', {:s})".format(dsp_af(af), dsp_type(st), dsp_proto(p), cn, repr(sa))


import socket

def main():
#    pdb.set_trace()
    res = socket.getaddrinfo("localhost", "", socket.AF_UNSPEC)
    print(res)
    for res in socket.getaddrinfo("localhost", "", socket.AF_UNSPEC):
        af, st, p, cn, sa = res
        print("{:s} \t: {:s}".format(repr(res), dsp_addrinfo(res)))


if __name__ == '__main__':
  main()
