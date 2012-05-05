README for SerialDirect
Author/Contact: Eric B. Decker <cire831@gmail.com>

Description:

Simple test program using low level Hpl interface to msp430
serial port.  (handles different processors using defines, X1,
X2, X5).   Unfortunately they are different at the HPL level.

Sends the sequence 00 through ff and repeats.
Used for platform bringup.

See support/sdk/python/misc/serlook.py for a python program that
displays anything from the serial port.
